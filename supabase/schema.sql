-- =============================================================================
-- TREADLY SUPABASE DATABASE SCHEMA (v2.0)
-- Includes:
--   - Lean Universal Tires
--   - Auth & Profiles
--   - Wallets (Balance & 5% Checkout Points)
--   - Universal Vouchers & User Voucher Redemption Tracking
--   - Purchases (Orders & Order Items)
--   - Auto-provisioning on Signup (Profile, Wallet, Initial Vouchers)
--   - Row Level Security (RLS)
-- =============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 2. TIRES (Cloud Catalog & Whitelist Feed)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.tires (
    id TEXT PRIMARY KEY,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    size TEXT NOT NULL,                -- e.g. '225/45 R18'
    width INT NOT NULL,                -- 225
    aspect_ratio INT NOT NULL,         -- 45
    rim_size INT NOT NULL,             -- 18
    category TEXT NOT NULL,            -- e.g. 'All-Season', 'Summer', 'All-Terrain'
    season TEXT NOT NULL DEFAULT 'All-Season',
    price NUMERIC(10, 2) NOT NULL,
    original_price NUMERIC(10, 2),
    rating NUMERIC(3, 2) NOT NULL DEFAULT 5.0,
    reviews_count INT NOT NULL DEFAULT 0,
    stock INT NOT NULL DEFAULT 0,
    dot_year INT,
    speed_rating TEXT,
    load_index INT,
    wet_grip TEXT,
    fuel_efficiency TEXT,
    noise_db INT,
    warranty_miles INT,
    description TEXT,
    compatible_cars JSONB,
    image_asset TEXT,
    image_url TEXT,                    -- URL to storage bucket or CDN
    is_whitelisted BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- =============================================================================
-- 3. PROFILES (Linked to Supabase Auth auth.users)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT 'Guest Driver',
    email TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- =============================================================================
-- 4. USER WALLETS (Matches Profile "My Wallet")
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.user_wallets (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    balance NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    vouchers_count INT NOT NULL DEFAULT 0,
    points_count INT NOT NULL DEFAULT 0,  -- 5% of each checkout item total
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- =============================================================================
-- 5. VOUCHERS (Universal Catalog of Vouchers for Everyone)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.vouchers (
    id TEXT PRIMARY KEY,               -- e.g. 'WELCOME500', 'SUMMER-TIRE-10'
    code TEXT NOT NULL UNIQUE,         -- 'WELCOME500'
    title TEXT NOT NULL,               -- '₱500 Off First Set'
    discount_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    min_spend NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- =============================================================================
-- 6. USER VOUCHERS (Tracks individual redemption: is_available changes to false when used)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.user_vouchers (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    voucher_id TEXT NOT NULL REFERENCES public.vouchers(id) ON DELETE CASCADE,
    is_available BOOLEAN NOT NULL DEFAULT true,  -- changes to false when redeemed!
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    UNIQUE(user_id, voucher_id)
);

-- =============================================================================
-- 7. CART ITEMS (Active Cart Synchronized to Cloud for Authenticated Users)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.cart_items (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    tire_id TEXT NOT NULL REFERENCES public.tires(id) ON DELETE CASCADE,
    quantity INT NOT NULL DEFAULT 1,
    is_set_of_four BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    UNIQUE(user_id, tire_id, is_set_of_four)
);

-- =============================================================================
-- 8. ORDERS & ORDER ITEMS (Matches Profile "My Purchases")
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.orders (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('to_ship', 'received', 'returns', 'cancelled')),
    total_amount NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id TEXT NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    tire_id TEXT NOT NULL REFERENCES public.tires(id) ON DELETE RESTRICT,
    quantity INT NOT NULL DEFAULT 1,
    price_at_purchase NUMERIC(10, 2) NOT NULL
);

-- =============================================================================
-- 8. USER ADDRESSES (Delivery Address for Checkout & Profile)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.user_addresses (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    recipient_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    street_address TEXT NOT NULL,
    city TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- =============================================================================
-- 9. AUTOMATION TRIGGER: Auto-create Profile, Wallet & Vouchers on Signup
-- =============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
    voucher_record RECORD;
    assigned_vouchers_count INT := 0;
BEGIN
    -- 1. Create user profile
    INSERT INTO public.profiles (id, name, email)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        NEW.email
    );

    -- 2. Assign all currently active vouchers to the new user
    FOR voucher_record IN SELECT id FROM public.vouchers WHERE is_active = true LOOP
        INSERT INTO public.user_vouchers (user_id, voucher_id, is_available)
        VALUES (NEW.id, voucher_record.id, true)
        ON CONFLICT (user_id, voucher_id) DO NOTHING;
        assigned_vouchers_count := assigned_vouchers_count + 1;
    END LOOP;

    -- 3. Create initial wallet with 0 balance, 0 points, and the voucher count
    INSERT INTO public.user_wallets (user_id, balance, vouchers_count, points_count)
    VALUES (NEW.id, 0.00, assigned_vouchers_count, 0);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger cleanly
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- 10. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

ALTER TABLE public.tires ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vouchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_vouchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_addresses ENABLE ROW LEVEL SECURITY;

-- 1. Tires: Public read
CREATE POLICY "Allow public read access for whitelisted tires"
    ON public.tires FOR SELECT
    USING (is_whitelisted = true);

-- 2. Profiles: Read & update own profile
CREATE POLICY "Users can view their own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- 3. Wallet: Read & update own wallet
CREATE POLICY "Users can view their own wallet"
    ON public.user_wallets FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own wallet"
    ON public.user_wallets FOR UPDATE
    USING (auth.uid() = user_id);

-- 4. Vouchers: Public read active vouchers
CREATE POLICY "Allow read access for active vouchers"
    ON public.vouchers FOR SELECT
    USING (is_active = true);

-- 5. User Vouchers: View, insert, & update own redemption status
CREATE POLICY "Users can view their own vouchers"
    ON public.user_vouchers FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own vouchers"
    ON public.user_vouchers FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own voucher status"
    ON public.user_vouchers FOR UPDATE
    USING (auth.uid() = user_id);

-- 6. Orders: View & insert own orders
CREATE POLICY "Users can view their own orders"
    ON public.orders FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own orders"
    ON public.orders FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own order items"
    ON public.order_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.orders
            WHERE orders.id = order_items.order_id
            AND orders.user_id = auth.uid()
        )
    );

-- 7. User Addresses: Full CRUD on own delivery address
CREATE POLICY "Users can view their own address"
    ON public.user_addresses FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own address"
    ON public.user_addresses FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own address"
    ON public.user_addresses FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own address"
    ON public.user_addresses FOR DELETE
    USING (auth.uid() = user_id);

-- =============================================================================
-- 11. INITIAL SEED DATA
-- =============================================================================

-- Seed Vouchers
INSERT INTO public.vouchers (id, code, title, discount_amount, min_spend, is_active)
VALUES
    ('welcome-500', 'WELCOME500', '₱500 Off Any Set of 4', 500.00, 3000.00, true),
    ('michelin-1000', 'MICHELIN1K', '₱1,000 Off Michelin Pilot Sport', 1000.00, 6000.00, true),
    ('first-ride-200', 'FIRST200', '₱200 Flat Welcome Voucher', 200.00, 1000.00, true)
ON CONFLICT (id) DO NOTHING;

-- Seed Tires (Clean 15 Modern Models with Full Specifications)
INSERT INTO public.tires (
    id, brand, model, size, width, aspect_ratio, rim_size, category, season,
    price, original_price, rating, reviews_count, stock, dot_year, speed_rating,
    load_index, wet_grip, fuel_efficiency, noise_db, warranty_miles, description,
    compatible_cars, image_asset, is_whitelisted
) VALUES
(
    'michelin-pilot-sport-5', 'Michelin', 'Pilot Sport 5', '225/45 R18',
    225, 45, 18, 'Ultra High Performance Summer', 'Summer',
    219.99, 249.99, 4.9, 512, 36, 2024, 'Y',
    95, 'A', 'B', 68, 30000,
    '5th generation of Michelin''s iconic performance tire. Offers razor-sharp steering precision and supreme wet braking distance.',
    '["BMW 3 Series", "Mercedes C-Class", "Audi A4", "Tesla Model 3"]'::jsonb,
    'assets/images/tires/michelin_pilot_sport_5.webp', true
),
(
    'michelin-pilot-sport-all-season-4', 'Michelin', 'Pilot Sport All-Season 4', '245/40 R18',
    245, 40, 18, 'Ultra High Performance All-Season', 'All-Season',
    234.99, 269.99, 4.8, 384, 28, 2024, 'Y',
    97, 'A', 'B', 69, 45000,
    'Supercar-level all-weather grip. Standard equipment on Corvette C8 with 4% better dry braking and 5% better wet braking.',
    '["Chevrolet Corvette", "Audi S4", "BMW M340i", "Lexus IS350"]'::jsonb,
    'assets/images/tires/michelin_pilot_sport_all_season_4.webp', true
),
(
    'michelin-pilot-sport-cup-2', 'Michelin', 'Pilot Sport Cup 2', '295/30 R19',
    295, 30, 19, 'Street-Legal Track & Competition', 'Summer Track',
    389.99, 429.99, 4.9, 196, 14, 2024, 'Y',
    100, 'C', 'E', 73, 15000,
    'Bi-Compound technology developed for endurance championships. Designed for lightning track lap times on dry circuits.',
    '["Porsche 911 GT3", "BMW M3 CS", "Ferrari 488", "Mercedes-AMG GT"]'::jsonb,
    'assets/images/tires/michelin_pilot_sport_cup_2.webp', true
),
(
    'michelin-primacy-4-plus', 'Michelin', 'Primacy 4+', '215/55 R17',
    215, 55, 17, 'Premium Touring Comfort', 'Summer',
    169.99, 189.99, 4.7, 420, 45, 2024, 'V',
    94, 'A', 'A', 67, 55000,
    'EverGrip self-regenerating tread technology ensures whisper-quiet cabin acoustics and class-leading safety when worn.',
    '["Toyota Camry", "Honda Accord", "Volkswagen Passat", "Hyundai Sonata"]'::jsonb,
    'assets/images/tires/michelin_primacy_4_plus.webp', true
),
(
    'michelin-e-primacy', 'Michelin', 'e-Primacy Electric Drive', '235/40 R19',
    235, 40, 19, 'EV Energy Saving', 'Summer EV',
    209.99, 239.99, 4.8, 215, 22, 2024, 'W',
    96, 'B', 'A+', 66, 50000,
    'Eco-designed for Electric & Hybrid vehicles. Low rolling resistance extends vehicle battery range by up to 7%.',
    '["Tesla Model 3", "Hyundai Ioniq 5", "Kia EV6", "Polestar 2"]'::jsonb,
    'assets/images/tires/michelin_e_primacy.webp', true
),
(
    'michelin-crossclimate-2-suv', 'Michelin', 'Cross Climate 2 SUV', '235/60 R18',
    235, 60, 18, 'All-Weather Touring SUV', 'All-Weather (3PMSF)',
    219.99, 249.99, 4.9, 630, 30, 2024, 'V',
    107, 'B', 'B', 70, 60000,
    'Distinctive V-shaped directional tread pattern certified for severe snow conditions without switching tires seasonally.',
    '["Toyota RAV4", "Honda CR-V", "Subaru Forester", "Mazda CX-5"]'::jsonb,
    'assets/images/tires/michelin_crossclimate_2_suv.webp', true
),
(
    'continental-extremecontact-dws06-plus', 'Continental', 'Extreme Contact DWS06 Plus', '225/45 R18',
    225, 45, 18, 'Ultra High Performance All-Season', 'All-Season',
    194.99, 219.99, 4.9, 890, 52, 2024, 'Y',
    95, 'A', 'C', 71, 50000,
    'Tuned Performance Indicators (D, W, S) stamped directly on tread to alert drivers when tire is optimized for Dry, Wet, or Snow.',
    '["BMW 3 Series", "Subaru WRX", "Volkswagen Golf R", "Audi S3"]'::jsonb,
    'assets/images/tires/continental_extremecontact_dws06_plus.webp', true
),
(
    'continental-extremecontact-sport-02', 'Continental', 'Extreme Contact Sport 02', '245/40 R19',
    245, 40, 19, 'Ultra High Performance Summer', 'Summer',
    242.99, 275.99, 4.8, 310, 25, 2024, 'Y',
    98, 'A', 'C', 70, 30000,
    'Co-developed with professional IMSA race drivers. SportPlus technology provides immediate steering response and extreme cornering grip.',
    '["Ford Mustang GT", "Chevrolet Camaro", "BMW M2", "Porsche Cayman"]'::jsonb,
    'assets/images/tires/continental_extremecontact_sport_02.webp', true
),
(
    'continental-sportcontact-7', 'Continental', 'Sport Contact 7', '265/35 R20',
    265, 35, 20, 'Max Performance Supercar', 'Summer',
    319.99, 359.99, 4.9, 275, 18, 2024, 'Y',
    99, 'A', 'D', 72, 25000,
    'BlackChili compound formulation engineered for sports cars and high-powered GTs. Ranked #1 in major European tire tests.',
    '["BMW M4 Competition", "Audi RS5", "Mercedes-AMG C63", "Porsche 911"]'::jsonb,
    'assets/images/tires/continental_sportcontact_7.webp', true
),
(
    'continental-ultracontact-uc7', 'Continental', 'Ultra Contact UC7', '205/55 R16',
    205, 55, 16, 'Daily Touring Safety & Noise', 'Summer',
    149.99, 172.99, 4.7, 480, 60, 2024, 'V',
    91, 'A', 'B', 67, 50000,
    'Diamond compound with Noise Breaker 3.0 interrupts sound waves in tire grooves to deliver an ultra-quiet cabin ride.',
    '["Toyota Corolla", "Honda Civic", "Mazda 3", "Volkswagen Jetta"]'::jsonb,
    'assets/images/tires/continental_ultracontact_uc7.webp', true
),
(
    'continental-terraincontact-at', 'Continental', 'Terrain Contact A/T', '265/70 R17',
    265, 70, 17, 'All-Terrain Truck & SUV', 'All-Terrain (3PMSF)',
    259.99, 289.99, 4.8, 520, 24, 2024, 'T',
    115, 'A', 'D', 72, 60000,
    'TractionPlus technology strikes the perfect balance between off-road durability (gravel, dirt, rock) and quiet highway comfort.',
    '["Ford F-150", "Toyota Tacoma", "Jeep Wrangler", "Chevrolet Silverado"]'::jsonb,
    'assets/images/tires/continental_terraincontact_at.webp', true
),
(
    'continental-crosscontact-lx25', 'Continental', 'Cross Contact LX25', '235/55 R19',
    235, 55, 19, 'Premium Crossover / SUV Touring', 'All-Season',
    224.99, 254.99, 4.8, 340, 35, 2024, 'H',
    105, 'A', 'B', 68, 70000,
    'EcoPlus technology saves fuel while providing best-in-class wet braking and an impressive 70,000-mile treadwear warranty.',
    '["Lexus RX350", "Audi Q5", "Acura MDX", "Volvo XC60"]'::jsonb,
    'assets/images/tires/continental_crosscontact_lx25.webp', true
),
(
    'continental-vikingcontact-7', 'Continental', 'Viking Contact 7', '225/50 R17',
    225, 50, 17, 'Nordic Winter / Ice & Snow', 'Winter (Studless)',
    184.99, 209.99, 4.9, 415, 20, 2024, 'T',
    98, 'B', 'C', 67, 40000,
    'Nordic silica compound remains flexible in sub-zero temperatures with 3D sipes locking together for unmatched braking on black ice.',
    '["Volvo S60", "Audi A4 Quattro", "BMW 3 Series xDrive", "Subaru Outback"]'::jsonb,
    'assets/images/tires/continental_vikingcontact_7.webp', true
),
(
    'pirelli-p-zero-pz4', 'Pirelli', 'P Zero (PZ4) Luxury', '245/40 R19',
    245, 40, 19, 'Ultra High Performance Luxury', 'Summer',
    279.99, 319.99, 4.8, 390, 28, 2024, 'Y',
    98, 'A', 'B', 69, 35000,
    'Original equipment for prestige automakers. High silica content provides exceptional wet safety and low rolling resistance.',
    '["Mercedes-Benz E-Class", "BMW 5 Series", "Audi A6", "Jaguar XF"]'::jsonb,
    'assets/images/tires/pirelli_p_zero_pz4.webp', true
),
(
    'goodyear-eagle-f1-asymmetric-6', 'Goodyear', 'Eagle F1 Asymmetric 6', '225/45 R18',
    225, 45, 18, 'Ultra High Performance EV-Ready', 'Summer',
    199.99, 229.99, 4.8, 450, 38, 2024, 'Y',
    95, 'A', 'B', 69, 45000,
    'Dry Contact Plus technology adapts tire footprint to driving style. EV-ready construction with noise-canceling foam layer.',
    '["Tesla Model 3", "BMW 3 Series", "Polestar 2", "Volkswagen Golf GTI"]'::jsonb,
    'assets/images/tires/goodyear_eagle_f1_asymmetric_6.webp', true
)
ON CONFLICT (id) DO UPDATE SET
    brand = EXCLUDED.brand,
    model = EXCLUDED.model,
    size = EXCLUDED.size,
    width = EXCLUDED.width,
    aspect_ratio = EXCLUDED.aspect_ratio,
    rim_size = EXCLUDED.rim_size,
    category = EXCLUDED.category,
    season = EXCLUDED.season,
    price = EXCLUDED.price,
    original_price = EXCLUDED.original_price,
    rating = EXCLUDED.rating,
    reviews_count = EXCLUDED.reviews_count,
    stock = EXCLUDED.stock,
    dot_year = EXCLUDED.dot_year,
    speed_rating = EXCLUDED.speed_rating,
    load_index = EXCLUDED.load_index,
    wet_grip = EXCLUDED.wet_grip,
    fuel_efficiency = EXCLUDED.fuel_efficiency,
    noise_db = EXCLUDED.noise_db,
    warranty_miles = EXCLUDED.warranty_miles,
    description = EXCLUDED.description,
    compatible_cars = EXCLUDED.compatible_cars,
    image_asset = EXCLUDED.image_asset,
    is_whitelisted = EXCLUDED.is_whitelisted,
    updated_at = timezone('utc'::text, now());

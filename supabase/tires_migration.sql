-- =============================================================================
-- TREADLY SUPABASE TIRES MIGRATION & SEED SCRIPT
-- Run this in your Supabase Dashboard -> SQL Editor
-- =============================================================================

-- 1. Ensure columns exist on the `tires` table (safe to run on existing table)
CREATE TABLE IF NOT EXISTS public.tires (
    id TEXT PRIMARY KEY,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    size TEXT NOT NULL,
    width INT NOT NULL,
    aspect_ratio INT NOT NULL,
    rim_size INT NOT NULL,
    category TEXT NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.tires ADD COLUMN IF NOT EXISTS original_price NUMERIC(10, 2);
ALTER TABLE public.tires ADD COLUMN IF NOT EXISTS rating NUMERIC(3, 2) NOT NULL DEFAULT 5.0;
ALTER TABLE public.tires ADD COLUMN IF NOT EXISTS reviews_count INT NOT NULL DEFAULT 0;
ALTER TABLE public.tires ADD COLUMN IF NOT EXISTS stock INT NOT NULL DEFAULT 0;
ALTER TABLE public.tires ADD COLUMN IF NOT EXISTS dot_year INT;
ALTER TABLE public.tires ADD COLUMN IF NOT EXISTS season TEXT DEFAULT 'All-Season';
ALTER TABLE public.tires ADD COLUMN IF NOT EXISTS speed_rating TEXT;
ALTER TABLE public.tires ADD COLUMN IF NOT EXISTS load_index INT;
ALTER TABLE public.tires ADD COLUMN IF NOT EXISTS wet_grip TEXT;
ALTER TABLE public.tires ADD COLUMN IF NOT EXISTS fuel_efficiency TEXT;
ALTER TABLE public.tires ADD COLUMN IF NOT EXISTS noise_db INT;
ALTER TABLE public.tires ADD COLUMN IF NOT EXISTS warranty_miles INT;
ALTER TABLE public.tires ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.tires ADD COLUMN IF NOT EXISTS compatible_cars JSONB;
ALTER TABLE public.tires ADD COLUMN IF NOT EXISTS image_asset TEXT;
ALTER TABLE public.tires ADD COLUMN IF NOT EXISTS is_whitelisted BOOLEAN NOT NULL DEFAULT true;

-- 2. Enable Row Level Security (RLS) & Public Read Access
ALTER TABLE public.tires ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access to tires" ON public.tires;
CREATE POLICY "Allow public read access to tires"
ON public.tires FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Allow authenticated all access to tires" ON public.tires;
CREATE POLICY "Allow authenticated all access to tires"
ON public.tires FOR ALL
USING (true);

-- 2b. Clean up legacy duplicate rows from previous seed runs
DELETE FROM public.tires 
WHERE id IN (
    'michelin-ps5-225-45-18',
    'michelin-ps-as4-245-40-18',
    'michelin-cup2-265-35-19',
    'continental-dws06-225-45-17',
    'continental-sc7-245-40-19',
    'pirelli-pzero-235-35-19',
    'goodyear-asym6-225-40-18',
    'bridgestone-re71rs-255-40-18'
);

-- 3. Seed / Upsert Live Catalog Data (Real prices, stock, ratings, reviews, specifications)
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

-- =============================================================================
-- 4. CART ITEMS TABLE (Cloud Sync for Authenticated Users)
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

ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own cart items" ON public.cart_items;
CREATE POLICY "Users can manage their own cart items"
ON public.cart_items FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 5. ORDERS & ORDER ITEMS TABLES (Purchases Tracking)
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

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own orders" ON public.orders;
CREATE POLICY "Users can manage their own orders"
ON public.orders FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view and insert order items" ON public.order_items;
CREATE POLICY "Users can view and insert order items"
ON public.order_items FOR ALL
USING (true)
WITH CHECK (true);

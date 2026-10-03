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
    price NUMERIC(10, 2) NOT NULL,
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
-- 7. ORDERS & ORDER ITEMS (Matches Profile "My Purchases")
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

-- Seed Tires
INSERT INTO public.tires (id, brand, model, size, width, aspect_ratio, rim_size, category, price, is_whitelisted)
VALUES
    ('michelin-ps5-225-45-18', 'Michelin', 'Pilot Sport 5', '225/45 R18', 225, 45, 18, 'Summer', 219.99, true),
    ('michelin-ps-as4-245-40-18', 'Michelin', 'Pilot Sport All-Season 4', '245/40 R18', 245, 40, 18, 'All-Season', 234.99, true),
    ('michelin-cup2-265-35-19', 'Michelin', 'Pilot Sport Cup 2', '265/35 R19', 265, 35, 19, 'Track / Summer', 389.99, true),
    ('continental-dws06-225-45-17', 'Continental', 'ExtremeContact DWS06 Plus', '225/45 R17', 225, 45, 17, 'All-Season', 184.99, true),
    ('continental-sc7-245-40-19', 'Continental', 'SportContact 7', '245/40 R19', 245, 40, 19, 'Summer', 279.99, true),
    ('pirelli-pzero-235-35-19', 'Pirelli', 'P Zero PZ4', '235/35 R19', 235, 35, 19, 'Summer', 269.99, true),
    ('goodyear-asym6-225-40-18', 'Goodyear', 'Eagle F1 Asymmetric 6', '225/40 R18', 225, 40, 18, 'Summer', 198.99, true),
    ('bridgestone-re71rs-255-40-18', 'Bridgestone', 'Potenza RE-71RS', '255/40 R18', 255, 40, 18, 'Track / Summer', 295.00, true)
ON CONFLICT (id) DO NOTHING;

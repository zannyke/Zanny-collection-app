-- ═══════════════════════════════════════════════════════════════════════════
-- ZANNY COLLECTION — Supabase Database Schema
-- Run this in your Supabase SQL Editor to set up the full schema
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Enable UUID extension ────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── CATEGORIES ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.categories (
  slug          TEXT PRIMARY KEY,
  name          TEXT NOT NULL,
  description   TEXT,
  image_url     TEXT,
  display_order INTEGER DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Seed all 9 categories
INSERT INTO public.categories (slug, name, description, image_url, display_order) VALUES
  ('new-arrivals',     'New Arrivals',         'Fresh drops straight from the streets', NULL, 1),
  ('shirts-t-shirts',  'Shirts & T-Shirts',    'Premium cuts for the modern wardrobe',  NULL, 2),
  ('hoodies',          'Hoodies',               'Cozy and street-ready',                NULL, 3),
  ('sweaters',         'Sweaters',              'Elevated comfort',                     NULL, 4),
  ('shorts-sweatpants','Shorts & Sweatpants',  'Comfort meets culture',                NULL, 5),
  ('shoes',            'Shoes',                 'Step up your game',                    NULL, 6),
  ('innerwear',        'Innerwear',             'The foundation of style',              NULL, 7),
  ('accessories',      'Accessories',           'The finishing touch',                  NULL, 8),
  ('sale',             'Sale',                  'Premium at a lower price',             NULL, 9)
ON CONFLICT (slug) DO NOTHING;

-- ── PRODUCTS ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.products (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            TEXT NOT NULL,
  subtitle        TEXT,
  description     TEXT,
  price           NUMERIC(10,2) NOT NULL,
  original_price  NUMERIC(10,2),
  images          JSONB DEFAULT '[]'::jsonb,   -- array of image URLs
  colors          JSONB DEFAULT '[]'::jsonb,   -- array of color strings
  sizes           JSONB DEFAULT '[]'::jsonb,   -- array of size strings
  category_slug   TEXT REFERENCES public.categories(slug) ON DELETE SET NULL,
  is_new          BOOLEAN DEFAULT FALSE,
  is_sale         BOOLEAN DEFAULT FALSE,
  is_active       BOOLEAN DEFAULT TRUE,
  stock           INTEGER DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast category lookups
CREATE INDEX IF NOT EXISTS products_category_idx ON public.products(category_slug);
CREATE INDEX IF NOT EXISTS products_is_new_idx ON public.products(is_new);
CREATE INDEX IF NOT EXISTS products_is_sale_idx ON public.products(is_sale);

-- Full-text search index
CREATE INDEX IF NOT EXISTS products_fts_idx ON public.products
  USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '')));

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS products_updated_at ON public.products;
CREATE TRIGGER products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── PROFILES (extends Supabase auth.users) ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email         TEXT,
  full_name     TEXT,
  phone         TEXT,
  avatar_url    TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── WISHLIST ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.wishlists (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id  UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

CREATE INDEX IF NOT EXISTS wishlists_user_idx ON public.wishlists(user_id);

-- ── ADDRESSES ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.addresses (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  label         TEXT DEFAULT 'Home',  -- Home, Work, etc.
  full_name     TEXT NOT NULL,
  phone         TEXT NOT NULL,
  address_line1 TEXT NOT NULL,
  address_line2 TEXT,
  city          TEXT NOT NULL,
  county        TEXT,
  is_default    BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── ORDERS ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.orders (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  order_number    TEXT UNIQUE NOT NULL,
  status          TEXT DEFAULT 'pending',
  -- status values: pending | confirmed | processing | shipped | delivered | cancelled
  items           JSONB NOT NULL,   -- snapshot of cart items at time of order
  subtotal        NUMERIC(10,2) NOT NULL,
  shipping_fee    NUMERIC(10,2) DEFAULT 250,
  total           NUMERIC(10,2) NOT NULL,
  shipping_address JSONB,
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS orders_user_idx ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS orders_status_idx ON public.orders(status);

DROP TRIGGER IF EXISTS orders_updated_at ON public.orders;
CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-generate human-readable order numbers
CREATE SEQUENCE IF NOT EXISTS order_number_seq START 1000;
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.order_number := 'ZC-' || LPAD(NEXTVAL('order_number_seq')::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_order_number ON public.orders;
CREATE TRIGGER set_order_number
  BEFORE INSERT ON public.orders
  FOR EACH ROW WHEN (NEW.order_number IS NULL OR NEW.order_number = '')
  EXECUTE FUNCTION generate_order_number();

-- ── PUSH NOTIFICATION TOKENS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.fcm_tokens (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  token       TEXT NOT NULL,
  platform    TEXT,  -- 'android' or 'ios'
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, token)
);

-- ══════════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- ══════════════════════════════════════════════════════════════════════════════

-- Products: anyone can read active products
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "products_public_read" ON public.products;
CREATE POLICY "products_public_read" ON public.products FOR SELECT USING (is_active = TRUE);

-- Categories: public read
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "categories_public_read" ON public.categories;
CREATE POLICY "categories_public_read" ON public.categories FOR SELECT USING (TRUE);

-- Profiles: users can only read/write their own
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "profiles_own" ON public.profiles;
CREATE POLICY "profiles_own" ON public.profiles USING (auth.uid() = id);

-- Wishlist: users manage their own
ALTER TABLE public.wishlists ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "wishlist_own" ON public.wishlists;
CREATE POLICY "wishlist_own" ON public.wishlists USING (auth.uid() = user_id);

-- Addresses: users manage their own
ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "addresses_own" ON public.addresses;
CREATE POLICY "addresses_own" ON public.addresses USING (auth.uid() = user_id);

-- Orders: users see only their own orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "orders_own_read" ON public.orders;
CREATE POLICY "orders_own_read" ON public.orders FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "orders_own_insert" ON public.orders;
CREATE POLICY "orders_own_insert" ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);

-- FCM tokens: own
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "fcm_tokens_own" ON public.fcm_tokens;
CREATE POLICY "fcm_tokens_own" ON public.fcm_tokens USING (auth.uid() = user_id);

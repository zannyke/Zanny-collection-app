-- Zanny Collection — Unified Database Schema
-- Shared between the Flutter mobile app and the Cloudflare Pages website

-- ── Users ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id             TEXT PRIMARY KEY,
  email          TEXT UNIQUE NOT NULL,
  password_hash  TEXT,
  salt           TEXT,
  first_name     TEXT DEFAULT '',
  last_name      TEXT DEFAULT '',
  full_name      TEXT DEFAULT '',
  phone          TEXT DEFAULT '',
  phone_number   TEXT DEFAULT '',
  avatar_url     TEXT DEFAULT '',
  role           TEXT DEFAULT 'customer',
  is_admin       INTEGER DEFAULT 0,
  is_verified    INTEGER DEFAULT 0,
  auth_provider  TEXT DEFAULT 'local', -- 'local' or 'google'
  login_count    INTEGER DEFAULT 0,
  last_login     TEXT,
  fcm_token      TEXT DEFAULT '',
  consecutive_cancellations INTEGER DEFAULT 0,
  restricted_from_cod INTEGER DEFAULT 0,
  consecutive_successful_orders INTEGER DEFAULT 0,
  default_delivery_zone TEXT DEFAULT '',
  default_address TEXT DEFAULT '',
  created_at     TEXT DEFAULT (datetime('now'))
);

-- ── Products ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id             TEXT PRIMARY KEY,
  name           TEXT NOT NULL,
  subtitle       TEXT DEFAULT '',
  discount_label TEXT DEFAULT '',
  description    TEXT DEFAULT '',
  price          REAL NOT NULL,
  original_price REAL,
  category       TEXT DEFAULT '',
  category_slug  TEXT DEFAULT '',
  image_url      TEXT DEFAULT '',
  gallery_urls   TEXT DEFAULT '[]',
  images         TEXT DEFAULT '[]',
  colors         TEXT DEFAULT '[]',
  sizes          TEXT DEFAULT '[]',
  variations     TEXT DEFAULT '[]',
  stock          INTEGER DEFAULT 10,
  sold           INTEGER DEFAULT 0,
  badge          TEXT DEFAULT '',
  is_new         INTEGER DEFAULT 0,
  is_sale        INTEGER DEFAULT 0,
  is_active      INTEGER DEFAULT 1,
  is_deleted     INTEGER DEFAULT 0,
  created_at     TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_slug);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_new ON products(is_new);
CREATE INDEX IF NOT EXISTS idx_products_sale ON products(is_sale);

-- ── Wishlists ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS wishlists (
  user_id    TEXT NOT NULL,
  product_id TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now')),
  PRIMARY KEY (user_id, product_id),
  FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE INDEX IF NOT EXISTS idx_wishlists_user ON wishlists(user_id);

-- ── Orders ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
  id                      TEXT PRIMARY KEY,
  user_id                 TEXT NOT NULL,
  items                   TEXT NOT NULL DEFAULT '[]',
  total_amount            REAL NOT NULL DEFAULT 0,
  status                  TEXT DEFAULT 'pending',
  delivery_address        TEXT DEFAULT '',
  shipping_address        TEXT DEFAULT '',
  recipient_name          TEXT DEFAULT '',
  recipient_phone         TEXT DEFAULT '',
  phone_number            TEXT DEFAULT '',
  mpesa_checkout_id       TEXT DEFAULT '',
  mpesa_receipt           TEXT DEFAULT '',
  mpesa_phone             TEXT DEFAULT '',
  review_prompt_dismissed INTEGER DEFAULT 0,
  tracking_number         TEXT DEFAULT '',
  confirmed_at            TEXT,
  shipped_at              TEXT,
  delivered_at            TEXT,
  created_at              TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);

-- ── Street Styles ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS street_styles (
  id          TEXT PRIMARY KEY,
  images      TEXT DEFAULT '[]',
  username    TEXT DEFAULT '',
  location    TEXT DEFAULT '',
  description TEXT DEFAULT '',
  created_at  TEXT DEFAULT (datetime('now'))
);

-- ── Sessions (Website Sessions) ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  device_name TEXT,
  expires_at TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ── Verification Codes ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS verification_codes (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);

-- ── Cart Items ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cart_items (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL,
  product_id  TEXT NOT NULL,
  quantity    INTEGER DEFAULT 1,
  size        TEXT DEFAULT '',
  color       TEXT DEFAULT '',
  created_at  TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_cart_items_user ON cart_items(user_id);

-- ── Feedback ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS feedback (
  id          TEXT PRIMARY KEY,
  order_id    TEXT NOT NULL,
  product_id  TEXT,
  user_id     TEXT,
  rating      INTEGER NOT NULL,
  comment     TEXT DEFAULT '',
  created_at  TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (product_id) REFERENCES products(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_feedback_order ON feedback(order_id);
CREATE INDEX IF NOT EXISTS idx_feedback_product ON feedback(product_id);
CREATE INDEX IF NOT EXISTS idx_feedback_user ON feedback(user_id);



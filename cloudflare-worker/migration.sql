CREATE TABLE IF NOT EXISTS style_likes (
  style_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now')),
  PRIMARY KEY (style_id, user_id)
);

CREATE TABLE IF NOT EXISTS style_comments (
  id TEXT PRIMARY KEY,
  style_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  username TEXT NOT NULL,
  comment TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);

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

-- ── Password Resets ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS password_resets (
  email      TEXT PRIMARY KEY,
  token      TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_password_resets_token ON password_resets(token);

-- ── Pre-Order Support ────────────────────────────────────────────────────────
ALTER TABLE products ADD COLUMN is_preorder INTEGER DEFAULT 0;
ALTER TABLE orders ADD COLUMN stripe_session_id TEXT DEFAULT '';


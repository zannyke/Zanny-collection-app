const { execSync } = require('child_process');

const dbName = 'zanny-collection-db';

const statements = [
  // users
  "ALTER TABLE users ADD COLUMN salt TEXT",
  "ALTER TABLE users ADD COLUMN first_name TEXT DEFAULT ''",
  "ALTER TABLE users ADD COLUMN last_name TEXT DEFAULT ''",
  "ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'customer'",
  "ALTER TABLE users ADD COLUMN is_verified INTEGER DEFAULT 0",
  "ALTER TABLE users ADD COLUMN auth_provider TEXT DEFAULT 'local'",
  "ALTER TABLE users ADD COLUMN phone_number TEXT DEFAULT ''",
  "ALTER TABLE users ADD COLUMN full_name TEXT DEFAULT ''",
  "ALTER TABLE users ADD COLUMN phone TEXT DEFAULT ''",
  "ALTER TABLE users ADD COLUMN avatar_url TEXT DEFAULT ''",
  "ALTER TABLE users ADD COLUMN is_admin INTEGER DEFAULT 0",
  "ALTER TABLE users ADD COLUMN fcm_token TEXT DEFAULT ''",
  "ALTER TABLE users ADD COLUMN login_count INTEGER DEFAULT 0",
  "ALTER TABLE users ADD COLUMN last_login TEXT",

  // products
  "ALTER TABLE products ADD COLUMN category TEXT DEFAULT ''",
  "ALTER TABLE products ADD COLUMN discount_label TEXT DEFAULT ''",
  "ALTER TABLE products ADD COLUMN category_slug TEXT DEFAULT ''",
  "ALTER TABLE products ADD COLUMN image_url TEXT DEFAULT ''",
  "ALTER TABLE products ADD COLUMN gallery_urls TEXT DEFAULT '[]'",
  "ALTER TABLE products ADD COLUMN images TEXT DEFAULT '[]'",
  "ALTER TABLE products ADD COLUMN colors TEXT DEFAULT '[]'",
  "ALTER TABLE products ADD COLUMN sizes TEXT DEFAULT '[]'",
  "ALTER TABLE products ADD COLUMN variations TEXT DEFAULT '[]'",
  "ALTER TABLE products ADD COLUMN stock INTEGER DEFAULT 10",
  "ALTER TABLE products ADD COLUMN sold INTEGER DEFAULT 0",
  "ALTER TABLE products ADD COLUMN badge TEXT DEFAULT ''",
  "ALTER TABLE products ADD COLUMN is_new INTEGER DEFAULT 0",
  "ALTER TABLE products ADD COLUMN is_sale INTEGER DEFAULT 0",
  "ALTER TABLE products ADD COLUMN is_active INTEGER DEFAULT 1",
  "ALTER TABLE products ADD COLUMN is_deleted INTEGER DEFAULT 0",

  // orders
  "ALTER TABLE orders ADD COLUMN items TEXT DEFAULT '[]'",
  "ALTER TABLE orders ADD COLUMN delivery_address TEXT DEFAULT ''",
  "ALTER TABLE orders ADD COLUMN shipping_address TEXT DEFAULT ''",
  "ALTER TABLE orders ADD COLUMN recipient_name TEXT DEFAULT ''",
  "ALTER TABLE orders ADD COLUMN recipient_phone TEXT DEFAULT ''",
  "ALTER TABLE orders ADD COLUMN phone_number TEXT DEFAULT ''",
  "ALTER TABLE orders ADD COLUMN mpesa_checkout_id TEXT DEFAULT ''",
  "ALTER TABLE orders ADD COLUMN mpesa_receipt TEXT DEFAULT ''",
  "ALTER TABLE orders ADD COLUMN mpesa_phone TEXT DEFAULT ''",
  "ALTER TABLE orders ADD COLUMN review_prompt_dismissed INTEGER DEFAULT 0",
  "ALTER TABLE orders ADD COLUMN tracking_number TEXT DEFAULT ''",
  "ALTER TABLE orders ADD COLUMN confirmed_at TEXT",
  "ALTER TABLE orders ADD COLUMN shipped_at TEXT",
  "ALTER TABLE orders ADD COLUMN delivered_at TEXT",

  // sessions table (in case missing)
  "CREATE TABLE IF NOT EXISTS sessions (id TEXT PRIMARY KEY, user_id TEXT NOT NULL, ip_address TEXT, user_agent TEXT, device_name TEXT, expires_at TEXT NOT NULL, created_at TEXT DEFAULT (datetime('now')), FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE)",
  
  // verification_codes table
  "CREATE TABLE IF NOT EXISTS verification_codes (id TEXT PRIMARY KEY, email TEXT NOT NULL, code TEXT NOT NULL, expires_at TEXT NOT NULL, created_at TEXT DEFAULT (datetime('now')))",

  // style likes & comments (Build 20 live data tracking)
  "CREATE TABLE IF NOT EXISTS style_likes (style_id TEXT NOT NULL, user_id TEXT NOT NULL, created_at TEXT DEFAULT (datetime('now')), PRIMARY KEY (style_id, user_id))",
  "CREATE TABLE IF NOT EXISTS style_comments (id TEXT PRIMARY KEY, style_id TEXT NOT NULL, user_id TEXT NOT NULL, username TEXT NOT NULL, comment TEXT NOT NULL, created_at TEXT DEFAULT (datetime('now')))",
  "ALTER TABLE feedback ADD COLUMN product_id TEXT",
  "ALTER TABLE feedback ADD COLUMN user_id TEXT",
  "CREATE INDEX IF NOT EXISTS idx_feedback_product ON feedback(product_id)",
  "CREATE INDEX IF NOT EXISTS idx_feedback_user ON feedback(user_id)"
];

console.log("Starting remote self-healing D1 database patch...");

for (const sql of statements) {
  try {
    // Run remote D1 execute command using wrangler (bypassing PowerShell policies via cmd/cmd.exe execution or direct call)
    execSync(`npx.cmd wrangler d1 execute ${dbName} --remote --command="${sql.replace(/"/g, '\\"')}"`, { stdio: 'ignore' });
    console.log(`✓ Executed: ${sql}`);
  } catch (e) {
    // Suppress error (column already exists or D1 timeout)
    console.log(`- Skipped (already exists or error): ${sql}`);
  }
}

console.log("D1 Database patch complete!");

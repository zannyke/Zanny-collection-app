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

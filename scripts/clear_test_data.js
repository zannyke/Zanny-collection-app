const cp = require('child_process');
const path = require('path');

const wranglerConfig = path.join(__dirname, '../cloudflare-worker/wrangler.toml');
const dbName = 'zanny-collection-db';

function runD1Query(query) {
  try {
    const command = `npx.cmd wrangler d1 execute ${dbName} --remote --config="${wranglerConfig}" --command="${query.replace(/"/g, '\\"')}" --format=json`;
    const output = cp.execSync(command).toString();
    // Parse JSON output from wrangler D1
    const lines = output.split('\n');
    const jsonLine = lines.find(l => l.trim().startsWith('[') || l.trim().startsWith('{'));
    if (jsonLine) {
      const data = JSON.parse(jsonLine);
      return Array.isArray(data) ? data[0].results : data.results;
    }
    return [];
  } catch (e) {
    console.error(`❌ Failed to run query: ${query}\nError: ${e.message}`);
    return [];
  }
}

function runD1Execute(commandText) {
  try {
    const command = `npx.cmd wrangler d1 execute ${dbName} --remote --config="${wranglerConfig}" --command="${commandText.replace(/"/g, '\\"')}"`;
    cp.execSync(command, { stdio: 'inherit' });
    console.log(`✓ Executed D1 command: ${commandText}`);
  } catch (e) {
    console.error(`❌ Failed D1 command: ${commandText}\nError: ${e.message}`);
  }
}

function deleteR2Object(key) {
  if (!key) return;
  try {
    const command = `npx.cmd wrangler r2 object delete zanny-images/${key} --config="${wranglerConfig}"`;
    cp.execSync(command, { stdio: 'ignore' });
    console.log(`✓ Deleted R2 object: ${key}`);
  } catch (e) {
    console.error(`❌ Failed to delete R2 object: ${key}\nError: ${e.message}`);
  }
}

function extractKey(url) {
  if (!url || typeof url !== 'string') return null;
  // If it's a JSON array
  if (url.startsWith('[') && url.endsWith(']')) {
    try {
      const arr = JSON.parse(url);
      return arr.map(extractKey).filter(Boolean);
    } catch (e) {
      return null;
    }
  }
  // Try to parse url
  try {
    if (url.includes('r2.dev/')) {
      return url.split('r2.dev/')[1].split('?')[0];
    }
    if (url.startsWith('http')) {
      const parsed = new URL(url);
      return path.basename(parsed.pathname);
    }
    return url;
  } catch (e) {
    return url;
  }
}

console.log("==> Step 1: Gathering test image references from database...");

// Get product images
const products = runD1Query("SELECT image_url, gallery_urls FROM products");
const productKeys = new Set();
for (const p of products) {
  const mainKey = extractKey(p.image_url);
  if (mainKey && typeof mainKey === 'string') productKeys.add(mainKey);
  
  const galleryKeys = extractKey(p.gallery_urls);
  if (Array.isArray(galleryKeys)) {
    galleryKeys.forEach(k => productKeys.add(k));
  } else if (galleryKeys && typeof galleryKeys === 'string') {
    productKeys.add(galleryKeys);
  }
}

// Get street style images
const styles = runD1Query("SELECT images FROM street_styles");
const styleKeys = new Set();
for (const s of styles) {
  const keys = extractKey(s.images);
  if (Array.isArray(keys)) {
    keys.forEach(k => styleKeys.add(k));
  } else if (keys && typeof keys === 'string') {
    styleKeys.add(keys);
  }
}

console.log(`Found ${productKeys.size} product images and ${styleKeys.size} street style images to delete.`);

console.log("\n==> Step 2: Deleting images from Cloudflare R2 bucket...");
const allKeys = new Set([...productKeys, ...styleKeys]);
for (const key of allKeys) {
  // Avoid deleting critical assets
  if (key.endsWith('.apk') || key.includes('logo') || key === 'version.json') {
    console.log(`- Skipping protected system file: ${key}`);
    continue;
  }
  deleteR2Object(key);
}

console.log("\n==> Step 3: Cleaning D1 Database tables...");
const deleteStatements = [
  "DELETE FROM feedback",
  "DELETE FROM orders",
  "DELETE FROM order_items",
  "DELETE FROM cart_items",
  "DELETE FROM wishlists",
  "DELETE FROM products",
  "DELETE FROM street_styles",
  "DELETE FROM style_likes",
  "DELETE FROM style_comments",
  "DELETE FROM sessions",
  "DELETE FROM verification_codes",
  "DELETE FROM users WHERE is_admin = 0" // Retain admin users for production management
];

for (const sql of deleteStatements) {
  runD1Execute(sql);
}

console.log("\n🎉 Full production reset completed successfully! Database and R2 storage are clean.");

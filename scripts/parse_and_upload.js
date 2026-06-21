const cp = require('child_process');
const fs = require('fs');

console.log("==> Step 1: Loading service account JSON...");
const sa = JSON.parse(fs.readFileSync('scratch/service_account.json', 'utf8'));

const rawKey = sa.private_key;

const cleanKey = rawKey
  .replace(/-----BEGIN PRIVATE KEY-----/, "")
  .replace(/-----END PRIVATE KEY-----/, "")
  .replace(/\s/g, "")
  .replace(/\\n/g, "");

console.log(`Cleaned Key Length: ${cleanKey.length}`);
if (cleanKey.length % 4 !== 0) {
  console.error(`⚠️ WARNING: Cleaned key length (${cleanKey.length}) is NOT a multiple of 4!`);
  console.log("Suffix:", cleanKey.substring(cleanKey.length - 20));
} else {
  console.log("✅ Key length is valid (multiple of 4).");
}

try {
  const decoded = atob(cleanKey);
  console.log(`✅ Success! Decoded binary length: ${decoded.length}`);
} catch (err) {
  console.error(`❌ Local atob validation failed: ${err.message}`);
  process.exit(1);
}

const secrets = {
  FIREBASE_PROJECT_ID: sa.project_id,
  FIREBASE_CLIENT_EMAIL: sa.client_email,
  FIREBASE_PRIVATE_KEY: cleanKey
};

for (const [key, value] of Object.entries(secrets)) {
  console.log(`==> Setting wrangler secret ${key}...`);
  try {
    cp.execSync(`npx wrangler secret put ${key} -c cloudflare-worker/wrangler.toml`, {
      input: value,
      stdio: ['pipe', 'inherit', 'inherit']
    });
    console.log(`✅ Successfully set ${key}.\n`);
  } catch (err) {
    console.error(`❌ Failed to set ${key}:`, err.message);
    process.exit(1);
  }
}
console.log("🎉 All Firebase secrets successfully uploaded from parsed JSON!");

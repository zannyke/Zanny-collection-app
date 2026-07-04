const cp = require('child_process');
const fs = require('fs');

console.log("==> Step 1: Renaming the compiled APK...");
let renameOutput;
try {
  renameOutput = cp.execSync("C:\\flutter\\bin\\dart.bat run scripts/rename_apk.dart").toString();
  console.log(renameOutput);
} catch (err) {
  console.error("❌ Failed to rename APK:", err.message);
  process.exit(1);
}

// Extract both the filename and the full path from the rename output
const match = renameOutput.match(/SUCCESS: APK renamed to (zanny_collection_v[\d._]+\.apk) \(located at (.+)\)/);
if (!match) {
  console.error("❌ Could not extract renamed APK filename from output.");
  process.exit(1);
}
const apkName = match[1];
const apkFullPath = match[2].trim();
console.log(`Renamed APK file name: ${apkName}`);
console.log(`APK full path: ${apkFullPath}`);

console.log("\n==> Step 2: Reading version info from pubspec.yaml...");
const pubspecContent = fs.readFileSync('pubspec.yaml', 'utf8');
const versionMatch = pubspecContent.match(/^version:\s*([\d.]+)\+(\d+)/m);
if (!versionMatch) {
  console.error("❌ Failed to parse version from pubspec.yaml");
  process.exit(1);
}
const version = versionMatch[1];
const build = parseInt(versionMatch[2], 10);
console.log(`Version: ${version}, Build: ${build}`);

console.log("\n==> Step 3: Writing version.json locally...");
const changelog = "This update contains interface enhancements, theme optimizations, and general performance improvements to keep your streetwear shopping experience smooth.";
const workerUrl = "https://zanny-collection-api.zannykenya254.workers.dev";
const versionJson = {
  version: version,
  build: build,
  apk_url: `https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/${apkName}`,
  changelog: changelog
};
fs.writeFileSync('version.json', JSON.stringify(versionJson, null, 2) + "\n");
console.log("version.json written successfully.");

console.log(`\n==> Step 4: Uploading APK (${apkName}) to Cloudflare R2...`);
try {
  cp.execSync(`npx wrangler r2 object put zanny-images/${apkName} --file=${apkFullPath} --remote`, {
    stdio: 'inherit'
  });
  console.log("✅ APK uploaded successfully.");
} catch (err) {
  console.error("❌ Failed to upload APK to R2:", err.message);
  process.exit(1);
}

console.log("\n==> Step 5: Publishing version.json & sending FCM notifications via Worker API...");
const https = require('https');
const adminSecret = 'ZannyAdmin2024Secret';

const payloadStr = JSON.stringify(versionJson);
const options = {
  hostname: 'zanny-collection-api.zannykenya254.workers.dev',
  port: 443,
  path: '/api/version',
  method: 'PUT',
  headers: {
    'Content-Type': 'application/json',
    'X-Admin-Secret': adminSecret,
    'Content-Length': Buffer.byteLength(payloadStr)
  }
};

const req = https.request(options, (res) => {
  let body = '';
  res.on('data', chunk => body += chunk);
  res.on('end', () => {
    console.log(`✅ Version API responded with status: ${res.statusCode}`);
    console.log(`Response: ${body}`);
    if (res.statusCode === 200 || res.statusCode === 201) {
      console.log("\n🎉 Deployed successfully! Build is live and FCM push notification broadcasted!");
    } else {
      console.error("❌ Version publish failed.");
      process.exit(1);
    }
  });
});

req.on('error', (e) => {
  console.error("❌ Failed to publish version via Worker:", e.message);
  process.exit(1);
});

req.write(payloadStr);
req.end();

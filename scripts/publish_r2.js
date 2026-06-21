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

const match = renameOutput.match(/SUCCESS: APK renamed to (zanny_collection_v[\d._]+.apk)/);
if (!match) {
  console.error("❌ Could not extract renamed APK filename from output.");
  process.exit(1);
}
const apkName = match[1];
console.log(`Renamed APK file name: ${apkName}`);

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
const changelog = "Add Android POST_NOTIFICATIONS permission to enable system tray and lock-screen push alerts.";
const workerUrl = "https://zanny-collection-api.zannykenya254.workers.dev";
const versionJson = {
  version: version,
  build: build,
  apk_url: `${workerUrl}/api/images/${apkName}`,
  changelog: changelog
};
fs.writeFileSync('version.json', JSON.stringify(versionJson, null, 2) + "\n");
console.log("version.json written successfully.");

console.log(`\n==> Step 4: Uploading APK (${apkName}) to Cloudflare R2...`);
try {
  cp.execSync(`npx wrangler r2 object put zanny-images/${apkName} --file=build/app/outputs/flutter-apk/${apkName} --remote`, {
    stdio: 'inherit'
  });
  console.log("✅ APK uploaded successfully.");
} catch (err) {
  console.error("❌ Failed to upload APK to R2:", err.message);
  process.exit(1);
}

console.log("\n==> Step 5: Uploading version.json to Cloudflare R2...");
try {
  cp.execSync('npx wrangler r2 object put zanny-images/version.json --file=version.json --remote', {
    stdio: 'inherit'
  });
  console.log("✅ version.json uploaded successfully.");
} catch (err) {
  console.error("❌ Failed to upload version.json to R2:", err.message);
  process.exit(1);
}

console.log("\n🎉 Deployed successfully! Build is live!");

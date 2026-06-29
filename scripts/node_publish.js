const fs = require('fs');
const https = require('https');
const path = require('path');

const adminSecret = 'ZannyAdmin2024Secret';
const workerUrl = 'https://zanny-collection-api.zannykenya254.workers.dev';

const apkDir = 'build/app/outputs/flutter-apk';
const files = fs.readdirSync(apkDir);
const apkFiles = files.filter(f => f.startsWith('zanny_collection_v1.0.15_') && f.endsWith('.apk'));

if (apkFiles.length === 0) {
  console.error("❌ No zanny_collection_v1.0.15_*.apk found in " + apkDir);
  process.exit(1);
}

apkFiles.sort();
const apkKey = apkFiles[apkFiles.length - 1];
const apkPath = path.join(apkDir, apkKey);

console.log(`==> Found latest APK: ${apkKey}`);
console.log(`==> Step 1: Uploading APK to ${workerUrl}/api/upload...`);

const apkBytes = fs.readFileSync(apkPath);
const boundary = '----WebKitFormBoundary' + Math.random().toString(36).substring(2);

const header = Buffer.concat([
  Buffer.from(`--${boundary}\r\n`),
  Buffer.from(`Content-Disposition: form-data; name="key"\r\n\r\n`),
  Buffer.from(`${apkKey}\r\n`),
  Buffer.from(`--${boundary}\r\n`),
  Buffer.from(`Content-Disposition: form-data; name="file"; filename="${apkKey}"\r\n`),
  Buffer.from(`Content-Type: application/vnd.android.package-archive\r\n\r\n`)
]);

const footer = Buffer.from(`\r\n--${boundary}--\r\n`);
const reqBody = Buffer.concat([header, apkBytes, footer]);

const uploadOptions = {
  method: 'POST',
  headers: {
    'X-Admin-Secret': adminSecret,
    'Content-Type': `multipart/form-data; boundary=${boundary}`,
    'Content-Length': reqBody.length
  }
};

const uploadUrl = new URL(`${workerUrl}/api/upload`);
const req1 = https.request(uploadUrl, uploadOptions, (res) => {
  let body = '';
  res.on('data', chunk => body += chunk);
  res.on('end', () => {
    console.log(`✅ Upload API responded with status: ${res.statusCode}`);
    console.log(`Response: ${body}`);

    if (res.statusCode === 200 || res.statusCode === 201) {
      publishVersion();
    } else {
      console.error("❌ Upload failed.");
    }
  });
});

req1.on('error', e => console.error("❌ Upload request error:", e));
req1.write(reqBody);
req1.end();

function publishVersion() {
  console.log(`\n==> Step 2: Updating version info and triggering FCM notification...`);

  const versionPayload = JSON.stringify({
    version: '1.0.15',
    build: 34,
    apk_url: `https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/${apkKey}`,
    changelog: "Migrate admin review prompts, welcome alerts, package tracking, and layout shimmer skeleton stencils."
  });

  const versionOptions = {
    method: 'PUT',
    headers: {
      'X-Admin-Secret': adminSecret,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(versionPayload)
    }
  };

  const versionUrl = new URL(`${workerUrl}/api/version`);
  const req2 = https.request(versionUrl, versionOptions, (res) => {
    let body = '';
    res.on('data', chunk => body += chunk);
    res.on('end', () => {
      console.log(`✅ Version API responded with status: ${res.statusCode}`);
      console.log(`Response: ${body}`);
      console.log(`\n🎉 Success! Zanny Collection v1.0.15 (Build 34) is now live!`);
    });
  });

  req2.on('error', e => console.error("❌ Version request error:", e));
  req2.write(versionPayload);
  req2.end();
}

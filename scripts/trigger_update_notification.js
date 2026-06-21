const https = require('https');

const data = JSON.stringify({
  version: "1.0.14",
  build: 26,
  apk_url: "https://zanny-collection-api.zannykenya254.workers.dev/api/images/zanny_collection_v1.0.14_20260622_0111.apk",
  changelog: "Push notification functionality successfully verified on your device!"
});

const options = {
  hostname: 'zanny-collection-api.zannykenya254.workers.dev',
  port: 443,
  path: '/api/version',
  method: 'PUT',
  headers: {
    'Content-Type': 'application/json',
    'X-Admin-Secret': 'ZannyAdmin2024Secret',
    'Content-Length': Buffer.byteLength(data)
  }
};

console.log("==> Sending authenticated PUT /api/version request to trigger FCM broadcast...");
const req = https.request(options, (res) => {
  let body = '';
  res.on('data', (chunk) => body += chunk);
  res.on('end', () => {
    console.log(`✅ Server responded with status: ${res.statusCode}`);
    console.log(`Response: ${body}`);
  });
});

req.on('error', (e) => {
  console.error(`❌ Error triggering notification: ${e.message}`);
});

req.write(data);
req.end();

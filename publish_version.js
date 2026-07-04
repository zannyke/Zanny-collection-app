const versionPayload = {
  version: "1.0.33",
  build: 52,
  apk_url: "https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/zanny_collection_v1.0.33_20260701_0123.apk",
  changelog: "Implement true edge-to-edge system transparent status and navigation bars, and optimize status bar notification icons."
};

console.log("==> Step 3: Publishing version.json (v1.0.33 build 52) ...");

fetch("https://zanny-collection-api.zannykenya254.workers.dev/api/version", {
  method: "PUT",
  headers: {
    "Content-Type": "application/json",
    "X-Admin-Secret": "ZannyAdmin2024Secret"
  },
  body: JSON.stringify(versionPayload)
})
.then(res => res.json())
.then(data => {
  console.log("✅ version.json updated:", JSON.stringify(data, null, 2));
  console.log("🎉 Version 1.0.33 (build 52) is now live!");
})
.catch(err => {
  console.error("❌ Failed to update version:", err.message);
  process.exit(1);
});

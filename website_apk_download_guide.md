# Zanny Collection — Website APK Download & Dynamic Fetching Guide

This guide is designed for the website developer to integrate the **Zanny Collection Android App** download buttons dynamically with the release system.

---

## ⚠️ The Problem: Hardcoded Static APK URL
Currently, the website landing page has download buttons that point to a static file:
`https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/zanny_collection.apk`

This setup is **fragile** and will break or serve outdated code because:
1. The app release process uploads version-specific compiled files to R2 (e.g., `zanny_collection_v1.0.23_20260627_1139.apk`).
2. There is no automated process renaming or copying the latest file to `zanny_collection.apk`.
3. If an old APK is cached or the static URL doesn't exist, users will get failed downloads or run old versions.

---

## 🚀 The Solution: Dynamic Version Resolution
To ensure users always download the latest verified release of the Zanny Collection APK, the website must resolve the APK download link dynamically using the official Cloudflare Worker API.

### 📡 1. The Version API Endpoint
The frontend website must call the public version configuration endpoint:

* **Endpoint**: `GET https://zanny-collection-api.zannykenya254.workers.dev/api/version`
* **Authentication**: None (CORS is enabled for all domains)
* **Response Format (JSON)**:
```json
{
  "version": "1.0.23",
  "build": 42,
  "apk_url": "https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/zanny_collection_v1.0.23_20260627_1139.apk",
  "changelog": "Full production release: cleared sandbox testing data from database and storage. Redesigned in-app update progress with a premium double-tracked progress bar overriding layout."
}
```

---

## 🛠️ Implementation Methods

Here are two options to implement this on the website:

### Method A: Client-Side Fetch & Update (Recommended)
This approach runs on the client browser. It fetches the latest API details when the page loads, updates the download button links, and dynamically displays the current version number and changelog to the user.

#### 1. Vanilla HTML / JavaScript Example
Update the HTML elements and add a small inline script at the end of the page:

```html
<!-- Sticky Header or Banner Button -->
<a id="nav-download-btn" href="/app" class="btn">Get App</a>

<!-- Main Download Page APK Buttons (e.g. on /app page) -->
<a id="main-download-apk" href="https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/zanny_collection_v1.0.23_20260627_1139.apk" class="download-btn">
  Download APK
</a>
<p id="app-version-display" style="opacity: 0.8; font-size: 0.9rem;">
  Loading latest version info...
</p>

<script>
  document.addEventListener('DOMContentLoaded', async () => {
    // 1. Fallback URL in case API fails
    const FALLBACK_APK_URL = "https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/zanny_collection_v1.0.23_20260627_1139.apk";
    const API_URL = "https://zanny-collection-api.zannykenya254.workers.dev/api/version";

    // 2. Select DOM elements
    const navBtn = document.getElementById('nav-download-btn');
    const mainBtn = document.getElementById('main-download-apk');
    const versionText = document.getElementById('app-version-display');

    try {
      // 3. Fetch from Cloudflare Worker API
      const response = await fetch(API_URL);
      if (!response.ok) throw new Error('API request failed');
      
      const data = await response.json();
      
      if (data && data.apk_url) {
        // 4. Update download links with versioned R2 URL
        if (mainBtn) mainBtn.href = data.apk_url;
        
        // 5. Optionally show version and changelog information
        if (versionText) {
          versionText.innerHTML = `Latest Version: <strong>v${data.version} (Build ${data.build})</strong>`;
        }
      }
    } catch (error) {
      console.warn('⚠️ Could not fetch latest APK metadata, using fallback URL:', error);
      if (mainBtn) mainBtn.href = FALLBACK_APK_URL;
      if (versionText) {
        versionText.innerHTML = `Latest Version: <strong>v1.0.23 (Build 42)</strong>`;
      }
    }
  });
</script>
```

#### 2. React / Next.js Example (For `/app` page component)
If the website uses Next.js or React, use a standard state-based fetch:

```typescript
import React, { useEffect, useState } from 'react';

const FALLBACK_APK_URL = "https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/zanny_collection_v1.0.23_20260627_1139.apk";
const API_URL = "https://zanny-collection-api.zannykenya254.workers.dev/api/version";

interface VersionInfo {
  version: string;
  build: number;
  apk_url: string;
  changelog: string;
}

export default function DownloadAppPage() {
  const [versionInfo, setVersionInfo] = useState<VersionInfo | null>(null);
  const [downloadUrl, setDownloadUrl] = useState<string>(FALLBACK_APK_URL);

  useEffect(() => {
    fetch(API_URL)
      .then((res) => res.json())
      .then((data) => {
        if (data && data.apk_url) {
          setVersionInfo(data);
          setDownloadUrl(data.apk_url);
        }
      })
      .catch((err) => {
        console.error("Failed to retrieve latest APK version info:", err);
      });
  }, []);

  return (
    <div className="download-section">
      <h2>Experience Zanny Collection on Android</h2>
      <p>Download our official application directly to your mobile device.</p>
      
      <a 
        href={downloadUrl} 
        className="btn-download" 
        download
      >
        Download Zanny App APK
      </a>
      
      {versionInfo && (
        <div className="version-meta">
          <span>Version {versionInfo.version} (Build {versionInfo.build})</span>
          <p className="changelog">What's New: {versionInfo.changelog}</p>
        </div>
      )}
    </div>
  );
}
```

---

### Method B: API Redirect (Zero Frontend Code Change)
If you want to avoid writing JavaScript on the frontend page or updating DOM nodes dynamically, we can add a redirect endpoint in the **Cloudflare Worker**. 

This endpoint will automatically read the latest `version.json` metadata from the R2 bucket and issue a standard `302 Found` redirect.

#### 1. How it works:
All download buttons on the website can point to a single static URL:
```html
<a href="https://zanny-collection-api.zannykenya254.workers.dev/api/version/download" class="download-btn">
  Download Zanny App
</a>
```

#### 2. Worker Code Snippet to Enable This (in `index.js`):
In `cloudflare-worker/src/index.js`, add the following route matching:
```javascript
      } else if (path === '/api/version/download' && method === 'GET') {
        response = await handleDownloadRedirect(env);
```

And implement `handleDownloadRedirect(env)` function:
```javascript
async function handleDownloadRedirect(env) {
  const fallbackUrl = 'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/zanny_collection_v1.0.23_20260627_1139.apk';
  try {
    const obj = await env.R2.get('version.json');
    if (obj) {
      const data = JSON.parse(await obj.text());
      if (data && data.apk_url) {
        return new Response(null, {
          status: 302,
          headers: {
            'Location': data.apk_url,
            'Cache-Control': 'no-cache, no-store, must-revalidate'
          }
        });
      }
    }
  } catch (e) {
    // Fallback on error
  }
  return new Response(null, {
    status: 302,
    headers: {
      'Location': fallbackUrl,
      'Cache-Control': 'no-cache, no-store, must-revalidate'
    }
  });
}
```

---

## 📝 Verification Checklist for Website Integration
After the website developer applies the updates, test and confirm the following:

1. **Verify Download Source**:
   - Go to `https://zannycollection.com/app`.
   - Click the **Download APK** button.
   - Confirm that the downloaded filename matches the version in the API (e.g. `zanny_collection_v1.0.23_20260627_1139.apk`). It should **not** download a generic `zanny_collection.apk`.

2. **Verify Version Update Propagation**:
   - When a new build is deployed (e.g. version `1.0.24` / build `43`), the admin will run the publication script.
   - Refresh `https://zannycollection.com/app` and check if the download buttons automatically point to the new APK link without requiring any developer intervention or website redeployment.

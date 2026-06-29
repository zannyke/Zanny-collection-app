# Zanny Collection — Website Integration & Database Guide

This guide is for the website developer to successfully integrate with the shared SQLite D1 database and display products, sizes, colors, and images correctly.

---

## 💾 1. Understanding the `products` Table Schema

SQLite D1 does not have native list or array datatypes. Therefore, multi-value fields (like sizes, colors, and gallery images) are stored inline inside the `products` table as **JSON-serialized strings**.

### Key Columns in the `products` Table:
* `sizes`: Stored as a JSON string array, e.g. `'["XS", "S", "M", "L"]'`
* `colors`: Stored as a JSON string array, e.g. `'["Black", "Navy Blue"]'`
* `image_url`: Stored as a relative filename, e.g. `'product_1719472343.jpg'` (Needs CDN prefix to resolve).
* `gallery_urls`: Stored as a JSON string array of relative filenames, e.g. `'["gallery_1719472343_0.jpg", "gallery_1719472343_1.jpg"]'`.
* `is_deleted`: Soft-delete flag. `1` means the product has been deleted; `0` means it is active. **Always query where `is_deleted = 0`**.
* `is_new`: `1` for new arrivals, `0` otherwise.
* `is_sale`: `1` for discount items, `0` otherwise.

---

## 🛠️ 2. How to Parse Sizes & Colors in Code

Since sizes and colors are stored as JSON strings, the website backend or frontend **must parse the JSON** before attempting to render them as HTML lists or selector buttons.

### JavaScript / Node.js / Next.js Example:
```javascript
// Fetch the product from D1
const product = dbRow; 

// Parse the JSON strings safely
const sizesArray = JSON.parse(product.sizes || '[]');
const colorsArray = JSON.parse(product.colors || '[]');

// Rendering in HTML/JSX:
return (
  <div>
    <h3>Available Sizes:</h3>
    {sizesArray.map(size => (
      <button key={size}>{size}</button>
    ))}
  </div>
);
```

### PHP Example:
```php
// Fetch row from D1
$product = $dbRow;

// Decode JSON strings into PHP arrays
$sizesArray = json_decode($product['sizes'] ?? '[]');
$colorsArray = json_decode($product['colors'] ?? '[]');

// Rendering in PHP:
echo "<h3>Available Sizes:</h3>";
foreach ($sizesArray as $size) {
    echo "<button>" . htmlspecialchars($size) . "</button>";
}
```

---

## 🖼️ 3. How to Resolve Product Images

To keep the database clean, only relative image filenames are stored in the database. To display them on the website, prefix the filenames with the **Cloudflare R2 Public CDN URL**:

* **R2 Public CDN Base URL**: `https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/`

### Example Image Resolution Code:
```javascript
const cdnBase = "https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/";

// Resolve main image
const mainImageUrl = product.image_url 
  ? `${cdnBase}${product.image_url}`
  : "placeholder_image.png";

// Resolve gallery images
const galleryUrlsArray = JSON.parse(product.gallery_urls || '[]');
const fullGalleryUrls = galleryUrlsArray.map(img => `${cdnBase}${img}`);
```

---

## 🔍 4. Recommended SQL Query for Fetching Active Products

Always filter out deleted items and parse/aggregate ratings (calculated from the `feedback` review table):

```sql
SELECT 
  p.id,
  p.name,
  p.subtitle,
  p.description,
  p.price,
  p.original_price,
  p.image_url,
  p.gallery_urls,
  p.colors,
  p.sizes,
  p.stock,
  p.is_new,
  p.is_sale,
  -- Calculate average rating and review counts on-the-fly
  ROUND(COALESCE((SELECT AVG(f.rating) FROM feedback f WHERE f.product_id = p.id), 0), 1) as avg_rating,
  COALESCE((SELECT COUNT(f.id) FROM feedback f WHERE f.product_id = p.id), 0) as review_count
FROM products p
WHERE p.is_deleted = 0
ORDER BY p.created_at DESC;
```

---

## 📱 5. Mobile App Download & Live Updates Section

To distribute the Zanny Collection Android App directly from the website, the website landing page or settings should feature a download button linked directly to the latest verified APK version.

### A. Fetching the Latest APK Info (Website Frontend)
Make a `GET` request from the frontend to fetch the current version configuration:
* **Endpoint**: `GET https://zanny-collection-api.zannykenya254.workers.dev/api/version`
* **Response Format**:
  ```json
  {
    "version": "1.0.23",
    "build": 42,
    "url": "https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/zanny_collection_v1.0.23_20260627_1139.apk",
    "changelog": "Database performance patches and review screen fixes.",
    "publishedAt": "2026-06-27T08:50:44Z"
  }
  ```

### B. Displaying the Download Button
Use the returned `url` property as the `href` attribute for the **"Download Zanny App (Android)"** button. 
```html
<a href="${versionResponse.url}" class="download-btn">
  Download Zanny App v${versionResponse.version} (APK)
</a>
```

---

## ⚙️ 6. Admin APK Upload & Version Management

The website Admin Panel should provide a simple interface for the administrator to release new APK versions to users.

### A. Uploading the APK File
When the admin uploads a new `.apk` file:
1. **Endpoint**: `POST https://zanny-collection-api.zannykenya254.workers.dev/api/upload`
2. **Payload**: `multipart/form-data` containing the file under key `file`.
3. **Response**: Returns the direct R2 URL of the uploaded APK file, e.g.:
   `"https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/zanny_collection_v1.0.24.apk"`

### B. Publishing the New Version
After receiving the uploaded URL, update the active version by sending a `PUT` request:
1. **Endpoint**: `PUT https://zanny-collection-api.zannykenya254.workers.dev/api/version`
2. **Headers**: `'Content-Type': 'application/json'`
3. **Payload**:
   ```json
   {
     "version": "1.0.24",
     "build": 43,
     "url": "https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/zanny_collection_v1.0.24.apk",
     "changelog": "Added new collection items and features.",
     "admin_secret": "ZannyAdmin2024Secret"
   }
   ```
   *(Note: `admin_secret` must match the secret configured in the Cloudflare Worker to authorize the version update).*

---

## ✉️ 7. Email Notifications & Resend Configuration

To ensure customers receive transactional confirmation emails (for orders placed, shipped, delivered, and cancelled), the **Resend API Key** must be bound to the Cloudflare Worker.

### Enabling Email Notifications:
If emails are not being sent, run the following Wrangler command to set the Resend API Key secret:
```bash
wrangler secret put RESEND_API_KEY
```
When prompted, paste your active Resend API Key (`re_...`). The Edge Worker will automatically start delivering rich-HTML receipts and shipping updates!

---

## 🛒 8. Live Cart Synchronization (Real-Time App & Website Sync)

To ensure the user has a unified shopping experience, the **shopping cart must be synchronized in real-time** between the mobile application and the website. 

When a user logs in, the website **must not** rely on client-side `localStorage` for their cart. Instead, the website must synchronize cart items with the server backend using the `/api/cart` endpoints.

### A. Fetching the Active Cart (On Website Load / Login)
Fetch the current logged-in user's cart from the server:
* **Endpoint**: `GET https://zanny-collection-api.zannykenya254.workers.dev/api/cart`
* **Headers**: `Authorization: Bearer <JWT_TOKEN>`
* **Response Format**:
  ```json
  {
    "items": [
      {
        "product": {
          "id": "prod_123",
          "name": "Classic Essential Hoodie",
          "price": 850
          // ...other product details
        },
        "selectedSize": "L",
        "selectedColor": "Black",
        "quantity": 2
      }
    ]
  }
  ```

### B. Syncing Cart Updates (On Add/Update/Remove in Website)
Whenever a user adds an item to the cart, modifies a quantity, or removes an item on the website, send the updated cart list to the server:
* **Endpoint**: `POST https://zanny-collection-api.zannykenya254.workers.dev/api/cart`
* **Headers**: `Authorization: Bearer <JWT_TOKEN>`
* **Payload**:
  ```json
  {
    "items": [
      {
        "product_id": "prod_123",
        "selected_size": "L",
        "selected_color": "Black",
        "quantity": 2
      }
    ]
  }
  ```
  *(Note: Send the complete active cart array in the payload. The Worker will overwrite the old database state with this new snapshot, ensuring the mobile app and website stay perfectly in sync).*



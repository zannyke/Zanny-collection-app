# Website Integration Guide — Pre-Order System

This document outlines the database schema, API changes, and frontend integration steps required to implement the **Pre-Order** feature on the React/Next.js web application.

---

## 1. Database Schema Changes (Cloudflare D1)

The `products` database table has been updated to include a new boolean flag column: `is_preorder`.

### SQL Migration
```sql
ALTER TABLE products ADD COLUMN is_preorder INTEGER DEFAULT 0;
```
*   `0`: Standard in-stock product (requires stock validation).
*   `1`: Pre-Order product (bypasses stock validations during checkout).

---

## 2. API Endpoint Changes (Cloudflare Worker)

### A. Fetching Products (`GET /api/products` and `GET /api/products/:id`)
Product JSON payloads now include the `is_preorder` field.

**Response Payload Example:**
```json
{
  "id": 104,
  "name": "Zanny Premium Heavyweight Hoodie",
  "price": 4500,
  "stock": 0,
  "is_preorder": 1,
  "images": [
    "https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/hoodie_grey.png"
  ]
}
```
> [!IMPORTANT]
> SQLite D1 returns boolean flags as integers (`0` for false, `1` for true). Ensure your website's type mappings parse `1` as `true` in JavaScript/TypeScript.

### B. Creating/Updating Products (`POST /api/admin/products` & `PUT /api/admin/products/:id`)
The admin panel form must send the `is_preorder` field when creating or editing a product.

**Request Body Example:**
```json
{
  "name": "Zanny Premium Heavyweight Hoodie",
  "price": 4500,
  "stock": 0,
  "is_preorder": 1,
  "images": ["https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/hoodie_grey.png"]
}
```

### C. Creating Orders & Checkout (`POST /api/orders`)
The checkout API handles stock differently for pre-order items:
*   For standard products, the API checks if `requestedQuantity <= product.stock` and decrements `stock` in the DB.
*   For pre-order products (`is_preorder = 1`), the API **completely bypasses the stock check** and does not decrement the stock (it allows checkout even if `stock` is 0). It only increments the `sold` counter.
*   *Action Required on Web Client*: Ensure your client-side checkout payload sends order details normally. The backend already contains this bypass logic.

---

## 3. Frontend Web Application Integration

Check `product.is_preorder` in your React/Next.js components to customize the shopping flow:

### A. Pre-Order Badge Overlay
If `product.is_preorder` is true, render a prominent purple/violet overlay badge (e.g. `PRE-ORDER`) on top of the product card image in lists.

### B. Product Detail Call-To-Action (CTA)
*   **Button Text**: If `product.is_preorder` is true, change the purchase button text from "ADD TO CART" / "BUY NOW" to **"PRE-ORDER ITEM"** or **"PRE-ORDER NOW"**.
*   **Disable Logic Bypass**: 
    *   Normally, if `product.stock <= 0`, you disable the button and show "OUT OF STOCK".
    *   For pre-order items, **do NOT disable the button** when `stock === 0`. Bypassing stock validation allows customers to place orders on production items.
    *   **React Example**:
        ```jsx
        const isOutOfStock = product.stock <= 0 && !product.is_preorder;
        const buttonText = product.is_preorder 
          ? "PRE-ORDER NOW" 
          : (product.stock > 0 ? "BUY NOW" : "OUT OF STOCK");

        return (
          <button disabled={isOutOfStock}>
            {buttonText}
          </button>
        );
        ```

### C. Shopping Cart Validations
*   Ensure that quantity validation checks in the cart page do not block checkout for pre-order items even if the item stock is `0`.

# Zanny Collection: Admin Section & Notification Systems Developer Guide

This document provides a comprehensive technical overview of the **Zanny Collection** backend administration structure, database design, automated email flows, and order tracking systems. It is structured to help any incoming developer understand the architecture and replicate these mechanics in the Android/mobile application.

---

## 1. System Architecture & Tech Stack
The web platform is built on the following technologies:
- **Frontend**: React (Vite-based Single Page Application).
- **Backend / Serverless**: Cloudflare Pages Functions (JavaScript-based edge workers).
- **Database**: Cloudflare D1 (Serverless SQL database powered by SQLite).
- **Email Service**: Resend API (used for transactional confirmations and status updates).

---

## 2. Database Schema Reference
The following D1/SQLite tables form the core of the user management, ordering, and feedback mechanisms:

### `users` Table
Stores user account details, roles, and "Trust System" metrics:
```sql
CREATE TABLE IF NOT EXISTS users (
  id                            TEXT PRIMARY KEY,
  email                         TEXT UNIQUE NOT NULL,
  password_hash                 TEXT,
  salt                          TEXT,
  first_name                    TEXT DEFAULT '',
  last_name                     TEXT DEFAULT '',
  phone_number                  TEXT DEFAULT '',
  role                          TEXT DEFAULT 'customer', -- 'customer' or 'admin'
  consecutive_cancellations     INTEGER DEFAULT 0,       -- Tracks cancellations to flag COD abuse
  restricted_from_cod           INTEGER DEFAULT 0,       -- 1 if banned from Cash on Delivery
  consecutive_successful_orders INTEGER DEFAULT 0,       -- Count towards restoring COD privileges
  created_at                    TEXT DEFAULT (datetime('now'))
);
```

### `orders` Table
Stores purchased items, totals, shipping info, and order state transition logs:
```sql
CREATE TABLE IF NOT EXISTS orders (
  id                      TEXT PRIMARY KEY,                  -- e.g., 'ORD-456789'
  user_id                 TEXT NOT NULL,                     -- References users.id or 'guest'
  items                   TEXT NOT NULL DEFAULT '[]',        -- JSON array of serialized products
  total_amount            REAL NOT NULL DEFAULT 0,
  status                  TEXT DEFAULT 'pending',            -- 'pending', 'confirmed', 'shipped', 'delivered', 'cancelled'
  shipping_address        TEXT DEFAULT '',
  recipient_name          TEXT DEFAULT '',
  recipient_phone         TEXT DEFAULT '',
  phone_number            TEXT DEFAULT '',
  mpesa_receipt           TEXT DEFAULT '',                   -- M-Pesa transaction ID
  review_prompt_dismissed INTEGER DEFAULT 0,                 -- If the user dismissed the review modal
  tracking_number         TEXT DEFAULT '',                   -- Courier tracking ID or link
  confirmed_at            TEXT,
  shipped_at              TEXT,
  delivered_at            TEXT,
  created_at              TEXT DEFAULT (datetime('now'))
);
```

### `feedback` Table
Contains submitted ratings and reviews for delivered orders:
```sql
CREATE TABLE IF NOT EXISTS feedback (
  id          TEXT PRIMARY KEY,                              -- e.g., 'FB-123456'
  order_id    TEXT NOT NULL,                                 -- References orders.id
  rating      INTEGER NOT NULL,                              -- 1 to 5 stars
  comment     TEXT DEFAULT '',
  created_at  TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (order_id) REFERENCES orders(id)
);
```

---

## 3. Administrative Control & Security
Admin endpoints check authorization before processing requests by extracting session tokens and verifying the user role in the database.

- **Helper Utility (`getCurrentUser`)**:
  Interprets headers or cookies to find the active session in the `sessions` table and fetches the associated user record.
- **Admin Verification Rule**:
  ```javascript
  const user = await getCurrentUser(context);
  const isAdmin = user && user.role === 'admin';
  if (!isAdmin) {
    return Response.json({ error: 'Unauthorized/Forbidden' }, { status: 403 });
  }
  ```

---

## 4. Checkout and Purchase Workflow

When a checkout transaction is initiated (`POST /api/orders`):
1. **COD Restriction Check**: The backend verifies if the user is flagged with `restricted_from_cod = 1`. If true and they try to use Cash on Delivery, the request is rejected, prompting an upfront M-Pesa payment.
2. **Live Stock Check**: The database is queried for each product ID. If any item is out of stock or requested quantities exceed available stock, the order is blocked.
3. **Data Serialization**: Complete snapshot details of the products (including categories, prices, sizes, and colors) are compiled into a JSON array and saved to `orders.items` to protect order history from future product description modifications.
4. **Order ID Generation**: Generates IDs in the format `ORD-` followed by the last 6 digits of the current timestamp (e.g., `ORD-876123`).
5. **Inventory Update**: Available stock is decremented and `sold` counts are incremented automatically.
6. **Order Placement Emails**:
   - **Admin Notification**: Sent to `zannykenya254@gmail.com` detailing the Order ID, total amount, shipping address, recipient phone, and items. It provides a direct hyperlink to the web Admin Dashboard:
     `https://zanny-collection.pages.dev/admin`
   - **Customer Confirmation**: Sent to the user's registered email with order details and a breakdown of their items.

---

## 5. Email Notification System (via Resend)

Transactional email notifications are fired during state transitions via `PATCH /api/orders`:

```
                  ┌──────────────┐
                  │ Order Placed │
                  └──────┬───────┘
                         │
                         ▼
        ┌──────────────────────────────────┐
        │ Email sent to:                   │
        │ 1. Admin (zannykenya254@gmail.m) │
        │ 2. Customer (order confirmation) │
        └────────────────┬─────────────────┘
                         │
                         │ (Admin marks "Shipped")
                         ▼
         ┌────────────────────────────────┐
         │      Order Shipped Email       │
         │   (Includes Tracking Number)   │
         └───────────────┬────────────────┘
                         │
                         │ (Admin marks "Delivered")
                         ▼
         ┌────────────────────────────────┐
         │     Order Delivered Email      │
         │   (Includes PDF-style Receipt  │
         │  & "Leave a Review" Hyperlink) │
         └────────────────────────────────┘
```

### Order Shipped
When the order status changes to `'shipped'`, the admin optionally provides a tracking number/link:
- **Email Subject**: `Your Order #ORD-XXXXXX has Shipped!`
- **Action for Customer**: The email contains the tracking identifier (`tracking_number`), which enables the customer to monitor delivery progress.

### Order Delivered & Receipt
When the order status changes to `'delivered'`:
- **Email Subject**: `Your Order #ORD-XXXXXX has been Delivered!`
- **Content**: A styled receipt showing the item names, sizes, quantities, payment method (M-Pesa receipt or Cash on Delivery), total paid, and shipping address.
- **Engagement Link**: The receipt features a prominent button: **"Leave a Review"** redirecting the user back to the web portal's review/account section (`https://zannycollection.com/account`).

### Order Cancelled (by Customer)
Customers are only allowed to cancel orders in `'pending'` state:
- **Inventory Restoration**: The system automatically parses the items JSON column, increments product stocks, and decrements `sold` counts.
- **Admin Alert**: Resend delivers a notification email informing the admin of the cancellation.
- **Trust System Penalties**: If a customer accumulates $\ge 3$ consecutive cancellations, their account is flagged (`restricted_from_cod = 1`), disabling Pay on Delivery. Conversely, completing 3 successful deliveries restores their COD status.

---

## 6. Feedback & Review Flow

To collect reviews after delivery, the backend exposes two main operations:

### Checking for Pending Reviews (`GET /api/feedback/pending`)
When a user logs in, the application checks if there are any reviews they should complete:
- **Query Filter**: Finds the most recent order for a given `userId` where:
  - `status = 'delivered'`
  - `review_prompt_dismissed = 0` (or NULL)
  - The order ID does not exist in the `feedback` table.
- **Result**: If an eligible order is found, the backend returns the order ID and items so the frontend can display a modal encouraging the user to leave a rating.

### Submitting Review (`POST /api/feedback`)
- **Validation**: Ensures the order belongs to the user, is marked as `'delivered'`, and doesn't already have feedback.
- **Security Check**: The backend sanitizes the comments by stripping all HTML tags to prevent **Stored Cross-Site Scripting (XSS)** attacks:
  ```javascript
  const sanitizedComment = (comment || '').replace(/<[^>]*>?/gm, '').substring(0, 1000);
  ```
- **Storage**: Inserts the rating (1-5) and sanitized comment into the `feedback` table under a new ID prefixed with `FB-`.

---

## 7. Android Implementation Roadmap
To implement these backend mechanics on the mobile client (Kotlin/Java/Dart/Flutter):
1. **Sync Engine**: Fetch active user orders via `GET /api/orders` to local SQLite/Room database. Check status shifts (`shipped`, `delivered`).
2. **Review Dialog Trigger**: Call `GET /api/feedback/pending?userId=<ID>` on app launch. If a pending feedback object is returned, display an in-app rating prompt.
3. **Notification/Welcome Logic**: When a user logs in or signs up, check their profile status. If they are a new registrant, trigger a local welcome notification.
4. **Order Tracking View**: Read `tracking_number` from the synced order record. If present, render an active progress timeline (Ordered ➔ Confirmed ➔ Shipped ➔ Delivered) and provide an external link to track the package.

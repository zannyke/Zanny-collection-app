# Tasks

## 1. Firebase FCM Push Notification Integration (v1.0.12+24) [Completed]
- `[x]` Move `google-services.json` to `android/app`
- `[x]` Add Google Services plugin configuration in settings.gradle.kts and app build.gradle.kts
- `[x]` Bump version to `1.0.12` and build `24` in `pubspec.yaml` and `update_service.dart`
- `[x]` Build release APK (`v1.0.12+24`)
- `[x]` Upload new APK and `version.json` metadata to R2 bucket
- `[x]` Set Wrangler secrets (`FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`) in the Cloudflare Worker
- `[x]` Verify end-to-end flow

## 2. In-App Updates & Version Alignment [Completed]
- `[x]` Align app code and server `version.json` to Build 28 (or the latest) to stop the infinite update popup
- `[x]` Security refinement: Simplify push notifications for app updates to use a clean non-technical message
- `[x]` Security refinement: Hide/simplify raw technical changelog in the in-app update bottom sheet for non-admin users
- `[x]` Redesign the in-app update bottom sheet to look premium and elegant

## 3. Admin Panel - Product Stock Bug Fix [Completed]
- `[x]` Fix the bug where editing a product's stock quantity does not save/persist on the server (Worker is missing `stock` in `UPDATE` and `INSERT` query preparation)

## 4. Admin Panel - Orders Filter [Completed]
- `[x]` Filter out invalid/empty/test orders (zero items, 'test' in order ID) from the admin panel orders section

## 5. Admin Panel - Product & Custom Adverts [Completed]
- `[x]` Implement "Advertise this product" toggle when adding/editing products to trigger a push notification
- `[x]` Create a new dedicated "Create Advert" section/screen in the admin panel to broadcast custom notifications with an image, text, and deep links

## 6. App Update Installer & Package Visibility Fix [Completed]
- `[x]` Add package archive VIEW query in `<queries>` inside `AndroidManifest.xml` to fix Package Visibility limits on Android 11+
- `[x]` Improve error propagation in `UpdateService.downloadAndInstall` (rethrow exceptions when package installer invocation fails)
- `[x]` Update `_UpdateBottomSheet` UI logic to handle installer launch failures gracefully (prevent silent dialog dismissal, show Snackbar error)
- `[x]` Bump Flutter app version to `1.0.14+31` and `currentBuild` to `31` in `pubspec.yaml` and `update_service.dart`
- `[x]` Compile release APK for Build 31
- `[x]` Update server-side `version.json` and upload the Build 31 APK to Cloudflare R2

## 7. Premium Shimmer Loading States [Completed]
- `[x]` Implement standard reusable `ShimmerPlaceholder` widget adapting to light/dark themes
- `[x]` Replace loading indicators in `edit_profile_screen.dart`
- `[x]` Replace loading indicators in `profile_screen.dart`
- `[x]` Replace loading indicators in `fashion_screen.dart`
- `[x]` Replace loading indicators in `checkout_screen.dart`
- `[x]` Replace loading indicators in `admin_add_product_screen.dart`
- `[x]` Replace loading indicators in `admin_add_style_screen.dart`
- `[x]` Replace loading indicators in `admin_dashboard_screen.dart`

## 8. Multi-device Cart Synchronization & Logout Cleanup [Completed]
- `[x]` Clear local cart state and SharedPreferences cache upon user logout to prevent cross-account cart pollution
- `[x]` Bump version to Build 32 and redeploy to verify

## 9. Version Check Cache Busting Fix [Completed]
- `[x]` Append a dynamic timestamp query parameter to `/api/version` requests in `UpdateService.checkForUpdate` to bust client-side caches
- `[x]` Add `Cache-Control: no-cache, no-store, must-revalidate` response headers to `handleGetVersion` in the Cloudflare Worker backend
- `[x]` Bump app version to Build 33, build the APK, and publish to verify the complete fix

## 10. Admin & Notifications System and UI Refinements
- `[x]` Backend: Implement COD restriction check in `/api/orders` POST
- `[x]` Backend: Implement live stock check in `/api/orders` POST
- `[x]` Backend: Generate order ID in format `ORD-XXXXXX` (last 6 digits of timestamp) in `/api/orders` POST
- `[x]` Backend: Save serialized snapshot of order items in `orders.items` in `/api/orders` POST
- `[x]` Backend: Update product inventory (decrement `stock` and increment `sold`) on checkout
- `[x]` Backend: Implement Resend email confirmation on order placement
- `[x]` Backend: Implement Resend email status notifications on shipped (tracking info), delivered (styled receipt, review link), cancelled (admin alert, inventory restore, trust penalty)
- `[x]` Frontend: Update `orders_provider.dart` to support payment method and server-generated order ID
- `[x]` Frontend: Pass selected payment method from `checkout_screen.dart`
- `[x]` Frontend: Change bottom navigation fashion icon to clothes hanger icon (`Icons.checkroom`) in `bottom_nav_scaffold.dart`
- `[x]` Frontend: Redesign no internet screen (remove diagnostics list, implement building Wi-Fi / red cancelled custom animation, animate green on success)
- `[x]` Frontend: Re-implement `ZannyFeedback` alerts to show premium center-aligned popups
- `[x]` Frontend: Redesign visual tracker stepper in `orders_screen.dart` to use blue/light blue theme colors
- `[x]` Release: Bump version to `1.0.16` and build `35` in `pubspec.yaml` and `update_service.dart`
- `[x]` Release: Compile, rename, upload new APK and version metadata to R2, set secrets, and verify

## 11. Product Reviews & Admin Ratings Panel [Completed]
- [x] Database: Update `feedback` table schema in `schema.sql` and `migration.sql`
- [x] Database: Run database patching using `patch_database.js` to alter tables on remote D1
- [x] Backend: Update `handlePostFeedback` in `index.js` to store `product_id` and `user_id`
- [x] Backend: Implement `handleGetProductReviews` in `index.js` to fetch aggregated product reviews
- [x] Backend: Implement `handleGetAdminReviews` in `index.js` to fetch reviews for admin panel
- [x] Frontend: Update `submitFeedback` in `orders_provider.dart` to pass selected product ID
- [x] Frontend: Create `productReviewsProvider` in `product_provider.dart`
- [x] Frontend: Redesign `FeedbackDialog` to support product selection list for multi-item orders
- [x] Frontend: Add ratings summary row on `product_detail_screen.dart`
- [x] Frontend: Create `ProductReviewsScreen` displaying review stats and scrollable comments list
- [x] Frontend: Add new REVIEWS tab in `admin_dashboard_screen.dart`
- [x] Verification: Compile, run analyzer, run tests, and verify flow end-to-end

## 12. Theme Adjustments, Time-Delayed Prompts, and Follow-Up Reviews
- [x] Frontend: Retheme OrderSuccessScreen (order_success_screen.dart) card background to light blue (Color(0xFFF0F7FF) or Color(0xFFE0F2FE)) and text colors to be properly legible in Light Mode (retheme all colors to react dynamically to current brightness)
- [x] Frontend: Fix OrderSuccessScreen checkmark icon background and icon color in Light Mode to match theme brightness
- [x] Frontend: Ensure OrderSuccessScreen "Go to my account" and "Continue Shopping" buttons react correctly to theme switches
- [x] Backend/Frontend: Add a 1-hour delay check after order delivery before prompting for review on app launch
- [x] Frontend: Implement a "Maybe Later" close action in FeedbackDialog (close dialog only, without updating server status) — renamed DISMISS to LATER, which only calls Navigator.pop()
- [x] Frontend: Display the rating status (e.g. "Rate this product" or "Rated ✓") next to each item in the order details/history section so the user can easily find unrated items
- [x] Release: Bump version to `1.0.17` and build `36` in `pubspec.yaml` and `update_service.dart`
- [x] Release: Compile, rename, upload new APK and version metadata to R2, and verify

## 13. Order Push Notifications [Completed]
- [x] Backend: `sendFcmToUser()` helper added to `index.js` for targeted per-user push
- [x] Backend: Push to admin when new order is placed (`handlePostOrder`)
- [x] Backend: Push to customer on order confirmation (`handlePostOrder`)
- [x] Backend: Push to customer when order is shipped (`handleUpdateOrderStatus`)
- [x] Backend: Push to customer when order is delivered (`handleUpdateOrderStatus`)
- [x] Backend: Push to customer + admin when order is cancelled (`handleUpdateOrderStatus`)
- [x] Backend: Deploy updated Worker (Version ID: e0353db7)
- [x] Database: `fcm_token` column already exists in `users` table — no migration needed
- [x] Frontend: In-app local notifications already handled via `_checkDifferencesAndNotify`
- [x] Release: v1.0.18+37 — APK built, uploaded to R2, version.json published

## 14. Reviews in Admin Panel & Product Cards [Completed]
- [x] Admin: Reviews tab already fully built in `admin_dashboard_screen.dart`
- [x] Frontend: Star rating row added to `product_card.dart` (⭐ stars + review count under price)
- [x] Backend: `avg_rating` and `review_count` now returned by `/api/products` and `/api/products/:id`
- [x] Database: `feedback` table already stores `product_id`, `rating`, `comment` — no new table needed

## 15. Customer Emails for Order Actions [Completed — already implemented]
- [x] Backend: Customer confirmation email on order placement — `handlePostOrder`
- [x] Backend: Admin alert email on order placement — `handlePostOrder`
- [x] Backend: Shipped email with tracking link — `handleUpdateOrderStatus`
- [x] Backend: Delivered email with receipt + review link — `handleUpdateOrderStatus`
- [x] Backend: Cancellation admin alert email — `handleUpdateOrderStatus`
- [x] Database: `orders` table already has all required fields — no schema changes needed

## 16. Production-Ready Logs
- [x] Cloudflare Worker Observability enabled (wrangler.toml `[observability]`) — logs live in dashboard
- [] Structured logs with timestamp, user_id, order_id etc. for each action in `index.js`
- [] Centralized log management / alerting (e.g. log to D1 or external sink)

## 17. Miscellaneous UX & Reliability
- [] Scrolling/pagination between pages in the admin section
- [x] Auto-mark product as out-of-stock / hide from shop when stock hits 0 — stock badge visible in admin; full enforcement in Task 17 backlog
- [x] Release v1.0.19+38 — fixed APK update loop (CDN direct URL), admin errors now visible, star ratings

## 18. Database Integrity, Live Stock, and Admin UX
- [x] Fix bug in adding/editing new product picking the last product deleted or having other issues
- [x] Add stock number correctly and fix stock addition/display issues
- [x] Swipe feature in admin section (swipe right/left to access different pages)
- [x] Professional blue shaded and animated in-app update notification to avoid update errors / loop and look premium
- [x] Live stock checks:
    - If product quantity is 5, and 5 users have it in cart, mark as out-of-stock
    - If 6th user tries to add, prevent check out or warn them to remove it from cart

## 19. Security & Production Reliability
- [x] make sure we avoid SQL/database injection attacks
- [x] make sure the admin section is well secured and can only be accessed by admins
- [x] In production we need to avoid errors such as:
    - failed D1 database connection
    - failed image upload to R2 storage
    - any error from the cloudflare worker
    - build errors or updates errors
- [x] make sure the application is well optimized and works well in production.

## 20. Safe App Release Procedure & Guidelines (v1.0.20+39) [Completed]
- `[x]` Wait for release APK compilation of version `1.0.20+39` to complete
- `[x]` Rename the compiled APK using `rename_apk.dart`
- `[x]` Upload the APK to Cloudflare R2 bucket
- `[x]` Update version metadata file `version.json` with the new version details and CDN direct URL
- `[x]` Confirm R2 hosting of APK and `version.json` is live and accessible
- `[x]` Trigger Firebase FCM update notification to all users (ONLY after R2 upload is confirmed)
- `[x]` Create `build_and_update_guidelines.md` detailing the safe release sequence to prevent user update loops and deployment bugs

## 21. Product CRUD, Image Cleanup, and Real-Time Stock Updates
- `[x]` Fix ProductsNotifier state initialization: if fetched products list is empty, clear state instead of keeping mock products
- `[x]` Update handleDeleteProduct in Cloudflare Worker to delete associated product image and gallery images from R2 bucket zanny-images
- `[x]` Verify product delete operation propagates correctly to UI (removes from list and deletes images)
- `[x]` Ensure product addition/editing fully supports sizes, colors, images, and descriptions, and updates database correctly
- `[x]` Update handleCreateOrder in Cloudflare Worker to implement live stock verification (check requested quantity against available database stock)
- `[x]` Update handleCreateOrder to atomically decrement products.stock and increment products.sold on checkout
- `[x]` Verify update version, re-compile release APK, and deploy
- `[x]` ensure proper communication between the backend frontend and the database and storage for proper data display and communication

## 22. Website Frontend — Sizes & Colors Display Fix
- `[x]` Parse `colors` and `sizes` JSON arrays from D1 into `parsedColors` and `parsedSizes` in ProductContext.jsx
- `[x]` Implement fallback rendering in ProductDetailPage.jsx — use parsedColors/parsedSizes when variations is empty
- `[x]` Implement fallback rendering in CategoryPage.jsx ProductCard — same fallback logic
- `[x]` Admin vault unlock state persisted to sessionStorage for stable re-navigation
- `[x]` Build verified: no compilation errors (vite v8.0.10 ✓)
- `[x]` Changes pushed to GitHub (main branch) for Cloudflare Pages auto-deploy


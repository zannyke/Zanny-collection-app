- [x] Theme Default to Light Mode
- [x] Omit build numbers and simplify version update notifications
- [x] [x] Forgot Password 6-digit verification code flow (backend & frontend)
- [x] Edit Profile avatar presets (vector male/female icons) & custom gallery image upload
- [x] Profile Screen Danger Zone for account deletion (requires current password verification)
- [x] Hero Banner Video support (silent looping video ads via video_player)
- [x] Compile Release APK, upload to R2, publish version.json, and trigger FCM simple update notification
- [x] Implement Banner Video Support in Admin Section
  - [x] Add `video_player` import
  - [x] Implement `_isVideo` helper function
  - [x] Implement `_AdminVideoPreview` widget
  - [x] Update `_pickAndAddBannerSlide` to support both images and videos via bottom sheet
  - [x] Update `_buildHomepageBannerSection` item preview to handle video slides and add a video indicator
- [x] Implement Personalized Email Notifications
  - [x] Modify `cloudflare-worker/src/index.js` inside `handlePostFeedback` to fetch user email and send a Thank You email
  - [x] Document Resend configuration guide for setting up Cloudflare secrets
- [x] Verify both features build and work as expected trigger FCM simple update notification

## 🚀 Future Backlog & Enhancements

- [x] **Immersive Collections Screen Redesign (Shop View)**
  - [x] Replace category-only list with a dynamic mixed-product browse catalog
  - [x] Implement an interactive category selector at the top (horizontal scrollable chips and/or dropdown menu)
  - [x] Display a mixed grid of all products (hoodies, shirts, caps, etc.) by default to allow organic browsing
  - [x] Integrate sorting (Price Low-to-High, High-to-Low, Newest) and search directly on the main collection tab
  - [x] Add a curated/recommended products highlight section
  - [x] make sure everything is working well and follows the UI colors and style used in the app
  - [x] Modify sendResendEmail to return success status and error messages in cloudflare-worker/src/index.js
  - [x] Update handleSignup to check sendResendEmail results and return error responses on failure
  - [x] Update handleForgotPassword to check sendResendEmail results and return error responses on failure
  - [x] Deploy updated worker and verify behavior


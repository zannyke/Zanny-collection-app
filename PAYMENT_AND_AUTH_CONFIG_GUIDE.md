# Zanny Collection — Unified Stripe & Google Sign-In Integration Guide

This guide compiles all required credentials, keys, configuration steps, and environment variables needed to finalize the Stripe payment gateway integration and Google Sign-In authentication.

---

## ── Part 1: Stripe Payment Gateway Integration ──

### Required Keys & Secrets:
To activate Stripe Checkout and Webhooks, configure the following keys:

| Key Name | Description | Source | Action Required |
| :--- | :--- | :--- | :--- |
| **`STRIPE_PUBLISHABLE_KEY`** | Public key used in the Flutter app to initialize the Stripe Checkout redirect. | Stripe Dashboard (Developers > API Keys) | Add to the app's `.env` configuration file |
| **`STRIPE_SECRET_KEY`** | Secret key used securely by the Cloudflare Worker to call Stripe APIs. | Stripe Dashboard (Developers > API Keys) | Set as a Cloudflare Secret (see command below) |
| **`STRIPE_WEBHOOK_SECRET`** | Secret token used to verify webhook event payloads from Stripe. | Stripe Dashboard (Developers > Webhooks) | Set as a Cloudflare Secret (see command below) |

### Cloudflare Secrets Setup:
Run these commands in your terminal to securely upload your Stripe keys to your Cloudflare Worker:
```bash
# Upload Stripe Secret Key
npx wrangler secret put STRIPE_SECRET_KEY

# Upload Stripe Webhook Signing Secret
npx wrangler secret put STRIPE_WEBHOOK_SECRET
```

### Webhook URL Endpoint:
Configure a webhook in your Stripe Dashboard (**Developers > Webhooks**) to listen for `checkout.session.completed` events and route them to:
- **Webhook Endpoint URL**: `https://zanny-collection-api.zannykenya254.workers.dev/api/payments/webhook`

---

## ── Part 2: Google Sign-In Authentication ──

### Required Credentials & Configs:
To support "Login by Google" on Android and iOS, configure the following:

| Configuration Item | Description | Setup Source | Action Required |
| :--- | :--- | :--- | :--- |
| **`GOOGLE_CLIENT_ID`** | Web Client ID used by the Worker to verify Google ID tokens. | Google Cloud / Firebase Console | Set as a Cloudflare Secret (see command below) |
| **SHA-1 Fingerprint** | Certificate fingerprint of your Android signing key. | Local Keystore (using keytool) | Register in Firebase Project Settings |
| **`google-services.json`** | Android Firebase config file. | Firebase Console | Place in Flutter project under `android/app/` |
| **`GoogleService-Info.plist`** | iOS Firebase config file. | Firebase Console | Add to your Xcode project |

### Cloudflare Secrets Setup:
Run this command in your terminal to securely configure the Google Web Client ID on your Cloudflare Worker:
```bash
# Upload Google Client ID for backend verification
npx wrangler secret put GOOGLE_CLIENT_ID
```

### Keystore SHA-1 Fingerprint Generation:
To generate the SHA-1 fingerprint required for Android Google Sign-In, run this command in your local terminal:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```
Copy the printed **SHA-1** fingerprint and paste it into the **Android app configuration** inside your Firebase project settings.

# Setup Guide: How to Retrieve Stripe & Google Sign-In Credentials

This document provides step-by-step instructions on what you need to do in your Stripe and Firebase/Google consoles to generate the keys needed for our integration.

---

## ── Step 1: Stripe Payment Dashboard ──

Follow these steps in your Stripe account:

1. **Go to API Keys**:
   - Log into your [Stripe Dashboard](https://dashboard.stripe.com/).
   - Toggle to **Test Mode** (top right) if you want to test first, or stay in Live Mode.
   - Go to **Developers > API Keys** in the menu.
   - Copy the **Publishable key** (starts with `pk_`). Save this to add to your app's `.env` file.
   - Click **Reveal live key token** (or test token) to show and copy your **Secret key** (starts with `sk_`). Save this for your Worker secret.

2. **Configure the Webhook**:
   - Go to **Developers > Webhooks** in the menu.
   - Click **Add endpoint**.
   - Paste this URL as the **Endpoint URL**: 
     `https://zanny-collection-api.zannykenya254.workers.dev/api/payments/webhook`
   - Under **Select events to listen to**, search for and select: `checkout.session.completed`
   - Click **Add endpoint**.
   - Copy the **Signing secret** (starts with `whsec_`) revealed under the webhook details. Save this for your Worker secret.

---

## ── Step 2: Google Developer / Firebase Console ──

Follow these steps in your Google Developers / Firebase account:

1. **Enable Google Provider in Firebase Auth**:
   - Log into the [Firebase Console](https://console.firebase.google.com/).
   - Open your project (**zanny-collection**).
   - Go to **Build > Authentication** in the left menu.
   - Click the **Sign-in method** tab.
   - Click **Add new provider**, select **Google**, enable it, choose your support email, and click **Save**.
   - Under the Google provider settings, copy the **Web SDK configuration Client ID** (e.g. `123456-abcdef.apps.googleusercontent.com`). Save this for your Worker secret.

2. **Add SHA-1 Signature for Android**:
   - Run this command in your local machine terminal to generate your SHA-1 key:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
   - Copy the printed **SHA-1** fingerprint string.
   - In the Firebase Console, go to **Project Settings** (gear icon next to Project Overview).
   - Scroll down to **Your apps > SDK setup and configuration** under the Android App section.
   - Click **Add fingerprint**, paste your SHA-1 signature, and click **Save**.
   - Download the newly updated `google-services.json` file and place it inside the `android/app/` folder of your Flutter project.

3. **Get iOS plist config**:
   - Under your iOS app settings in the Firebase Project Settings, download the `GoogleService-Info.plist` file and add it to your Xcode project.

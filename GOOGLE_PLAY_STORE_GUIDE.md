# Zanny Collection — Google Play Store Release Guide

This simple guide explains the steps required to upload and release the **Zanny Collection Android App** on the **Google Play Store** without any policy complications or rejections.

---

## ⚠️ 1. Change the Package Name (Mandatory)
Before uploading to the Google Play Store, you **must** change the app's package name (also called Application ID). 

*   **The Issue**: The app currently uses the default name `com.example.zanny_collection`. Google Play strictly **blocks** any app using `com.example`.
*   **The Solution**: Change it to a unique business namespace, such as `com.zannycollection.app`.

### How to change it:
Open the project code and update the package name in these specific files:
1.  **[build.gradle.kts](file:///c:/Users/Administrator/Desktop/zanny%20collection%20application/android/app/build.gradle.kts)** (Line 32):
    Change `applicationId = "com.example.zanny_collection"` to `applicationId = "com.zannycollection.app"`.
2.  **[AndroidManifest.xml](file:///c:/Users/Administrator/Desktop/zanny%20collection%20application/android/app/src/main/AndroidManifest.xml)** (Line 46):
    Change the file provider authority from `com.example.zanny_collection.fileprovider` to `com.zannycollection.app.fileprovider`.
3.  **Rename Folder and MainActivity**:
    *   Rename the folder structure under `android/app/src/main/kotlin/` from `com/example/zanny_collection/` to `com/zannycollection/app/`.
    *   Open `MainActivity.kt` inside that folder and change the first line:
        `package com.example.zanny_collection` ➔ `package com.zannycollection.app`

---

## 🚫 2. Disable Self-Update Permissions
Google Play handles all app updates automatically. If an app tries to update itself outside the Play Store, Google will reject or remove the app.

### How to comply:
1.  Open your **[AndroidManifest.xml](file:///c:/Users/Administrator/Desktop/zanny%20collection%20application/android/app/src/main/AndroidManifest.xml)**.
2.  Locate line 4 and **comment it out or delete it**:
    ```xml
    <!-- Remove or comment this line for Play Store builds: -->
    <!-- <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/> -->
    ```
    *(Note: Keep this permission active ONLY when you are compiling APK versions that you plan to distribute directly from your website landing page).*

---

## 📦 3. Compiling for Google Play (App Bundle)
Google Play requires submissions to be in the **AAB (Android App Bundle)** format instead of standard `.apk` files.

Open your terminal in the project root and run this command:
```powershell
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols --dart-define=PLAY_STORE=true --dart-define=CF_WORKER_URL=https://zanny-collection-api.zannykenya254.workers.dev --dart-define=CF_R2_PUBLIC_URL=https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev
```

### What this command does:
*   **`appbundle`**: Compiles the required `.aab` file.
*   **`--obfuscate`**: Scrambles the app's code to prevent reverse engineering and satisfy Google's security guidelines.
*   **`--dart-define=PLAY_STORE=true`**: Tells the app's code that it is running on the Play Store, which **automatically disables the website self-update screens and prompts**, ensuring compliance with Google Play Store developer guidelines.

---

## 🚀 4. Uploading to Play Console
Once the build command completes successfully:
1.  Locate your compiled app bundle file at:
    `build/app/outputs/bundle/release/app-release.aab`
2.  Log in to your **Google Play Console**.
3.  Create a new Release and upload the `app-release.aab` file.
4.  Provide your public website privacy policy link (the legal screens built into your app cover this policy content).
5.  Publish your app!

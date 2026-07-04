# Zanny Collection App Release Guide

This guide describes the standard, consistent release workflow to push updates to the Zanny Collection Flutter app. Following this workflow guarantees that any compiled update will successfully overwrite previous installs in-place (without signature conflicts).

---

## 🔑 Shared Signing Keystore (Fixed)

Previously, release builds defaulted to the local developer machine's auto-generated debug key. Because of this, an APK built on one machine could not upgrade an app installed from another machine (causing Android's "App not installed" error).

To fix this, a shared keystore has been added to the repository at:
* [key.jks](file:///c:/Users/Administrator/Desktop/zanny%20collection%20application/android/app/key.jks)

And [build.gradle.kts](file:///c:/Users/Administrator/Desktop/zanny%20collection%20application/android/app/build.gradle.kts) has been configured to sign release builds using this key. **All developers must use this repository to compile update builds.**

---

## 🚀 Step-by-Step Release Workflow

When you want to deploy a new version/update:

### Step 1: Bump version in `pubspec.yaml`
Open [pubspec.yaml](file:///c:/Users/Administrator/Desktop/zanny%20collection%20application/pubspec.yaml) and increment both the version name and build number (e.g. from `1.0.6+18` to `1.0.7+19`).

### Step 2: Update version and build number in `update_service.dart`
Open [update_service.dart](file:///c:/Users/Administrator/Desktop/zanny%20collection%20application/lib/core/services/update_service.dart) and update both the `currentVersion` and `currentBuild` constants to match:
```dart
static const String currentVersion = '1.0.7'; // Must match the version string from pubspec.yaml
static const int currentBuild = 19; // Must match the "+19" from pubspec.yaml
```

### Step 3: Compile the Release APK
Run the compiler from the project root:
```powershell
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols --dart-define=CF_WORKER_URL=https://zanny-collection-api.zannykenya254.workers.dev --dart-define=CF_R2_PUBLIC_URL=https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev
```

### Step 4: Rename the APK
Run the script to append the version and timestamp:
```powershell
dart run scripts/rename_apk.dart
```
This renames the APK file to `zanny_collection_v1.0.6_YYYYMMDD_HHMM.apk` in `build/app/outputs/flutter-apk/`.

### Step 5: Upload the APK to Cloudflare R2
Upload the renamed APK file directly to the R2 bucket:
```powershell
npx wrangler r2 object put zanny-images/zanny_collection_v1.0.6_YYYYMMDD_HHMM.apk --file=build/app/outputs/flutter-apk/zanny_collection_v1.0.6_YYYYMMDD_HHMM.apk --remote
```

### Step 6: Publish `version.json` Metadata
1. Open [version.json](file:///c:/Users/Administrator/Desktop/zanny%20collection%20application/version.json) in the project root and update it:
```json
{
  "version": "1.0.6",
  "build": 18,
  "apk_url": "https://zanny-collection-api.zannykenya254.workers.dev/api/images/zanny_collection_v1.0.6_YYYYMMDD_HHMM.apk",
  "changelog": "List of changes in this build."
}
```
2. Upload this metadata file to R2:
```powershell
npx wrangler r2 object put zanny-images/version.json --file=version.json --remote
```

### Step 7: Commit Changes to Git
Once the update is live and tested, commit all source code changes to the Git repository to record history logs and prevent code divergence:
```powershell
git add .
git commit -m "feat: release version 1.0.6 build 18 with [key features]"
```

---
*Note: Any installed client app will automatically see the update notification on the next check. Since the signature is unified, tapping "Update Now" will download the APK and update the app seamlessly in place.*

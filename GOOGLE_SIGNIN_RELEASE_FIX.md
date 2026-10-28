# 🔧 Google Sign-In Fix for Release APK

## Issue Description

Google Sign-In works fine in debug mode but fails with a network error in release builds. This is because:
- **Debug builds** use a debug certificate (automatically configured)
- **Release builds** use your release keystore certificate (needs manual configuration)

The error occurs because Firebase doesn't have the SHA-1 fingerprint from your release keystore.

## ✅ Solution: Add Release SHA-1 to Firebase

### Step 1: Get Your Release Keystore SHA-1

You have a keystore file at: `nikah-blessing-key.jks`  
From your `build.gradle`:
- **Keystore**: `nikah-blessing-key.jks`
- **Alias**: `nikah-blessing`
- **Password**: `nkb@123`

Run this command in your terminal (from project root):

```bash
keytool -list -v -keystore nikah-blessing-key.jks -alias nikah-blessing -storepass nkb@123 -keypass nkb@123
```

**Expected Output:**
```
Certificate fingerprints:
     SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
     SHA256: XX:XX:XX:XX:XX...
```

**Copy the SHA-1 fingerprint** (it will be something like: `9B:9E:BD:71:74:27:28:9E:47:A1:49:81:BE:B2:20:A5:24:25:24:C9`)

### Step 2: Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **nikahblessingapp-org**
3. Click the **gear icon** ⚙️ > **Project Settings**
4. Scroll down to **Your apps** section
5. Find your Android app: `com.nikahblessing.marriagebureau.app`
6. Click **Add fingerprint** button
7. Paste your **SHA-1** from Step 1
8. Click **Save**

### Step 3: Download Updated google-services.json

1. In the same Firebase Console page
2. Click **Download google-services.json** button
3. Replace the existing file at:
   - `android/app/google-services.json`
   - `android/google-services.json`

### Step 4: Rebuild Your App

```bash
# Clean the build
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Or build app bundle
flutter build appbundle --release
```

## 🔍 Verify the Fix

### Test Google Sign-In in Release Build:

1. Install the release APK on your device:
   ```bash
   flutter install --release
   ```

2. Open the app and try Google Sign-In
3. It should now work without network errors!

## 📋 Current Configuration

Your current `google-services.json` shows:
```json
"oauth_client": [
  {
    "client_id": "582571190650-9bscd7n2d9d47v37mmir0j7dnj7bdvvm.apps.googleusercontent.com",
    "client_type": 1,
    "android_info": {
      "package_name": "com.nikahblessing.marriagebureau.app",
      "certificate_hash": "9b9ebd717427289e47a14981beb220a5242524c9"
    }
  }
]
```

This shows **only one SHA-1 is registered**: `9b9ebd717427289e47a14981beb220a5242524c9`

After adding your release SHA-1, you should see **two** entries in the JSON file.

## 🛠️ Alternative: Get SHA-1 from Built APK

If you've already built a release APK, you can extract the SHA-1 from it:

```bash
# First, get the certificate from the APK
unzip -p build/app/outputs/apk/release/app-release.apk META-INF/*.RSA | keytool -printcert

# Look for the SHA1 fingerprint in the output
```

## ⚠️ Common Mistakes to Avoid

1. **Wrong Keystore**: Make sure you're using `nikah-blessing-key.jks` not the debug keystore
2. **Wrong Alias**: Use alias `nikah-blessing` (as configured in build.gradle)
3. **Not Rebuilding**: After updating google-services.json, you MUST rebuild the app
4. **Package Name Mismatch**: Ensure package name is exactly: `com.nikahblessing.marriagebureau.app`

## 🔐 ProGuard Configuration (Already Set)

Your `proguard-rules.pro` should include Google Sign-In rules. Check that it has:

```proguard
# Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
```

✅ Your configuration already includes these rules.

## 📱 Testing Checklist

After implementing the fix:

- [ ] SHA-1 from release keystore added to Firebase
- [ ] Downloaded new google-services.json
- [ ] Replaced google-services.json in both locations
- [ ] Ran `flutter clean`
- [ ] Ran `flutter pub get`
- [ ] Built release APK/AAB
- [ ] Installed release build on device
- [ ] Tested Google Sign-In successfully

## 🎯 Quick Fix Command Summary

```bash
# 1. Get SHA-1
keytool -list -v -keystore nikah-blessing-key.jks -alias nikah-blessing -storepass nkb@123 -keypass nkb@123

# 2. Add to Firebase (manual step in console)

# 3. Download new google-services.json (manual step)

# 4. Rebuild app
flutter clean
flutter pub get
flutter build apk --release
```

## 📞 If Still Not Working

If Google Sign-In still fails after following these steps:

1. **Check Firebase Authentication**:
   - Go to Firebase Console > Authentication
   - Ensure Google Sign-In provider is **enabled**

2. **Verify OAuth Consent Screen**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Select your project
   - Navigate to **APIs & Services** > **OAuth consent screen**
   - Ensure app is published or in testing mode with your email added

3. **Check Package Name**:
   - In `android/app/build.gradle`: `applicationId = "com.nikahblessing.marriagebureau.app"`
   - In Firebase Console: Must match exactly

4. **Clear App Data**:
   - Uninstall the app completely
   - Reinstall the release build
   - Try Google Sign-In again

## 🔄 For Play Store Builds

When you upload to Play Store, Google Play will re-sign your app with their own certificate. You'll need to:

1. Go to Play Console > **App Integrity**
2. Copy the **SHA-1 certificate fingerprint** from "App signing key certificate"
3. Add this SHA-1 to Firebase as well
4. Download and update google-services.json again

This ensures Google Sign-In works for users who download from Play Store!

---

## 📦 Package Name Change (Feb 2025)

The app package was changed from `com.nikahblessing.marriagebeauro.nikah_blessing` to **`com.nikahblessing.app`** to resolve "package name already used" in Play Store.

**What was updated:**
- `android/app/build.gradle` — `namespace` and `applicationId` → `com.nikahblessing.app`
- `android/app/src/main/java/com/nikahblessing/app/MainActivity.java` — new package path
- `android/app/google-services.json` — `package_name` set to `com.nikahblessing.app`

**What you need to do:**

1. **Remove old Java path (if present)**  
   Delete the folder:  
   `android/app/src/main/java/com/nikahblessing/marriagebureau/`  
   (so only `com/nikahblessing/app/MainActivity.java` remains.)

2. **Firebase**  
   In [Firebase Console](https://console.firebase.google.com) → your project → Project settings:
   - Add an **Android app** with package name **`com.nikahblessing.app`**.
   - Add your release **SHA-1** (same keystore as before).
   - Download the new **google-services.json** and replace `android/app/google-services.json`.

3. **Google Play**  
   Use the new package when creating or updating the app listing (new package = new app unless you use Play App Signing and the same key).

---

**Created**: December 1, 2025  
**Status**: Ready to Implement  
**Priority**: 🔴 High (Blocks Release)


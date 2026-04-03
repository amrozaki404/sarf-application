# Android Release Checklist

## 1. Create or use your upload keystore

Put your keystore file outside git-tracked files or keep it locally only.

Example location:

`android/upload-keystore.jks`

## 2. Create `android/key.properties`

Copy from:

`android/key.properties.example`

Fill it with your real values:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

## 3. Download the correct Firebase Android config

Replace:

`android/app/google-services.json`

It must belong to:

- Firebase project: `sarf-54738`
- Android package: `com.sarf.app`

## 4. Add SHA fingerprints

In Firebase and Google Play:

- debug SHA-1 / SHA-256
- upload key SHA-1 / SHA-256
- Play App Signing SHA-1 / SHA-256

## 5. Build the Play Store artifact

Important:

- if `android/key.properties` is missing, the project falls back to debug signing
- that output is not valid for Google Play production upload

Preferred for Google Play:

```bash
flutter build appbundle --release
```

APK for manual testing:

```bash
flutter build apk --release
```

## 6. Upload to Google Play

Upload:

`build/app/outputs/bundle/release/app-release.aab`

Use Play Console internal testing first before production.

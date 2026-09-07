# Android V1 release

Ood V1 is configured for a signed Android release build with:

- application ID: `com.ood.app`
- version: `1.0.1+3`
- compile SDK: 36
- target SDK: 36
- Java / Kotlin target: 17
- release signing from `android/key.properties`

The real keystore and passwords must never be committed to GitHub.

## 1. Upload keystore

The current Ood upload keystore is stored locally at:

```text
C:/dev/keys/ood-upload-key.jks
```

Keep the keystore and its password backed up somewhere private. Never commit the `.jks` file to GitHub.

## 2. Local signing file

From Git Bash on Windows:

```bash
cd /c/dev/ood-calendar
```

`android/key.properties` should point to the private upload key:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:/dev/keys/ood-upload-key.jks
```

Use forward slashes in the Windows path.

The repository ignores:

- `android/key.properties`
- `*.jks`
- `*.keystore`

## 3. Verify the release candidate

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The APK is created at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Install it on a connected Android phone for a final V1 check:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Test at least:

- launch / resume
- Calendar month navigation
- create today's doodle
- undo
- memo entry and 60-character limit
- Save confirmation
- return to Calendar
- reopen today's Card
- edit today's entry
- delete today's and a past saved entry
- persistence after fully closing and reopening the app
- onboarding and question-theme flow on a fresh install
- bundled Gaegu font in the release build

## 4. Build the Google Play bundle

After the release APK passes the device check:

```bash
flutter build appbundle --release
```

The Play bundle is created at:

```text
build/app/outputs/bundle/release/app-release.aab
```

Upload that `.aab` to Google Play Console Internal Testing first.

Expected metadata for this build:

```text
version name: 1.0.1
version code: 3
package: com.ood.app
```

## Versioning after this build

Every new Google Play upload must use a higher build number. For example:

```yaml
version: 1.0.2+4
```

Google Play requires every uploaded Android build to use a higher version code than all previous uploads.

## Launcher icon

The Android launcher uses the approved Ood icon artwork: a soft cream calendar with a warm beige header and one loose doodle line.

Density-specific PNGs are committed directly:

- mdpi: 48 × 48
- hdpi: 72 × 72
- xhdpi: 96 × 96
- xxhdpi: 144 × 144
- xxxhdpi: 192 × 192

Both normal and round launcher requests point to the same `@mipmap/ic_launcher` artwork. The Play Store listing should use the matching 512 × 512 store icon.

## Final high-density splash pass

The splash mark uses density-specific PNG resources:

- mdpi: 288 × 288
- hdpi: 432 × 432
- xhdpi: 576 × 576
- xxhdpi: 864 × 864
- xxxhdpi: 1152 × 1152

This keeps the centered calendar+doodle mark and warm ivory field sharp on high-density Android screens while remaining inside the Android splash safe area.

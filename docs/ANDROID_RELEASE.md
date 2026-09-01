# Android V1 release

Sodam V1 is configured for a signed Android release build with:

- application ID: `com.sodam.app`
- version: `1.0.0+1`
- compile SDK: 36
- target SDK: 36
- Java / Kotlin target: 17
- release signing from `android/key.properties`

The real keystore and passwords must never be committed to GitHub.

## 1. Create the upload keystore once

From Git Bash on Windows:

```bash
keytool -genkeypair -v \
  -keystore C:/Users/USER/sodam-upload-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

Choose a strong password and keep it somewhere safe. The keystore should also be backed up somewhere private.

If `keytool` is not found, use the JDK bundled with Android Studio or the JDK used by Flutter.

## 2. Create the local signing file

```bash
cd /c/dev/sodam
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:/Users/USER/sodam-upload-key.jks
```

Use forward slashes in the Windows path.

The repository already ignores:

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

## Versioning after V1

For the next Play upload, increase the build number in `pubspec.yaml`, for example:

```yaml
version: 1.0.1+2
```

Google Play requires every uploaded Android build to use a higher version code.

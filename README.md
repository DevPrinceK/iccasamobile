# ICCASA Field

Responsive, offline-first field collection for ICCASA M&E. The Flutter app runs
on Android, iOS, tablets and web for development verification.

## Run locally

```powershell
flutter pub get
flutter run -d chrome --dart-define=ICCASA_API_URL=http://127.0.0.1:8002/api/v1
```

For an Android emulator, use `http://10.0.2.2:8002/api/v1`. Production builds
default to `https://iccasa.pkaylabs.com/api/v1`; `ICCASA_API_URL` can still
override it for a controlled test environment.

## Android release signing

Copy `key.properties.example` to `android/key.properties` and replace every value with the
production keystore details. The keystore and properties file are ignored by Git. Release
builds fail deliberately when signing is absent or incomplete; debug builds continue to use
Flutter's development signing configuration.

```powershell
flutter build apk --release --split-per-abi --dart-define=ICCASA_API_URL=https://iccasa.pkaylabs.com/api/v1
```

The development seed includes `abena.mensah@iccasa.local` with password
`Password123!`. A local preview workspace is also available in debug builds.

## Quality checks

```powershell
flutter analyze
flutter test
flutter build web --release --dart-define=ICCASA_API_URL=https://iccasa.pkaylabs.com/api/v1
flutter build apk --debug --dart-define=ICCASA_API_URL=http://10.0.2.2:8002/api/v1
```

The split release build produces separate `armeabi-v7a`, `arm64-v8a`, and
`x86_64` APKs. Most current phones and tablets use the `arm64-v8a` package.

## Push notifications

Firebase Cloud Messaging is integrated for Android and iOS. Register the Android
package `org.iccasa.iccasa_mobile` in ICCASA's Firebase project and place its
`google-services.json` in `android/app/`. Place the iOS
`GoogleService-Info.plist` in `ios/Runner/`, enable Push Notifications and
Background Modes in Xcode, and upload an APNs key to Firebase. The local Firebase
files are Git-ignored. Without them, the app still builds and runs, but push
notifications remain unavailable. The API/worker setup is described in the
backend's `docs/push-notifications.md`.

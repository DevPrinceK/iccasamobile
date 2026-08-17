# ICCASA Field

Responsive, offline-first field collection for ICCASA M&E. The Flutter app runs
on Android, iOS, tablets and web for development verification.

## Run locally

```powershell
flutter pub get
flutter run -d chrome --dart-define=ICCASA_API_URL=http://127.0.0.1:8002/api/v1
```

For an Android emulator, use `http://10.0.2.2:8002/api/v1`. Production builds
must supply the deployed HTTPS API URL through `ICCASA_API_URL`.

## Android release signing

Copy `key.properties.example` to `android/key.properties` and replace every value with the
production keystore details. The keystore and properties file are ignored by Git. Release
builds fail deliberately when signing is absent or incomplete; debug builds continue to use
Flutter's development signing configuration.

```powershell
flutter build appbundle --release --dart-define=ICCASA_API_URL=https://api.iccasa.example/api/v1
```

The development seed includes `abena.mensah@iccasa.local` with password
`Password123!`. A local preview workspace is also available in debug builds.

## Quality checks

```powershell
flutter analyze
flutter test
flutter build web --release --dart-define=ICCASA_API_URL=https://api.example.org/api/v1
flutter build apk --debug --dart-define=ICCASA_API_URL=http://10.0.2.2:8002/api/v1
```

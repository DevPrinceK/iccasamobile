# Android publishing checklist

## Release artifact

- Package: `org.iccasa.iccasa_mobile`
- App name: ICCASA Field
- Release: `1.1.5` (`versionCode` 7)
- Minimum Android: API 24 (Android 7.0)
- Target Android: API 36 (Android 16)
- Bundle: `build/app/outputs/bundle/release/app-release.aab`
- Signing: ICCASA release keystore; JAR signature verified
- Native libraries: ARM64, ARMv7 and x86_64; ARM64 load segments are aligned to at least 16 KB
- Live API: `https://iccasa.pkaylabs.com/api/v1`

## Play Console listing

- Upload the app bundle.
- Use the app name, short description, full description and release notes in `play-listing.md`.
- Upload `store-icon.png` and `feature-graphic.png`.
- Upload the six images under `phone/` as phone screenshots.
- Upload the five images under `tablet/` for both 7-inch and 10-inch tablet screenshot sections.
- Category recommendation: Productivity.
- Support website: `https://iccasa.pkaylabs.com/contact`
- Privacy policy: `https://iccasa.pkaylabs.com/privacy`

## App content declarations

- Ads: No.
- Target audience: Adults / organizational field staff; the app is not designed for children.
- App access: Restricted. Provide Google Play with a reusable live reviewer account that can sign in without OTP or a location restriction and has at least one published form assignment.
- Content rating: Complete the IARC questionnaire accurately. The app itself contains no user-generated public feed, gambling, violence, or mature entertainment content.
- Permissions: Explain that camera and location are optional collection tools used only when a configured form requests supporting evidence or GPS. Notifications alert signed-in users about assigned work and system updates.
- Data safety: Complete this from the deployed system's actual practices and retention policy. The app can process account name/email, profile photo, form responses, files/photos, signatures, precise location, and a push token. It uses encrypted HTTPS in transit; authentication tokens and cached workspace data are kept in Android secure storage.
- Account deletion: Accounts are organization-managed rather than created in the mobile app. Confirm the external deletion/request process and enter its URL in Play Console if Google classifies the app as allowing account creation.
- Data deletion: Document how a user can ask ICCASA or their organization administrator to delete eligible personal data.
- Government / health / financial-feature declarations: answer No unless the Play Console's definitions and the organization's use of collected survey data require otherwise.

## Required external configuration

- Add `android/app/google-services.json` for package `org.iccasa.iccasa_mobile` before publishing if push notifications must be active in this release. Without it, the app still builds and works, but Android push delivery is disabled.
- Confirm that version code `7` has not already been used in this Play Console app. Increment it before rebuilding if necessary.
- Keep `android/key.properties` and the keystore backed up securely. Never upload either to source control.
- Enable Play App Signing when creating the first Play release and retain the existing keystore as the upload key.
- Run the Play Console pre-launch report on phone and tablet form factors, then resolve any blocking accessibility, stability, or policy findings.

## Verification completed

- `flutter analyze`
- `flutter test`
- `flutter build appbundle --release`
- Feature graphic: 1024 x 500, 24-bit RGB PNG
- Store icon: 512 x 512, 32-bit PNG, under 1 MB
- Phone screenshots: 1080 x 1920
- Tablet screenshots: 1800 x 2560

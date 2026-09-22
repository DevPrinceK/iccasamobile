# Google Play data safety worksheet

This is an implementation-based worksheet, not legal advice. Confirm every answer with ICCASA's data controller and infrastructure owners before submitting the Play Console declaration.

## Security and account model

- Data encrypted in transit: Yes. The production API uses HTTPS.
- Data deletion request mechanism: ICCASA or an authorised institution administrator handles requests under the published privacy policy.
- Account creation in app: No. Accounts are provisioned by an organisation administrator.
- Ads: No.
- Public user-generated content: No.
- Ephemeral processing only: No. Forms, drafts, queued submissions, and recent records can be stored securely on the device and retained by the ICCASA service.

## Data types used by the mobile app

| Google Play category | Examples in ICCASA Field | Collected | Shared | Purpose | Required |
| --- | --- | --- | --- | --- | --- |
| Personal info: name, email, user ID | Signed-in field agent profile and submission attribution | Yes | Confirm with ICCASA | App functionality, account management, security | Required for account access |
| Photos | Optional profile photo and form evidence images | When used | Confirm with ICCASA | App functionality | Optional unless a configured form requires evidence |
| Files and documents | Form evidence attachments and captured signatures | When used | Confirm with ICCASA | App functionality | Optional unless a configured form requires evidence |
| Location: precise | GPS evidence and country or administrative area selections | When used | Confirm with ICCASA | App functionality | GPS optional; configured geography fields required |
| App activity / other user-generated content | Survey answers, drafts, submissions, and review status | Yes | Confirm with ICCASA | App functionality, analytics/reporting within ICCASA | Required for field collection |
| Device or other identifiers | Device ID and Firebase push token when push is configured | Yes | Firebase processes the token when configured | Security, app functionality, notifications | Device ID required; notifications optional |

"Shared" must be answered according to Google Play's definition and ICCASA's contracts with hosting, email, notification, support, and other processors. Do not infer the final Play Console answer from this repository alone.

## Permission explanations

- Camera: capture a profile photo or evidence photo requested by a form.
- Precise/coarse location: capture GPS evidence requested by a form.
- Notifications: alert signed-in users about assigned work and relevant system updates.
- Internet: authenticate, download assigned forms, upload submissions, and synchronize records.

## Public policy URL

`https://iccasa.pkaylabs.com/privacy`

The source page now includes an ICCASA Field-specific mobile data notice. Deploy that web update before submitting the Play listing.

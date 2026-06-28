# ICCASA Field Agent Tablet App Specification

## 1. Product Vision

The ICCASA field agent mobile app is a Flutter tablet application for field teams who register people, verify records, collect field observations, manage assigned visits, capture supporting media, and synchronize work reliably in low-connectivity environments.

The app should feel calm, fast, and premium. Field agents may use it for long sessions, outdoors, in vehicles, at partner sites, or during interviews, so the interface must be readable, touch-friendly, resilient, and forgiving.

The product promise:

> Field agents can complete accurate field work from a tablet, even with unstable internet, while supervisors receive clean, auditable data.

## 2. Target Users

### 2.1 Field Agent

Primary tablet user.

Needs:

- Daily assignment list.
- Fast search.
- Guided data collection.
- Offline-first forms.
- Photo/document capture.
- Signature capture where needed.
- GPS/location capture where permitted.
- Clear sync status.
- Error recovery without data loss.

### 2.2 Field Supervisor

Reviews field work and monitors team progress.

Needs:

- View assigned agents.
- Review submitted records.
- See incomplete or blocked work.
- Approve/reject submissions if required.
- Reassign visits.
- Monitor sync issues.

### 2.3 Admin/Operations Team

Configures work templates, regions, agent access, and reporting.

Needs:

- Role-based access.
- Device/session visibility.
- Audit trails.
- Export-ready records.
- Configurable forms and validation rules.

## 3. App Scope

Initial tablet app scope:

- Authentication.
- Agent home dashboard.
- Daily assignments.
- Beneficiary/client/entity record search.
- Field visit workflow.
- Dynamic forms.
- Offline data capture.
- Draft autosave.
- Photo/document upload queue.
- Signature capture.
- GPS/location capture.
- Sync center.
- Notifications/alerts.
- Supervisor review mode, if user role permits.
- Settings and device diagnostics.

## 4. Platform and Stack

Required stack:

- Flutter stable.
- Dart.
- Material 3.
- Tablet-first responsive layout.
- Riverpod or Bloc for state management.
- GoRouter for navigation.
- Dio for HTTP.
- Drift or Isar for local offline database.
- Secure storage for tokens and device keys.
- Connectivity Plus for network awareness.
- Image Picker/Camera package for media capture.
- Geolocator for location capture.
- Signature package or custom canvas for signatures.
- Flutter Animate or implicit animations for polished motion.
- Sentry or equivalent crash reporting.

Recommended architecture:

```text
lib/
  app/
    app.dart
    router.dart
    theme.dart
    providers.dart

  core/
    api/
    auth/
    database/
    errors/
    location/
    media/
    sync/
    security/
    telemetry/
    widgets/

  features/
    auth/
    dashboard/
    assignments/
    records/
    visits/
    forms/
    media_capture/
    sync_center/
    supervisor/
    settings/

  design_system/
    components/
    motion/
    tokens/
```

## 5. UX Principles

The UI should be:

- Tablet-first, not stretched phone UI.
- Large enough for outdoor touch use.
- Fast to scan.
- Friendly but professional.
- Motion-rich but never distracting.
- Offline-safe by default.
- Clear about what is saved, pending, failed, or synced.

Design tone:

- Field-ready.
- Trustworthy.
- Modern public-service operations feel.
- Warm, human, and organized.

Avoid:

- Tiny tap targets.
- Dense desktop tables copied onto tablets.
- Overly decorative dashboards.
- Hidden sync state.
- Long forms without progress.
- Blocking agents from moving forward when data can be saved as draft.

## 6. Visual Design Direction

### 6.1 Layout

Tablet layout should use:

- Persistent side rail on landscape tablets.
- Bottom navigation or compact rail on portrait tablets.
- Two-pane layouts for list/detail workflows.
- Sticky form progress header.
- Large touch rows for assignments.
- Split review panels for supervisor workflows.

Suggested primary navigation:

- Home.
- Assignments.
- Records.
- Sync.
- Alerts.
- Settings.

Landscape assignment layout:

```text
| Rail | Assignment list | Assignment detail / action panel |
```

Portrait assignment layout:

```text
Top app bar
Assignment cards
Bottom navigation
```

### 6.2 Color

Use a balanced palette:

- Primary: deep teal or blue-green for action and trust.
- Secondary: warm gold/amber for attention and field context.
- Neutral: soft slate/stone backgrounds.
- Success: green.
- Warning: amber.
- Error: red.
- Offline: grey/indigo status treatment.

Avoid a single-hue interface. Status colors should carry meaning consistently.

### 6.3 Typography

Use a readable modern sans-serif.

Guidance:

- Page titles: 24-32.
- Section titles: 18-22.
- Body: 15-17.
- Table/card metadata: 13-14.
- Minimum body size should remain comfortable on tablets.

### 6.4 Components

Core components:

- AppShell.
- NavigationRail.
- BottomNavigationBar.
- AssignmentCard.
- StatusBadge.
- SyncStatusPill.
- OfflineBanner.
- RecordSummaryCard.
- FormStepHeader.
- SectionCard.
- PhotoCaptureTile.
- SignaturePad.
- LocationCaptureButton.
- EmptyState.
- ErrorState.
- LoadingSkeleton.
- ConfirmSheet.
- ReviewPanel.
- ActivityTimeline.

Do not nest cards inside cards. Use cards for records/items/tools, and use unframed page sections for layout.

## 7. Motion and Animation

Motion should make the app feel premium, responsive, and calm.

### 7.1 Motion Principles

- Use short, purposeful animations.
- Prefer shared-axis transitions for task flows.
- Use fade/slide for list changes.
- Use spring-like microinteractions sparingly.
- Respect reduced motion settings.
- Never animate in a way that delays field work.

### 7.2 Required Animations

App launch:

- Soft fade-in from splash to login or home.
- Logo mark can gently scale/fade.

Navigation:

- Shared-axis transition between main sections.
- Active navigation item uses smooth indicator movement.

Assignment list:

- Cards stagger in subtly on first load.
- Status changes animate color/label transition.
- Pull-to-refresh uses a polished progress indicator.

Forms:

- Step changes use horizontal slide/fade.
- Validation errors gently expand under fields.
- Save status changes from "Saving" to "Saved" with a check animation.
- Required missing fields can use a mild shake only after attempted submit.

Media capture:

- Captured photo thumbnail animates into the evidence grid.
- Upload progress animates inside the tile.
- Failed upload state pulses very subtly until retried.

Sync center:

- Queue rows animate between pending, syncing, failed, and synced.
- Sync progress uses smooth determinate progress when possible.

Supervisor review:

- Approve/reject actions use confirmation sheet animation.
- Review panel slides in from the right on landscape tablets.

## 8. Core User Flows

### 8.1 Login

Steps:

1. Agent opens app.
2. App checks local session.
3. If no session, show login.
4. Agent enters email/phone and password or PIN, depending backend support.
5. App authenticates.
6. App downloads assigned profile, permissions, and initial work queue.
7. App lands on Home.

States:

- Loading.
- Invalid credentials.
- Offline with no cached session.
- Offline with cached session.
- Device not authorized.
- Password reset required.

### 8.2 Home Dashboard

Home should show:

- Today assigned.
- In progress.
- Completed but pending sync.
- Failed sync items.
- Urgent alerts.
- Quick search.
- Continue last draft.

### 8.3 Assignment Workflow

Assignment states:

- New.
- In progress.
- Needs attention.
- Completed locally.
- Pending sync.
- Submitted.
- Returned for correction.
- Approved.

Workflow:

1. Agent opens assignment.
2. App shows record summary and required tasks.
3. Agent starts visit.
4. App captures time, optional location, and draft record.
5. Agent completes guided form.
6. App validates required fields.
7. Agent attaches photos/documents/signatures.
8. Agent marks assignment complete.
9. App submits immediately if online or queues for sync if offline.

### 8.4 Record Search

Search should support:

- Name.
- ID/reference.
- Phone.
- Location/community.
- Assignment status.
- Sync state.

Search must work offline against locally cached records.

### 8.5 Dynamic Forms

Field types:

- Text.
- Number.
- Currency/amount if needed.
- Date.
- Single select.
- Multi select.
- Checkbox.
- Radio.
- GPS/location.
- Photo.
- Document.
- Signature.
- Repeating household/member section.
- Conditional section.

Form behavior:

- Autosave every few seconds and on navigation.
- Show last saved time.
- Allow draft completion later.
- Validate locally before submit.
- Preserve partial work through app restart.

### 8.6 Media Capture

Media requirements:

- Capture photo from camera.
- Attach existing image if permitted.
- Compress images before upload.
- Store pending uploads locally.
- Retry failed uploads.
- Show upload progress.
- Preserve metadata: timestamp, assignment, form field, optional location.

### 8.7 Sync

Sync principles:

- Offline-first.
- No silent data loss.
- All local mutations enter an outbox queue.
- Queue items have type, status, retries, error, and timestamps.
- Sync is resumable.
- Agent can manually retry.

Sync states:

- Pending.
- Syncing.
- Synced.
- Failed.
- Blocked.
- Conflict.

Conflict handling:

- Prefer server-configurable rules.
- Show field-level conflict where possible.
- Let supervisor/admin resolve complex conflicts.

## 9. Backend API Assumptions

The app will need APIs for:

- Login/session refresh.
- Current user profile.
- Device registration.
- Assignment list.
- Assignment detail.
- Record search.
- Dynamic form schema.
- Draft/visit submission.
- Media upload.
- Signature upload.
- Sync batch submit.
- Sync status.
- Notifications/alerts.
- Supervisor review actions.

Recommended endpoints:

```text
POST /api/mobile/auth/login
POST /api/mobile/auth/refresh
POST /api/mobile/devices/register
GET  /api/mobile/me
GET  /api/mobile/assignments
GET  /api/mobile/assignments/{id}
POST /api/mobile/assignments/{id}/start
POST /api/mobile/assignments/{id}/complete
GET  /api/mobile/records/search
GET  /api/mobile/forms/{form_id}/schema
POST /api/mobile/sync/batch
POST /api/mobile/media
GET  /api/mobile/alerts
POST /api/mobile/supervisor/reviews/{id}/approve
POST /api/mobile/supervisor/reviews/{id}/reject
```

## 10. Offline Data Model

Local tables/collections:

- current_user.
- device_profile.
- assignments.
- records.
- form_schemas.
- form_drafts.
- media_items.
- signatures.
- outbox_queue.
- sync_events.
- alerts.
- cached_reference_data.

Outbox item fields:

- id.
- type.
- local_entity_id.
- endpoint.
- payload.
- media_path nullable.
- status.
- retry_count.
- last_error.
- created_at.
- updated_at.
- synced_at.

## 11. Security

Required:

- Secure token storage.
- Optional device registration.
- Session timeout policy.
- App lock/PIN after inactivity if required.
- Encrypted local database if sensitive data requires it.
- Media stored in app-private storage.
- Redact sensitive logs.
- Do not expose access tokens in crash reports.
- Role-based feature access.

Future:

- Biometric unlock.
- Remote device revoke.
- Certificate pinning if required.
- MDM support.

## 12. Accessibility

Required:

- Large tap targets.
- Good color contrast.
- Screen reader labels.
- Reduced motion support.
- Keyboard/focus support for hardware keyboards.
- Error text connected to form fields.
- Icons paired with labels for important actions.

## 13. Analytics and Telemetry

Track product events:

- Login success/failure.
- Assignment opened.
- Assignment started.
- Form step completed.
- Draft saved.
- Assignment completed.
- Sync started.
- Sync succeeded.
- Sync failed.
- Media upload failed.
- Supervisor review action.

Do not send sensitive form answers unless explicitly approved.

## 14. Testing Strategy

Unit tests:

- Validators.
- Form schema parser.
- Sync queue state machine.
- API error mapping.
- Permission helpers.

Widget tests:

- Login form.
- Assignment card.
- Dynamic form fields.
- Sync status widgets.
- Media tile states.

Integration tests:

- Login to dashboard.
- Complete assignment online.
- Complete assignment offline then sync.
- Media capture and retry.
- Returned-for-correction workflow.

Manual QA:

- Tablet landscape and portrait.
- Offline start.
- Network drop during submit.
- App kill/restart with draft.
- Large assignment queue.
- Low storage behavior.

## 15. Acceptance Criteria

The app is ready for pilot when:

- Agents can log in and see assigned work.
- Assignments can be opened and completed.
- Forms autosave locally.
- Work can continue offline.
- Pending work syncs when internet returns.
- Media capture and upload queue works.
- Sync failures are visible and recoverable.
- UI works comfortably on tablet portrait and landscape.
- Important actions are animated smoothly without slowing field work.
- No completed local work is lost during app restart.

## 16. Open Questions

- What exact field entities are agents managing: people, households, facilities, cases, assets, visits, or all of these?
- Which backend repo/API should this app integrate with first?
- Does ICCASA require encrypted offline storage for all records?
- Should agents authenticate with email/password, phone/PIN, OTP, or SSO?
- Are supervisors expected to use the same tablet app or a separate web dashboard?
- What geolocation precision and consent rules are required?
- Are signatures legally required or only operational evidence?
- What languages must the app support?
- What tablets and Android/iPadOS versions are targeted?


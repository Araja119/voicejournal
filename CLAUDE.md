# VoiceJournal

## Overview
iOS app + Node.js backend for preserving family stories through voice recordings. Users create journals for loved ones, send thought-provoking questions, and receive audio recordings of their answers. Supports self-journaling (recording your own answers).

## Tech Stack
- **iOS**: Swift 5.9+, SwiftUI, iOS 17.0+, MVVM + Services layer
- **Backend**: Node.js/TypeScript, Express, PostgreSQL/Prisma ORM, JWT + Apple Sign-In
- **Storage**: Local filesystem (dev) / Cloudflare R2 (prod)
- **Push**: Firebase Cloud Messaging (backend `push.service.ts` deployed; iOS Firebase SDK not yet added)
- **Email**: Console mock (dev) / Resend (prod, free tier — test domain only)
- **Deployment**: Railway (backend), TestFlight (iOS)

## Key Paths
- **Project root**: `/Users/ARaja/voicejournal/`
- **iOS source**: `ios/VoiceJournal/VoiceJournal/` — Core/, Models/, Services/, ViewModels/, Views/
- **Backend source**: `backend/src/` — routes/, services/, validators/, middleware/, views/
- **Prisma schema**: `backend/prisma/schema.prisma`
- **Xcode project**: `ios/VoiceJournal/VoiceJournal.xcodeproj`
- **Production URL**: `https://invigorating-amazement-production-81b6.up.railway.app`
- **Bundle ID**: `ARaja.VoiceJournal`
- **URL utility**: `backend/src/utils/url.ts` — shared `getAppUrl()` ensures `https://` prefix on all generated links

## Architecture & Conventions

### iOS
- ViewModels as `@StateObject`, `AppState` via `@EnvironmentObject`, services are plain classes
- `NavigationStack` + `.sheet()` / `.fullScreenCover()` for modals
- **Parent-handled actions**: Child views use `onMenuTapped` callback → parent shows `confirmationDialog`. Avoids SwiftUI Menu closure bug where button actions don't fire in child views.
- **Idempotency**: Recording uploads use UUID `Idempotency-Key` header to prevent duplicates
- **Self-journal detection**: `dedicatedToPerson.relationship == "self"` OR `linkedUserId == journal.owner.id`
- Questions sent via native iOS share sheet (`SharePresenter` wrapping `UIActivityViewController`), not email
- Share link is embedded inline in the message text (not as a separate URL object) to avoid iMessage rich preview orientation issues
- Contacts import uses `CNContactPickerViewController` with `CNContactStore` re-fetch for photo access

### Backend
- Express routes → services → Prisma ORM
- Separate routers: `/recordings` (authenticated) vs `/record` (public link-token) — avoids dynamic param collision
- `syncSelfPersonsWithUsers()` runs at startup (links self-persons, syncs profile photos)
- Cascade delete: deleting a person deletes their journals, questions, assignments, recordings
- Assignment remind has escalating cooldown: 1h → 24h → 72h
- Push notifications: `push.service.ts` uses Firebase Admin SDK, falls back to console.log mock when `FIREBASE_SERVICE_ACCOUNT` env var is not set
- Profile photo URLs from R2 must be signed with `getSignedUrl()` before returning in API responses (same as audio URLs)

## Design System
- **Colors** (`AppColors`): accentPrimary (#FF6B35 orange), accentSecondary (#C47F17 gold), accentRecord (#8B5CF6 purple — used for self-recording buttons)
- **Typography** (`AppTypography`): Display 28-34pt, Headlines 18-22pt, Body 15-17pt, Labels 12-14pt
- **Background** (`AppBackground`): Full-screen image with atmospheric vignette gradients, reads `appState.backgroundTheme` for selected theme
- **Background themes** (`BackgroundTheme` enum in AppState):
  - Classic (default light/dark)
  - Desert Sun (light) / Calm Ocean (dark)
  - Antique Parchment (light) / Archive Gray (dark)
  - Assets in `Assets.xcassets/Background*.imageset/`, each with `Contents.json` defining luminosity variants
  - Persisted to UserDefaults key `"backgroundTheme"`, selectable via carousel in Settings → Appearance
- **Glass system** (`GlassView.swift`):
  - `.glassCard()` for primary cards, `.glassCardSecondary()` for nested cards
  - `GlassIconCircle(icon:iconColor:)`, `GlassTextColors`, `GlassIconColors`
  - Light mode uses UIKit `TranslucentBlurView` because SwiftUI materials render opaque white
  - Icon colors: `.sendQuestion` (#FF7A2F), `.slate` (#5B6B9A)
- **Recording page** (`backend/src/views/record-page.ts`): Server-rendered HTML with glass stack layout, custom audio player, real-time level meter, ambient animated orbs. Template variables: `${personName}`, `${questionText}`, `${requesterName}`, `${linkToken}`

## Recording Player
- `RecordingPlayerView.swift` with AVPlayer, 5-second skip forward/back
- Uses `seek(to:toleranceBefore:toleranceAfter:)` with `.zero` for frame-accurate seeking
- Duration prefers API `durationSeconds` (measured at recording time) over asset metadata (unreliable for streamed browser-recorded audio)
- Self-corrects duration when playback ends before reported length
- `StaticWaveformView` supports drag-to-scrub gesture via `onScrub`/`onScrubEnd` callbacks

## Current Status — What's TODO

### Next Priorities
- [x] **Firebase push notifications** — Fully working. Firebase project "Lore" (lore-3613f), APNs key uploaded, service account on Railway. See memory `firebase-push-setup.md`.
- [x] **Playback speed control** — 1x/1.25x/1.5x/2x speed cycling in recording player.
- [ ] **Custom domain** — Buy domain, add to Railway, update `WEB_APP_URL` env var. Fixes iMessage link tappability for long Railway subdomain.
- [ ] **App renaming** — Renaming to Lore. Affects Firebase bundle ID, domain, App Store listing.
- [ ] **Search** — No search in journals, people, or recordings lists
- [ ] **Voice note transcription** — Built-in transcription so users can read what a person said in their recording (Whisper API or similar)

### Later
- [ ] Add `ANTHROPIC_API_KEY` to Railway (for AI-suggested questions)
- [ ] SMS delivery (Twilio)
- [ ] Custom Resend email domain (currently test domain, can only send to verified addresses)
- [ ] Video recording (premium feature idea)
- [ ] More background themes (user has mood boards with 12+ options)

## Known Issues
- **Xcode build caching**: `rm -rf ~/Library/Developer/Xcode/DerivedData/VoiceJournal-*` if changes not picked up
- **Apple Sign-In on Simulator**: Always fails — requires physical device with signed-in Apple ID
- **Self-journal legacy data**: Old "myself" persons without `relationship="self"` or `linkedUserId` won't detect; delete and recreate through app
- **SwiftUI Menu closures**: Button actions don't fire in child views — use parent `confirmationDialog` pattern instead
- **Firebase project named "Lore"**: Firebase project ID is `lore-3613f`. Bundle ID will need updating in Firebase when app is renamed.
- **Browser audio duration**: Asset metadata can report wrong duration for browser-recorded audio streamed from R2. Player auto-corrects on first play.

## Running Locally

### Backend
```bash
cd backend && npm install && npx prisma migrate dev && npm run dev  # port 3000
```

### iOS
Open `VoiceJournal.xcodeproj` in Xcode → select device → Cmd+R

### Backend Dev Env Vars
```
PORT=3000  NODE_ENV=development  DATABASE_URL="file:./dev.db"
JWT_SECRET=<secret>  REFRESH_TOKEN_SECRET=<secret>
APP_URL=http://localhost:3000  WEB_APP_URL=http://localhost:3000
```

### Production Env Vars (Railway)
All existing vars plus:
- `FIREBASE_SERVICE_ACCOUNT` — Base64-encoded Firebase Admin SDK service account JSON (for push notifications)

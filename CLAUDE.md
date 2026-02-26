# VoiceJournal

## Overview
iOS app + Node.js backend for preserving family stories through voice recordings. Users create journals for loved ones, send thought-provoking questions, and receive audio recordings of their answers. Supports self-journaling (recording your own answers).

## Tech Stack
- **iOS**: Swift 5.9+, SwiftUI, iOS 17.0+, MVVM + Services layer
- **Backend**: Node.js/TypeScript, Express, PostgreSQL/Prisma ORM, JWT + Apple Sign-In
- **Storage**: Local filesystem (dev) / Cloudflare R2 (prod)
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

## Architecture & Conventions

### iOS
- ViewModels as `@StateObject`, `AppState` via `@EnvironmentObject`, services are plain classes
- `NavigationStack` + `.sheet()` / `.fullScreenCover()` for modals
- **Parent-handled actions**: Child views use `onMenuTapped` callback → parent shows `confirmationDialog`. Avoids SwiftUI Menu closure bug where button actions don't fire in child views.
- **Idempotency**: Recording uploads use UUID `Idempotency-Key` header to prevent duplicates
- **Self-journal detection**: `dedicatedToPerson.relationship == "self"` OR `linkedUserId == journal.owner.id`
- Questions sent via native iOS share sheet (`SharePresenter` wrapping `UIActivityViewController`), not email
- Contacts import uses `CNContactPickerViewController` with `CNContactStore` re-fetch for photo access

### Backend
- Express routes → services → Prisma ORM
- Separate routers: `/recordings` (authenticated) vs `/record` (public link-token) — avoids dynamic param collision
- `syncSelfPersonsWithUsers()` runs at startup (links self-persons, syncs profile photos)
- Cascade delete: deleting a person deletes their journals, questions, assignments, recordings
- Assignment remind has escalating cooldown: 1h → 24h → 72h

## Design System
- **Colors** (`AppColors`): accentPrimary (#FF6B35 orange), accentSecondary (#C47F17 gold), accentRecord (#8B5CF6 purple — used for self-recording buttons)
- **Typography** (`AppTypography`): Display 28-34pt, Headlines 18-22pt, Body 15-17pt, Labels 12-14pt
- **Background** (`AppBackground`): Full-screen image with atmospheric vignette gradients, light/dark variants
- **Glass system** (`GlassView.swift`):
  - `.glassCard()` for primary cards, `.glassCardSecondary()` for nested cards
  - `GlassIconCircle(icon:iconColor:)`, `GlassTextColors`, `GlassIconColors`
  - Light mode uses UIKit `TranslucentBlurView` because SwiftUI materials render opaque white
  - Icon colors: `.sendQuestion` (#FF7A2F), `.slate` (#5B6B9A)

## Current Status — What's TODO

### Next Priorities
- [ ] **Deploy Apple Sign-In to Railway** — Code complete on backend + iOS, needs: deploy migration, test on physical device, re-archive TestFlight build
- [ ] **Push notifications** — Backend push token endpoint exists, iOS Firebase FCM not implemented
- [ ] **Search** — No search in journals, people, or recordings lists
- [ ] **Voice note transcription** — Built-in transcription so users can read what a person said in their recording (Whisper API or similar)
- [ ] **Playback speed control** — Let users adjust playback speed (0.5x, 1x, 1.5x, 2x) when listening to recordings

### Later
- [ ] Add `ANTHROPIC_API_KEY` to Railway (for AI-suggested questions)
- [ ] SMS delivery (Twilio)
- [ ] Custom Resend email domain (currently test domain, can only send to verified addresses)
- [ ] Video recording (premium feature idea)

### Apple Sign-In Deployment Steps
1. Push backend to Railway (migration adds `appleUserId`, `authProvider`, makes `passwordHash` nullable)
2. `APPLE_CLIENT_ID=ARaja.VoiceJournal` already set in Railway
3. Add "Sign in with Apple" capability in Xcode Signing & Capabilities
4. Enable in Apple Developer portal for bundle ID
5. Test on physical iPhone (doesn't work on Simulator)
6. Re-archive + upload new TestFlight build

## Known Issues
- **Xcode build caching**: `rm -rf ~/Library/Developer/Xcode/DerivedData/VoiceJournal-*` if changes not picked up
- **Apple Sign-In on Simulator**: Always fails — requires physical device with signed-in Apple ID
- **Self-journal legacy data**: Old "myself" persons without `relationship="self"` or `linkedUserId` won't detect; delete and recreate through app
- **SwiftUI Menu closures**: Button actions don't fire in child views — use parent `confirmationDialog` pattern instead

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

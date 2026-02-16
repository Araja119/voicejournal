# VoiceJournal - Project Context Document

## Overview
VoiceJournal is an iOS app with a Node.js backend that helps families preserve meaningful stories and memories through voice recordings. Users create journals dedicated to loved ones, send them thought-provoking questions, and receive audio recordings of their answers.

## Tech Stack

### iOS Frontend
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Minimum iOS**: 17.0
- **Architecture**: MVVM with Services layer
- **Location**: `/ios/VoiceJournal/VoiceJournal/`

### Backend
- **Runtime**: Node.js with TypeScript
- **Framework**: Express.js
- **Database**: PostgreSQL with Prisma ORM (SQLite for local dev)
- **Authentication**: JWT (access + refresh tokens) + Apple Sign-In
- **File Storage**: Local filesystem (dev) / Cloudflare R2 (production)
- **Email**: Console mock (dev) / Resend (production)
- **Deployment**: Railway with Dockerfile
- **Location**: `/backend/`

## Project Structure

```
voicejournal/
├── ios/VoiceJournal/VoiceJournal/
│   ├── Core/
│   │   ├── Network/
│   │   │   ├── APIClient.swift        # HTTP client with auth, multipart uploads
│   │   │   ├── APIEndpoints.swift     # All API endpoint definitions
│   │   │   └── AuthManager.swift      # Token management
│   │   └── Theme/
│   │       ├── Colors.swift           # AppColors, light/dark mode
│   │       ├── Typography.swift       # AppTypography fonts
│   │       └── Theme.swift            # Spacing, radius constants
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Journal.swift              # Includes JournalPerson with isSelf detection
│   │   ├── Question.swift
│   │   ├── Person.swift
│   │   ├── Recording.swift
│   │   ├── Assignment.swift
│   │   └── RemindEligibility.swift    # Remind cooldown logic
│   ├── Services/
│   │   ├── AuthService.swift          # Includes appleSignIn() method
│   │   ├── AppleSignInManager.swift   # ASAuthorizationController async/await wrapper
│   │   ├── JournalService.swift
│   │   ├── QuestionService.swift
│   │   ├── PersonService.swift
│   │   ├── RecordingService.swift     # Includes authenticated upload
│   │   └── RemindCapTracker.swift     # Daily remind cap tracking
│   ├── ViewModels/
│   │   ├── JournalDetailViewModel.swift
│   │   ├── PeopleViewModel.swift      # Handles "myself" person detection
│   │   └── ActivityViewModel.swift    # In Progress data, carousel sentences, priority sorting
│   └── Views/
│       ├── Hub/
│       │   ├── HubView.swift          # Main home screen
│       │   ├── HubActionCard.swift    # Primary/secondary action cards
│       │   └── SecondaryActionRow.swift
│       ├── Journals/
│       │   ├── JournalsListView.swift
│       │   ├── JournalDetailView.swift # Journal timeline, self-recording
│       │   └── CreateJournalSheet.swift
│       ├── People/
│       │   ├── PeopleListView.swift   # MyselfCard + PersonCard
│       │   └── AddPersonSheet.swift
│       ├── Recordings/
│       │   ├── RecordingsListView.swift
│       │   ├── RecordingModal.swift   # 4-state recording UI
│       │   ├── RecordingPlayerView.swift # Full playback with controls
│       │   └── AudioRecorder.swift    # AVFoundation recording
│       ├── Questions/
│       │   └── SendQuestionSheet.swift # 3-step send wizard (person → journal → question)
│       ├── Components/
│       │   ├── AppBackground.swift    # Gradient vignette over image
│       │   ├── AvatarView.swift
│       │   ├── EmptyStateView.swift
│       │   ├── GlassView.swift        # Frosted glass card modifiers
│       │   └── LoadingView.swift
│       ├── Auth/
│       │   ├── LoginView.swift
│       │   └── SignupView.swift
│       └── Components/
│           └── AppleSignInButtonView.swift  # Custom Apple Sign-In button (Apple HIG)
│
└── backend/
    ├── Dockerfile                     # Multi-stage Alpine build for Railway
    ├── .dockerignore
    ├── railway.toml                   # Railway deployment config
    ├── src/
    │   ├── app.ts                     # Express app setup + web routes
    │   ├── routes/
    │   │   ├── auth.routes.ts
    │   │   ├── journals.routes.ts     # Includes authenticated recording upload
    │   │   ├── questions.routes.ts
    │   │   ├── people.routes.ts
    │   │   ├── recordings.routes.ts   # Exports router + recordPublicRouter
    │   │   ├── assignments.routes.ts  # Send, remind, delete assignments
    │   │   ├── web.routes.ts          # HTML recording page for recipients
    │   │   ├── templates.routes.ts
    │   │   ├── users.routes.ts
    │   │   ├── stats.routes.ts
    │   │   └── notifications.routes.ts
    │   ├── services/
    │   │   ├── auth.service.ts
    │   │   ├── users.service.ts       # syncSelfPersonsWithUsers() runs at startup
    │   │   ├── journals.service.ts    # Returns linkedUserId + recording links
    │   │   ├── questions.service.ts
    │   │   ├── assignments.service.ts # Send/remind with escalating cooldown
    │   │   ├── ai.service.ts          # Claude API for suggested questions
    │   │   ├── recordings.service.ts  # createAuthenticatedRecording()
    │   │   ├── storage.ts             # Provider router (local/R2)
    │   │   ├── r2-storage.ts          # Cloudflare R2 implementation
    │   │   ├── email.ts               # Provider router (mock/Resend)
    │   │   ├── resend-email.ts        # Resend email implementation
    │   │   ├── templates.service.ts
    │   │   ├── stats.service.ts
    │   │   └── notifications.service.ts
    │   ├── views/
    │   │   └── record-page.ts         # Server-rendered recording page HTML
    │   ├── validators/
    │   │   ├── people.validators.ts   # Includes "self" relationship type
    │   │   └── auth.validators.ts     # Login, signup, and Apple sign-in schemas
    │   └── middleware/
    │       └── authenticate.ts
    └── prisma/
        ├── schema.prisma              # PostgreSQL database schema
        └── migrations/                # Prisma migrations
```

## Key Features

### 1. Home Screen (HubView)
- Welcome header with user's name
- **Rotating carousel text**: Data-driven sentences that rotate every 9 seconds with soft 1.8s fade animation
  - Example sentences: "You're waiting on 2 people today.", "3 stories are waiting to be heard."
  - Categories: Data-driven (primary), Emotional truths (rare), Action bias (very rare)
- Primary action: "Send Question" (paperplane icon)
- **Hybrid "In Progress" panel** with two priority cards:
  - **Card 1 - Emotional anchor**: Person with oldest unanswered question (psychological weight)
  - **Card 2 - Momentum win**: Person with recent activity + high response rate (likely success)
  - Cards remain stable during navigation (cached until meaningful data change)
- Secondary actions: My People, Latest Recordings
- Custom background image with atmospheric vignette overlay
- Note: "New Journal" moved to structural surfaces (Journals list), not on home screen

### 2. Journals
- Create journals dedicated to specific people OR yourself (self-journaling)
- Each journal has a timeline of questions
- Questions have states: Draft → Awaiting → Answered
- Visual timeline with state-based styling (hollow dot for draft, filled for sent, checkmark for answered)
- **Self-journals**: When dedicated to "Myself", shows "Record Answer" button instead of "Send"
- **Edit journal**: Menu option to edit title and description
- **Journals list**: Collapsible person sections with profile photos, pin/star favorites

### 3. Questions
- Create questions manually or use AI-suggested questions
- AI suggestions powered by Claude API (personalized based on journal context)
- Edit and delete draft questions via action sheet
- Send questions to recipients via email with recording link

### 4. People
- Add family members/friends as "People"
- **"Myself" card** always appears at top of People list
- Associate people with journals
- Track their response status
- `linkedUserId` field links Person to User account for self-journaling

### 5. Recordings & Self-Recording
- Recipients record voice answers to questions
- **Self-recording flow**: Users can record answers to their own questions
- Recordings appear in timeline when answered
- Play button opens RecordingPlayerView with full playback controls
- **RecordingModal**: 4-state UI (idle → recording → review → uploading)
  - **Enhanced waveform visualizer**: 11 bars with spring animations, gradient opacity, multi-frequency waves
  - **Review screen**: Re-record and Replay buttons side by side, Save button centered below
  - **Replay functionality**: AVAudioPlayer-based playback with animated visualization
  - **Playback controls**: 10-second skip forward/backward buttons with current time display
- **AudioRecorder**: AVFoundation-based, 3-min max, real-time audio level metering
- **Recordings List View (RecordingsListView)**:
  - Collapsible person sections with avatars and recording counts
  - Quick-play functionality: tap play button for inline playback with progress ring
  - Tap card background opens full RecordingPlayerView
  - QuickPlayManager class handles AVPlayer with progress tracking

### 6. Profile Photos
- **User profile photo**: Set in ProfileEditView, stored in User record
- **Person profile photos**: Uploaded per-contact, stored in Person record
- **Automatic sync**: When user updates profile photo, it syncs to any linked Person records (e.g., "Myself" person)
- **Startup sync**: Backend runs `syncSelfPersonsWithUsers()` on startup to link "self" relationship persons and sync photos
- Profile photos display in:
  - Journals list (person sections)
  - Journal detail (assignments in awaiting/answered states)
  - Send Question sheet (person selection)
  - Recordings list (person sections and player)
  - People list (MyselfCard and PersonCard)

### 7. Web Recording Page
- Recipients receive email with link to `/record/{token}`
- Server-rendered HTML page (no SPA framework needed)
- Shows greeting, requester name, and question text
- MediaRecorder API for browser-based audio recording
- 4-state flow: Record → Review → Upload → Success
- Mobile-friendly responsive design with dark theme
- Already-answered detection shows confirmation page
- 404 page for invalid/expired tokens

## Self-Recording Feature (Detailed)

### How Self-Journal Detection Works
A journal is considered a "self-journal" when:
1. `dedicatedToPerson.relationship == "self"`, OR
2. User owns the journal AND `dedicatedToPerson.linkedUserId == journal.owner.id`

This two-pronged check handles both:
- Newly created "myself" persons with explicit "self" relationship
- Legacy persons that have `linkedUserId` but different relationship

### Recording Flow
1. User opens self-journal → `isSelfJournal` evaluates to true
2. Draft questions show "Record Answer" button (not "Send to [Name]")
3. Tap → Generate idempotency key → RecordingModal presented
4. User records (up to 3 min) → Review → Submit
5. iOS calls `uploadRecordingAuthenticated()` with idempotency key header
6. Backend validates ownership, creates assignment if needed, stores audio
7. Success → Modal dismisses → Journal refreshes → Question shows "Answered" with Play
8. Duplicate submit detected via idempotency key → Returns existing recording

### Playback Flow
1. User taps Play on answered question → "Answered" badge shown in green
2. RecordingPlayerView presented via fullScreenCover (item-based API for reliability)
3. Audio loads via signed `audioUrl` → AVPlayer streams
4. User can play/pause, skip ±15s
5. **UI**: AppBackground, prominent white question text in quotes, enhanced waveform visualization

## Home Screen Redesign (Retention-Focused)

### Design Philosophy
The home screen is designed as a "guilt + curiosity engine" that creates emotional pull to engage with the app daily. Every element surfaces meaningful loose ends that create psychological weight.

### Carousel Text System
- **Timer**: Rotates every 9 seconds with 1.8s ease-in-out fade animation
- **Sentence Categories**:
  1. **Data-driven (primary weight)**: "You're waiting on X people today", "X stories are waiting to be heard"
  2. **Emotional truths (rare)**: "Every question becomes a memory", "Some stories only they can tell"
  3. **Action bias (very rare)**: "Today is a good day to ask"
- **Implementation**: `ActivityViewModel.carouselText(at:)` and `nextCarouselIndex(current:)`
- **UI Stability**: Uses `.id(currentCarouselIndex)` with `.transition(.opacity)` for smooth text changes

### Hybrid In Progress Panel
Two cards optimized for different psychological triggers:

**Card 1 - Emotional Anchor (Oldest Unanswered)**
- Person with the oldest unanswered question
- Creates guilt/responsibility feeling
- Sorted by `oldestUnansweredDate` ascending

**Card 2 - Momentum Win (Recent + High Response Rate)**
- Person with recent activity AND good response history
- Creates "easy win" feeling to build momentum
- Sorted by `lastReplyDate` descending, filtered by response rate

### UI Stability Pattern
Cards remain stable during navigation to prevent jarring changes:
```swift
@State private var hasLoadedOnce = false
// Private cached cards only update on meaningful changes
private var loadedCardOne: InProgressItem?
private var loadedCardTwo: InProgressItem?
```

### ActivityViewModel Key Properties
- `inProgressItems: [InProgressItem]` - All people with pending questions
- `peopleOwingStoriesCount: Int` - Count for carousel sentences
- `totalUnansweredCount: Int` - Total pending questions
- `cardOneItem: InProgressItem?` - Cached emotional anchor card
- `cardTwoItem: InProgressItem?` - Cached momentum win card

## Design System

### Colors (AppColors)
- **Light Mode**: Warm neutrals, accentPrimary (#FF6B35 orange), accentSecondary (#C47F17 gold), accentRecord (#8B5CF6 purple)
- **Dark Mode**: Deep backgrounds, accentRecord (#7C3AED darker purple)
- **accentRecord**: Used for "Record Answer" buttons in self-journals (differentiates from orange "Send" buttons)
- Surface colors with varying opacity for cards

### Typography (AppTypography)
- Display: Large titles (28-34pt)
- Headlines: Section headers (18-22pt)
- Body: Content text (15-17pt)
- Labels/Captions: UI elements (12-14pt)

### Background (AppBackground)
- Full-screen image background (from asset catalog)
- Atmospheric vignette gradients:
  - Top: 8-13% opacity, warm gray/charcoal falloff
  - Bottom: 5-10% opacity, gradual fade
- Supports light/dark mode image variants

### Frosted Glass System (GlassView.swift)
The app uses a custom frosted glass system that provides true translucency with visible background bleed-through in both light and dark modes.

**Components:**
- `GlassCardModifier` - Primary cards with `.glassCard()` extension
- `GlassCardSecondaryModifier` - Nested/inner cards with `.glassCardSecondary()` extension
- `GlassIconCircle` - Frosted glass icon circles (48pt default)
- `GlassTextColors` - Consistent text colors for glass surfaces
- `GlassIconColors` - Predefined icon colors (sendQuestion orange, slate for others)
- `TranslucentBlurView` - UIKit wrapper for precise blur control

**Light Mode Implementation:**
The key insight is that SwiftUI's built-in materials (`.ultraThinMaterial`, etc.) render as opaque white in light mode. The solution uses UIKit's `UIVisualEffectView`:
```swift
// Light mode: UIKit blur + subtle white overlay
ZStack {
    TranslucentBlurView(style: .light, intensity: 0.38)
    RoundedRectangle(...).fill(Color.white.opacity(0.22))
}
```

**Text Colors (GlassTextColors):**
- Light mode: primary (black 0.82), secondary (0.55), tertiary (0.35), sectionLabel (0.65)
- Dark mode: primary (white), secondary (0.6), tertiary (0.4), sectionLabel (0.9)

**Icon Colors (GlassIconColors):**
- `sendQuestion`: #FF7A2F (orange)
- `slate`: #5B6B9A (muted indigo for People, Recordings icons)

**Usage:**
```swift
VStack { ... }
    .padding(Theme.Spacing.md)
    .glassCard(cornerRadius: 22)

GlassIconCircle(icon: "paperplane.fill", iconColor: GlassIconColors.sendQuestion)
```

## API Endpoints

Base URL (local): `http://localhost:3000/v1`
Base URL (production): `https://invigorating-amazement-production-81b6.up.railway.app/v1`

### Auth
- POST `/auth/signup` - Create account
- POST `/auth/login` - Login, returns tokens
- POST `/auth/refresh` - Refresh access token
- POST `/auth/logout` - Invalidate tokens
- POST `/auth/apple` - Apple Sign-In (verifies identity token, creates/links account)

### Journals
- GET `/journals` - List user's journals
- POST `/journals` - Create journal
- GET `/journals/:id` - Get journal with questions (includes `linked_user_id` in dedicated_to_person)
- PATCH `/journals/:id` - Update journal
- DELETE `/journals/:id` - Delete journal
- GET `/journals/:id/suggested-questions` - AI-generated questions
- **POST `/journals/:journal_id/questions/:question_id/recordings`** - Upload authenticated recording (self-recording)

### Questions
- POST `/journals/:id/questions` - Create question (with optional `assign_to_person_ids`)
- PATCH `/journals/:id/questions/:qid` - Update question
- DELETE `/journals/:id/questions/:qid` - Delete question

### Assignments
- POST `/assignments/:id/send` - Send assignment via email/SMS
- POST `/assignments/:id/remind` - Send reminder (escalating cooldown: 1h → 24h → 72h)
- DELETE `/assignments/:id` - Delete assignment

### People
- GET `/people` - List people
- POST `/people` - Create person (supports `linked_user_id` for self)
- PATCH `/people/:id` - Update person
- DELETE `/people/:id` - Delete person

### Recordings (Authenticated - `/recordings`)
- GET `/recordings` - List recordings
- GET `/recordings/:id` - Get single recording with signed audio URL
- DELETE `/recordings/:id` - Delete recording
- POST `/recordings/:id/transcribe` - Request transcription

### Public Recording (Unauthenticated - `/record`)
- GET `/record/:link_token` - Get recording page data for external recipients
- POST `/record/:link_token/upload` - Upload recording via link token

### Web Recording Page (HTML, not API)
- GET `/record/:link_token` - Serves full HTML recording page for recipients (browser)

## SwiftUI Patterns Used

### State Management
- `@StateObject` for view models
- `@State` for local UI state
- `@EnvironmentObject` for app-wide state (AppState)
- `@Environment(\.colorScheme)` for dark mode

### Navigation
- `NavigationStack` with `navigationDestination`
- `.sheet()` for modal presentations
- `.fullScreenCover()` for full-screen modals (RecordingModal, RecordingPlayerView)
- `.confirmationDialog()` for action sheets

### Key Pattern: Parent-Handled Actions
For child views with action menus (like QuestionTimelineCard):
- Child has simple `onMenuTapped: () -> Void` callback
- Parent sets state: `menuQuestion = question; showingQuestionMenu = true`
- Parent's `.confirmationDialog` handles the actual actions
- This avoids SwiftUI Menu closure issues in child views

### Key Pattern: Idempotency for Uploads
- Generate UUID when RecordingModal opens
- Pass as `Idempotency-Key` header
- Backend dedupes by (userId, questionId, idempotencyKey)
- Prevents duplicate recordings from double-taps or retries

## Current Implementation Status

### Completed
- [x] User authentication (signup, login, logout)
- [x] Journal CRUD operations
- [x] Question CRUD operations
- [x] People management
- [x] Recording listing and playback
- [x] AI-suggested questions (Claude API integration)
- [x] Home screen with activity section
- [x] Edit/Delete questions from timeline
- [x] Custom background with vignette
- [x] Dark/light mode support
- [x] "Myself" card in People list
- [x] Self-journal detection (relationship + linkedUserId)
- [x] Authenticated recording upload endpoint
- [x] RecordingModal with 4-state UI
- [x] RecordingPlayerView with playback controls
- [x] Idempotency support for uploads
- [x] Self-recording UI with "Record Answer" button
- [x] Purple accent color for recording actions
- [x] Enhanced RecordingModal with sleek waveform visualizer
- [x] Replay functionality in review screen
- [x] Audio playback working in RecordingPlayerView
- [x] RecordingPlayerView styled with AppBackground and prominent question text
- [x] "Answered" badge in green for visual satisfaction
- [x] Backend route separation (public `/record` vs authenticated `/recordings`)
- [x] Signed URL generation handles both keys and full URLs
- [x] 10-second skip controls during playback review in RecordingModal
- [x] Recordings list with collapsible person sections
- [x] Quick-play functionality in recordings list (inline AVPlayer)
- [x] Profile photo sync between User and Person records
- [x] Profile photos display across all views (journals, recordings, send question)
- [x] Edit journal title/description via menu
- [x] Draft badge removed from question timeline cards
- [x] Startup sync for self-persons (links and syncs profile photos)
- [x] Home screen redesign with retention-focused approach
- [x] Rotating carousel text with data-driven sentences (9s interval, 1.8s fade)
- [x] Hybrid In Progress panel (emotional anchor + momentum win cards)
- [x] Stable card caching to prevent UI glitches during navigation
- [x] "New Journal" moved from home screen to Journals list
- [x] Light mode frosted glass system (GlassView.swift)
- [x] True translucent cards with background bleed-through
- [x] GlassTextColors and GlassIconColors for consistent styling
- [x] UIKit TranslucentBlurView for precise blur control
- [x] Transcription display in RecordingPlayerView
- [x] Play button in timeline (fully functional end-to-end)
- [x] Microphone permission handling with Settings redirect
- [x] Re-record option in review screen
- [x] Apple Sign-In — full backend + iOS implementation, deployed to Railway
- [x] App icon (cloud/microphone design, purple/orange theme)
- [x] TestFlight build uploaded (1.0 build 3) to App Store Connect
- [x] Export compliance resolved for TestFlight
- [x] First-time user tutorial (4-step frosted glass overlay on HubView)
- [x] Tutorial resets on logout so new accounts see it again
- [x] "Add People" button in Send Question empty state
- [x] Privacy picker removed from journal creation (all journals default to private)
- [x] Home screen auto-refreshes activity after dismissing sheets
- [x] Cascade delete: deleting a person also deletes all their journals, questions, and recordings
- [x] Two-step delete confirmation for people (warns about cascade deletion)
- [x] Myself card tappable → opens Edit Profile (name, phone, photo)
- [x] Myself card persists after Cancel (synthetic person preserved across API reloads)
- [x] Profile photo/name changes sync to Myself card immediately via `refreshSyntheticMyself`
- [x] Send question fix: re-entry guard prevents duplicate questions, graceful handling when person has no email
- [x] ProfileEditView Cancel button added for sheet dismissal

### TODO - Feature Completion
- [x] "Send to [Name]" in timeline — wired to QuestionService.sendAssignment
- [x] "Remind" button — wired with escalating cooldown (1h → 24h → 72h)
- [x] Copy Link — copies recording link to clipboard with haptic feedback
- [x] Resend — resends assignment via email
- [x] **Delete recording from timeline** — Menu option with confirmation dialog, refreshes journal after deletion
- [x] **Account deletion** — DELETE `/users/me` endpoint + Settings UI with two-step confirmation
- [x] **Image compression** — `ImageUtils.compressForUpload()` helper, applied to all 4 upload sites
- [ ] **Push notifications** — Backend push token endpoint exists, iOS implementation missing (Firebase FCM)
- [ ] **Search** — No search in journals, people, or recordings lists

### TODO - Deployment (Phase 1 — Complete)
- [x] Backend Dockerfile + railway.toml for Railway deployment
- [x] PostgreSQL migration (baseline from SQLite)
- [x] Cloudflare R2 storage provider (`r2-storage.ts`)
- [x] Resend email provider (`resend-email.ts`)
- [x] Provider routing (`STORAGE_PROVIDER`, `EMAIL_PROVIDER` env vars)
- [x] **Deploy to Railway** — Backend deployed with PostgreSQL addon
- [x] **Configure R2 bucket** — Bucket `voicejournal` created, env vars set
- [x] **Configure Resend** — API key configured, EMAIL_PROVIDER=resend
- [x] **Update iOS APIClient base URL** to production (line 8 of APIEndpoints.swift)
- [x] **Apple Developer Account** — Approved and activated
- [x] **TestFlight build** — Version 1.0 (3) uploaded to App Store Connect
- [x] **App icon** — Generated 1024x1024 AppIcon.png (orange-to-coral gradient, microphone + "VJ")
- [x] **Export compliance** — Set to "None of the algorithms mentioned above" (standard HTTPS only)
- [ ] **Add ANTHROPIC_API_KEY** — For AI-suggested questions (optional, do later)
- [ ] **Deploy Apple Sign-In backend changes** — Migration + new route (see Apple Sign-In section below)

#### Railway Deployment Details
- **Project**: `invigorating-amazement`
- **Public URL**: `https://invigorating-amazement-production-81b6.up.railway.app`
- **Health check**: `https://invigorating-amazement-production-81b6.up.railway.app/health`
- **Region**: EU West (Amsterdam, Netherlands)
- **Database**: PostgreSQL (Railway addon, auto-configured DATABASE_URL)

**Configured env vars (all set):**
- `DATABASE_URL` — Auto-set by Railway PostgreSQL addon
- `NODE_ENV` — production
- `PORT` — Auto-set by Railway
- `JWT_SECRET` — Set
- `REFRESH_TOKEN_SECRET` — Set
- `JWT_EXPIRES_IN` — Set
- `REFRESH_TOKEN_EXPIRES_IN` — Set
- `EMAIL_FROM` — Set
- `APP_URL` — https://invigorating-amazement-production-81b6.up.railway.app
- `WEB_APP_URL` — https://invigorating-amazement-production-81b6.up.railway.app
- `STORAGE_PROVIDER` — r2
- `R2_ACCOUNT_ID` — Set
- `R2_ACCESS_KEY_ID` — Set
- `R2_SECRET_ACCESS_KEY` — Set
- `R2_BUCKET_NAME` — voicejournal
- `EMAIL_PROVIDER` — resend
- `RESEND_API_KEY` — Set

- `APPLE_CLIENT_ID` — ARaja.VoiceJournal

**Not yet configured:**
- `ANTHROPIC_API_KEY` — Needed for AI question suggestions (optional)

#### Cloudflare R2 Details
- **Bucket name**: `voicejournal`
- **Account**: Araja1685@gmail.com
- **API Token**: `voicejournal-backend` (Object Read & Write permissions)

#### Resend Email Limitations (Free Tier)
- Currently using Resend's test domain (`onboarding@resend.dev`)
- Can only send to **your own verified email addresses** on free tier
- To send to any email address: verify a custom domain in Resend dashboard
- When you have a domain, update `EMAIL_FROM` env var to `noreply@yourdomain.com`

#### App Store Connect Details
- **App Name**: VoiceJournal: Stories
- **Bundle ID**: ARaja.VoiceJournal
- **SKU**: VoiceJournal2026
- **Team**: Abdullah Raja (Apple Developer Program)
- **iPhone UDID**: 00008150-0018059A34C0401C (registered for development)
- **TestFlight builds uploaded**: 1.0 (1), 1.0 (2), 1.0 (3) — build 3 is latest
- **Note**: TestFlight build 1.0 (3) does NOT include Apple Sign-In (was uploaded before implementation)

#### TestFlight Process (Completed)
1. Signed with "Abdullah Raja" Developer Team (not Personal Team)
2. Registered iPhone UDID at developer.apple.com
3. Product → Archive → Distribute App → App Store Connect → Upload
4. App Store Connect → TestFlight → Manage Compliance → "None of the algorithms"
5. Add testers via TestFlight tab

### Apple Sign-In (Code Complete — Awaiting Deployment)
Full Apple Sign-In implementation is code-complete on both backend and iOS. Builds successfully but has NOT been deployed to Railway or tested on a physical device yet.

#### Backend Changes (Local, Not Deployed)
- **`prisma/schema.prisma`**: `passwordHash` now nullable (`String?`), added `appleUserId String? @unique`, added `authProvider String @default("email")`
- **`prisma/migrations/20260211000000_add_apple_signin_fields/migration.sql`**: Manual migration SQL (no local PostgreSQL)
- **`src/validators/auth.validators.ts`**: Added `appleSignInSchema` Zod schema
- **`src/services/auth.service.ts`**: Added `appleSignIn()` function with 3-step logic (lookup by appleUserId → lookup by email for account linking → create new user), uses `apple-signin-auth` package to verify Apple identity tokens
- **`src/routes/auth.routes.ts`**: Added `POST /auth/apple` route
- **Dependency**: `apple-signin-auth` npm package installed

#### iOS Changes (Built Successfully)
- **`Services/AppleSignInManager.swift`** (NEW): `@MainActor class` wrapping `ASAuthorizationController` with async/await via `CheckedContinuation`. Generates random nonce with SHA-256 hash for replay protection. Returns `AppleSignInResult` with identityToken, authorizationCode, userId, email, fullName.
- **`Views/Components/AppleSignInButtonView.swift`** (NEW): Custom styled button — white on dark, black on light (Apple HIG). Shows Apple logo + "Sign in with Apple" text, or ProgressView when loading.
- **`Core/Network/APIEndpoints.swift`**: Added `.appleSignIn` case → `/auth/apple`, POST, no auth required
- **`Services/AuthService.swift`**: Added `appleSignIn()` method sending identityToken, authorizationCode, appleUserId, email, fullName to backend
- **`ViewModels/AppState.swift`**: Added `signInWithApple()` method, stores `appleUserId` in UserDefaults, credential revocation check in `checkAuthState()` via `ASAuthorizationAppleIDProvider().credentialState()`
- **`ViewModels/AuthViewModel.swift`**: Added `isAppleSigningIn`, `appleSignInError` state, `signInWithApple(appState:)` method. Handles `ASAuthorizationError.canceled` silently.
- **`Views/Auth/LoginView.swift`**: Added "or" divider + AppleSignInButtonView after "Log In" button
- **`Views/Auth/SignupView.swift`**: Added "or" divider + AppleSignInButtonView after "Create Account" button
- **`Views/Onboarding/OnboardingView.swift`**: Added AppleSignInButtonView between "Create Account" and "Already have an account?"
- **`VoiceJournalApp.swift`**: Listens for `ASAuthorizationAppleIDProvider.credentialRevokedNotification` → auto logout

#### Key Design Decisions
- **Account linking**: If Apple email matches an existing email/password account, links them (`authProvider` → "both")
- **Apple-only users**: `passwordHash` is null; attempting email/password login returns a specific error
- **First vs subsequent sign-ins**: Apple only provides email/name on first authorization; backend uses `appleUserId` for lookup after that
- **Private relay email**: Stored as-is; works for sending emails
- **Credential revocation**: Detected via notification + credential state check → auto logout
- **AppleSignInManager is NOT an ObservableObject** — it's used as a one-shot async call from AuthViewModel (removed ObservableObject conformance to fix NSObject + @MainActor build error)

#### Deployment Steps Remaining
1. Push backend changes to git / deploy to Railway
2. Add `APPLE_CLIENT_ID=ARaja.VoiceJournal` env var to Railway
3. Add "Sign in with Apple" capability in Xcode Signing & Capabilities tab
4. Enable Sign in with Apple in Apple Developer portal for bundle ID `ARaja.VoiceJournal`
5. Run on physical iPhone to test (Apple Sign-In does NOT work on Simulator)
6. Re-archive and upload new TestFlight build with Apple Sign-In

#### Future: Google Sign-In
- Requires Google Cloud Console OAuth credentials
- Add `GOOGLE_CLIENT_ID` env var
- Backend verifies Google tokens
- Can coexist with email/password and Apple auth
- Deferred until after Apple Sign-In is tested

### First-Time Tutorial
- **File**: `Views/Tutorial/FirstTimeTutorialView.swift`
- 4-step full-screen overlay presented via `.fullScreenCover` on HubView
- Steps: Welcome → Add People → Send Question → Listen Back
- Uses frosted glass card (`.glassCard()`) with `GlassIconCircle`, `GlassTextColors`
- Dot indicators for progress, "Skip" button always visible
- State tracked via `AppState.hasSeenTutorial` (persisted in UserDefaults)
- Resets on logout so new accounts see the tutorial

### Person Deletion (Cascade)
- Deleting a person cascade-deletes ALL journals dedicated to that person (and their questions/assignments/recordings)
- Two-step confirmation dialog:
  1. First: "Delete [Name]? This will permanently delete them along with ALL of their journals, questions, and voice recordings."
  2. Second: "Are you absolutely sure? This cannot be undone."
- Backend: `people.service.ts` `deletePerson()` finds and deletes dedicated journals before deleting the person
- iOS: `EditPersonSheet.swift` uses `confirmationDialog` → `alert` two-step flow

### TODO - Core Loop (Phase 2 — Code Complete)
- [x] Web recording page for recipients (server-rendered HTML)
- [x] Email sending via Resend (with mock fallback for dev)
- [x] End-to-end "Send Question → Receive Recording" flow
- [x] Recording link in journal detail API response

### TODO - Polish (Phase 3)
- [ ] Push notifications (Firebase FCM)
- [ ] Transcription via Whisper API
- [ ] SMS delivery option (Twilio)

### Future Ideas / Monetization
- [ ] **Video Recording (Premium)**: Allow recipients to record video alongside audio when answering questions. Gate behind paywall as a premium feature. Adds visual element to preserved memories.

## Running the Project

### Backend
```bash
cd backend
npm install
npx prisma migrate dev  # Setup database
npm run dev             # Starts on port 3000
```

### iOS
1. Open `/ios/VoiceJournal/VoiceJournal.xcodeproj` in Xcode
2. Select iPhone simulator or physical device from the device selector (top center toolbar)
3. Build and run (Cmd+R)

#### Running on Physical iPhone
1. Connect iPhone via USB cable
2. In Xcode's main project window (not Organizer), click the device selector in the top center toolbar
3. Your iPhone should appear under "iOS Devices" — select it
4. Press Cmd+R to build and run
5. First time: iPhone will prompt to trust the developer certificate — go to Settings → General → VPN & Device Management → Trust
6. **Note**: Apple Sign-In only works on physical devices, not Simulator

### Environment Variables (Backend)
```
PORT=3000
NODE_ENV=development
DATABASE_URL="file:./dev.db"            # SQLite for local dev
# DATABASE_URL="postgresql://..."       # PostgreSQL for production (set by Railway)
JWT_SECRET=your-secret
REFRESH_TOKEN_SECRET=your-refresh-secret
ANTHROPIC_API_KEY=your-claude-api-key
APP_URL=http://localhost:3000
WEB_APP_URL=http://localhost:3000
# STORAGE_PROVIDER=r2                   # Unset = local filesystem mock
# EMAIL_PROVIDER=resend                 # Unset = console mock
```

## Known Issues & Workarounds

### SwiftUI Menu Closure Issue
**Problem**: Button actions inside `Menu` components don't fire when the Menu is in a child view and uses closures passed from parent.

**Solution**: Move action handling to parent view using `confirmationDialog` instead:
1. Child view calls `onMenuTapped()` when button pressed
2. Parent sets `menuQuestion` and `showingQuestionMenu = true`
3. Parent's `confirmationDialog` modifier handles Edit/Delete actions

### Build Caching
Sometimes Xcode doesn't pick up code changes. Fix:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/VoiceJournal-*
# Then rebuild in Xcode
```

### Self-Journal Detection for Legacy Data
If existing "myself" person records don't have `relationship = "self"` or `linkedUserId` set, they won't be detected as self-journals. Solutions:
1. Update person record manually in database
2. Delete and recreate the "myself" person through the app

### Apple Sign-In on Simulator
**Problem**: Tapping "Sign in with Apple" on the iOS Simulator shows "Apple Sign In failed".

**Expected behavior**: Apple Sign-In requires a real device with a signed-in Apple ID. It will never work on the Simulator. Always test on a physical iPhone.

### Express Route Ordering for Recordings
**Problem**: Public route `/:link_token` and authenticated `/:recording_id` both use dynamic params. Express matches routes in order, so the public route captured authenticated requests.

**Solution**: Use separate routers mounted at different paths:
- `router` (authenticated) → mounted at `/recordings`
- `publicRouter` → mounted at `/record`

This avoids parameter collision and keeps route concerns separated.

## Database Schema (Key Tables — PostgreSQL)

```prisma
model User {
  id            String    @id @default(uuid())
  email         String    @unique
  passwordHash  String?   // Nullable for Apple-only users
  displayName   String?
  appleUserId   String?   @unique  // Apple's stable user identifier
  authProvider  String    @default("email")  // "email", "apple", or "both"
  journals      Journal[]
  people        Person[]
}

model Journal {
  id              String     @id @default(uuid())
  title           String
  description     String?
  dedicatedToId   String?    // Person this journal is for
  dedicatedTo     Person?
  questions       Question[]
  userId          String
  user            User       @relation(...)
}

model Question {
  id           String       @id @default(uuid())
  questionText String
  displayOrder Int
  journalId    String
  journal      Journal      @relation(...)
  assignments  QuestionAssignment[]
}

model Person {
  id           String    @id @default(uuid())
  name         String
  relationship String    // "self" for myself
  email        String?
  phone        String?
  linkedUserId String?   // Links to User.id for self-journaling
  userId       String
  user         User      @relation(...)
}

model Recording {
  id             String    @id @default(uuid())
  audioFileUrl   String
  durationSeconds Int?
  transcript     String?
  personId       String?
  assignmentId   String
  idempotencyKey String?   // For upload deduplication
  recordedAt     DateTime
}

model QuestionAssignment {
  id              String    @id @default(uuid())
  questionId      String
  personId        String
  status          String    // pending, sent, viewed, answered
  uniqueLinkToken String    @unique @default(uuid())
  sentAt          DateTime?
  viewedAt        DateTime?
  answeredAt      DateTime?
  reminderCount   Int       @default(0)
  lastReminderAt  DateTime?
  recordings      Recording[]
}
```

## Contact & Repository
- Primary developer workspace: `/Users/ARaja/voicejournal/`
- iOS project: `/Users/ARaja/voicejournal/ios/VoiceJournal/`
- Backend: `/Users/ARaja/voicejournal/backend/`

---
*Last updated: February 16, 2026 — First-time tutorial added, cascade delete for people, Myself card tappable with profile edit, send question flow fixed, profile photo syncs to Myself card. Next priorities: account deletion (App Store requirement), image compression, push notifications.*

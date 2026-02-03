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
- **Database**: SQLite with Prisma ORM
- **Authentication**: JWT (access + refresh tokens)
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
│   │   └── Assignment.swift
│   ├── Services/
│   │   ├── AuthService.swift
│   │   ├── JournalService.swift
│   │   ├── QuestionService.swift
│   │   ├── PersonService.swift
│   │   └── RecordingService.swift     # Includes authenticated upload
│   ├── ViewModels/
│   │   ├── JournalDetailViewModel.swift
│   │   ├── PeopleViewModel.swift      # Handles "myself" person detection
│   │   └── ActivityViewModel.swift
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
│       ├── Components/
│       │   ├── AppBackground.swift    # Gradient vignette over image
│       │   ├── AvatarView.swift
│       │   ├── EmptyStateView.swift
│       │   └── LoadingView.swift
│       └── Auth/
│           ├── LoginView.swift
│           └── SignupView.swift
│
└── backend/
    ├── src/
    │   ├── app.ts                     # Express app setup
    │   ├── routes/
    │   │   ├── auth.routes.ts
    │   │   ├── journals.routes.ts     # Includes authenticated recording upload
    │   │   ├── questions.routes.ts
    │   │   ├── people.routes.ts
    │   │   └── recordings.routes.ts   # Exports router + recordPublicRouter
    │   ├── services/
    │   │   ├── auth.service.ts
    │   │   ├── journals.service.ts    # Returns linkedUserId for self-detection
    │   │   ├── questions.service.ts
    │   │   ├── ai.service.ts          # Claude API for suggested questions
    │   │   └── recordings.service.ts  # createAuthenticatedRecording()
    │   ├── validators/
    │   │   └── people.validators.ts   # Includes "self" relationship type
    │   └── middleware/
    │       └── authenticate.ts
    └── prisma/
        ├── schema.prisma              # Database schema with idempotencyKey
        └── dev.db                     # SQLite database file
```

## Key Features

### 1. Home Screen (HubView)
- Welcome header with rotating intent phrases
- Primary action: "Send Question"
- Secondary action: "New Journal"
- "In Progress" activity section showing:
  - Who you're waiting on for responses
  - Count of questions awaiting responses
  - Last reply info with relative time
- Tertiary actions: My People, Latest Recordings
- Custom background image with atmospheric vignette overlay

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
- Send questions to recipients (TODO)

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

## API Endpoints

Base URL: `http://localhost:3000/v1`

### Auth
- POST `/auth/signup` - Create account
- POST `/auth/login` - Login, returns tokens
- POST `/auth/refresh` - Refresh access token
- POST `/auth/logout` - Invalidate tokens

### Journals
- GET `/journals` - List user's journals
- POST `/journals` - Create journal
- GET `/journals/:id` - Get journal with questions (includes `linked_user_id` in dedicated_to_person)
- PATCH `/journals/:id` - Update journal
- DELETE `/journals/:id` - Delete journal
- GET `/journals/:id/suggested-questions` - AI-generated questions
- **POST `/journals/:journal_id/questions/:question_id/recordings`** - Upload authenticated recording (self-recording)

### Questions
- POST `/journals/:id/questions` - Create question
- PATCH `/journals/:id/questions/:qid` - Update question
- DELETE `/journals/:id/questions/:qid` - Delete question

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

### TODO
- [ ] "Send to [Name]" button flow - send questions to recipients
- [ ] "Remind" button for awaiting questions
- [ ] Copy Link functionality
- [ ] Resend functionality
- [ ] Transcription display in timeline
- [ ] Delete recording from timeline

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
2. Select iPhone simulator
3. Build and run (Cmd+R)

### Environment Variables (Backend)
```
PORT=3000
DATABASE_URL="file:./dev.db"
JWT_SECRET=your-secret
JWT_REFRESH_SECRET=your-refresh-secret
ANTHROPIC_API_KEY=your-claude-api-key  # For AI suggestions
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

### Express Route Ordering for Recordings
**Problem**: Public route `/:link_token` and authenticated `/:recording_id` both use dynamic params. Express matches routes in order, so the public route captured authenticated requests.

**Solution**: Use separate routers mounted at different paths:
- `router` (authenticated) → mounted at `/recordings`
- `publicRouter` → mounted at `/record`

This avoids parameter collision and keeps route concerns separated.

## Database Schema (Key Tables)

```prisma
model User {
  id            String    @id @default(uuid())
  email         String    @unique
  passwordHash  String
  displayName   String?
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
  id         String    @id @default(uuid())
  questionId String
  personId   String
  status     String    // pending, sent, viewed, answered
  recordings Recording[]
}
```

## Contact & Repository
- Primary developer workspace: `/Users/ARaja/voicejournal/`
- iOS project: `/Users/ARaja/voicejournal/ios/VoiceJournal/`
- Backend: `/Users/ARaja/voicejournal/backend/`

---
*Last updated: February 2026 - Profile photo sync, collapsible recordings list with quick-play, edit journal feature, profile photos across all views*

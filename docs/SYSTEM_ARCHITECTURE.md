# VoiceJournal - System Architecture Overview

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENTS                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────┐         ┌─────────────────┐                          │
│   │   iOS App       │         │  Web Recorder   │                          │
│   │   (Swift/       │         │  (Simple HTML   │                          │
│   │   SwiftUI)      │         │   + JS page)    │                          │
│   │                 │         │                 │                          │
│   │  • Create       │         │  • View         │                          │
│   │    journals     │         │    question     │                          │
│   │  • Add people   │         │  • Record       │                          │
│   │  • Send         │         │    audio        │                          │
│   │    questions    │         │  • Upload       │                          │
│   │  • Listen to    │         │    recording    │                          │
│   │    recordings   │         │                 │                          │
│   │  • Manage       │         │  No login       │                          │
│   │    account      │         │  required!      │                          │
│   └────────┬────────┘         └────────┬────────┘                          │
│            │                           │                                    │
└────────────┼───────────────────────────┼────────────────────────────────────┘
             │                           │
             │      HTTPS / REST API     │
             │                           │
┌────────────▼───────────────────────────▼────────────────────────────────────┐
│                              BACKEND                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────┐      │
│   │                      API Server (Node.js)                        │      │
│   │                                                                  │      │
│   │   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │      │
│   │   │    Auth      │  │   Journals   │  │  Questions   │         │      │
│   │   │   Routes     │  │    Routes    │  │    Routes    │         │      │
│   │   └──────────────┘  └──────────────┘  └──────────────┘         │      │
│   │                                                                  │      │
│   │   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │      │
│   │   │   People     │  │  Recordings  │  │ Notifications│         │      │
│   │   │   Routes     │  │    Routes    │  │    Routes    │         │      │
│   │   └──────────────┘  └──────────────┘  └──────────────┘         │      │
│   │                                                                  │      │
│   │   ┌──────────────────────────────────────────────────┐         │      │
│   │   │              Middleware Layer                     │         │      │
│   │   │  • Authentication (JWT)                          │         │      │
│   │   │  • Rate Limiting                                 │         │      │
│   │   │  • Request Validation                            │         │      │
│   │   │  • Error Handling                                │         │      │
│   │   └──────────────────────────────────────────────────┘         │      │
│   └─────────────────────────────────────────────────────────────────┘      │
│                                                                             │
│            │                    │                    │                      │
│            ▼                    ▼                    ▼                      │
│   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐           │
│   │   PostgreSQL    │  │  Cloud Storage  │  │  Notification   │           │
│   │   Database      │  │  (Audio Files)  │  │    Services     │           │
│   │                 │  │                 │  │                 │           │
│   │  • Users        │  │  • Recordings   │  │  • Push (APNs)  │           │
│   │  • Journals     │  │  • Profile pics │  │  • SMS (Twilio) │           │
│   │  • Questions    │  │  • Cover images │  │  • Email        │           │
│   │  • Recordings   │  │                 │  │                 │           │
│   │    (metadata)   │  │                 │  │                 │           │
│   └─────────────────┘  └─────────────────┘  └─────────────────┘           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

### iOS App
| Component | Technology | Why |
|-----------|------------|-----|
| Language | Swift 5.9+ | Modern, safe, Apple's primary language |
| UI Framework | SwiftUI | Declarative, modern, less code |
| Audio Recording | AVFoundation | Native iOS audio APIs |
| Networking | URLSession + async/await | Built-in, no dependencies |
| Local Storage | SwiftData | Modern persistence, syncs with CloudKit if needed |
| Push Notifications | APNs | Apple's push notification service |

### Web Recorder
| Component | Technology | Why |
|-----------|------------|-----|
| Framework | Vanilla HTML/CSS/JS | Simple, no build step, fast loading |
| Audio Recording | MediaRecorder API | Built into browsers |
| Styling | Tailwind CSS (CDN) | Quick styling, mobile-friendly |
| Hosting | Same server as API | Simplicity |

### Backend API
| Component | Technology | Why |
|-----------|------------|-----|
| Runtime | Node.js 20+ | JavaScript everywhere, huge ecosystem |
| Framework | Express.js or Fastify | Simple, well-documented |
| Language | TypeScript | Type safety, better DX |
| Authentication | JWT (jsonwebtoken) | Stateless, scalable |
| Validation | Zod | Runtime type checking |
| ORM | Prisma | Type-safe database access |

### Database
| Component | Technology | Why |
|-----------|------------|-----|
| Primary Database | PostgreSQL | Reliable, feature-rich, scalable |
| Hosting | Supabase, Railway, or AWS RDS | Managed, easy setup |

### File Storage
| Component | Technology | Why |
|-----------|------------|-----|
| Audio Storage | AWS S3 or Cloudflare R2 | Scalable, cheap, signed URLs |
| CDN | CloudFront or Cloudflare | Fast delivery |

### External Services
| Service | Provider | Purpose |
|---------|----------|---------|
| SMS | Twilio | Sending question links and reminders |
| Email | SendGrid or Resend | Email notifications |
| Push Notifications | Apple APNs | iOS push notifications |
| Transcription | OpenAI Whisper API | Audio-to-text (premium feature) |

---

## Data Flow Diagrams

### Flow 1: Creating a Journal and Sending a Question

```
┌──────────────┐                                              
│  User opens  │                                              
│   iOS app    │                                              
└──────┬───────┘                                              
       │                                                      
       ▼                                                      
┌──────────────┐     POST /journals                          
│  Creates new │ ─────────────────────────►  ┌─────────────┐
│   journal    │                             │   Backend   │
└──────┬───────┘     ◄─────────────────────  │   Server    │
       │             Journal created          └──────┬──────┘
       │                                            │
       ▼                                            ▼
┌──────────────┐                             ┌─────────────┐
│  Adds person │     POST /people            │  Database   │
│   "Mom"      │ ─────────────────────────►  │  (stores    │
└──────┬───────┘                             │   journal,  │
       │                                     │   person)   │
       ▼                                     └─────────────┘
┌──────────────┐     GET /templates?relationship=parent      
│  Selects     │ ─────────────────────────►                  
│  questions   │                                              
└──────┬───────┘     ◄───────────────────── Returns 45 parent
       │                                    questions         
       │                                                      
       ▼                                                      
┌──────────────┐     POST /journals/{id}/questions           
│  Adds        │ ─────────────────────────►                  
│  question    │                                              
└──────┬───────┘     ◄───────────────────── Question created 
       │                                    with assignment   
       │                                                      
       ▼                                                      
┌──────────────┐     POST /assignments/{id}/send             
│  Taps        │ ─────────────────────────►  ┌─────────────┐
│  "Send"      │                             │   Twilio    │
└──────────────┘                             │   (SMS)     │
                                             └──────┬──────┘
                                                    │
                                                    ▼
                                             ┌─────────────┐
                                             │  Mom gets   │
                                             │  SMS with   │
                                             │  link       │
                                             └─────────────┘
```

### Flow 2: Recording and Uploading a Response

```
┌──────────────┐                                              
│  Mom clicks  │                                              
│  link in SMS │                                              
└──────┬───────┘                                              
       │                                                      
       ▼                                                      
┌──────────────┐     GET /record/{token}                     
│ Web recorder │ ─────────────────────────►  ┌─────────────┐
│   page loads │                             │   Backend   │
└──────┬───────┘     ◄─────────────────────  │   Server    │
       │             Returns question text    └─────────────┘
       │             and context                              
       ▼                                                      
┌──────────────┐                                              
│  Page shows: │                                              
│  "John would │                                              
│  like to ask │                                              
│  you..."     │                                              
└──────┬───────┘                                              
       │                                                      
       ▼                                                      
┌──────────────┐                                              
│  Mom taps    │                              ┌─────────────┐
│  record,     │    Browser MediaRecorder     │   Browser   │
│  speaks      │ ◄──────────────────────────► │   Audio     │
└──────┬───────┘    Records audio locally     │   Buffer    │
       │                                      └─────────────┘
       ▼                                                      
┌──────────────┐                                              
│  Mom taps    │                                              
│  "Play" to   │                                              
│  review      │                                              
└──────┬───────┘                                              
       │  Happy with recording                                
       ▼                                                      
┌──────────────┐     POST /record/{token}/upload             
│  Mom taps    │ ─────────────────────────►  ┌─────────────┐
│  "Submit"    │     (audio file attached)   │   Backend   │
└──────────────┘                             │   Server    │
                                             └──────┬──────┘
                                                    │
                    ┌───────────────────────────────┼───────┐
                    │                               │       │
                    ▼                               ▼       │
             ┌─────────────┐              ┌─────────────┐   │
             │   Cloud     │              │  Database   │   │
             │   Storage   │              │  (update    │   │
             │  (S3/R2)    │              │  assignment │   │
             │             │              │  status)    │   │
             │  Audio file │              └─────────────┘   │
             │  stored     │                               │
             └─────────────┘                               │
                                                          │
                    ┌─────────────────────────────────────┘
                    │
                    ▼
             ┌─────────────┐              ┌─────────────┐
             │    APNs     │ ────────────►│  John's     │
             │   (Push     │   Push       │  iPhone     │
             │notification)│   sent       │             │
             └─────────────┘              └─────────────┘
```

---

## Database Schema (PostgreSQL)

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    display_name VARCHAR(100) NOT NULL,
    profile_photo_url TEXT,
    subscription_tier VARCHAR(20) DEFAULT 'free',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Journals table
CREATE TABLE journals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    cover_image_url TEXT,
    privacy_setting VARCHAR(20) DEFAULT 'private',
    share_code VARCHAR(50) UNIQUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Journal collaborators
CREATE TABLE journal_collaborators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journal_id UUID REFERENCES journals(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    email VARCHAR(255),
    phone_number VARCHAR(20),
    permission_level VARCHAR(20) DEFAULT 'view',
    invited_at TIMESTAMP DEFAULT NOW(),
    accepted_at TIMESTAMP
);

-- People (interview subjects)
CREATE TABLE people (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    relationship VARCHAR(50) NOT NULL,
    email VARCHAR(255),
    phone_number VARCHAR(20),
    profile_photo_url TEXT,
    linked_user_id UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Question templates
CREATE TABLE question_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    relationship_type VARCHAR(50) NOT NULL,
    question_text TEXT NOT NULL,
    category VARCHAR(50),
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true
);

-- Questions in journals
CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journal_id UUID REFERENCES journals(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    source VARCHAR(20) DEFAULT 'custom',
    template_id UUID REFERENCES question_templates(id),
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Question assignments
CREATE TABLE question_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID REFERENCES questions(id) ON DELETE CASCADE,
    person_id UUID REFERENCES people(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending',
    unique_link_token VARCHAR(100) UNIQUE NOT NULL,
    sent_at TIMESTAMP,
    viewed_at TIMESTAMP,
    answered_at TIMESTAMP,
    reminder_count INT DEFAULT 0,
    last_reminder_at TIMESTAMP
);

-- Recordings
CREATE TABLE recordings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID REFERENCES question_assignments(id) ON DELETE CASCADE,
    person_id UUID REFERENCES people(id),
    audio_file_url TEXT NOT NULL,
    duration_seconds INT,
    file_size_bytes BIGINT,
    transcription TEXT,
    recorded_at TIMESTAMP,
    uploaded_at TIMESTAMP DEFAULT NOW()
);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL,
    channel VARCHAR(20),
    title VARCHAR(200),
    body TEXT,
    related_assignment_id UUID REFERENCES question_assignments(id),
    related_recording_id UUID REFERENCES recordings(id),
    sent_at TIMESTAMP DEFAULT NOW(),
    read_at TIMESTAMP
);

-- Push tokens for notifications
CREATE TABLE push_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_journals_owner ON journals(owner_id);
CREATE INDEX idx_people_owner ON people(owner_id);
CREATE INDEX idx_questions_journal ON questions(journal_id);
CREATE INDEX idx_assignments_question ON question_assignments(question_id);
CREATE INDEX idx_assignments_person ON question_assignments(person_id);
CREATE INDEX idx_assignments_token ON question_assignments(unique_link_token);
CREATE INDEX idx_recordings_assignment ON recordings(assignment_id);
CREATE INDEX idx_notifications_user ON notifications(recipient_user_id);
CREATE INDEX idx_templates_relationship ON question_templates(relationship_type);
```

---

## Security Considerations

### Authentication
- JWT tokens with short expiry (15 minutes)
- Refresh tokens stored securely, rotated on use
- Passwords hashed with bcrypt (cost factor 12)
- Rate limiting on auth endpoints

### Authorization
- Users can only access their own journals, people, recordings
- Collaborators have limited access based on permission_level
- Recording upload only via valid, unused link tokens

### Data Protection
- Audio files stored encrypted at rest
- Signed URLs for audio access (expire in 1 hour)
- HTTPS everywhere
- Phone numbers and emails never exposed to other users

### Link Security
- Link tokens are 32 random characters (UUID + random bytes)
- Links can only be used once for upload
- Links expire after 30 days if unused

---

## Scalability Path

### Phase 1 (MVP)
- Single server, single database
- Handle ~1,000 users
- Storage: ~100GB

### Phase 2 (Growth)
- Add read replicas for database
- CDN for audio delivery
- Background job queue (BullMQ) for transcription
- Handle ~10,000 users

### Phase 3 (Scale)
- Microservices split (auth, recordings, notifications)
- Database sharding by user
- Global CDN
- Handle ~100,000+ users

---

## Folder Structure

```
voicejournal/
├── docs/                       # Documentation (you are here)
│   ├── DATA_ARCHITECTURE.md
│   ├── API_ENDPOINTS.md
│   ├── QUESTION_TEMPLATES.md
│   └── SYSTEM_ARCHITECTURE.md
│
├── backend/                    # Node.js API server
│   ├── src/
│   │   ├── routes/
│   │   ├── controllers/
│   │   ├── services/
│   │   ├── models/
│   │   ├── middleware/
│   │   └── utils/
│   ├── prisma/
│   │   └── schema.prisma
│   ├── package.json
│   └── tsconfig.json
│
├── web-recorder/               # Simple recording page
│   ├── index.html
│   ├── styles.css
│   └── recorder.js
│
└── ios/                        # iOS app (Xcode project)
    └── VoiceJournal/
        ├── VoiceJournalApp.swift
        ├── Models/
        ├── Views/
        ├── ViewModels/
        └── Services/
```

---

## Next Steps

**Phase 1 Complete ✓**
- Data architecture defined
- API endpoints specified
- Question templates created
- System architecture documented

**Phase 2: Build the Backend**
- Set up Node.js project with TypeScript
- Implement Prisma schema
- Build all API endpoints
- Set up PostgreSQL database
- Integrate Twilio for SMS
- Set up file storage

**Phase 3: Build the Web Recorder**
- Create simple recording page
- Implement audio capture
- Build upload flow

**Phase 4: Build the iOS App**
- Set up Xcode project
- Build authentication flow
- Build journal management
- Build recording playback
- Integrate push notifications

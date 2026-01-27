# VoiceJournal - API Endpoints Specification

## Overview

This document defines every API endpoint the app needs. The backend will implement these endpoints, and both the iOS app and web recorder will call them.

**Base URL:** `https://api.voicejournal.app/v1`

---

## Authentication Endpoints

### POST `/auth/signup`
Create a new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securepassword",
  "display_name": "John Doe",
  "phone_number": "+15551234567"  // optional
}
```

**Response (201 Created):**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "display_name": "John Doe",
    "subscription_tier": "free",
    "created_at": "2024-01-15T10:30:00Z"
  },
  "access_token": "jwt_token_here",
  "refresh_token": "refresh_token_here"
}
```

---

### POST `/auth/login`
Log in to existing account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response (200 OK):**
```json
{
  "user": { ... },
  "access_token": "jwt_token_here",
  "refresh_token": "refresh_token_here"
}
```

---

### POST `/auth/refresh`
Get a new access token using refresh token.

**Request:**
```json
{
  "refresh_token": "refresh_token_here"
}
```

**Response (200 OK):**
```json
{
  "access_token": "new_jwt_token_here"
}
```

---

### POST `/auth/logout`
Invalidate current session.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "message": "Logged out successfully"
}
```

---

### POST `/auth/forgot-password`
Request password reset email.

**Request:**
```json
{
  "email": "user@example.com"
}
```

**Response (200 OK):**
```json
{
  "message": "If an account exists, a reset link has been sent"
}
```

---

### POST `/auth/reset-password`
Reset password with token from email.

**Request:**
```json
{
  "token": "reset_token_from_email",
  "new_password": "newsecurepassword"
}
```

**Response (200 OK):**
```json
{
  "message": "Password reset successfully"
}
```

---

## User Endpoints

### GET `/users/me`
Get current user's profile.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "display_name": "John Doe",
  "phone_number": "+15551234567",
  "profile_photo_url": "https://...",
  "subscription_tier": "free",
  "created_at": "2024-01-15T10:30:00Z"
}
```

---

### PATCH `/users/me`
Update current user's profile.

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
  "display_name": "Johnny Doe",
  "phone_number": "+15559876543"
}
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "display_name": "Johnny Doe",
  ...
}
```

---

### POST `/users/me/profile-photo`
Upload profile photo.

**Headers:** `Authorization: Bearer {access_token}`
**Content-Type:** `multipart/form-data`

**Request:** Form data with `photo` field containing image file

**Response (200 OK):**
```json
{
  "profile_photo_url": "https://storage.voicejournal.app/profiles/uuid.jpg"
}
```

---

## Journal Endpoints

### GET `/journals`
Get all journals owned by or shared with current user.

**Headers:** `Authorization: Bearer {access_token}`

**Query Parameters:**
- `owned` (boolean): Only show journals I created
- `shared` (boolean): Only show journals shared with me

**Response (200 OK):**
```json
{
  "journals": [
    {
      "id": "uuid",
      "title": "Mom's Life Story",
      "description": "Recording mom's memories",
      "cover_image_url": "https://...",
      "privacy_setting": "private",
      "owner": {
        "id": "uuid",
        "display_name": "John Doe"
      },
      "is_owner": true,
      "question_count": 15,
      "answered_count": 8,
      "person_count": 1,
      "created_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

---

### POST `/journals`
Create a new journal.

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
  "title": "Mom's Life Story",
  "description": "Recording mom's memories for future generations",
  "privacy_setting": "private"
}
```

**Response (201 Created):**
```json
{
  "id": "uuid",
  "title": "Mom's Life Story",
  "description": "Recording mom's memories for future generations",
  "privacy_setting": "private",
  "share_code": "abc123xyz",
  "share_link": "https://voicejournal.app/j/abc123xyz",
  "created_at": "2024-01-15T10:30:00Z"
}
```

---

### GET `/journals/{journal_id}`
Get a specific journal with all its questions and people.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "id": "uuid",
  "title": "Mom's Life Story",
  "description": "...",
  "privacy_setting": "private",
  "share_code": "abc123xyz",
  "share_link": "https://voicejournal.app/j/abc123xyz",
  "owner": {
    "id": "uuid",
    "display_name": "John Doe"
  },
  "is_owner": true,
  "people": [
    {
      "id": "uuid",
      "name": "Mom",
      "relationship": "parent",
      "profile_photo_url": "https://..."
    }
  ],
  "questions": [
    {
      "id": "uuid",
      "question_text": "What's your earliest memory?",
      "source": "template",
      "display_order": 1,
      "assignments": [
        {
          "id": "uuid",
          "person_id": "uuid",
          "person_name": "Mom",
          "status": "answered",
          "recording": {
            "id": "uuid",
            "duration_seconds": 145,
            "recorded_at": "2024-01-16T14:20:00Z"
          }
        }
      ]
    }
  ],
  "created_at": "2024-01-15T10:30:00Z"
}
```

---

### PATCH `/journals/{journal_id}`
Update a journal.

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
  "title": "Mom's Complete Life Story",
  "privacy_setting": "shared"
}
```

**Response (200 OK):** Updated journal object

---

### DELETE `/journals/{journal_id}`
Delete a journal and all its content.

**Headers:** `Authorization: Bearer {access_token}`

**Response (204 No Content)**

---

### POST `/journals/{journal_id}/cover-image`
Upload journal cover image.

**Headers:** `Authorization: Bearer {access_token}`
**Content-Type:** `multipart/form-data`

**Response (200 OK):**
```json
{
  "cover_image_url": "https://storage.voicejournal.app/covers/uuid.jpg"
}
```

---

## Journal Sharing Endpoints

### GET `/journals/{journal_id}/collaborators`
Get all people who have access to this journal.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "collaborators": [
    {
      "id": "uuid",
      "user": {
        "id": "uuid",
        "display_name": "Jane Doe",
        "email": "jane@example.com"
      },
      "permission_level": "view",
      "invited_at": "2024-01-15T10:30:00Z",
      "accepted_at": "2024-01-15T11:00:00Z"
    }
  ]
}
```

---

### POST `/journals/{journal_id}/collaborators`
Invite someone to access this journal.

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
  "email": "jane@example.com",  // or phone_number
  "permission_level": "view"
}
```

**Response (201 Created):**
```json
{
  "id": "uuid",
  "email": "jane@example.com",
  "permission_level": "view",
  "invited_at": "2024-01-15T10:30:00Z"
}
```

---

### DELETE `/journals/{journal_id}/collaborators/{collaborator_id}`
Remove someone's access to journal.

**Headers:** `Authorization: Bearer {access_token}`

**Response (204 No Content)**

---

### GET `/journals/shared/{share_code}`
Access a journal via share code (for recipients).

**Headers:** `Authorization: Bearer {access_token}` (optional - can be anonymous for public journals)

**Response (200 OK):** Journal object (with limited info for non-collaborators)

---

## Person Endpoints

### GET `/people`
Get all people the current user has added.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "people": [
    {
      "id": "uuid",
      "name": "Mom",
      "relationship": "parent",
      "email": "mom@example.com",
      "phone_number": "+15551234567",
      "profile_photo_url": "https://...",
      "total_recordings": 12,
      "pending_questions": 3,
      "created_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

---

### POST `/people`
Add a new person.

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
  "name": "Mom",
  "relationship": "parent",
  "email": "mom@example.com",
  "phone_number": "+15551234567"
}
```

**Response (201 Created):**
```json
{
  "id": "uuid",
  "name": "Mom",
  "relationship": "parent",
  ...
}
```

---

### GET `/people/{person_id}`
Get details about a specific person including all their recordings.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "id": "uuid",
  "name": "Mom",
  "relationship": "parent",
  "email": "mom@example.com",
  "phone_number": "+15551234567",
  "recordings": [
    {
      "id": "uuid",
      "question": {
        "id": "uuid",
        "question_text": "What's your earliest memory?"
      },
      "journal": {
        "id": "uuid",
        "title": "Mom's Life Story"
      },
      "duration_seconds": 145,
      "recorded_at": "2024-01-16T14:20:00Z"
    }
  ],
  "pending_assignments": [
    {
      "id": "uuid",
      "question": {
        "id": "uuid",
        "question_text": "What was school like for you?"
      },
      "status": "sent",
      "sent_at": "2024-01-17T09:00:00Z"
    }
  ]
}
```

---

### PATCH `/people/{person_id}`
Update a person's details.

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
  "name": "Momma",
  "email": "newemail@example.com"
}
```

**Response (200 OK):** Updated person object

---

### DELETE `/people/{person_id}`
Delete a person (does not delete their recordings).

**Headers:** `Authorization: Bearer {access_token}`

**Response (204 No Content)**

---

### POST `/people/{person_id}/photo`
Upload person's photo.

**Headers:** `Authorization: Bearer {access_token}`
**Content-Type:** `multipart/form-data`

**Response (200 OK):**
```json
{
  "profile_photo_url": "https://..."
}
```

---

## Question Template Endpoints

### GET `/templates`
Get all question templates, optionally filtered by relationship.

**Query Parameters:**
- `relationship` (string): Filter by relationship type
- `category` (string): Filter by category

**Response (200 OK):**
```json
{
  "templates": [
    {
      "id": "uuid",
      "relationship_type": "parent",
      "question_text": "What's your earliest memory?",
      "category": "childhood",
      "display_order": 1
    }
  ]
}
```

---

### GET `/templates/relationships`
Get list of all relationship types.

**Response (200 OK):**
```json
{
  "relationships": [
    {
      "type": "parent",
      "display_name": "Parent",
      "question_count": 45
    },
    {
      "type": "grandparent",
      "display_name": "Grandparent",
      "question_count": 30
    }
  ]
}
```

---

## Question Endpoints

### POST `/journals/{journal_id}/questions`
Add a question to a journal.

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
  "question_text": "What's your earliest memory?",
  "template_id": "uuid",  // optional, if from template
  "assign_to_person_ids": ["uuid", "uuid"]  // optional, assign immediately
}
```

**Response (201 Created):**
```json
{
  "id": "uuid",
  "question_text": "What's your earliest memory?",
  "source": "template",
  "display_order": 1,
  "assignments": [
    {
      "id": "uuid",
      "person_id": "uuid",
      "status": "pending"
    }
  ]
}
```

---

### POST `/journals/{journal_id}/questions/bulk`
Add multiple questions at once.

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
  "questions": [
    {
      "question_text": "What's your earliest memory?",
      "template_id": "uuid"
    },
    {
      "question_text": "What was your childhood home like?",
      "template_id": "uuid"
    }
  ],
  "assign_to_person_ids": ["uuid"]
}
```

**Response (201 Created):**
```json
{
  "questions": [ ... ]
}
```

---

### PATCH `/journals/{journal_id}/questions/{question_id}`
Update a question.

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
  "question_text": "Updated question text?",
  "display_order": 5
}
```

**Response (200 OK):** Updated question object

---

### DELETE `/journals/{journal_id}/questions/{question_id}`
Delete a question.

**Headers:** `Authorization: Bearer {access_token}`

**Response (204 No Content)**

---

### PATCH `/journals/{journal_id}/questions/reorder`
Reorder questions in a journal.

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
  "question_ids": ["uuid", "uuid", "uuid"]  // in desired order
}
```

**Response (200 OK):**
```json
{
  "message": "Questions reordered successfully"
}
```

---

## Question Assignment Endpoints

### POST `/questions/{question_id}/assign`
Assign a question to one or more people.

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
  "person_ids": ["uuid", "uuid"]
}
```

**Response (201 Created):**
```json
{
  "assignments": [
    {
      "id": "uuid",
      "question_id": "uuid",
      "person_id": "uuid",
      "status": "pending",
      "unique_link_token": "abc123xyz789",
      "recording_link": "https://voicejournal.app/record/abc123xyz789"
    }
  ]
}
```

---

### POST `/assignments/{assignment_id}/send`
Send the question to the person (via SMS or email).

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
  "channel": "sms"  // or "email"
}
```

**Response (200 OK):**
```json
{
  "message": "Question sent successfully",
  "sent_via": "sms",
  "sent_at": "2024-01-17T09:00:00Z"
}
```

---

### POST `/assignments/{assignment_id}/remind`
Send a reminder for a pending question.

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
  "channel": "sms"
}
```

**Response (200 OK):**
```json
{
  "message": "Reminder sent",
  "reminder_count": 2
}
```

---

### DELETE `/assignments/{assignment_id}`
Cancel/delete a question assignment.

**Headers:** `Authorization: Bearer {access_token}`

**Response (204 No Content)**

---

## Recording Endpoints (Web Recorder - Public)

### GET `/record/{link_token}`
Get question details for recording (called by web recorder page).

**No authentication required**

**Response (200 OK):**
```json
{
  "assignment_id": "uuid",
  "question_text": "What's your earliest memory?",
  "person_name": "Mom",
  "requester_name": "John",
  "journal_title": "Mom's Life Story",
  "status": "sent",
  "already_answered": false
}
```

---

### POST `/record/{link_token}/upload`
Upload a recording for this assignment.

**No authentication required**
**Content-Type:** `multipart/form-data`

**Request:** Form data with `audio` field containing audio file

**Response (201 Created):**
```json
{
  "message": "Recording uploaded successfully",
  "recording_id": "uuid",
  "duration_seconds": 145
}
```

---

## Recording Endpoints (Authenticated)

### GET `/recordings`
Get all recordings across all journals.

**Headers:** `Authorization: Bearer {access_token}`

**Query Parameters:**
- `journal_id` (uuid): Filter by journal
- `person_id` (uuid): Filter by person
- `limit` (int): Pagination
- `offset` (int): Pagination

**Response (200 OK):**
```json
{
  "recordings": [
    {
      "id": "uuid",
      "question": {
        "id": "uuid",
        "question_text": "What's your earliest memory?"
      },
      "person": {
        "id": "uuid",
        "name": "Mom"
      },
      "journal": {
        "id": "uuid",
        "title": "Mom's Life Story"
      },
      "audio_url": "https://...",  // signed URL, expires
      "duration_seconds": 145,
      "transcription": "Well, I remember when I was about 4...",
      "recorded_at": "2024-01-16T14:20:00Z"
    }
  ],
  "total": 25,
  "limit": 10,
  "offset": 0
}
```

---

### GET `/recordings/{recording_id}`
Get a specific recording with audio URL.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "id": "uuid",
  "audio_url": "https://...",  // signed URL
  "duration_seconds": 145,
  "transcription": "...",
  "question": { ... },
  "person": { ... },
  "recorded_at": "2024-01-16T14:20:00Z"
}
```

---

### DELETE `/recordings/{recording_id}`
Delete a recording.

**Headers:** `Authorization: Bearer {access_token}`

**Response (204 No Content)**

---

### POST `/recordings/{recording_id}/transcribe`
Request transcription of a recording (premium feature).

**Headers:** `Authorization: Bearer {access_token}`

**Response (202 Accepted):**
```json
{
  "message": "Transcription started",
  "estimated_time_seconds": 30
}
```

---

## Notification Endpoints

### GET `/notifications`
Get user's notifications.

**Headers:** `Authorization: Bearer {access_token}`

**Query Parameters:**
- `unread_only` (boolean)
- `limit` (int)

**Response (200 OK):**
```json
{
  "notifications": [
    {
      "id": "uuid",
      "type": "recording_received",
      "title": "New recording from Mom",
      "body": "Mom answered: What's your earliest memory?",
      "related_recording_id": "uuid",
      "related_journal_id": "uuid",
      "read": false,
      "sent_at": "2024-01-16T14:25:00Z"
    }
  ],
  "unread_count": 3
}
```

---

### PATCH `/notifications/{notification_id}/read`
Mark notification as read.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "message": "Marked as read"
}
```

---

### POST `/notifications/read-all`
Mark all notifications as read.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "message": "All notifications marked as read"
}
```

---

### POST `/users/me/push-token`
Register device for push notifications.

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
  "token": "apns_device_token_here",
  "platform": "ios"
}
```

**Response (200 OK):**
```json
{
  "message": "Push token registered"
}
```

---

## Statistics Endpoints

### GET `/stats/dashboard`
Get overview statistics for user's dashboard.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "total_journals": 3,
  "total_recordings": 47,
  "total_recording_minutes": 127,
  "total_people": 5,
  "pending_questions": 12,
  "recent_activity": [
    {
      "type": "recording_received",
      "description": "Mom answered a question",
      "timestamp": "2024-01-16T14:25:00Z"
    }
  ]
}
```

---

## Error Response Format

All errors follow this format:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is required",
    "details": {
      "field": "email"
    }
  }
}
```

**Common Error Codes:**
- `VALIDATION_ERROR` (400)
- `UNAUTHORIZED` (401)
- `FORBIDDEN` (403)
- `NOT_FOUND` (404)
- `CONFLICT` (409) - e.g., email already exists
- `RATE_LIMITED` (429)
- `INTERNAL_ERROR` (500)

---

## Rate Limits

- Authentication endpoints: 10 requests/minute
- General API: 100 requests/minute
- File uploads: 20 requests/minute
- Send/remind endpoints: 30 requests/hour

---

## Pagination

List endpoints support pagination:

```
GET /recordings?limit=20&offset=40
```

Response includes:
```json
{
  "data": [...],
  "total": 150,
  "limit": 20,
  "offset": 40
}
```

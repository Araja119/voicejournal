# VoiceJournal - Data Architecture

## Overview

This document defines every piece of data the app stores and how they relate to each other. Think of this as the blueprint for the entire application.

---

## Core Entities

### 1. USER
The person who downloads the app and creates journals.

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| email | String | Login email |
| password_hash | String | Encrypted password |
| phone_number | String | Optional, for SMS features |
| display_name | String | How their name appears |
| profile_photo_url | String | Optional avatar |
| subscription_tier | Enum | "free" or "premium" |
| created_at | Timestamp | When they signed up |
| updated_at | Timestamp | Last profile update |

---

### 2. JOURNAL
A collection of questions for one or more people. Examples: "Mom's Life Story", "Wedding Memories", "Grandpa's War Stories"

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| owner_id | UUID | The user who created this journal (foreign key → USER) |
| title | String | Name of the journal |
| description | String | Optional description |
| cover_image_url | String | Optional cover photo |
| privacy_setting | Enum | "private", "public", or "shared" |
| share_code | String | Unique code for shared access (e.g., "abc123") |
| share_link | String | Full URL for sharing |
| created_at | Timestamp | When created |
| updated_at | Timestamp | Last modified |

---

### 3. JOURNAL_COLLABORATOR
People who have been granted access to view a shared journal (not the owner).

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| journal_id | UUID | Which journal (foreign key → JOURNAL) |
| user_id | UUID | The user granted access (foreign key → USER, nullable) |
| email | String | If invited by email before they have an account |
| phone_number | String | If invited by phone |
| permission_level | Enum | "view" or "edit" |
| invited_at | Timestamp | When access was granted |
| accepted_at | Timestamp | When they first accessed it |

---

### 4. PERSON
Someone you're collecting voice recordings from. They may or may not have the app.

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| owner_id | UUID | The user who added this person (foreign key → USER) |
| name | String | Display name (e.g., "Mom", "David") |
| relationship | Enum | See relationship types below |
| email | String | For sending question links |
| phone_number | String | For SMS invites |
| profile_photo_url | String | Optional photo |
| linked_user_id | UUID | If this person also has an account (foreign key → USER, nullable) |
| created_at | Timestamp | When added |

**Relationship Types:**
- parent
- grandparent
- spouse
- partner
- sibling
- child
- friend
- coworker
- boss
- mentor
- other

---

### 5. QUESTION_TEMPLATE
Pre-made questions that the app suggests based on relationship type.

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| relationship_type | Enum | Which relationship this question fits |
| question_text | String | The actual question |
| category | String | Grouping (e.g., "childhood", "career", "relationships") |
| display_order | Integer | Suggested order to show questions |
| is_active | Boolean | Whether to show this template |

---

### 6. QUESTION
A specific question within a journal, assigned to one or more people.

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| journal_id | UUID | Which journal this belongs to (foreign key → JOURNAL) |
| question_text | String | The question being asked |
| source | Enum | "template" or "custom" |
| template_id | UUID | If from a template (foreign key → QUESTION_TEMPLATE, nullable) |
| display_order | Integer | Order within the journal |
| created_at | Timestamp | When added |

---

### 7. QUESTION_ASSIGNMENT
Links a question to a specific person who should answer it.

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| question_id | UUID | The question (foreign key → QUESTION) |
| person_id | UUID | Who should answer (foreign key → PERSON) |
| status | Enum | "pending", "sent", "viewed", "answered" |
| unique_link_token | String | Unique token for the web recorder link |
| sent_at | Timestamp | When the link was sent |
| viewed_at | Timestamp | When they opened the link |
| answered_at | Timestamp | When they submitted a recording |
| reminder_count | Integer | How many reminders sent |
| last_reminder_at | Timestamp | When last nudged |

---

### 8. RECORDING
The actual voice recording submitted by a person.

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| assignment_id | UUID | Which question assignment (foreign key → QUESTION_ASSIGNMENT) |
| person_id | UUID | Who recorded it (foreign key → PERSON) |
| audio_file_url | String | URL to the stored audio file |
| duration_seconds | Integer | Length of recording |
| file_size_bytes | Integer | Size of audio file |
| transcription | String | Optional text transcription (premium feature) |
| recorded_at | Timestamp | When they made the recording |
| uploaded_at | Timestamp | When it hit the server |

---

### 9. NOTIFICATION
Tracks all notifications and reminders sent.

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| recipient_type | Enum | "user" or "person" |
| recipient_user_id | UUID | If sending to a user (foreign key → USER, nullable) |
| recipient_person_id | UUID | If sending to a person (foreign key → PERSON, nullable) |
| notification_type | Enum | See types below |
| channel | Enum | "push", "sms", "email" |
| title | String | Notification title |
| body | String | Notification content |
| related_assignment_id | UUID | If about a specific question (foreign key → QUESTION_ASSIGNMENT, nullable) |
| sent_at | Timestamp | When sent |
| read_at | Timestamp | When opened (nullable) |

**Notification Types:**
- question_received (someone sent you a question to answer)
- recording_received (someone answered your question)
- reminder (nudge to answer pending questions)
- journal_shared (someone shared a journal with you)
- weekly_digest (summary of activity)

---

## Relationships Diagram

```
USER
 │
 ├──< JOURNAL (user owns many journals)
 │      │
 │      ├──< JOURNAL_COLLABORATOR (journal has many collaborators)
 │      │
 │      └──< QUESTION (journal has many questions)
 │             │
 │             └──< QUESTION_ASSIGNMENT (question assigned to many people)
 │                    │
 │                    └──< RECORDING (assignment has one recording)
 │
 ├──< PERSON (user manages many people)
 │
 └──< NOTIFICATION (user receives many notifications)


QUESTION_TEMPLATE (standalone, system-wide)
```

---

## Example Data Flow

### Scenario: You want to ask your mom about her childhood

1. **You create a journal:** "Mom's Life Story" (JOURNAL created)

2. **You add your mom as a person:** Name: "Mom", Relationship: "parent", Phone: her number (PERSON created)

3. **App suggests questions** for "parent" relationship from QUESTION_TEMPLATE

4. **You select a question:** "What's your favorite childhood memory?" (QUESTION created, linked to journal)

5. **You assign it to mom:** (QUESTION_ASSIGNMENT created with status "pending")

6. **You tap "Send":** 
   - Unique link generated with token
   - SMS sent to mom's phone
   - Status changes to "sent"
   - NOTIFICATION logged

7. **Mom clicks the link:**
   - Web recorder opens
   - Shows the question
   - Status changes to "viewed"

8. **Mom records and submits:**
   - Audio uploaded to storage
   - RECORDING created with file URL
   - Status changes to "answered"
   - You get a push notification (NOTIFICATION created)

9. **You open the app:**
   - See the recording in "Mom's Life Story" journal
   - Tap to play her voice answering the question

---

## File Storage Structure

Audio files stored in cloud storage (e.g., AWS S3, Firebase Storage):

```
/recordings
  /{user_id}
    /{journal_id}
      /{recording_id}.m4a
```

---

## Privacy & Security Considerations

1. **Audio files:** Stored encrypted, accessed via signed URLs that expire
2. **Share links:** Tokens are random, unguessable strings (e.g., 32 characters)
3. **Passwords:** Never stored plain text, always hashed
4. **Phone numbers:** Used only for sending links/reminders, never shared
5. **Public journals:** Only owner can see who submitted recordings unless explicitly shared

---

## Future Expansion (Phase 2+)

- **SUBSCRIPTION:** Track payment status, billing dates
- **TRANSCRIPTION_JOB:** Queue for converting audio to text
- **JOURNAL_EXPORT:** Track when users download their journals
- **REPORT:** Handle flagged content on public journals

---

## Summary

| Entity | Purpose |
|--------|---------|
| USER | App account holder |
| JOURNAL | Container for questions on a theme |
| JOURNAL_COLLABORATOR | Shared access to journals |
| PERSON | Someone you're collecting recordings from |
| QUESTION_TEMPLATE | Pre-made suggested questions |
| QUESTION | Actual question in a journal |
| QUESTION_ASSIGNMENT | Links question to person, tracks status |
| RECORDING | The voice recording submitted |
| NOTIFICATION | All alerts and reminders |

This is your complete data foundation. Every feature in the app reads from or writes to these tables.

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "phone_number" TEXT,
    "display_name" TEXT NOT NULL,
    "profile_photo_url" TEXT,
    "subscription_tier" TEXT NOT NULL DEFAULT 'free',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "journals" (
    "id" TEXT NOT NULL,
    "owner_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "cover_image_url" TEXT,
    "privacy_setting" TEXT NOT NULL DEFAULT 'private',
    "share_code" TEXT,
    "dedicated_to_person_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "journals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "journal_collaborators" (
    "id" TEXT NOT NULL,
    "journal_id" TEXT NOT NULL,
    "user_id" TEXT,
    "email" TEXT,
    "phone_number" TEXT,
    "permission_level" TEXT NOT NULL DEFAULT 'view',
    "invited_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "accepted_at" TIMESTAMP(3),

    CONSTRAINT "journal_collaborators_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "people" (
    "id" TEXT NOT NULL,
    "owner_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "relationship" TEXT NOT NULL,
    "email" TEXT,
    "phone_number" TEXT,
    "profile_photo_url" TEXT,
    "linked_user_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "people_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "question_templates" (
    "id" TEXT NOT NULL,
    "relationship_type" TEXT NOT NULL,
    "question_text" TEXT NOT NULL,
    "category" TEXT,
    "display_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "question_templates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "questions" (
    "id" TEXT NOT NULL,
    "journal_id" TEXT NOT NULL,
    "question_text" TEXT NOT NULL,
    "source" TEXT NOT NULL DEFAULT 'custom',
    "template_id" TEXT,
    "display_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "questions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "question_assignments" (
    "id" TEXT NOT NULL,
    "question_id" TEXT NOT NULL,
    "person_id" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "unique_link_token" TEXT NOT NULL,
    "sent_at" TIMESTAMP(3),
    "viewed_at" TIMESTAMP(3),
    "answered_at" TIMESTAMP(3),
    "reminder_count" INTEGER NOT NULL DEFAULT 0,
    "last_reminder_at" TIMESTAMP(3),

    CONSTRAINT "question_assignments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "recordings" (
    "id" TEXT NOT NULL,
    "assignment_id" TEXT NOT NULL,
    "person_id" TEXT,
    "audio_file_url" TEXT NOT NULL,
    "duration_seconds" INTEGER,
    "file_size_bytes" BIGINT,
    "transcription" TEXT,
    "idempotency_key" TEXT,
    "recorded_at" TIMESTAMP(3),
    "uploaded_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "recordings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "recipient_user_id" TEXT NOT NULL,
    "notification_type" TEXT NOT NULL,
    "channel" TEXT,
    "title" TEXT,
    "body" TEXT,
    "related_assignment_id" TEXT,
    "related_recording_id" TEXT,
    "sent_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "read_at" TIMESTAMP(3),

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "push_tokens" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "platform" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "push_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_key" ON "refresh_tokens"("token");

-- CreateIndex
CREATE UNIQUE INDEX "journals_share_code_key" ON "journals"("share_code");

-- CreateIndex
CREATE INDEX "journals_owner_id_idx" ON "journals"("owner_id");

-- CreateIndex
CREATE INDEX "journals_dedicated_to_person_id_idx" ON "journals"("dedicated_to_person_id");

-- CreateIndex
CREATE INDEX "people_owner_id_idx" ON "people"("owner_id");

-- CreateIndex
CREATE INDEX "question_templates_relationship_type_idx" ON "question_templates"("relationship_type");

-- CreateIndex
CREATE INDEX "questions_journal_id_idx" ON "questions"("journal_id");

-- CreateIndex
CREATE UNIQUE INDEX "question_assignments_unique_link_token_key" ON "question_assignments"("unique_link_token");

-- CreateIndex
CREATE INDEX "question_assignments_question_id_idx" ON "question_assignments"("question_id");

-- CreateIndex
CREATE INDEX "question_assignments_person_id_idx" ON "question_assignments"("person_id");

-- CreateIndex
CREATE INDEX "question_assignments_unique_link_token_idx" ON "question_assignments"("unique_link_token");

-- CreateIndex
CREATE INDEX "recordings_assignment_id_idx" ON "recordings"("assignment_id");

-- CreateIndex
CREATE INDEX "recordings_idempotency_key_idx" ON "recordings"("idempotency_key");

-- CreateIndex
CREATE INDEX "notifications_recipient_user_id_idx" ON "notifications"("recipient_user_id");

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "journals" ADD CONSTRAINT "journals_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "journals" ADD CONSTRAINT "journals_dedicated_to_person_id_fkey" FOREIGN KEY ("dedicated_to_person_id") REFERENCES "people"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "journal_collaborators" ADD CONSTRAINT "journal_collaborators_journal_id_fkey" FOREIGN KEY ("journal_id") REFERENCES "journals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "journal_collaborators" ADD CONSTRAINT "journal_collaborators_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "people" ADD CONSTRAINT "people_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "questions" ADD CONSTRAINT "questions_journal_id_fkey" FOREIGN KEY ("journal_id") REFERENCES "journals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "questions" ADD CONSTRAINT "questions_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "question_templates"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "question_assignments" ADD CONSTRAINT "question_assignments_question_id_fkey" FOREIGN KEY ("question_id") REFERENCES "questions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "question_assignments" ADD CONSTRAINT "question_assignments_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "people"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recordings" ADD CONSTRAINT "recordings_assignment_id_fkey" FOREIGN KEY ("assignment_id") REFERENCES "question_assignments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recordings" ADD CONSTRAINT "recordings_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "people"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_recipient_user_id_fkey" FOREIGN KEY ("recipient_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_related_assignment_id_fkey" FOREIGN KEY ("related_assignment_id") REFERENCES "question_assignments"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_related_recording_id_fkey" FOREIGN KEY ("related_recording_id") REFERENCES "recordings"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "push_tokens" ADD CONSTRAINT "push_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

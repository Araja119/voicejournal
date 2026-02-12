-- AlterTable
ALTER TABLE "users" ALTER COLUMN "password_hash" DROP NOT NULL;

-- AddColumn
ALTER TABLE "users" ADD COLUMN "apple_user_id" TEXT;
ALTER TABLE "users" ADD COLUMN "auth_provider" TEXT NOT NULL DEFAULT 'email';

-- CreateIndex
CREATE UNIQUE INDEX "users_apple_user_id_key" ON "users"("apple_user_id");

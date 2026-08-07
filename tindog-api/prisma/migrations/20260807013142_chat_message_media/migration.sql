-- CreateEnum
CREATE TYPE "ChatMessageType" AS ENUM ('text', 'image', 'video');

-- AlterTable
ALTER TABLE "chat_messages" ADD COLUMN     "duration_sec" INTEGER,
ADD COLUMN     "media_public_id" TEXT,
ADD COLUMN     "media_url" TEXT,
ADD COLUMN     "thumbnail_url" TEXT,
ADD COLUMN     "type" "ChatMessageType" NOT NULL DEFAULT 'text',
ALTER COLUMN "body" SET DEFAULT '';

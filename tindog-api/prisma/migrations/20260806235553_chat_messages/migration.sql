-- CreateTable
CREATE TABLE "chat_messages" (
    "id" TEXT NOT NULL,
    "match_id" TEXT NOT NULL,
    "from_pet_id" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "chat_messages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "chat_messages_match_id_created_at_idx" ON "chat_messages"("match_id", "created_at");

-- CreateIndex
CREATE INDEX "chat_messages_from_pet_id_idx" ON "chat_messages"("from_pet_id");

-- AddForeignKey
ALTER TABLE "chat_messages" ADD CONSTRAINT "chat_messages_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "matches"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_messages" ADD CONSTRAINT "chat_messages_from_pet_id_fkey" FOREIGN KEY ("from_pet_id") REFERENCES "pets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- CreateTable
CREATE TABLE "muted_chats" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "match_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "muted_chats_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "muted_chats_user_id_idx" ON "muted_chats"("user_id");

-- CreateIndex
CREATE INDEX "muted_chats_match_id_idx" ON "muted_chats"("match_id");

-- CreateIndex
CREATE UNIQUE INDEX "muted_chats_user_id_match_id_key" ON "muted_chats"("user_id", "match_id");

-- AddForeignKey
ALTER TABLE "muted_chats" ADD CONSTRAINT "muted_chats_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

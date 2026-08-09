-- Chat HTTP local eliminado: los mensajes viven en Stream Chat.
DROP TABLE IF EXISTS "chat_messages";
DROP TYPE IF EXISTS "ChatMessageType";

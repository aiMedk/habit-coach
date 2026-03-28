-- T017: Conversations table
-- Matches data-model.md Conversation entity

CREATE TYPE conversation_type_enum AS ENUM ('morning', 'evening');

CREATE TABLE public.conversations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type        conversation_type_enum NOT NULL,
  date        DATE NOT NULL,
  messages    JSONB NOT NULL DEFAULT '[]'::JSONB,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- One conversation per type per user per date
  CONSTRAINT unique_conversation_per_day UNIQUE (user_id, type, date),

  CONSTRAINT messages_max_20 CHECK (
    jsonb_array_length(messages) <= 20
  )
);

CREATE INDEX conversations_user_date_idx ON public.conversations(user_id, date DESC);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own conversations"
  ON public.conversations FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

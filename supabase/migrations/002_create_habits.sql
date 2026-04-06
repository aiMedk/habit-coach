-- T014: Habits table
-- Matches data-model.md Habit entity

CREATE TYPE frequency_enum AS ENUM ('daily', 'specific_days');

CREATE TABLE public.habits (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name            TEXT NOT NULL CHECK (char_length(name) BETWEEN 1 AND 100),
  description     TEXT CHECK (description IS NULL OR char_length(description) <= 500),
  frequency       frequency_enum NOT NULL,
  frequency_days  INT[] CHECK (
    frequency = 'daily' OR (
      frequency = 'specific_days' AND
      frequency_days IS NOT NULL AND
      array_length(frequency_days, 1) BETWEEN 1 AND 7
    )
  ),
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX habits_user_id_idx ON public.habits(user_id);
CREATE INDEX habits_user_active_idx ON public.habits(user_id, is_active);

CREATE TRIGGER habits_updated_at
  BEFORE UPDATE ON public.habits
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- RLS: users can only access own habits
ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own habits"
  ON public.habits FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

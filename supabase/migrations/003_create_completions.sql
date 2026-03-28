-- T015: Completions table
-- Matches data-model.md Completion entity
-- local_date is derived at write time and immutable once written.

CREATE TABLE public.completions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  habit_id      UUID NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  completed_at  TIMESTAMPTZ NOT NULL,
  local_date    DATE NOT NULL,
  is_undone     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Idempotent: only one non-undone completion per habit per local day
  CONSTRAINT unique_completion_per_day
    UNIQUE NULLS NOT DISTINCT (habit_id, local_date, is_undone)
    DEFERRABLE INITIALLY DEFERRED
);

-- Partial unique index: one active (non-undone) completion per habit/day
CREATE UNIQUE INDEX completions_active_per_day_idx
  ON public.completions(habit_id, local_date)
  WHERE is_undone = FALSE;

CREATE INDEX completions_user_id_idx ON public.completions(user_id);
CREATE INDEX completions_habit_date_idx ON public.completions(habit_id, local_date DESC);

-- Prevent local_date from being updated after insert
CREATE OR REPLACE FUNCTION public.prevent_local_date_update()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.local_date <> OLD.local_date THEN
    RAISE EXCEPTION 'local_date is immutable once written';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER completions_immutable_local_date
  BEFORE UPDATE ON public.completions
  FOR EACH ROW EXECUTE FUNCTION public.prevent_local_date_update();

ALTER TABLE public.completions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own completions"
  ON public.completions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- T020: Commitments table
-- Matches data-model.md Commitment entity

CREATE TYPE commitment_status_enum AS ENUM ('active', 'fulfilled', 'failed');

CREATE TABLE public.commitments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  partner_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  habit_id        UUID NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
  target_streak   INT NOT NULL CHECK (target_streak >= 1),
  deadline        DATE NOT NULL,
  status          commitment_status_enum NOT NULL DEFAULT 'active',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT deadline_must_be_achievable CHECK (
    deadline >= CURRENT_DATE + (target_streak * INTERVAL '1 day')
  ),
  CONSTRAINT no_self_commitment CHECK (user_id <> partner_id)
);

CREATE INDEX commitments_user_id_idx ON public.commitments(user_id);
CREATE INDEX commitments_partner_id_idx ON public.commitments(partner_id);

-- Enforce: max 3 active commitments per user
CREATE OR REPLACE FUNCTION public.check_active_commitment_limit()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF (SELECT COUNT(*) FROM public.commitments
      WHERE user_id = NEW.user_id AND status = 'active') >= 3 THEN
    RAISE EXCEPTION 'Maximum 3 active commitments per user';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER enforce_commitment_limit
  BEFORE INSERT ON public.commitments
  FOR EACH ROW EXECUTE FUNCTION public.check_active_commitment_limit();

ALTER TABLE public.commitments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own commitments"
  ON public.commitments FOR ALL
  USING (auth.uid() = user_id OR auth.uid() = partner_id)
  WITH CHECK (auth.uid() = user_id);

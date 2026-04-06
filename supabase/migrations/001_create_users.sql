-- T013: Users table
-- Matches data-model.md User entity

CREATE TYPE subscription_tier_enum AS ENUM ('free', 'pro');
CREATE TYPE deletion_status_enum AS ENUM ('active', 'pending_deletion');

CREATE TABLE public.users (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email                     TEXT NOT NULL UNIQUE,
  display_name              TEXT NOT NULL CHECK (char_length(display_name) BETWEEN 1 AND 50),
  timezone                  TEXT NOT NULL DEFAULT 'UTC',
  subscription_tier         subscription_tier_enum NOT NULL DEFAULT 'free',
  notification_preferences  JSONB NOT NULL DEFAULT '{
    "reminder": true,
    "streak_at_risk": true,
    "milestone": true,
    "partner_nudge": true,
    "challenge_update": true
  }'::JSONB,
  deletion_status           deletion_status_enum NOT NULL DEFAULT 'active',
  deletion_requested_at     TIMESTAMPTZ,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT display_name_no_whitespace CHECK (
    display_name = TRIM(display_name)
  ),
  CONSTRAINT deletion_requested_at_consistency CHECK (
    (deletion_status = 'pending_deletion' AND deletion_requested_at IS NOT NULL) OR
    (deletion_status = 'active' AND deletion_requested_at IS NULL)
  )
);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- RLS: users can only read/update their own row
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own row"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own row"
  ON public.users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own row"
  ON public.users FOR INSERT
  WITH CHECK (auth.uid() = id);

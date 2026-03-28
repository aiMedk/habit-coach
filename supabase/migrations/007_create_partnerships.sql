-- T019: Partnerships table
-- Matches data-model.md Partnership entity

CREATE TYPE partnership_status_enum AS ENUM ('pending', 'active', 'suspended', 'dissolved');

CREATE TABLE public.partnerships (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inviter_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  invitee_id     UUID REFERENCES public.users(id) ON DELETE SET NULL,
  invite_token   TEXT NOT NULL UNIQUE,
  status         partnership_status_enum NOT NULL DEFAULT 'pending',
  suspended_at   TIMESTAMPTZ,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT no_self_partnership CHECK (inviter_id <> invitee_id),

  CONSTRAINT suspended_at_consistency CHECK (
    (status = 'suspended' AND suspended_at IS NOT NULL) OR
    (status <> 'suspended' AND suspended_at IS NULL)
  )
);

CREATE INDEX partnerships_inviter_idx ON public.partnerships(inviter_id);
CREATE INDEX partnerships_invitee_idx ON public.partnerships(invitee_id);
CREATE INDEX partnerships_token_idx ON public.partnerships(invite_token);

-- Enforce: a user may have at most one active/pending partnership
CREATE UNIQUE INDEX one_active_partnership_per_inviter
  ON public.partnerships(inviter_id)
  WHERE status IN ('pending', 'active', 'suspended');

CREATE UNIQUE INDEX one_active_partnership_per_invitee
  ON public.partnerships(invitee_id)
  WHERE status IN ('pending', 'active', 'suspended') AND invitee_id IS NOT NULL;

CREATE TRIGGER partnerships_updated_at
  BEFORE UPDATE ON public.partnerships
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.partnerships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Partners can read shared partnership"
  ON public.partnerships FOR SELECT
  USING (auth.uid() = inviter_id OR auth.uid() = invitee_id);

CREATE POLICY "Inviter manages partnership"
  ON public.partnerships FOR ALL
  USING (auth.uid() = inviter_id)
  WITH CHECK (auth.uid() = inviter_id);

-- T023: Blocked users table
-- Matches data-model.md BlockedUser entity
-- On block: dissolve any active partnership and remove from shared challenges.

CREATE TABLE public.blocked_users (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  blocked_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT unique_block UNIQUE (blocker_id, blocked_id),
  CONSTRAINT no_self_block CHECK (blocker_id <> blocked_id)
);

CREATE INDEX blocked_users_blocker_idx ON public.blocked_users(blocker_id);
CREATE INDEX blocked_users_blocked_idx ON public.blocked_users(blocked_id);

-- On block: dissolve active/pending partnership between the two users
CREATE OR REPLACE FUNCTION public.on_user_blocked()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Dissolve any partnership between blocker and blocked
  UPDATE public.partnerships
  SET status = 'dissolved', updated_at = NOW()
  WHERE status IN ('pending', 'active', 'suspended')
    AND (
      (inviter_id = NEW.blocker_id AND invitee_id = NEW.blocked_id) OR
      (inviter_id = NEW.blocked_id AND invitee_id = NEW.blocker_id)
    );

  -- Remove blocked user from shared challenges where blocker is also a participant
  UPDATE public.challenge_participants
  SET status = 'left'
  WHERE user_id = NEW.blocked_id
    AND challenge_id IN (
      SELECT cp.challenge_id FROM public.challenge_participants cp
      WHERE cp.user_id = NEW.blocker_id AND cp.status <> 'left'
    );

  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_on_user_blocked
  AFTER INSERT ON public.blocked_users
  FOR EACH ROW EXECUTE FUNCTION public.on_user_blocked();

ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own block list"
  ON public.blocked_users FOR ALL
  USING (auth.uid() = blocker_id)
  WITH CHECK (auth.uid() = blocker_id);

-- RLS helper: filter blocked pairs in partnership/challenge queries
CREATE OR REPLACE FUNCTION public.is_blocked(user_a UUID, user_b UUID)
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.blocked_users
    WHERE (blocker_id = user_a AND blocked_id = user_b)
       OR (blocker_id = user_b AND blocked_id = user_a)
  );
$$;

-- T021: Challenges and challenge_participants tables
-- Matches data-model.md Challenge and ChallengeParticipant entities

CREATE TYPE challenge_mode_enum AS ENUM ('compete', 'collaborate');
CREATE TYPE challenge_status_enum AS ENUM ('pending', 'active', 'completed', 'cancelled');
CREATE TYPE participant_status_enum AS ENUM ('pending', 'active', 'left');

CREATE TABLE public.challenges (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id               UUID NOT NULL REFERENCES public.users(id) ON DELETE SET NULL,
  habit_description        TEXT NOT NULL CHECK (char_length(habit_description) BETWEEN 1 AND 200),
  mode                     challenge_mode_enum NOT NULL,
  start_date               DATE NOT NULL,
  end_date                 DATE NOT NULL,
  max_participants         INT NOT NULL DEFAULT 5 CHECK (max_participants BETWEEN 2 AND 5),
  collaborate_target_pct   INT CHECK (
    (mode = 'collaborate' AND collaborate_target_pct BETWEEN 1 AND 100) OR
    (mode = 'compete' AND collaborate_target_pct IS NULL)
  ),
  invite_token             TEXT NOT NULL UNIQUE,
  status                   challenge_status_enum NOT NULL DEFAULT 'pending',
  purge_at                 TIMESTAMPTZ,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT end_after_start CHECK (end_date > start_date),
  CONSTRAINT start_not_past CHECK (start_date >= CURRENT_DATE)
);

CREATE INDEX challenges_creator_idx ON public.challenges(creator_id);

CREATE TABLE public.challenge_participants (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id     UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  user_id          UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  completion_count INT NOT NULL DEFAULT 0,
  current_streak   INT NOT NULL DEFAULT 0,
  status           participant_status_enum NOT NULL DEFAULT 'pending',
  joined_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT unique_participant UNIQUE (challenge_id, user_id)
);

CREATE INDEX challenge_participants_user_idx ON public.challenge_participants(user_id);
CREATE INDEX challenge_participants_challenge_idx ON public.challenge_participants(challenge_id);

-- Enforce: max 5 participants per challenge
CREATE OR REPLACE FUNCTION public.check_challenge_participant_limit()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF (SELECT COUNT(*) FROM public.challenge_participants
      WHERE challenge_id = NEW.challenge_id AND status <> 'left') >= 5 THEN
    RAISE EXCEPTION 'Maximum 5 participants per challenge';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER enforce_participant_limit
  BEFORE INSERT ON public.challenge_participants
  FOR EACH ROW EXECUTE FUNCTION public.check_challenge_participant_limit();

-- Enforce: max 3 active challenges per user
CREATE OR REPLACE FUNCTION public.check_user_active_challenges()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF (SELECT COUNT(*) FROM public.challenge_participants cp
      JOIN public.challenges c ON c.id = cp.challenge_id
      WHERE cp.user_id = NEW.user_id
        AND cp.status = 'active'
        AND c.status IN ('pending', 'active')) >= 3 THEN
    RAISE EXCEPTION 'Maximum 3 active challenges per user';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER enforce_user_challenge_limit
  BEFORE INSERT ON public.challenge_participants
  FOR EACH ROW EXECUTE FUNCTION public.check_user_active_challenges();

ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants can read challenge"
  ON public.challenges FOR SELECT
  USING (
    creator_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.challenge_participants
      WHERE challenge_id = challenges.id AND user_id = auth.uid()
    )
  );

CREATE POLICY "Creator manages challenge"
  ON public.challenges FOR ALL
  USING (creator_id = auth.uid())
  WITH CHECK (creator_id = auth.uid());

CREATE POLICY "Participants manage own participation"
  ON public.challenge_participants FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Participants read all participants in their challenges"
  ON public.challenge_participants FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.challenge_participants cp2
      WHERE cp2.challenge_id = challenge_participants.challenge_id
        AND cp2.user_id = auth.uid()
    )
  );

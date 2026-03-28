-- T102 + T173: Challenge lifecycle functions
-- Handles: cancellation (<2 participants), completion (end_date reached),
-- ownership transfer on creator deletion, and purge timestamp.

-- 1. Cancel challenges that reach start_date with fewer than 2 active participants
CREATE OR REPLACE FUNCTION public.cancel_underpopulated_challenges()
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  UPDATE public.challenges
     SET status = 'cancelled'
   WHERE status = 'pending'
     AND start_date <= CURRENT_DATE
     AND (
       SELECT COUNT(*) FROM public.challenge_participants
        WHERE challenge_id = challenges.id
          AND status <> 'left'
     ) < 2;
END;
$$;

-- 2. Complete challenges whose end_date has passed and set purge_at
CREATE OR REPLACE FUNCTION public.complete_finished_challenges()
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  UPDATE public.challenges
     SET status   = 'completed',
         purge_at = end_date + INTERVAL '30 days'
   WHERE status  = 'active'
     AND end_date < CURRENT_DATE;
END;
$$;

-- 3. Activate pending challenges on start_date
CREATE OR REPLACE FUNCTION public.activate_pending_challenges()
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  -- Activate participants first
  UPDATE public.challenge_participants cp
     SET status = 'active'
   FROM public.challenges c
   WHERE cp.challenge_id = c.id
     AND c.status        = 'pending'
     AND c.start_date   <= CURRENT_DATE
     AND cp.status       = 'pending'
     AND (
       SELECT COUNT(*) FROM public.challenge_participants cp2
        WHERE cp2.challenge_id = c.id
          AND cp2.status <> 'left'
     ) >= 2;

  -- Activate challenges
  UPDATE public.challenges
     SET status = 'active'
   WHERE status     = 'pending'
     AND start_date <= CURRENT_DATE
     AND (
       SELECT COUNT(*) FROM public.challenge_participants
        WHERE challenge_id = challenges.id
          AND status <> 'left'
     ) >= 2;
END;
$$;

-- 4. T173: Ownership transfer — when creator_id is set to NULL (user deleted),
--    transfer ownership to the earliest active joiner.
CREATE OR REPLACE FUNCTION public.transfer_challenge_ownership()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_new_owner UUID;
BEGIN
  IF OLD.creator_id IS NOT NULL AND NEW.creator_id IS NULL THEN
    -- Find earliest active participant who is not the deleted creator
    SELECT cp.user_id INTO v_new_owner
    FROM public.challenge_participants cp
    WHERE cp.challenge_id = NEW.id
      AND cp.user_id <> OLD.creator_id
      AND cp.status  = 'active'
    ORDER BY cp.joined_at ASC
    LIMIT 1;

    IF v_new_owner IS NOT NULL THEN
      NEW.creator_id := v_new_owner;

      -- Insert a notification for the new owner
      INSERT INTO public.notifications (user_id, title, body, type)
      VALUES (
        v_new_owner,
        'You are now the challenge owner',
        'The original creator left. You are now managing this challenge.',
        'challenge_ownership'
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER challenge_ownership_transfer
  BEFORE UPDATE OF creator_id ON public.challenges
  FOR EACH ROW EXECUTE FUNCTION public.transfer_challenge_ownership();

-- 5. Purge completed challenges past their purge_at date
CREATE OR REPLACE FUNCTION public.purge_old_challenges()
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM public.challenges
   WHERE status   = 'completed'
     AND purge_at < NOW();
END;
$$;

-- All lifecycle functions are intended to be called by a pg_cron job:
-- SELECT cron.schedule('challenge-lifecycle', '0 * * * *',
--   'SELECT public.cancel_underpopulated_challenges();
--    SELECT public.activate_pending_challenges();
--    SELECT public.complete_finished_challenges();
--    SELECT public.purge_old_challenges();');

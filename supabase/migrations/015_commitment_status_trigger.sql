-- T093: Commitment status trigger
-- Fires after each completion upsert to check if a commitment should be
-- marked as fulfilled.  A separate scheduled job (or deadline check on read)
-- handles the "failed" transition when deadline passes.

-- Function: recalculate streak for a given user+habit and update any active
-- commitment that targets that habit.

CREATE OR REPLACE FUNCTION public.check_commitment_fulfilment()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_streak_count  INT;
  v_commitment    RECORD;
BEGIN
  -- Only act on non-undone completions
  IF NEW.is_undone THEN
    RETURN NEW;
  END IF;

  -- Count the current streak for this user+habit (consecutive days ending today)
  SELECT COUNT(*) INTO v_streak_count
  FROM (
    SELECT local_date,
           ROW_NUMBER() OVER (ORDER BY local_date DESC) AS rn
    FROM public.completions
    WHERE user_id    = NEW.user_id
      AND habit_id   = NEW.habit_id
      AND is_undone  = FALSE
  ) dated
  WHERE dated.local_date::DATE =
        (CURRENT_DATE - (dated.rn - 1) * INTERVAL '1 day')::DATE;

  -- Find any active commitment for this user+habit
  SELECT * INTO v_commitment
  FROM public.commitments
  WHERE user_id  = NEW.user_id
    AND habit_id = NEW.habit_id
    AND status   = 'active'
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN NEW;
  END IF;

  -- Mark fulfilled if target streak reached before deadline
  IF v_streak_count >= v_commitment.target_streak
     AND CURRENT_DATE <= v_commitment.deadline THEN
    UPDATE public.commitments
       SET status = 'fulfilled'
     WHERE id = v_commitment.id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER commitment_fulfilment_check
  AFTER INSERT OR UPDATE ON public.completions
  FOR EACH ROW EXECUTE FUNCTION public.check_commitment_fulfilment();

-- Function: mark expired active commitments as failed (run periodically or on read)
CREATE OR REPLACE FUNCTION public.expire_missed_commitments()
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  UPDATE public.commitments
     SET status = 'failed'
   WHERE status   = 'active'
     AND deadline < CURRENT_DATE;
END;
$$;

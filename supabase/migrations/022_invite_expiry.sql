-- T149: Invite link expiry cleanup.
--
-- Partnership invites: expire after 7 days.
-- Challenge invites: expire 48 hours before challenge start_date.
-- Run every hour via pg_cron.

CREATE OR REPLACE FUNCTION public.expire_invites()
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  -- 1. Expire partnership invites older than 7 days that are still pending.
  UPDATE public.partnerships
     SET status = 'expired'
   WHERE status = 'pending'
     AND created_at < NOW() - INTERVAL '7 days';

  -- 2. Expire challenge invites where the challenge starts within 48 hours
  --    and the invite is still pending.
  UPDATE public.challenge_participants
     SET status = 'expired'
   WHERE status = 'invited'
     AND challenge_id IN (
       SELECT id FROM public.challenges
        WHERE start_date <= NOW() + INTERVAL '48 hours'
          AND status = 'pending'
     );
END;
$$;

-- Schedule: every hour
-- Requires pg_cron extension enabled in Supabase dashboard.
-- SELECT cron.schedule(
--   'expire-invites',
--   '0 * * * *',
--   'SELECT public.expire_invites()'
-- );

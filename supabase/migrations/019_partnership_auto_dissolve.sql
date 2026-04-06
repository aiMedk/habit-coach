-- T182: Partnership auto-dissolve scheduled function.
-- Dissolves partnerships that have been suspended for 90+ days
-- (triggered by subscription expiry with no renewal).
-- Run daily via pg_cron.

CREATE OR REPLACE FUNCTION public.auto_dissolve_suspended_partnerships()
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  UPDATE public.partnerships
     SET status       = 'dissolved',
         updated_at   = NOW()
   WHERE status       = 'suspended'
     AND suspended_at < NOW() - INTERVAL '90 days';
END;
$$;

-- Schedule: every day at 04:00 UTC
-- Requires pg_cron extension enabled in Supabase dashboard.
-- SELECT cron.schedule(
--   'auto-dissolve-partnerships',
--   '0 4 * * *',
--   'SELECT public.auto_dissolve_suspended_partnerships()'
-- );

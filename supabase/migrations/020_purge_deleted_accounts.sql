-- T141: Purge accounts that have been pending deletion for 30+ days.
-- Deleting the user row cascades to all related data (habits, completions,
-- partnerships, challenges, notifications, weekly_reviews) via ON DELETE CASCADE.
-- Run daily via pg_cron.

CREATE OR REPLACE FUNCTION public.purge_deleted_accounts()
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM public.users
   WHERE deletion_status = 'pending_deletion'
     AND deletion_requested_at < NOW() - INTERVAL '30 days';
END;
$$;

-- Schedule: every day at 03:00 UTC
-- Requires pg_cron extension enabled in Supabase dashboard.
-- SELECT cron.schedule(
--   'purge-deleted-accounts',
--   '0 3 * * *',
--   'SELECT public.purge_deleted_accounts()'
-- );

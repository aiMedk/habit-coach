-- T148: 90-day retention cleanup — purge expired AI coaching conversations,
-- weekly reviews, and challenge leaderboard entries.
--
-- Conversations: delete messages + conversations older than 90 days.
-- Weekly reviews: delete reviews older than 90 days.
-- Challenge leaderboard: delete entries for challenges that ended 30+ days ago.
-- Run daily via pg_cron.

CREATE OR REPLACE FUNCTION public.retention_cleanup()
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  -- 1. Delete AI conversation messages for conversations older than 90 days.
  DELETE FROM public.messages
   WHERE conversation_id IN (
     SELECT id FROM public.conversations
      WHERE created_at < NOW() - INTERVAL '90 days'
   );

  -- 2. Delete AI conversations older than 90 days.
  DELETE FROM public.conversations
   WHERE created_at < NOW() - INTERVAL '90 days';

  -- 3. Delete weekly reviews older than 90 days.
  DELETE FROM public.weekly_reviews
   WHERE week_start < NOW() - INTERVAL '90 days';

  -- 4. Delete challenge participant records for challenges that ended 30+ days ago.
  DELETE FROM public.challenge_participants
   WHERE challenge_id IN (
     SELECT id FROM public.challenges
      WHERE end_date < NOW() - INTERVAL '30 days'
        AND status IN ('completed', 'cancelled')
   );
END;
$$;

-- Schedule: every day at 04:00 UTC
-- Requires pg_cron extension enabled in Supabase dashboard.
-- SELECT cron.schedule(
--   'retention-cleanup',
--   '0 4 * * *',
--   'SELECT public.retention_cleanup()'
-- );

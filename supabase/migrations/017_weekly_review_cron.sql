-- T114: Weekly review CRON trigger
-- Schedules AI weekly review generation for all eligible Pro users
-- every Sunday at 20:00 UTC (configurable per user in future).

-- Function called by pg_cron to trigger review generation via Edge Function
-- for all Pro users who haven't received a review for the current week.
CREATE OR REPLACE FUNCTION public.trigger_weekly_reviews()
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
  v_user         RECORD;
  v_week_start   DATE;
  v_week_end     DATE;
BEGIN
  -- ISO week: Monday to Sunday
  v_week_start := date_trunc('week', CURRENT_DATE)::DATE;
  v_week_end   := v_week_start + 6;

  FOR v_user IN
    SELECT DISTINCT s.user_id
    FROM public.subscriptions s
    WHERE s.tier = 'pro'
      AND s.status = 'active'
      -- User has at least 7 completions in the past 7 days
      AND (
        SELECT COUNT(*) FROM public.completions c
         WHERE c.user_id = s.user_id
           AND c.local_date >= v_week_start::TEXT
           AND c.local_date <= v_week_end::TEXT
           AND c.is_undone = FALSE
      ) >= 7
      -- No review generated yet for this week
      AND NOT EXISTS (
        SELECT 1 FROM public.weekly_reviews wr
         WHERE wr.user_id = s.user_id
           AND wr.week_start = v_week_start
      )
  LOOP
    -- Invoke via pg_net (fire-and-forget HTTP POST to Edge Function)
    PERFORM extensions.http_post(
      url     := current_setting('app.supabase_url') || '/functions/v1/ai-weekly-review',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.service_role_key')
      ),
      body    := jsonb_build_object(
        'user_id',    v_user.user_id,
        'week_start', v_week_start,
        'week_end',   v_week_end
      )::TEXT
    );
  END LOOP;
END;
$$;

-- Schedule: every Sunday at 20:00 UTC
-- Requires pg_cron extension enabled in Supabase dashboard.
-- SELECT cron.schedule(
--   'weekly-reviews',
--   '0 20 * * 0',
--   'SELECT public.trigger_weekly_reviews()'
-- );

-- Purge expired reviews (>90 days old) — run daily
CREATE OR REPLACE FUNCTION public.purge_expired_reviews()
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM public.weekly_reviews
   WHERE expires_at < NOW();
END;
$$;

-- SELECT cron.schedule('purge-reviews', '0 3 * * *', 'SELECT public.purge_expired_reviews()');

-- T127: Add fcm_token column to users table for FCM push notification delivery.
-- Also adds consecutive_unresponsive_days for fatigue reduction logic in push-scheduler.

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS fcm_token TEXT,
  ADD COLUMN IF NOT EXISTS consecutive_unresponsive_days INT NOT NULL DEFAULT 0;

-- Index for push-scheduler: quickly find users with FCM tokens.
CREATE INDEX IF NOT EXISTS users_fcm_token_idx
  ON public.users(fcm_token)
  WHERE fcm_token IS NOT NULL;

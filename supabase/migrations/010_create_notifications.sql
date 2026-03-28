-- T022: Notifications table
-- Matches data-model.md Notification entity

CREATE TYPE notification_type_enum AS ENUM (
  'reminder', 'streak_at_risk', 'milestone', 'partner_nudge', 'challenge_update'
);

CREATE TABLE public.notifications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type            notification_type_enum NOT NULL,
  content         TEXT NOT NULL CHECK (char_length(content) <= 500),
  scheduled_at    TIMESTAMPTZ NOT NULL,
  sent_at         TIMESTAMPTZ,
  fcm_message_id  TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX notifications_user_scheduled_idx
  ON public.notifications(user_id, scheduled_at DESC);

CREATE INDEX notifications_unsent_idx
  ON public.notifications(scheduled_at)
  WHERE sent_at IS NULL;

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Service role manages notifications"
  ON public.notifications FOR ALL
  USING (auth.role() = 'service_role');

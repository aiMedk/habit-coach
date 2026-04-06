-- T024: Development seed data
-- Creates two test users (free + pro), sample habits, completions, and a partnership.
-- Run after migrations: supabase db reset (which applies migrations + seed)

-- ── Test users (auth.users + public.users) ────────────────────────────────────
-- Note: In local dev, create auth users via Supabase Studio or API first,
-- then these UUIDs must match. Adjust UUIDs to match your local auth users.

DO $$
DECLARE
  free_user_id  UUID := '00000000-0000-0000-0000-000000000001';
  pro_user_id   UUID := '00000000-0000-0000-0000-000000000002';
  habit1_id     UUID := '00000000-0000-0000-0000-000000000010';
  habit2_id     UUID := '00000000-0000-0000-0000-000000000011';
  habit3_id     UUID := '00000000-0000-0000-0000-000000000012';
  partnership_id UUID := '00000000-0000-0000-0000-000000000020';
BEGIN

-- Public user profiles
INSERT INTO public.users (id, email, display_name, timezone, subscription_tier)
VALUES
  (free_user_id, 'free@habitcoach.test', 'Alex Free', 'America/New_York', 'free'),
  (pro_user_id,  'pro@habitcoach.test',  'Sam Pro',  'America/New_York', 'pro')
ON CONFLICT (id) DO NOTHING;

-- Subscription record for Pro user
INSERT INTO public.subscriptions (user_id, tier, status, platform, started_at, expires_at)
VALUES (
  pro_user_id, 'pro', 'active', 'ios',
  NOW() - INTERVAL '30 days',
  NOW() + INTERVAL '335 days'
)
ON CONFLICT (user_id) DO NOTHING;

-- Habits for Pro user
INSERT INTO public.habits (id, user_id, name, frequency)
VALUES
  (habit1_id, pro_user_id, 'Morning Run',  'daily'),
  (habit2_id, pro_user_id, 'Read 30 mins', 'daily'),
  (habit3_id, pro_user_id, 'Meditate',     'specific_days')
ON CONFLICT (id) DO NOTHING;

-- Update habit3 frequency_days (Mon-Fri = 0-4)
UPDATE public.habits SET frequency_days = ARRAY[0,1,2,3,4] WHERE id = habit3_id;

-- Completions for the last 7 days for habit1 (creates a 7-day streak)
INSERT INTO public.completions (habit_id, user_id, completed_at, local_date)
SELECT
  habit1_id,
  pro_user_id,
  NOW() - (gs.day * INTERVAL '1 day'),
  (CURRENT_DATE - gs.day)
FROM generate_series(0, 6) AS gs(day)
ON CONFLICT DO NOTHING;

-- Free user habit (1 habit only for demo)
INSERT INTO public.habits (user_id, name, frequency)
VALUES (free_user_id, 'Daily Walk', 'daily')
ON CONFLICT DO NOTHING;

-- Partnership between free and pro users
INSERT INTO public.partnerships (id, inviter_id, invitee_id, invite_token, status)
VALUES (
  partnership_id,
  pro_user_id,
  free_user_id,
  'dev-invite-token-001',
  'active'
)
ON CONFLICT DO NOTHING;

END $$;

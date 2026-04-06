-- T016: Subscriptions table
-- Matches data-model.md Subscription entity

CREATE TYPE subscription_status_enum AS ENUM ('active', 'cancelled', 'expired');
CREATE TYPE platform_enum AS ENUM ('ios', 'android');

CREATE TABLE public.subscriptions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  tier            subscription_tier_enum NOT NULL DEFAULT 'free',
  status          subscription_status_enum NOT NULL,
  revenuecat_id   TEXT,
  platform        platform_enum NOT NULL,
  started_at      TIMESTAMPTZ,
  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own subscription"
  ON public.subscriptions FOR SELECT
  USING (auth.uid() = user_id);

-- Only service role can modify subscription records (via RevenueCat webhook)
CREATE POLICY "Service role manages subscriptions"
  ON public.subscriptions FOR ALL
  USING (auth.role() = 'service_role');

-- T018: Weekly reviews table
-- Matches data-model.md WeeklyReview entity

CREATE TABLE public.weekly_reviews (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  week_start       DATE NOT NULL,
  week_end         DATE NOT NULL,
  patterns         JSONB NOT NULL DEFAULT '[]'::JSONB,
  insights         JSONB NOT NULL DEFAULT '[]'::JSONB,
  partner_summary  JSONB,
  expires_at       TIMESTAMPTZ NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- One review per user per week
  CONSTRAINT unique_review_per_week UNIQUE (user_id, week_start),

  CONSTRAINT week_end_after_start CHECK (week_end > week_start)
);

CREATE INDEX weekly_reviews_user_idx ON public.weekly_reviews(user_id, week_start DESC);

ALTER TABLE public.weekly_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own reviews"
  ON public.weekly_reviews FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

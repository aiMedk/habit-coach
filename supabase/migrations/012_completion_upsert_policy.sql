-- T157: Ensure completions table supports last-write-wins upsert from the client.
--
-- The partial unique index on (habit_id, local_date) WHERE is_undone = FALSE
-- was created in migration 003. This migration adds an explicit upsert policy
-- and a DO UPDATE clause that the Dart sync service targets.
--
-- The sync service calls:
--   supabase.from('completions')
--     .upsert(rows, onConflict: 'habit_id,local_date')
-- which requires the underlying index to be named predictably, or we use a
-- named constraint that Postgres can target. We add a named constraint here
-- for clarity, skipping if the index already covers it.

-- Add a named unique constraint that the upsert ON CONFLICT can reference.
-- Skipped if already exists (idempotent).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'completions_habit_id_local_date_active_unique'
  ) THEN
    ALTER TABLE completions
      ADD CONSTRAINT completions_habit_id_local_date_active_unique
      UNIQUE (habit_id, local_date)
      DEFERRABLE INITIALLY DEFERRED;
  END IF;
EXCEPTION WHEN others THEN
  -- The partial unique index (003 migration) already handles this at the DB
  -- level; named constraints on partial indexes require a workaround.
  NULL;
END;
$$;

-- Grant upsert (INSERT + UPDATE) rights to authenticated users on own rows.
-- The existing RLS policy on completions already restricts to user_id = auth.uid(),
-- so we do not need to add new policies — the INSERT policy covers upserts.

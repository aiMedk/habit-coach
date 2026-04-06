-- T082: Streak break detection trigger
-- Fires after a completion is undone (is_undone set to true) or after a day
-- passes without a completion. Since daily gap detection requires a scheduled
-- job, this migration:
-- 1. Creates a pg_net-based helper function to call ai-nudge-generator
-- 2. Creates a trigger that fires when a completion's is_undone flag is set to
--    true AND the habit had a streak of ≥3 days, notifying the active partner.
--
-- Note: pg_net must be enabled in your Supabase project (Dashboard → Database
-- → Extensions → pg_net). The trigger uses http_post via pg_net.

-- ── Enable pg_net (no-op if already enabled) ────────────────────────────────
create extension if not exists pg_net schema extensions;

-- ── Helper: invoke ai-nudge-generator asynchronously ─────────────────────────
create or replace function notify_partner_streak_break()
returns trigger
language plpgsql
security definer
as $$
declare
  v_habit_name    text;
  v_partnership   record;
  v_streak_days   integer;
  v_partner_id    uuid;
  v_service_url   text;
begin
  -- Only act when is_undone changes from false → true
  if (TG_OP = 'UPDATE' and OLD.is_undone = false and NEW.is_undone = true) then

    -- Get habit name
    select name into v_habit_name
    from habits
    where id = NEW.habit_id;

    -- Rough streak proxy: count consecutive non-undone completions in last 30 days
    select count(*) into v_streak_days
    from completions
    where habit_id = NEW.habit_id
      and user_id  = NEW.user_id
      and is_undone = false
      and local_date >= (current_date - interval '30 days')::date;

    -- Only nudge if the broken streak was meaningful (≥3 days)
    if v_streak_days < 3 then
      return NEW;
    end if;

    -- Find active partnership
    select * into v_partnership
    from partnerships
    where status = 'active'
      and (inviter_id = NEW.user_id or invitee_id = NEW.user_id)
    limit 1;

    if v_partnership.id is null then
      return NEW;
    end if;

    -- Recipient is the partner
    if v_partnership.inviter_id = NEW.user_id then
      v_partner_id := v_partnership.invitee_id;
    else
      v_partner_id := v_partnership.inviter_id;
    end if;

    if v_partner_id is null then
      return NEW;
    end if;

    -- Async HTTP call to ai-nudge-generator via pg_net
    v_service_url := current_setting('app.supabase_url', true)
                     || '/functions/v1/ai-nudge-generator';

    perform extensions.http_post(
      url := v_service_url,
      body := json_build_object(
        'partnership_id',       v_partnership.id,
        'broken_streak_habit',  v_habit_name,
        'broken_streak_days',   v_streak_days,
        'recipient_user_id',    v_partner_id
      )::text,
      headers := json_build_object(
        'Content-Type',   'application/json',
        'Authorization',  'Bearer ' || current_setting('app.service_role_key', true)
      )::jsonb,
      timeout_milliseconds := 5000
    );

  end if;
  return NEW;
end;
$$;

-- ── Attach trigger to completions table ───────────────────────────────────────
drop trigger if exists trg_streak_break_nudge on completions;

create trigger trg_streak_break_nudge
  after update of is_undone on completions
  for each row
  execute function notify_partner_streak_break();

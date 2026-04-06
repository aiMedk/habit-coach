// T122: push-scheduler Edge Function
// CRON-triggered every 15 minutes by pg_cron.
// Queries users due for notifications, personalises via ai-notification-personaliser,
// sends via FCM, records delivery, and applies fatigue reduction.

import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY")!;

// Fatigue threshold: reduce notifications after 3+ consecutive non-responsive days.
const FATIGUE_THRESHOLD_DAYS = 3;

interface PendingNotification {
  id: string;
  user_id: string;
  type: string;
  content: string;
  scheduled_at: string;
}

interface UserRow {
  fcm_token: string | null;
  notification_preferences: Record<string, boolean>;
  timezone: string;
  consecutive_unresponsive_days: number;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, content-type",
      },
    });
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  const now = new Date();
  const windowStart = new Date(now.getTime() - 15 * 60 * 1000); // 15 min ago
  const windowEnd = now;

  // ── Fetch pending notifications due in this window ────────────────────────
  const { data: pending, error } = await supabase
    .from("notifications")
    .select("id, user_id, type, content, scheduled_at")
    .is("sent_at", null)
    .gte("scheduled_at", windowStart.toISOString())
    .lte("scheduled_at", windowEnd.toISOString())
    .limit(200);

  if (error) {
    console.error("push-scheduler: fetch error:", error);
    return json({ error: error.message }, 500);
  }

  if (!pending || pending.length === 0) {
    return json({ processed: 0 });
  }

  // ── Fetch user data for all affected users ────────────────────────────────
  const userIds = [...new Set((pending as PendingNotification[]).map((n) => n.user_id))];

  const { data: users } = await supabase
    .from("users")
    .select("id, fcm_token, notification_preferences, timezone, consecutive_unresponsive_days")
    .in("id", userIds);

  const userMap = new Map<string, UserRow & { id: string }>(
    (users ?? []).map((u: UserRow & { id: string }) => [u.id, u])
  );

  let sent = 0;
  let skipped = 0;

  for (const notification of pending as PendingNotification[]) {
    const user = userMap.get(notification.user_id);
    if (!user || !user.fcm_token) {
      skipped++;
      continue;
    }

    // ── Fatigue reduction: skip if user has been unresponsive ─────────────
    if ((user.consecutive_unresponsive_days ?? 0) >= FATIGUE_THRESHOLD_DAYS) {
      // Only send milestone and partner_nudge types when fatigued
      if (
        notification.type !== "milestone" &&
        notification.type !== "partner_nudge"
      ) {
        skipped++;
        continue;
      }
    }

    // ── Check notification type preference ────────────────────────────────
    const prefs = user.notification_preferences ?? {};
    const prefKey = notification.type; // matches JSONB keys
    if (prefs[prefKey] === false) {
      skipped++;
      continue;
    }

    // ── Personalise via ai-notification-personaliser ──────────────────────
    let title = "Habit Coach";
    let body = notification.content;

    try {
      const personalised = await fetch(
        `${SUPABASE_URL}/functions/v1/ai-notification-personaliser`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
          },
          body: JSON.stringify({
            user_id: notification.user_id,
            notification_type: notification.type,
            context: { habit_name: notification.content },
          }),
        }
      );
      if (personalised.ok) {
        const data = await personalised.json();
        title = data.title ?? title;
        body = data.body ?? body;
      }
    } catch {
      // Use defaults if personaliser unavailable
    }

    // ── Send via FCM ──────────────────────────────────────────────────────
    let fcmMessageId: string | null = null;
    try {
      const fcmResponse = await fetch(
        "https://fcm.googleapis.com/fcm/send",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `key=${FCM_SERVER_KEY}`,
          },
          body: JSON.stringify({
            to: user.fcm_token,
            notification: { title, body },
            data: { type: notification.type, notification_id: notification.id },
          }),
        }
      );

      if (fcmResponse.ok) {
        const fcmData = await fcmResponse.json();
        fcmMessageId = fcmData.results?.[0]?.message_id ?? null;
      }
    } catch {
      // FCM delivery failed — still mark as sent to avoid duplicate attempts
    }

    // ── Record delivery ───────────────────────────────────────────────────
    await supabase
      .from("notifications")
      .update({
        sent_at: new Date().toISOString(),
        fcm_message_id: fcmMessageId,
      })
      .eq("id", notification.id);

    sent++;
  }

  return json({ processed: pending.length, sent, skipped });
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}

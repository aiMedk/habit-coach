// T121: ai-notification-personaliser Edge Function
// Generates personalised push notification title and body using Claude Haiku.
// Called by the push-scheduler Edge Function for each scheduled notification.

import Anthropic from "npm:@anthropic-ai/sdk@0.24.3";
import { createClient } from "npm:@supabase/supabase-js@2";

const anthropic = new Anthropic({
  apiKey: Deno.env.get("ANTHROPIC_API_KEY")!,
});

type NotificationType =
  | "reminder"
  | "streak_at_risk"
  | "milestone"
  | "challenge_update";

interface NotificationContext {
  habit_name?: string;
  streak_days?: number;
  milestone_type?: string | null;
  challenge_name?: string | null;
}

// Fallback templates per notification type — used when Claude is unavailable.
function fallbackContent(
  type: NotificationType,
  ctx: NotificationContext,
  displayName: string
): { title: string; body: string } {
  switch (type) {
    case "reminder":
      return {
        title: `Time for ${ctx.habit_name ?? "your habit"}!`,
        body: `Keep the momentum going, ${displayName}. Your streak is waiting.`,
      };
    case "streak_at_risk":
      return {
        title: "Don't break your streak!",
        body: `Your ${ctx.habit_name ?? "habit"} streak of ${ctx.streak_days ?? 0} days is at risk. Complete it today!`,
      };
    case "milestone":
      return {
        title: "Milestone reached! 🎉",
        body: `Amazing work, ${displayName}! You've hit a ${ctx.milestone_type ?? ""} milestone.`,
      };
    case "challenge_update":
      return {
        title: `Challenge update: ${ctx.challenge_name ?? ""}`,
        body: `Check your progress in the challenge leaderboard!`,
      };
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return json(null, 204, {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, content-type",
    });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Missing Authorization header" }, 401);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
        Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    // ── Parse request ─────────────────────────────────────────────────────────
    const body = await req.json();
    const user_id: string = body.user_id;
    const notification_type: NotificationType = body.notification_type;
    const context: NotificationContext = body.context ?? {};

    if (!user_id || !notification_type) {
      return json({ error: "Missing user_id or notification_type" }, 400);
    }

    // ── Fetch user display name ───────────────────────────────────────────────
    const { data: user } = await supabase
      .from("users")
      .select("display_name")
      .eq("id", user_id)
      .single();

    const displayName = user?.display_name ?? "there";

    // ── Build prompt ─────────────────────────────────────────────────────────
    const typeLabel: Record<NotificationType, string> = {
      reminder: "habit reminder",
      streak_at_risk: "streak at risk alert",
      milestone: "milestone celebration",
      challenge_update: "group challenge update",
    };

    const prompt = `Generate a short, personalised push notification for a habit tracking app.

User: ${displayName}
Notification type: ${typeLabel[notification_type]}
${context.habit_name ? `Habit: ${context.habit_name}` : ""}
${context.streak_days != null ? `Current streak: ${context.streak_days} days` : ""}
${context.milestone_type ? `Milestone: ${context.milestone_type}` : ""}
${context.challenge_name ? `Challenge name: ${context.challenge_name}` : ""}

Requirements:
- Title: max 50 characters, motivating and specific to the habit/context
- Body: 1 sentence, max 100 characters, personal and actionable
- Use the user's name naturally
- Tone: supportive and energising, not corporate

Return as JSON only: { "title": "...", "body": "..." }`;

    // ── Call Claude Haiku (1 retry, 3s delay) ────────────────────────────────
    let title: string | null = null;
    let body_text: string | null = null;

    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        if (attempt > 0) await delay(3000);

        const response = await anthropic.messages.create({
          model: "claude-haiku-4-5-20251001",
          max_tokens: 150,
          messages: [{ role: "user", content: prompt }],
        });

        const raw =
          response.content[0].type === "text"
            ? response.content[0].text.trim()
            : "";

        const parsed = JSON.parse(raw);
        title = parsed.title ?? null;
        body_text = parsed.body ?? null;
        break;
      } catch {
        // Retry or fall through to fallback
      }
    }

    // ── Fallback if Claude unavailable ───────────────────────────────────────
    if (!title || !body_text) {
      const fb = fallbackContent(notification_type, context, displayName);
      title = fb.title;
      body_text = fb.body;
    }

    return json({ title, body: body_text });
  } catch (err) {
    console.error("ai-notification-personaliser error:", err);
    return json({ error: "Internal server error" }, 500);
  }
});

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function json(
  body: unknown,
  status = 200,
  extraHeaders: Record<string, string> = {}
): Response {
  return new Response(body === null ? null : JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      ...extraHeaders,
    },
  });
}

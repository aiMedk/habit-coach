// T081: ai-nudge-generator Edge Function
// Generates a personalised nudge message when a partner breaks a streak.
// Called by the streak-break database trigger (via pg_net / HTTP).
// Uses Claude Sonnet for higher-quality empathetic copy.

import Anthropic from "npm:@anthropic-ai/sdk@0.24.3";
import { createClient } from "npm:@supabase/supabase-js@2";

const anthropic = new Anthropic({
  apiKey: Deno.env.get("ANTHROPIC_API_KEY")!,
});

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, content-type",
      },
    });
  }

  try {
    // ── Auth — accepts both user JWT and service role key ─────────────────────
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
    const { partnership_id, broken_streak_habit, broken_streak_days, recipient_user_id } =
      await req.json();

    if (!partnership_id || !broken_streak_habit || !recipient_user_id) {
      return json({ error: "Missing required fields" }, 400);
    }

    // ── Fetch context ─────────────────────────────────────────────────────────
    const { data: partnership } = await supabase
      .from("partnerships")
      .select("inviter_id, invitee_id, status")
      .eq("id", partnership_id)
      .eq("status", "active")
      .single();

    if (!partnership) {
      return json({ error: "Partnership not found or not active" }, 404);
    }

    // The partner who broke the streak (not the recipient)
    const breakerId =
      partnership.inviter_id === recipient_user_id
        ? partnership.invitee_id
        : partnership.inviter_id;

    const [breakerProfile, recipientProfile] = await Promise.all([
      supabase
        .from("users")
        .select("display_name")
        .eq("id", breakerId)
        .single()
        .then((r) => r.data),
      supabase
        .from("users")
        .select("display_name")
        .eq("id", recipient_user_id)
        .single()
        .then((r) => r.data),
    ]);

    const breakerName = breakerProfile?.display_name ?? "Your partner";
    const recipientName = recipientProfile?.display_name ?? "there";
    const streakDays = broken_streak_days ?? 0;

    // ── Call Claude Sonnet ────────────────────────────────────────────────────
    const prompt = `Generate a warm, empathetic nudge notification for a habit accountability app.

Context:
- Recipient: ${recipientName}
- Their accountability partner (${breakerName}) just broke their "${broken_streak_habit}" streak after ${streakDays} day${streakDays !== 1 ? "s" : ""}
- The notification should encourage ${recipientName} to reach out to ${breakerName} with support

Requirements:
- Notification title: 1 short sentence (max 50 chars), warm and personal
- Nudge text: 1-2 sentences, empathetic, encouraging action without being pushy
- Use the partner's name (${breakerName}) naturally
- Tone: supportive friend, not a coach lecturing

Return as JSON: { "notification_title": "...", "nudge_text": "..." }`;

    const response = await anthropic.messages.create({
      model: "claude-sonnet-4-6",
      max_tokens: 200,
      messages: [{ role: "user", content: prompt }],
    });

    const text =
      response.content[0].type === "text" ? response.content[0].text : "{}";

    // Parse AI response
    let nudgeTitle = `${breakerName} could use your support 💪`;
    let nudgeText = `${breakerName} broke their ${broken_streak_habit} streak. A quick message of encouragement could make all the difference!`;

    try {
      const parsed = JSON.parse(text);
      nudgeTitle = parsed.notification_title ?? nudgeTitle;
      nudgeText = parsed.nudge_text ?? nudgeText;
    } catch {
      // Use defaults if AI returned non-JSON
    }

    return json({ nudge_text: nudgeText, notification_title: nudgeTitle });
  } catch (err) {
    console.error("ai-nudge-generator error:", err);
    return json({ error: "AI service unavailable" }, 503);
  }
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

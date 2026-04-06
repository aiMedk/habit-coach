// T068: ai-evening-reflection Edge Function
// Starts or continues an evening AI reflection conversation for a Pro user.
// Calls Claude Haiku with today's completions and 7-day patterns.
// Enforces 20-turn limit and stores conversation in the conversations table.

import Anthropic from "npm:@anthropic-ai/sdk@0.24.3";
import { createClient } from "npm:@supabase/supabase-js@2";

const anthropic = new Anthropic({
  apiKey: Deno.env.get("ANTHROPIC_API_KEY")!,
});

const TURN_LIMIT = 20;
const CONVERSATION_TYPE = "evening";

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
    // ── Auth ──────────────────────────────────────────────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Missing Authorization header" }, 401);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();
    if (authError || !user) return json({ error: "Unauthorized" }, 401);

    // ── Entitlement check ────────────────────────────────────────────────────
    const { data: profile } = await supabase
      .from("users")
      .select("subscription_tier, display_name, timezone")
      .eq("id", user.id)
      .single();

    if (!profile || profile.subscription_tier !== "pro") {
      return json({ error: "Pro subscription required" }, 403);
    }

    // ── Parse request ────────────────────────────────────────────────────────
    const { conversation_id, user_message } = await req.json();
    const today = new Date().toISOString().split("T")[0];

    // ── Idempotency: check existing conversation ──────────────────────────────
    let conversation: ConversationRow | null = null;

    if (conversation_id) {
      const { data } = await supabase
        .from("conversations")
        .select("*")
        .eq("id", conversation_id)
        .eq("user_id", user.id)
        .single();
      conversation = data;
    } else {
      // Check if evening reflection already exists for today
      const { data } = await supabase
        .from("conversations")
        .select("*")
        .eq("user_id", user.id)
        .eq("type", CONVERSATION_TYPE)
        .eq("date", today)
        .single();

      if (data && !user_message) {
        return json({ error: "Evening reflection already completed today" }, 409);
      }
      conversation = data ?? null;
    }

    // ── Turn limit check ──────────────────────────────────────────────────────
    const messages: MessageEntry[] = conversation?.messages ?? [];
    if (messages.length >= TURN_LIMIT) {
      return json(
        { error: "Conversation turn limit reached", is_complete: true },
        422
      );
    }

    // ── Build context for AI ──────────────────────────────────────────────────
    const context = await buildUserContext(supabase, user.id, today);
    const systemPrompt = buildSystemPrompt(profile.display_name, context);

    // Append new user message if continuing
    if (user_message) {
      messages.push({
        role: "user",
        content: user_message,
        timestamp: new Date().toISOString(),
      });
    }

    // ── Call Claude Haiku ─────────────────────────────────────────────────────
    const anthropicMessages = messages.map((m) => ({
      role: m.role as "user" | "assistant",
      content: m.content,
    }));

    // If starting fresh, don't pass any messages yet (AI opens the conversation)
    const response = await anthropic.messages.create({
      model: "claude-haiku-4-5-20251001",
      max_tokens: 300,
      system: systemPrompt,
      messages:
        anthropicMessages.length > 0
          ? anthropicMessages
          : [{ role: "user", content: "Good evening!" }],
    });

    const assistantText =
      response.content[0].type === "text" ? response.content[0].text : "";

    // Append assistant reply
    messages.push({
      role: "assistant",
      content: assistantText,
      timestamp: new Date().toISOString(),
    });

    // ── Persist conversation ──────────────────────────────────────────────────
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 90);

    let conversationId: string;
    if (conversation) {
      await supabase
        .from("conversations")
        .update({ messages })
        .eq("id", conversation.id);
      conversationId = conversation.id;
    } else {
      const { data: inserted } = await supabase
        .from("conversations")
        .insert({
          user_id: user.id,
          type: CONVERSATION_TYPE,
          date: today,
          messages,
          expires_at: expiresAt.toISOString(),
        })
        .select("id")
        .single();
      conversationId = inserted!.id;
    }

    return json({
      conversation_id: conversationId,
      assistant_message: assistantText,
      turn_count: messages.length,
      is_complete: messages.length >= TURN_LIMIT,
    });
  } catch (err) {
    console.error("ai-evening-reflection error:", err);
    return json({ error: "AI service unavailable" }, 503);
  }
});

// ── Helpers ───────────────────────────────────────────────────────────────────

interface MessageEntry {
  role: "user" | "assistant";
  content: string;
  timestamp: string;
}

interface ConversationRow {
  id: string;
  messages: MessageEntry[];
}

async function buildUserContext(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  today: string
): Promise<string> {
  // Fetch active habits
  const { data: habits } = await supabase
    .from("habits")
    .select("id, name")
    .eq("user_id", userId)
    .eq("is_active", true)
    .limit(10);

  if (!habits?.length) return "User has no active habits yet.";

  // Today's completions
  const { data: todayCompletions } = await supabase
    .from("completions")
    .select("habit_id")
    .eq("user_id", userId)
    .eq("local_date", today)
    .eq("is_undone", false);

  const todayCompletedIds = new Set(
    todayCompletions?.map((c: { habit_id: string }) => c.habit_id) ?? []
  );

  const completedToday = todayCompletedIds.size;
  const totalHabits = habits.length;

  // 7-day completion rate
  const sevenDaysAgo = new Date(today);
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
  const sevenDaysAgoStr = sevenDaysAgo.toISOString().split("T")[0];

  const { data: weekCompletions } = await supabase
    .from("completions")
    .select("habit_id, local_date")
    .eq("user_id", userId)
    .eq("is_undone", false)
    .gte("local_date", sevenDaysAgoStr)
    .lt("local_date", today);

  const weekTotal = weekCompletions?.length ?? 0;
  const maxPossible = totalHabits * 7;
  const weekRate =
    maxPossible > 0 ? Math.round((weekTotal / maxPossible) * 100) : 0;

  const lines = [
    `Today (${today}): completed ${completedToday}/${totalHabits} habits.`,
    `7-day completion rate: ${weekRate}% (${weekTotal}/${maxPossible} possible).`,
    "",
    "Today's habits:",
  ];

  for (const habit of habits.slice(0, 5)) {
    const done = todayCompletedIds.has(habit.id) ? "✓" : "✗";
    lines.push(`  ${done} ${habit.name}`);
  }

  return lines.join("\n");
}

function buildSystemPrompt(displayName: string, context: string): string {
  return `You are a warm, encouraging AI habit coach for ${displayName}.

Your role in this evening reflection:
- Acknowledge what they accomplished today with genuine warmth
- Gently and non-judgmentally note any missed habits
- Identify one positive pattern from the past week
- Ask one thoughtful question about tomorrow's intentions
- Keep responses concise (2-3 sentences max)
- End with an uplifting note for tomorrow

User context:
${context}

Important: Keep responses short and conversational. This is a brief evening wind-down, not a long review session.`;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}

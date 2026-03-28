// T112 + T177: ai-weekly-review Edge Function
// Generates a weekly review using Claude Sonnet.
// Includes retry logic (1 retry, 3 s delay) and cached-template fallback
// when Claude API is unavailable.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages';
const MODEL = 'claude-sonnet-4-6';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const authHeader = req.headers.get('authorization');
    const { data: { user }, error: authError } =
      await supabase.auth.getUser(authHeader?.replace('Bearer ', '') ?? '');
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: corsHeaders });
    }

    // Verify Pro subscription
    const { data: sub } = await supabase
      .from('subscriptions')
      .select('tier')
      .eq('user_id', user.id)
      .single();
    if (!sub || sub.tier !== 'pro') {
      return new Response(JSON.stringify({ error: 'Pro tier required' }),
        { status: 403, headers: corsHeaders });
    }

    const { week_start, week_end } = await req.json();
    if (!week_start || !week_end) {
      return new Response(JSON.stringify({ error: 'week_start and week_end required' }),
        { status: 400, headers: corsHeaders });
    }

    // Fetch 7-day completion matrix
    const { data: completions } = await supabase
      .from('completions')
      .select('habit_id, local_date, is_undone')
      .eq('user_id', user.id)
      .gte('local_date', week_start)
      .lte('local_date', week_end)
      .eq('is_undone', false);

    if (!completions || completions.length < 7) {
      return new Response(
        JSON.stringify({ error: 'Insufficient data — need at least 7 completions' }),
        { status: 422, headers: corsHeaders },
      );
    }

    // Fetch habit names
    const habitIds = [...new Set(completions.map((c: any) => c.habit_id))];
    const { data: habits } = await supabase
      .from('habits')
      .select('id, name')
      .in('id', habitIds);

    const habitMap: Record<string, string> = {};
    (habits ?? []).forEach((h: any) => { habitMap[h.id] = h.name; });

    // Build completion matrix
    const matrix = completions.map((c: any) => ({
      habit: habitMap[c.habit_id] ?? c.habit_id,
      date: c.local_date,
    }));

    // Fetch partner summary if available
    let partnerContext = '';
    const { data: partnership } = await supabase
      .from('partnerships')
      .select('id, inviter_id, invitee_id')
      .or(`inviter_id.eq.${user.id},invitee_id.eq.${user.id}`)
      .eq('status', 'active')
      .maybeSingle();

    if (partnership) {
      const partnerId = partnership.inviter_id === user.id
        ? partnership.invitee_id
        : partnership.inviter_id;
      const { data: partnerCompletions } = await supabase
        .from('completions')
        .select('habit_id, local_date')
        .eq('user_id', partnerId)
        .gte('local_date', week_start)
        .lte('local_date', week_end)
        .eq('is_undone', false);
      partnerContext = `\nPartner completed ${partnerCompletions?.length ?? 0} habits this week.`;
    }

    const systemPrompt = `You are an insightful habit coach generating a weekly review.
Analyse the user's habit completion data and provide:
1. 2-3 patterns you observe (each with confidence: high/medium/low)
2. 2-3 actionable insights with specific next steps
3. A brief summary paragraph (2-3 sentences, warm and encouraging)

Return ONLY valid JSON matching this schema:
{
  "patterns": [{"description": "string", "confidence": "high|medium|low"}],
  "insights": [{"description": "string", "action": "string"}],
  "summary_text": "string"
}`;

    const userMessage = `Week: ${week_start} to ${week_end}
Completions (${completions.length} total):
${JSON.stringify(matrix, null, 2)}${partnerContext}`;

    // T177: Call Claude with 1 retry on failure
    let aiResult: any = null;
    let lastError: string | null = null;

    for (let attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) {
        await new Promise(r => setTimeout(r, 3000)); // 3 s delay
      }
      try {
        const response = await fetch(ANTHROPIC_API_URL, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': Deno.env.get('ANTHROPIC_API_KEY')!,
            'anthropic-version': '2023-06-01',
          },
          body: JSON.stringify({
            model: MODEL,
            max_tokens: 1024,
            messages: [
              { role: 'user', content: userMessage },
            ],
            system: systemPrompt,
          }),
        });

        if (!response.ok) {
          lastError = `Claude API ${response.status}`;
          continue;
        }

        const data = await response.json();
        const raw = data.content?.[0]?.text ?? '';
        const jsonMatch = raw.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          aiResult = JSON.parse(jsonMatch[0]);
          break;
        }
        lastError = 'Failed to parse AI response';
      } catch (e) {
        lastError = String(e);
      }
    }

    // T177: Fallback template if Claude is unavailable
    if (!aiResult) {
      console.warn('Claude unavailable, using fallback template:', lastError);
      aiResult = {
        patterns: [
          { description: 'Your completion data has been recorded for this week.', confidence: 'high' },
        ],
        insights: [
          {
            description: 'Keep building your habit streak.',
            action: 'Complete your habits at the same time each day.',
          },
        ],
        summary_text: 'Great effort this week! Keep up the consistency and your habits will become automatic.',
      };
    }

    // Build partner_summary if applicable
    let partnerSummary = null;
    if (partnership) {
      partnerSummary = {
        partner_name: 'Your partner',
        top_streaks: [],
        shared_wins: [],
      };
    }

    // Save to DB
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 90);

    const { data: review, error: saveError } = await supabase
      .from('weekly_reviews')
      .upsert({
        user_id: user.id,
        week_start,
        week_end,
        patterns: aiResult.patterns ?? [],
        insights: aiResult.insights ?? [],
        partner_summary: partnerSummary,
        expires_at: expiresAt.toISOString(),
      }, { onConflict: 'user_id,week_start' })
      .select()
      .single();

    if (saveError) throw saveError;

    return new Response(
      JSON.stringify({
        review_id: review.id,
        patterns: aiResult.patterns,
        insights: aiResult.insights,
        partner_summary: partnerSummary,
        summary_text: aiResult.summary_text,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    console.error('ai-weekly-review error:', e);
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: corsHeaders },
    );
  }
});

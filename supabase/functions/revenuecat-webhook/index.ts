// T129: revenuecat-webhook Edge Function
// Handles RevenueCat subscription lifecycle events.
// Auth: RevenueCat webhook secret (X-RevenueCat-Signature header), not user JWT.

import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const RC_WEBHOOK_SECRET = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");

const FREE_TIER_HABIT_LIMIT = 3;

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers":
          "authorization, content-type, x-revenuecat-signature",
      },
    });
  }

  // ── Verify RevenueCat webhook secret ─────────────────────────────────────
  if (RC_WEBHOOK_SECRET) {
    const sig = req.headers.get("X-RevenueCat-Signature");
    if (sig !== RC_WEBHOOK_SECRET) {
      return json({ error: "Unauthorized" }, 401);
    }
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const event = payload.event as Record<string, unknown> | undefined;
  if (!event) return json({ error: "Missing event" }, 400);

  const eventType = event.type as string;
  const appUserId = event.app_user_id as string | undefined;
  const revenuecatId = event.id as string | undefined;
  const expiresAt = event.expiration_at_ms
    ? new Date(event.expiration_at_ms as number).toISOString()
    : null;
  const platform = ((event.store as string) ?? "").toLowerCase().includes(
    "play"
  )
    ? "android"
    : "ios";

  if (!appUserId) return json({ error: "Missing app_user_id" }, 400);

  try {
    switch (eventType) {
      case "INITIAL_PURCHASE": {
        // Upsert subscription record and upgrade user tier to pro.
        await supabase.from("subscriptions").upsert(
          {
            user_id: appUserId,
            tier: "pro",
            status: "active",
            revenuecat_id: revenuecatId,
            platform,
            started_at: new Date().toISOString(),
            expires_at: expiresAt,
          },
          { onConflict: "user_id" }
        );
        await supabase
          .from("users")
          .update({ subscription_tier: "pro" })
          .eq("id", appUserId);
        break;
      }

      case "RENEWAL": {
        await supabase
          .from("subscriptions")
          .update({ status: "active", tier: "pro", expires_at: expiresAt })
          .eq("user_id", appUserId);
        await supabase
          .from("users")
          .update({ subscription_tier: "pro" })
          .eq("id", appUserId);
        break;
      }

      case "CANCELLATION": {
        // Cancelled — still active until expires_at.
        await supabase
          .from("subscriptions")
          .update({ status: "cancelled" })
          .eq("user_id", appUserId);
        break;
      }

      case "EXPIRATION": {
        // Downgrade to free tier.
        await supabase
          .from("subscriptions")
          .update({ status: "expired", tier: "free", expires_at: null })
          .eq("user_id", appUserId);
        await supabase
          .from("users")
          .update({ subscription_tier: "free" })
          .eq("id", appUserId);

        // Suspend active partnerships.
        await supabase
          .from("partnerships")
          .update({ status: "suspended", suspended_at: new Date().toISOString() })
          .or(`inviter_id.eq.${appUserId},invitee_id.eq.${appUserId}`)
          .eq("status", "active");

        // Deactivate habits beyond the free tier limit (keep oldest 3 active).
        const { data: habits } = await supabase
          .from("habits")
          .select("id")
          .eq("user_id", appUserId)
          .eq("is_active", true)
          .order("created_at", { ascending: true });

        if (habits && habits.length > FREE_TIER_HABIT_LIMIT) {
          const toDeactivate = habits
            .slice(FREE_TIER_HABIT_LIMIT)
            .map((h: { id: string }) => h.id);
          await supabase
            .from("habits")
            .update({ is_active: false })
            .in("id", toDeactivate);
        }
        break;
      }

      case "BILLING_ISSUE": {
        console.warn(
          `BILLING_ISSUE for user ${appUserId}: ${JSON.stringify(event)}`
        );
        // Schedule a billing-issue notification for the user.
        await supabase.from("notifications").insert({
          user_id: appUserId,
          type: "streak_at_risk", // closest available type for urgency
          content:
            "There was a billing issue with your Pro subscription. Please update your payment method to keep access.",
          scheduled_at: new Date().toISOString(),
        });
        break;
      }

      case "SUBSCRIBER_ALIAS": {
        const newAlias = event.new_app_user_id as string | undefined;
        if (newAlias) {
          await supabase
            .from("subscriptions")
            .update({ revenuecat_id: newAlias })
            .eq("user_id", appUserId);
        }
        break;
      }

      default:
        // Unknown event type — acknowledge but take no action.
        console.log(`revenuecat-webhook: unhandled event type "${eventType}"`);
    }

    return json({ received: true });
  } catch (err) {
    console.error("revenuecat-webhook error:", err);
    return json({ error: "Internal server error" }, 500);
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

// Supabase Edge Function: Cross-Venture API & Event Gateway
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { pathname } = new URL(req.url);

    // Route: GET /venture-gateway/ventures
    if (pathname.endsWith("/ventures") && req.method === "GET") {
      const { data, error } = await supabase.from("ventures").select("*").order("name");
      if (error) throw error;
      return new Response(JSON.stringify({ ventures: data }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Route: POST /venture-gateway/events
    if (pathname.endsWith("/events") && req.method === "POST") {
      const body = await req.json();
      const { data, error } = await supabase.from("ventures_events").insert(body).select();
      if (error) throw error;
      return new Response(JSON.stringify({ success: true, event: data[0] }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Route: POST /venture-gateway/veridex/match
    if (pathname.endsWith("/veridex/match") && req.method === "POST") {
      const { market_id, side, price, quantity, outcome, user_id } = await req.json();
      
      // Atomic insert of order
      const { data: order, error: orderErr } = await supabase.from("veridex_orders").insert({
        market_id,
        user_id,
        outcome,
        side,
        price,
        quantity,
        quantity_remaining: quantity,
        status: "OPEN"
      }).select().single();

      if (orderErr) throw orderErr;

      return new Response(JSON.stringify({ success: true, order }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ message: "VERIDEX & Ventures Gateway Active" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

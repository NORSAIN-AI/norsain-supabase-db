import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""  // Bruk service role for DB-tilgang
    );

    const { query_embedding } = await req.json();  // Inndata: vektor fra agent

    // Semantisk søk med pgvector (cosine similarity)
    const { data, error } = await supabase
      .rpc("match_documents", {  // Bruk RPC for custom funksjon, eller direkte query
        query_embedding: query_embedding,
        match_threshold: 0.78,  // Likhetsterskel
        match_count: 5
      });

    if (error) throw error;

    return new Response(JSON.stringify({ results: data }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400 });
  }
});

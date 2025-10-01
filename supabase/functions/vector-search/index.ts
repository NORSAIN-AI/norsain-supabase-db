// Import standard Deno HTTP server and Supabase client
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Define TypeScript interfaces for type safety
interface SearchRequest {
  query_embedding: number[]; // Vector embedding for the query (e.g., 1536 dimensions)
  match_threshold?: number; // Cosine similarity threshold (default: 0.78)
  match_count?: number; // Number of results to return (default: 5)
}

interface DocumentResult {
  id: number;
  content: string;
  similarity: number;
}

// CORS headers for cross-origin requests
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Main Edge Function handler
serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Validate request method
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed" }),
        { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse request body
    const body: SearchRequest = await req.json();
    const { query_embedding, match_threshold = 0.78, match_count = 5 } = body;

    // Validate input
    if (!query_embedding || !Array.isArray(query_embedding)) {
      return new Response(
        JSON.stringify({ error: "query_embedding must be an array" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase client with service role for database access
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Call the match_documents RPC function for vector search
    const { data, error } = await supabase
      .rpc("match_documents", {
        query_embedding,
        match_threshold,
        match_count,
      }) as { data: DocumentResult[], error: any };

    if (error) {
      throw new Error(`Database error: ${error.message}`);
    }

    // Return search results
    return new Response(
      JSON.stringify({ results: data }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    // Handle errors and return a JSON response
    return new Response(
      JSON.stringify({ error: error.message || "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

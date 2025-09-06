import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";

console.log("Generate Image function up and running!");

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const {
      prompt,
      aspectRatio = "1:1",
      model = "imagen-3.0-fast-generate-001",
      location = "us-central1",
    } = await req.json();

    if (!prompt) {
      return new Response(JSON.stringify({ error: "Prompt is required" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }

    // Get Vertex AI credentials from environment (Supabase secret)
    const vertexAICredentials = Deno.env.get("VERTEX_AI_CREDENTIALS");

    if (!vertexAICredentials) {
      return new Response(
        JSON.stringify({ error: "Vertex AI credentials not configured" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 500,
        }
      );
    }

    // Parse service account key
    const credentials = JSON.parse(vertexAICredentials);
    
    // Extract project ID from credentials
    const projectId = credentials.project_id;

    if (!projectId) {
      return new Response(
        JSON.stringify({ error: "Project ID not found in credentials" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 500,
        }
      );
    }

    // Get access token for Vertex AI
    const accessToken = await getVertexAIAccessToken(credentials);

    // Prepare Vertex AI Imagen request
    const vertexAIUrl = `https://${location}-aiplatform.googleapis.com/v1/projects/${projectId}/locations/${location}/publishers/google/models/${model}:predict`;

    const requestBody = {
      instances: [
        {
          prompt: prompt,
          parameters: {
            aspectRatio: aspectRatio,
            sampleCount: 1,
            seed: Math.floor(Math.random() * 1000000),
            safetyFilterLevel: "block_some",
            personGeneration: "allow_adult",
            includePeopleWatermark: false,
            outputMimeType: "image/png"
          },
        },
      ],
    };

    console.log("Calling Vertex AI with prompt:", prompt);

    // Call Vertex AI Imagen
    const response = await fetch(vertexAIUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("Vertex AI error:", errorText);
      return new Response(
        JSON.stringify({
          error: "Image generation failed",
          details: errorText,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: response.status,
        }
      );
    }

    const result = await response.json();
    console.log("Vertex AI response received");

    // Extract generated images
    if (result.predictions && result.predictions.length > 0) {
      const images = result.predictions.map((prediction: any) => ({
        bytesBase64Encoded: prediction.bytesBase64Encoded,
        mimeType: prediction.mimeType || "image/png",
      }));

      return new Response(
        JSON.stringify({
          success: true,
          images: images,
          prompt: prompt,
          aspectRatio: aspectRatio,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    } else {
      return new Response(JSON.stringify({ error: "No images generated" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      });
    }
  } catch (error) {
    console.error("Function error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});

// Function to get access token for Vertex AI
async function getVertexAIAccessToken(credentials: any): Promise<string> {
  const header = {
    alg: "RS256",
    typ: "JWT",
    kid: credentials.private_key_id,
  };

  const payload = {
    iss: credentials.client_email,
    scope: "https://www.googleapis.com/auth/cloud-platform",
    aud: "https://oauth2.googleapis.com/token",
    exp: Math.floor(Date.now() / 1000) + 3600,
    iat: Math.floor(Date.now() / 1000),
  };

  // Create JWT token
  const jwt = await createJWT(header, payload, credentials.private_key);

  // Exchange JWT for access token
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!tokenResponse.ok) {
    throw new Error("Failed to get access token");
  }

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

// Simple JWT creation function for Deno
async function createJWT(
  header: any,
  payload: any,
  privateKey: string
): Promise<string> {
  const headerEncoded = btoa(JSON.stringify(header))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
  const payloadEncoded = btoa(JSON.stringify(payload))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");

  const message = headerEncoded + "." + payloadEncoded;

  // Import private key
  const keyData = privateKey
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const keyBytes = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );

  // Sign the message
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(message)
  );

  const signatureEncoded = btoa(
    String.fromCharCode(...new Uint8Array(signature))
  )
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");

  return message + "." + signatureEncoded;
}

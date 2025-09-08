import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// JWT library for Google Cloud authentication
import { create, getNumericDate, Header } from "https://deno.land/x/djwt@v2.8/mod.ts"

interface VertexAIRequest {
  prompt: string;
}

interface GoogleCredentials {
  type: string;
  project_id: string;
  private_key_id: string;
  private_key: string;
  client_email: string;
  client_id: string;
  auth_uri: string;
  token_uri: string;
  auth_provider_x509_cert_url: string;
  client_x509_cert_url: string;
}

async function generateAccessToken(credentials: GoogleCredentials): Promise<string> {
  console.log('[AUTH] Generating access token for:', credentials.client_email);
  
  const header: Header = {
    alg: "RS256",
    typ: "JWT"
  };

  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: credentials.client_email,
    scope: "https://www.googleapis.com/auth/cloud-platform",
    aud: "https://oauth2.googleapis.com/token",
    exp: getNumericDate(60 * 60), // 1 hour
    iat: getNumericDate(0),
  };

  // Clean and import the private key
  const cleanPrivateKey = credentials.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");

  // Convert base64 to bytes
  const privateKeyBytes = Uint8Array.from(atob(cleanPrivateKey), c => c.charCodeAt(0));

  // Import the private key
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    privateKeyBytes,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );

  // Create and sign the JWT
  const jwt = await create(header, payload, privateKey);
  console.log('[AUTH] JWT created successfully');

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
    const error = await tokenResponse.text();
    console.error('[AUTH] Token exchange failed:', error);
    throw new Error(`Failed to get access token: ${error}`);
  }

  const tokenData = await tokenResponse.json();
  console.log('[AUTH] Access token generated successfully');
  return tokenData.access_token;
}

async function callVertexAIImageGeneration(
  accessToken: string,
  projectId: string,
  modelVersion: string,
  prompt: string
): Promise<any> {
  const location = "us-central1"; // Default location for Vertex AI
  
  const endpoint = `https://${location}-aiplatform.googleapis.com/v1/projects/${projectId}/locations/${location}/publishers/google/models/${modelVersion}:predict`;
  
  console.log('[API] Calling Vertex AI endpoint:', endpoint);
  console.log('[API] Model:', modelVersion);
  console.log('[API] Prompt:', prompt.substring(0, 100) + '...');

  // Construct the request payload for Imagen
  const payload = {
    instances: [
      {
        prompt: prompt,
      }
    ],
    parameters: {
      sampleCount: 1,
      aspectRatio: "1:1", // Default aspect ratio
      includeRaiReason: false,
    }
  };

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const error = await response.text();
    console.error('[API] Vertex AI API error:', error);
    throw new Error(`Vertex AI API error: ${response.status} - ${error}`);
  }

  const result = await response.json();
  console.log('[API] Vertex AI response received successfully');
  return result;
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    console.log('[INIT] Starting image generation request');
    
    // Parse request body
    const requestBody = await req.json() as VertexAIRequest;
    console.log('[REQUEST] Received request:', {
      prompt: requestBody.prompt?.substring(0, 100) + '...',
    });

    // Validate required parameters
    if (!requestBody.prompt || typeof requestBody.prompt !== 'string') {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Missing or invalid prompt parameter' 
        }),
        { 
          status: 400,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          }
        }
      );
    }

    // Get Supabase environment variables
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    
    // Get secrets from Supabase environment
    const vertexCredentials = Deno.env.get('VERTEX_AI_CREDENTIALS');
    const imagenModel = Deno.env.get('IMAGEN_MODEL');

    if (!vertexCredentials) {
      console.error('[SECRETS] VERTEX_AI_CREDENTIALS not found in environment');
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Vertex AI credentials not configured' 
        }),
        { 
          status: 500,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          }
        }
      );
    }

    if (!imagenModel) {
      console.error('[SECRETS] IMAGEN_MODEL not found in environment');
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Imagen model not configured' 
        }),
        { 
          status: 500,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          }
        }
      );
    }

    console.log('[SECRETS] Using model:', imagenModel);

    // Parse the credentials JSON
    let credentials: GoogleCredentials;
    try {
      credentials = JSON.parse(vertexCredentials);
      console.log('[SECRETS] Credentials parsed successfully for project:', credentials.project_id);
    } catch (parseError) {
      console.error('[SECRETS] Failed to parse credentials JSON:', parseError);
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Invalid credentials format' 
        }),
        { 
          status: 500,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          }
        }
      );
    }

    // Generate access token
    const accessToken = await generateAccessToken(credentials);

    // Call Vertex AI
    const result = await callVertexAIImageGeneration(
      accessToken,
      credentials.project_id,
      imagenModel,
      requestBody.prompt
    );

    console.log('[SUCCESS] Image generation completed successfully');

    return new Response(
      JSON.stringify({
        success: true,
        data: result,
        metadata: {
          model: imagenModel,
          prompt: requestBody.prompt,
          timestamp: new Date().toISOString()
        }
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );

  } catch (error) {
    console.error('[ERROR] Image generation failed:', error);
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Internal server error',
        timestamp: new Date().toISOString()
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );
  }
});
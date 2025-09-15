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
  
  // Use the newer generateImages endpoint for Imagen 4.0
  const endpoint = `https://${location}-aiplatform.googleapis.com/v1/projects/${projectId}/locations/${location}/publishers/google/models/${modelVersion}:generateImages`;
  
  console.log('[API] Calling Vertex AI endpoint:', endpoint);
  console.log('[API] Model:', modelVersion);
  console.log('[API] Prompt:', prompt.substring(0, 100) + '...');

  // Updated payload for Imagen 4.0 generateImages endpoint
  const payload = {
    instances: [
      {
        prompt: prompt
      }
    ],
    parameters: {
      sampleCount: 1,
      aspectRatio: "1:1",
      safetyFilterLevel: "block_some",
      personGeneration: "dont_allow"
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
    console.error('[API] Vertex AI API error status:', response.status);
    console.error('[API] Vertex AI API error details:', error);
    console.error('[API] Request payload was:', JSON.stringify(payload, null, 2));
    throw new Error(`Vertex AI API error: ${response.status} - ${error}`);
  }

  const result = await response.json();
  console.log('[API] Vertex AI response received successfully');
  console.log('[API] Response structure:', JSON.stringify(result, null, 2));
  return result;
}

serve(async (req: Request) => {
  // Handle CORS preflight
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

  // Only allow POST requests - ensures function only triggers on button click
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: 'Method not allowed. Only POST requests are accepted.' 
      }),
      { 
        status: 405,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        }
      }
    );
  }

  try {
    console.log('[INIT] Image generation request received from user action');
    console.log('[INIT] Request method:', req.method);
    console.log('[INIT] Request URL:', req.url);
    
    // Parse request body
    const requestBody = await req.json() as VertexAIRequest;
    console.log('[REQUEST] Received request:', {
      prompt: requestBody.prompt?.substring(0, 100) + '...',
      promptLength: requestBody.prompt?.length || 0,
    });

    // Strict validation - ensures this only runs with valid user input
    if (!requestBody.prompt || typeof requestBody.prompt !== 'string') {
      console.log('[VALIDATION] Invalid prompt - rejecting request');
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

    // Additional validation - prompt must be meaningful
    if (requestBody.prompt.trim().length < 3) {
      console.log('[VALIDATION] Prompt too short - rejecting request');
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Prompt must be at least 3 characters long' 
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
    
    // Use Imagen 4.0 directly (no need for environment variable)
    const imagenModel = 'imagen-4.0-generate-001';

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

    console.log('[MODEL] Using Imagen model:', imagenModel);

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
    console.error('[ERROR] Error type:', typeof error);
    console.error('[ERROR] Error details:', error instanceof Error ? error.message : String(error));
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Internal server error',
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
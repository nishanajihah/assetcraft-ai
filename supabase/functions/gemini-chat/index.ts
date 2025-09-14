import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.15.0";
import { corsHeaders } from "../_shared/cors.ts";

console.log("Gemini Chat function loaded");

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("[INIT] Starting chat request");

    // Parse request body
    const { message, context } = await req.json();
    console.log("[REQUEST] Received request:", {
      message: message?.substring(0, 100) + "...",
      context: context,
    });

    // Validate required parameters
    if (!message || typeof message !== "string") {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Missing or invalid message parameter",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get Gemini API key from environment
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiApiKey) {
      console.error("[ERROR] GEMINI_API_KEY not found in environment");
      return new Response(
        JSON.stringify({
          success: false,
          error: "Gemini API key not configured",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Initialize Gemini AI with forced 1.5-flash model
    const genAI = new GoogleGenerativeAI(geminiApiKey);
    const model = genAI.getGenerativeModel({
      model: "gemini-1.5-flash", // Force use of Gemini 1.5 Flash
      generationConfig: {
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 512,
      },
    });

    console.log("[AI] Using model: gemini-1.5-flash");

    // Create context-aware chat prompt
    let systemPrompt = "";
    if (context === "assetcraft_ai_assistant") {
      systemPrompt = `You are AssetCraft AI Assistant, a helpful AI companion for the AssetCraft AI app. This app helps users generate digital assets and artwork using AI.

Your role:
- Help users with the AssetCraft AI app
- Provide guidance on creating better prompts for image generation
- Assist with app features and functionality
- Be friendly, helpful, and concise
- Keep responses under 150 words

User message: "${message}"

Response:`;
    } else {
      systemPrompt = `You are a helpful AI assistant. Please respond to this message in a friendly and helpful way: ${message}`;
    }

    // Generate chat response
    console.log("[AI] Generating chat response...");
    const result = await model.generateContent(systemPrompt);
    const response = await result.response;
    const chatResponse = response.text().trim();

    console.log("[SUCCESS] Chat response generated successfully");
    console.log("[RESPONSE] Response length:", chatResponse.length);

    return new Response(
      JSON.stringify({
        success: true,
        response: chatResponse,
        context: context,
        model_used: "gemini-1.5-flash",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[ERROR] Chat failed:", error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || "Failed to generate chat response",
        model_used: "gemini-1.5-flash",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

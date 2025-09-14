import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.15.0";
import { corsHeaders } from "../_shared/cors.ts";

console.log("Gemini Generate Suggestions function loaded");

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("[INIT] Starting suggestions generation request");

    // Parse request body
    const { asset_type, style, theme, count = 5 } = await req.json();
    console.log("[REQUEST] Received request:", {
      asset_type,
      style,
      theme,
      count,
    });

    // Validate required parameters
    if (!asset_type || typeof asset_type !== "string") {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Missing or invalid asset_type parameter",
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
        temperature: 0.8,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 512,
      },
    });

    console.log("[AI] Using model: gemini-1.5-flash");

    // Create suggestions prompt
    const systemPrompt = `You are an AI assistant helping users generate creative prompts for AI image generation.

Generate ${count} creative and detailed prompt suggestions for creating ${asset_type} assets.

Additional context:
- Asset type: ${asset_type}
- Style preference: ${style || "any style"}
- Theme/color: ${theme || "any theme"}

Requirements:
- Each suggestion should be a complete, detailed prompt suitable for AI image generation
- Include visual details like colors, lighting, composition, and artistic style
- Make each suggestion unique and creative
- Keep each suggestion between 10-30 words
- Focus on ${asset_type} assets specifically

Please return exactly ${count} suggestions as a JSON array of strings.

Example format:
["suggestion 1", "suggestion 2", "suggestion 3"]

Suggestions:`;

    // Generate suggestions
    console.log("[AI] Generating suggestions...");
    const result = await model.generateContent(systemPrompt);
    const response = await result.response;
    const suggestionsText = response.text().trim();

    console.log("[AI] Raw response:", suggestionsText);

    // Try to parse as JSON array
    let suggestions = [];
    try {
      // Look for JSON array in the response
      const jsonMatch = suggestionsText.match(/\[.*\]/s);
      if (jsonMatch) {
        suggestions = JSON.parse(jsonMatch[0]);
      } else {
        // Fallback: split by lines and clean up
        suggestions = suggestionsText
          .split("\n")
          .map((line) => line.trim())
          .filter(
            (line) =>
              line.length > 0 && !line.startsWith("[") && !line.startsWith("]")
          )
          .map((line) =>
            line.replace(/^["\-\*\d\.]+\s*/, "").replace(/["]+$/, "")
          )
          .filter((line) => line.length > 5)
          .slice(0, count);
      }
    } catch (parseError) {
      console.log(
        "[FALLBACK] Using line-by-line parsing due to JSON parse error"
      );
      suggestions = suggestionsText
        .split("\n")
        .map((line) => line.trim())
        .filter(
          (line) =>
            line.length > 0 && !line.startsWith("[") && !line.startsWith("]")
        )
        .map((line) =>
          line.replace(/^["\-\*\d\.]+\s*/, "").replace(/["]+$/, "")
        )
        .filter((line) => line.length > 5)
        .slice(0, count);
    }

    // Ensure we have valid suggestions
    if (!Array.isArray(suggestions) || suggestions.length === 0) {
      throw new Error("Failed to generate valid suggestions");
    }

    console.log("[SUCCESS] Generated", suggestions.length, "suggestions");

    return new Response(
      JSON.stringify({
        success: true,
        suggestions: suggestions,
        asset_type,
        style,
        theme,
        model_used: "gemini-1.5-flash",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[ERROR] Suggestions generation failed:", error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || "Failed to generate suggestions",
        model_used: "gemini-1.5-flash",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

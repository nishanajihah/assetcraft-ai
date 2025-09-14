import { GoogleGenerativeAI } from 'https://esm.sh/@google/generative-ai@0.15.0'
import { corsHeaders } from '../_shared/cors.ts'

console.log('Gemini Enhance Prompt function loaded')

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('[INIT] Starting prompt enhancement request')
    
    // Parse request body
    const { prompt, task } = await req.json()
    console.log('[REQUEST] Received request:', {
      prompt: prompt?.substring(0, 100) + '...',
      task: task,
    })

    // Validate required parameters
    if (!prompt || typeof prompt !== 'string') {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Missing or invalid prompt parameter' 
        }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Get Gemini API key from environment
    const geminiApiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiApiKey) {
      console.error('[ERROR] GEMINI_API_KEY not found in environment')
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Gemini API key not configured' 
        }),
        { 
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Initialize Gemini AI with forced 1.5-flash model
    const genAI = new GoogleGenerativeAI(geminiApiKey)
    const model = genAI.getGenerativeModel({ 
      model: "gemini-1.5-flash",  // Force use of Gemini 1.5 Flash
      generationConfig: {
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      }
    })

    console.log('[AI] Using model: gemini-1.5-flash')

    // Create enhancement prompt based on task
    let systemPrompt = ''
    if (task === 'enhance_for_image_generation') {
      systemPrompt = `You are an expert prompt engineer for AI image generation. Your task is to enhance the given prompt to create more detailed, specific, and visually compelling descriptions while maintaining the original intent.

Guidelines:
- Add specific visual details (colors, lighting, textures, composition)
- Include artistic style references when appropriate
- Enhance with descriptive adjectives that improve image quality
- Keep the enhanced prompt under 200 words
- Maintain the original concept and intent
- Make it suitable for AI image generation models

Original prompt: "${prompt}"

Enhanced prompt:`
    } else {
      systemPrompt = `Enhance this prompt to be more detailed and specific: ${prompt}`
    }

    // Generate enhanced prompt
    console.log('[AI] Generating enhanced prompt...')
    const result = await model.generateContent(systemPrompt)
    const response = await result.response
    const enhancedPrompt = response.text().trim()

    console.log('[SUCCESS] Enhanced prompt generated successfully')
    console.log('[RESPONSE] Enhanced prompt length:', enhancedPrompt.length)

    return new Response(
      JSON.stringify({
        success: true,
        enhanced_prompt: enhancedPrompt,
        original_prompt: prompt,
        model_used: 'gemini-1.5-flash',
        task: task
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('[ERROR] Prompt enhancement failed:', error)
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Failed to enhance prompt',
        model_used: 'gemini-1.5-flash'
      }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

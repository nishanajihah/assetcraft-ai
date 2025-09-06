import 'package:supabase_flutter/supabase_flutter.dart';

class ImageGenerationService {
  static Future<Map<String, dynamic>?> generateImage({
    required String prompt,
    String aspectRatio = "1:1",
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'generate-image', // The name of your deployed function
        body: {'prompt': prompt, 'aspectRatio': aspectRatio},
      );

      // The function's response is in response.data
      print('Function response: ${response.data}');
      return response.data;
    } catch (e) {
      // Handle any errors
      print('An error occurred: $e');
      return null;
    }
  }
}

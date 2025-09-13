// Example: How to call the generate-image Edge Function from Flutter

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:typed_data';

class ImageGenerationExample extends StatefulWidget {
  const ImageGenerationExample({super.key});

  @override
  State<ImageGenerationExample> createState() => _ImageGenerationExampleState();
}

class _ImageGenerationExampleState extends State<ImageGenerationExample> {
  final _supabase = Supabase.instance.client;
  bool _isGenerating = false;
  Uint8List? _generatedImage;
  String? _error;

  Future<void> _generateImage() async {
    setState(() {
      _isGenerating = true;
      _error = null;
      _generatedImage = null;
    });

    try {
      // Call the Supabase Edge Function
      final response = await _supabase.functions.invoke(
        'generate-image',
        body: {
          'prompt': 'A beautiful sunset over mountains',
          'aspectRatio': '1:1',
          'model': 'imagen-3.0-generate-001',
        },
      );

      if (response.status == 200) {
        final data = response.data;

        if (data['success'] == true) {
          // Get the first generated image
          final images = data['images'] as List<dynamic>;
          if (images.isNotEmpty) {
            final base64String = images[0]['bytesBase64Encoded'] as String;

            // Decode base64 to bytes
            final imageBytes = base64Decode(base64String);

            setState(() {
              _generatedImage = imageBytes;
            });
          }
        } else {
          setState(() {
            _error = data['error'] ?? 'Generation failed';
          });
        }
      } else {
        setState(() {
          _error = 'HTTP Error: ${response.status}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Generation Test')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateImage,
              child: _isGenerating
                  ? Text('Generating...')
                  : Text('Generate Image'),
            ),

            SizedBox(height: 20),

            if (_isGenerating) CircularProgressIndicator(),

            if (_error != null)
              Text('Error: $_error', style: TextStyle(color: Colors.red)),

            if (_generatedImage != null)
              Expanded(child: Image.memory(_generatedImage!)),
          ],
        ),
      ),
    );
  }
}

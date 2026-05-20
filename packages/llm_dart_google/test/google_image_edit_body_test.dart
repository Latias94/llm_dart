import 'dart:convert';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_google/src/google_image_edit_body.dart';
import 'package:llm_dart_google/src/google_image_editing.dart';
import 'package:llm_dart_google/src/google_image_options.dart';
import 'package:llm_dart_google/src/google_model_settings.dart';
import 'package:llm_dart_google/src/google_safety_settings.dart';
import 'package:test/test.dart';

void main() {
  group('Google image edit body projection', () {
    test('maps inline and URI image inputs to Gemini body parts', () {
      final body = buildGoogleGeminiImageEditRequestBody(
        GoogleImageEditRequest(
          prompt: 'Blend these images.',
          images: [
            const GoogleImageEditInput.bytes(
              [1, 2, 3],
              mediaType: 'image/png',
            ),
            GoogleImageEditInput.uri(
              Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/files/image',
              ),
            ),
          ],
          aspectRatio: '3:4',
          seed: 123,
          callOptions: const CallOptions(
            providerOptions: GoogleImageOptions(
              aspectRatio: GoogleImageAspectRatio.square1x1,
            ),
          ),
        ),
        options: const GoogleImageOptions(
          aspectRatio: GoogleImageAspectRatio.square1x1,
        ),
        settings: const GoogleImageModelSettings(
          safetySettings: [
            GoogleSafetySetting(
              category: GoogleHarmCategory.harassment,
              threshold: GoogleHarmBlockThreshold.blockOnlyHigh,
            ),
          ],
        ),
      );

      expect(
        body,
        {
          'contents': [
            {
              'parts': [
                {
                  'text': 'Blend these images.',
                },
                {
                  'inlineData': {
                    'mimeType': 'image/png',
                    'data': base64Encode([1, 2, 3]),
                  },
                },
                {
                  'fileData': {
                    'mimeType': 'image/*',
                    'fileUri':
                        'https://generativelanguage.googleapis.com/v1beta/files/image',
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'responseModalities': ['TEXT', 'IMAGE'],
            'imageConfig': {
              'aspectRatio': '3:4',
            },
            'seed': 123,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_ONLY_HIGH',
            },
          ],
        },
      );
    });
  });
}

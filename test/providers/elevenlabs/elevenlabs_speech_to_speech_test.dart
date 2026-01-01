import 'dart:convert';

import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('ElevenLabs Speech-to-speech', () {
    test('SpeechToSpeechRequest builds multipart form data + query params', () {
      final req = SpeechToSpeechRequest(
        audioData: const [1, 2, 3],
        voiceId: 'voice_123',
        modelId: 'model_abc',
        voiceSettings: const {'stability': 0.5},
        seed: 7,
        removeBackgroundNoise: true,
        fileFormat: 'other',
        enableLogging: false,
        optimizeStreamingLatency: 3,
        outputFormat: 'mp3_44100_128',
        filename: 'in.mp3',
      );

      final form = req.toFormData();

      expect(form.files, hasLength(1));
      expect(form.files.single.key, equals('audio'));
      expect(form.files.single.value.filename, equals('in.mp3'));

      final fields = {for (final e in form.fields) e.key: e.value};
      expect(fields['model_id'], equals('model_abc'));
      expect(jsonDecode(fields['voice_settings']!), equals({'stability': 0.5}));
      expect(fields['seed'], equals('7'));
      expect(fields['remove_background_noise'], equals('true'));
      expect(fields['file_format'], equals('other'));

      final qp = req.toQueryParams();
      expect(qp['enable_logging'], equals('false'));
      expect(qp['optimize_streaming_latency'], equals('3'));
      expect(qp['output_format'], equals('mp3_44100_128'));
    });
  });
}

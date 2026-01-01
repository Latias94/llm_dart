import 'package:test/test.dart';
import 'package:llm_dart_elevenlabs/forced_alignment.dart';

void main() {
  group('ElevenLabs Forced Alignment', () {
    test('ForcedAlignmentRequest builds multipart form data', () {
      final req = ForcedAlignmentRequest(
        audioData: const [1, 2, 3],
        text: 'hello',
        enabledSpooledFile: true,
        filename: 'a.mp3',
      );

      final form = req.toFormData();

      expect(form.fields.map((e) => e.key), contains('text'));
      expect(form.fields.map((e) => e.key), contains('enabled_spooled_file'));

      expect(form.files, hasLength(1));
      expect(form.files.single.key, equals('file'));
      expect(form.files.single.value.filename, equals('a.mp3'));
    });

    test('ForcedAlignmentResponse parses response shape', () {
      final json = {
        'characters': [
          {'text': 'h', 'start': 0.0, 'end': 0.1},
        ],
        'words': [
          {'text': 'hello', 'start': 0.0, 'end': 0.5, 'loss': 0.2},
        ],
        'loss': 0.42,
      };

      final res = ForcedAlignmentResponse.fromJson(json);
      expect(res.loss, closeTo(0.42, 1e-9));
      expect(res.characters, hasLength(1));
      expect(res.words, hasLength(1));
      expect(res.characters.single.text, equals('h'));
      expect(res.words.single.text, equals('hello'));
    });
  });
}

import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';
import 'package:test/test.dart';

void main() {
  test('public API smoke', () {
    expect(registerElevenLabsProvider, isNotNull);
    expect(createElevenLabs, isNotNull);
    expect(elevenlabs, isNotNull);
  });
}

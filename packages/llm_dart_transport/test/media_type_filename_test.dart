import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  test('MediaTypeFilename normalizes content-type parameters', () {
    expect(
      MediaTypeFilename.normalize(' Audio/MPEG ; charset=utf-8'),
      'audio/mpeg',
    );
  });

  test('MediaTypeFilename maps allowed media types to extensions', () {
    expect(
      MediaTypeFilename.build(
        basename: 'audio',
        mediaType: 'audio/x-wav; codecs=1',
        extensionsByMediaType: const {
          'audio/mpeg': 'mp3',
          'audio/x-wav': 'wav',
        },
      ),
      'audio.wav',
    );
  });

  test('MediaTypeFilename uses fallback for unknown media types', () {
    expect(
      MediaTypeFilename.build(
        basename: 'file',
        mediaType: 'application/custom',
        extensionsByMediaType: const {
          'image/png': 'png',
        },
      ),
      'file.bin',
    );
  });
}

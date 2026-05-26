import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic;
import 'package:test/test.dart';

void main() {
  group('Anthropic package entrypoint', () {
    test('exposes short provider factory without the root package', () {
      final provider = anthropic.anthropic(apiKey: 'test-key');
      final model = provider.chatModel('claude-sonnet-4-5');

      expect(provider, isA<anthropic.Anthropic>());
      expect(provider.providerDescriptor.providerId, 'anthropic');
      expect(
          provider.specification.supportsModelFacet(
            anthropic.ProviderModelFacet.language,
          ),
          isTrue);
      expect(model.providerId, 'anthropic');
      expect(model.modelId, 'claude-sonnet-4-5');
    });

    test('exposes Anthropic files public types', () {
      const upload = anthropic.AnthropicFileUpload(
        bytes: [1, 2, 3],
        filename: 'notes.txt',
        mediaType: 'text/plain',
      );
      const deleted = anthropic.AnthropicFileDeleteResponse(
        id: 'file_123',
        deleted: true,
      );

      expect(upload.filename, 'notes.txt');
      expect(deleted.toJson(), {
        'id': 'file_123',
        'deleted': true,
      });
      expect(
        anthropic.AnthropicFileDescriptor.fromJson(
          {
            'id': 'file_123',
            'type': 'file',
            'filename': 'notes.txt',
            'mime_type': 'text/plain',
            'size_bytes': 3,
            'created_at': '2026-03-29T10:00:00Z',
            'downloadable': true,
          },
        ).filename,
        'notes.txt',
      );
    });
  });
}

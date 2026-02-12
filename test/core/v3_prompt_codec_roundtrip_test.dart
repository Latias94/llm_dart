import 'dart:typed_data';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('v3 prompt codec: round-trip', () {
    test('encode -> decode -> encode is stable (bytes encoding)', () {
      final prompt = Prompt(
        messages: [
          PromptMessage.system('You are a helpful assistant.'),
          PromptMessage(
            role: PromptRole.user,
            parts: const [
              TextPart('hi'),
              FilePart(
                mime: FileMime.pdf,
                data: [0, 1, 2, 255],
                text: 'see attached',
              ),
            ],
            providerOptions: const {
              'openai': {'store': false}
            },
          ),
          PromptMessage(
            role: PromptRole.assistant,
            parts: [
              const TextPart('ok'),
              ToolCallPart.fromToolCall(
                const ToolCall(
                  id: 'call_1',
                  callType: 'function',
                  function: FunctionCall(
                    name: 'search',
                    arguments: '{"q":"dart"}',
                  ),
                  providerOptions: {
                    'xai': {'mode': 'fast'}
                  },
                ),
              ),
              const FileUrlPart(
                mime: FileMime('image/png'),
                url: 'https://example.com/image.png',
              ),
              ImagePart(
                mime: ImageMime.png,
                data: Uint8List.fromList([1, 2, 3]),
              ),
            ],
          ),
          PromptMessage(
            role: PromptRole.tool,
            parts: const [
              ToolResultPart(
                'call_1',
                'search',
                ToolResultJsonOutput({'ok': true}),
              ),
            ],
          ),
        ],
      );

      final encoded = encodeV3Prompt(
        prompt,
        dataEncoding: V3PromptDataEncoding.bytes,
      );
      final decoded = decodeV3Prompt(encoded);
      final encoded2 = encodeV3Prompt(
        decoded,
        dataEncoding: V3PromptDataEncoding.bytes,
      );

      expect(encoded2, encoded);
    });
  });
}

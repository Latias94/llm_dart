import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/openai.dart';
import 'package:llm_dart_openai_compatible/responses.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

void main() {
  group('OpenAI Responses Prompt IR request body', () {
    test('groups multi-part user message into a single input entry', () async {
      final config = OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.com',
        model: 'gpt-4o-mini',
        useResponsesAPI: true,
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = {
          'id': 'resp_1',
          'status': 'completed',
          'output': [
            {
              'type': 'message',
              'role': 'assistant',
              'content': [
                {'type': 'output_text', 'text': 'ok'}
              ],
            }
          ],
        };
      final responses = OpenAIResponses(client, config);

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: PromptRole.user,
            parts: [
              const TextPart('Describe this image:'),
              ImagePart(
                mime: ImageMime.png,
                data: const [1, 2, 3],
                text: 'A small icon.',
              ),
            ],
          ),
        ],
      );

      await responses.chatPrompt(prompt);

      final input = client.lastJsonBody?['input'] as List?;
      expect(input, isNotNull);
      expect(input, hasLength(1));

      final user = input!.single as Map;
      expect(user['role'], equals('user'));

      final content = user['content'] as List;
      expect(content, hasLength(3));

      expect(
        content[0],
        equals({'type': 'input_text', 'text': 'Describe this image:'}),
      );
      expect(
          content[1], equals({'type': 'input_text', 'text': 'A small icon.'}));

      final expectedDataUrl =
          'data:image/png;base64,${base64Encode([1, 2, 3])}';
      expect(
        content[2],
        equals({'type': 'input_image', 'image_url': expectedDataUrl}),
      );
    });

    test('splits ToolResultPart into function_call_output input items',
        () async {
      final config = OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.com',
        model: 'gpt-4o-mini',
        useResponsesAPI: true,
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = {
          'id': 'resp_1',
          'status': 'completed',
          'output': [
            {
              'type': 'message',
              'role': 'assistant',
              'content': [
                {'type': 'output_text', 'text': 'ok'}
              ],
            }
          ],
        };
      final responses = OpenAIResponses(client, config);

      final toolResult = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(
          name: 'get_weather',
          arguments: '{"temp":25}',
        ),
      );

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: PromptRole.user,
            parts: [
              const TextPart('Before'),
              ToolResultPart.fromToolCall(
                toolResult,
                overrideRole: PromptRole.tool,
              ),
              const TextPart('After'),
            ],
          ),
        ],
      );

      await responses.chatPrompt(prompt);

      final input = client.lastJsonBody?['input'] as List?;
      expect(input, isNotNull);
      expect(input, hasLength(3));

      expect(
        input![0],
        equals({
          'role': 'user',
          'content': [
            {'type': 'input_text', 'text': 'Before'}
          ],
        }),
      );
      expect(
          input[1],
          equals({
            'type': 'function_call_output',
            'call_id': 'call_1',
            'output': '{"temp":25}'
          }));
      expect(
        input[2],
        equals({
          'role': 'user',
          'content': [
            {'type': 'input_text', 'text': 'After'}
          ],
        }),
      );
    });

    test('encodes PDF FilePart as input_file with data URL (AI SDK parity)',
        () async {
      final config = OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.com',
        model: 'gpt-4o-mini',
        useResponsesAPI: true,
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = {
          'id': 'resp_1',
          'status': 'completed',
          'output': [
            {
              'type': 'message',
              'role': 'assistant',
              'content': [
                {'type': 'output_text', 'text': 'ok'}
              ],
            }
          ],
        };
      final responses = OpenAIResponses(client, config);

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: PromptRole.user,
            parts: const [
              FilePart(mime: FileMime.pdf, data: [1, 2, 3]),
            ],
          ),
        ],
      );

      await responses.chatPrompt(prompt);

      final input = client.lastJsonBody?['input'] as List?;
      expect(input, isNotNull);
      expect(input, hasLength(1));

      final user = input!.single as Map;
      expect(user['role'], equals('user'));
      final content = user['content'] as List;
      expect(content, hasLength(1));

      expect(
        content.single,
        equals({
          'type': 'input_file',
          'filename': 'document.pdf',
          'file_data': 'data:application/pdf;base64,${base64Encode([1, 2, 3])}',
        }),
      );
    });

    test('encodes PDF FileUrlPart as input_file with file_url (AI SDK parity)',
        () async {
      final config = OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.com',
        model: 'gpt-4o-mini',
        useResponsesAPI: true,
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = {
          'id': 'resp_1',
          'status': 'completed',
          'output': [
            {
              'type': 'message',
              'role': 'assistant',
              'content': [
                {'type': 'output_text', 'text': 'ok'}
              ],
            }
          ],
        };
      final responses = OpenAIResponses(client, config);

      final prompt = Prompt(
        messages: [
          const PromptMessage(
            role: PromptRole.user,
            parts: [
              FileUrlPart(
                mime: FileMime.pdf,
                url: ' https://example.com/a.pdf ',
              ),
            ],
          ),
        ],
      );

      await responses.chatPrompt(prompt);

      final input = client.lastJsonBody?['input'] as List?;
      expect(input, isNotNull);
      expect(input, hasLength(1));

      final user = input!.single as Map;
      expect(user['role'], equals('user'));
      final content = user['content'] as List;
      expect(content, hasLength(1));

      expect(
        content.single,
        equals({
          'type': 'input_file',
          'file_url': 'https://example.com/a.pdf',
        }),
      );
    });

    test('encodes PDF FileIdPart as input_file with file_id (AI SDK parity)',
        () async {
      final config = OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.com',
        model: 'gpt-4o-mini',
        useResponsesAPI: true,
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = {
          'id': 'resp_1',
          'status': 'completed',
          'output': [
            {
              'type': 'message',
              'role': 'assistant',
              'content': [
                {'type': 'output_text', 'text': 'ok'}
              ],
            }
          ],
        };
      final responses = OpenAIResponses(client, config);

      final prompt = Prompt(
        messages: [
          const PromptMessage(
            role: PromptRole.user,
            parts: [
              FileIdPart(
                mime: FileMime.pdf,
                id: 'file-abc',
              ),
            ],
          ),
        ],
      );

      await responses.chatPrompt(prompt);

      final input = client.lastJsonBody?['input'] as List?;
      expect(input, isNotNull);
      expect(input, hasLength(1));

      final user = input!.single as Map;
      expect(user['role'], equals('user'));
      final content = user['content'] as List;
      expect(content, hasLength(1));

      expect(
        content.single,
        equals({
          'type': 'input_file',
          'file_id': 'file-abc',
        }),
      );
    });

    test('encodes image FileIdPart as input_image with file_id (AI SDK parity)',
        () async {
      final config = OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.com',
        model: 'gpt-4o-mini',
        useResponsesAPI: true,
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = {
          'id': 'resp_1',
          'status': 'completed',
          'output': [
            {
              'type': 'message',
              'role': 'assistant',
              'content': [
                {'type': 'output_text', 'text': 'ok'}
              ],
            }
          ],
        };
      final responses = OpenAIResponses(client, config);

      final prompt = Prompt(
        messages: [
          const PromptMessage(
            role: PromptRole.user,
            parts: [
              FileIdPart(
                mime: FileMime.png,
                id: 'file-img',
              ),
            ],
          ),
        ],
      );

      await responses.chatPrompt(prompt);

      final input = client.lastJsonBody?['input'] as List?;
      expect(input, isNotNull);
      expect(input, hasLength(1));

      final user = input!.single as Map;
      expect(user['role'], equals('user'));
      final content = user['content'] as List;
      expect(content, hasLength(1));

      expect(
        content.single,
        equals({
          'type': 'input_image',
          'file_id': 'file-img',
        }),
      );
    });
  });
}

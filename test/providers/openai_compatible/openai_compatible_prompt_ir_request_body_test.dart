import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

void main() {
  group('OpenAI-compatible Prompt IR request body', () {
    test('groups multi-part user message into a single wire message', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'openai',
        providerName: 'OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://example.com',
        model: 'gpt-4o-mini',
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = {
          'choices': [
            {
              'message': {'role': 'assistant', 'content': 'ok'}
            }
          ],
        };
      final chat = OpenAIChat(client, config);

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: ChatRole.user,
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

      await chat.chatPrompt(prompt);

      final messages = client.lastJsonBody?['messages'] as List?;
      expect(messages, isNotNull);
      expect(messages, hasLength(1));

      final user = messages!.single as Map;
      expect(user['role'], equals('user'));

      final content = user['content'] as List;
      expect(content, hasLength(3));

      expect(
          content[0], equals({'type': 'text', 'text': 'Describe this image:'}));
      expect(content[1], equals({'type': 'text', 'text': 'A small icon.'}));

      final expectedDataUrl =
          'data:image/png;base64,${base64Encode([1, 2, 3])}';
      expect(
        content[2],
        equals({
          'type': 'image_url',
          'image_url': {'url': expectedDataUrl},
        }),
      );
    });

    test('inserts config.systemPrompt when prompt has no system message',
        () async {
      final config = OpenAICompatibleConfig(
        providerId: 'openai',
        providerName: 'OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://example.com',
        model: 'gpt-4o-mini',
        systemPrompt: 'You are concise.',
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = {
          'choices': [
            {
              'message': {'role': 'assistant', 'content': 'ok'}
            }
          ],
        };
      final chat = OpenAIChat(client, config);

      await chat.chatPrompt(
        const Prompt(
          messages: [
            PromptMessage(role: ChatRole.user, parts: [TextPart('Hi')]),
          ],
        ),
      );

      final messages = client.lastJsonBody?['messages'] as List?;
      expect(messages, isNotNull);
      expect(messages, hasLength(2));
      expect(messages![0],
          equals({'role': 'system', 'content': 'You are concise.'}));
      expect(messages[1], equals({'role': 'user', 'content': 'Hi'}));
    });

    test('splits ToolResultPart into tool-role messages (order-preserving)',
        () async {
      final config = OpenAICompatibleConfig(
        providerId: 'openai',
        providerName: 'OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://example.com',
        model: 'gpt-4o-mini',
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = {
          'choices': [
            {
              'message': {'role': 'assistant', 'content': 'ok'}
            }
          ],
        };
      final chat = OpenAIChat(client, config);

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
            role: ChatRole.user,
            parts: [
              const TextPart('Before'),
              ToolResultPart(toolResult),
              const TextPart('After'),
            ],
          ),
        ],
      );

      await chat.chatPrompt(prompt);

      final messages = client.lastJsonBody?['messages'] as List?;
      expect(messages, isNotNull);
      expect(messages, hasLength(3));

      expect(messages![0], equals({'role': 'user', 'content': 'Before'}));
      expect(
          messages[1],
          equals({
            'role': 'tool',
            'tool_call_id': 'call_1',
            'content': '{"temp":25}'
          }));
      expect(messages[2], equals({'role': 'user', 'content': 'After'}));
    });

    test('collects ToolCallPart into assistant tool_calls', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'openai',
        providerName: 'OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://example.com',
        model: 'gpt-4o-mini',
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = {
          'choices': [
            {
              'message': {'role': 'assistant', 'content': 'ok'}
            }
          ],
        };
      final chat = OpenAIChat(client, config);

      final call1 = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(
          name: 'get_weather',
          arguments: '{"city":"Tokyo"}',
        ),
      );
      final call2 = ToolCall(
        id: 'call_2',
        callType: 'function',
        function: const FunctionCall(
          name: 'get_time',
          arguments: '{"tz":"Asia/Tokyo"}',
        ),
      );

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: ChatRole.assistant,
            parts: [
              const TextPart('Calling tools...'),
              ToolCallPart(call1),
              ToolCallPart(call2),
            ],
          ),
        ],
      );

      await chat.chatPrompt(prompt);

      final messages = client.lastJsonBody?['messages'] as List?;
      expect(messages, isNotNull);
      expect(messages, hasLength(1));

      final assistant = messages!.single as Map;
      expect(assistant['role'], equals('assistant'));
      expect(
        assistant['content'],
        equals([
          {'type': 'text', 'text': 'Calling tools...'},
        ]),
      );
      expect(
        assistant['tool_calls'],
        equals([
          call1.toJson(),
          call2.toJson(),
        ]),
      );
    });
  });
}

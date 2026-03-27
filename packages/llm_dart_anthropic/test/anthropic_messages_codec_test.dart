import 'dart:convert';

import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  const codec = AnthropicMessagesCodec();

  group('AnthropicMessagesCodec', () {
    test('groups user and tool blocks into Anthropic user messages', () {
      final request = codec.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: [
          SystemPromptMessage.text('You are helpful.'),
          UserPromptMessage(
            parts: const [
              TextPromptPart('Hello'),
            ],
          ),
          ToolPromptMessage(
            toolName: 'weather',
            parts: const [
              ToolResultPromptPart(
                toolCallId: 'toolu_1',
                toolName: 'weather',
                output: {
                  'temp': 72,
                },
              ),
            ],
          ),
          AssistantPromptMessage(
            parts: const [
              TextPromptPart('Answer   '),
            ],
          ),
        ],
        options: const GenerateTextOptions(),
        providerOptions: const AnthropicGenerateTextOptions(),
        stream: false,
      );

      expect(
        request.body['system'],
        [
          {
            'type': 'text',
            'text': 'You are helpful.',
          },
        ],
      );

      final messages = request.body['messages'] as List<Object?>;
      expect(messages, hasLength(2));
      expect(
        messages.first,
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Hello',
            },
            {
              'type': 'tool_result',
              'tool_use_id': 'toolu_1',
              'content': '{"temp":72}',
            },
          ],
        },
      );
      expect(
        messages.last,
        {
          'role': 'assistant',
          'content': [
            {
              'type': 'text',
              'text': 'Answer',
            },
          ],
        },
      );
      expect(request.betaFeatures, isEmpty);
      expect(request.warnings, isEmpty);
    });

    test('encodes image and document prompt parts for multimodal chat', () {
      final request = codec.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: [
          UserPromptMessage(
            parts: [
              const TextPromptPart('See attachment'),
              const ImagePromptPart(
                mediaType: 'image/png',
                bytes: [1, 2, 3],
              ),
              FilePromptPart(
                mediaType: 'text/plain',
                filename: 'notes.txt',
                bytes: utf8.encode('hello'),
              ),
              FilePromptPart(
                mediaType: 'application/pdf',
                filename: 'doc.pdf',
                uri: Uri.parse('https://example.com/doc.pdf'),
              ),
            ],
          ),
        ],
        options: const GenerateTextOptions(),
        providerOptions: const AnthropicGenerateTextOptions(),
        stream: false,
      );

      final messages = request.body['messages'] as List<Object?>;
      expect(
        messages.single,
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'See attachment',
            },
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': 'image/png',
                'data': 'AQID',
              },
            },
            {
              'type': 'document',
              'source': {
                'type': 'text',
                'media_type': 'text/plain',
                'data': 'hello',
              },
              'title': 'notes.txt',
            },
            {
              'type': 'document',
              'source': {
                'type': 'url',
                'url': 'https://example.com/doc.pdf',
              },
              'title': 'doc.pdf',
            },
          ],
        },
      );
    });

    test('adds thinking settings, beta features, and warnings', () {
      final request = codec.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: [
          UserPromptMessage.text('Think step by step'),
        ],
        options: const GenerateTextOptions(
          maxOutputTokens: 200,
          temperature: 0.6,
          topP: 0.8,
          topK: 40,
        ),
        providerOptions: AnthropicGenerateTextOptions(
          extendedThinking: true,
          interleavedThinking: true,
          metadata: const {
            'request_id': 'req_1',
          },
          container: 'container_1',
          mcpServers: const [
            AnthropicMcpServer.url(
              name: 'workspace',
              url: 'https://mcp.example.com',
            ),
          ],
        ),
        stream: true,
      );

      expect(request.body['max_tokens'], 1224);
      expect(
        request.body['thinking'],
        {
          'type': 'enabled',
          'budget_tokens': 1024,
        },
      );
      expect(request.body.containsKey('temperature'), isFalse);
      expect(request.body.containsKey('top_p'), isFalse);
      expect(request.body.containsKey('top_k'), isFalse);
      expect(
        request.body['metadata'],
        {
          'request_id': 'req_1',
        },
      );
      expect(request.body['container'], 'container_1');
      expect(
        request.body['mcp_servers'],
        [
          {
            'name': 'workspace',
            'type': 'url',
            'url': 'https://mcp.example.com',
          },
        ],
      );
      expect(
        request.betaFeatures,
        [
          'interleaved-thinking-2025-05-14',
          'mcp-client-2025-04-04',
        ],
      );
      expect(
        request.warnings.map((warning) => warning.field),
        containsAll([
          'thinkingBudgetTokens',
          'temperature',
          'topP',
          'topK',
        ]),
      );
    });

    test('rejects system messages after conversation blocks', () {
      expect(
        () => codec.encodeRequest(
          modelId: 'claude-sonnet-4-5',
          prompt: [
            SystemPromptMessage.text('Before'),
            UserPromptMessage.text('Hello'),
            SystemPromptMessage.text('After'),
          ],
          options: const GenerateTextOptions(),
          providerOptions: const AnthropicGenerateTextOptions(),
          stream: false,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}

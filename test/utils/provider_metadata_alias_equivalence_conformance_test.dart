import 'dart:async';
import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../utils/fakes/google_fake_client.dart';
import '../utils/fakes/openai_fake_client.dart';

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

void _expectAliasesMirrorCanonical(
  Map<String, dynamic> meta, {
  required String canonicalKey,
}) {
  expect(meta.containsKey(canonicalKey), isTrue);
  final canonical = meta[canonicalKey];

  for (final entry in meta.entries) {
    if (entry.key == canonicalKey) continue;
    if (entry.key.startsWith('$canonicalKey.')) {
      expect(entry.value, equals(canonical));
    }
  }
}

void _expectOpenAICompatibleChatAliases(
  Map<String, dynamic> meta, {
  required String providerId,
}) {
  final baseKey = providerId.split('.').first;
  final chatKey = providerId.contains('.') ? providerId : '$providerId.chat';

  expect(meta.containsKey(baseKey), isTrue);
  expect(meta.containsKey(chatKey), isTrue);
  expect(meta.containsKey('$chatKey.chat'), isFalse);
  expect(meta[chatKey], equals(meta[baseKey]));
}

Future<List<LLMStreamPart>> _runOpenAICompatibleChatCompletionsStreamParts({
  required String providerId,
  required String model,
}) async {
  final config = OpenAICompatibleConfig(
    providerId: providerId,
    providerName: providerId,
    apiKey: 'test-key',
    baseUrl: 'https://example.com/v1/',
    model: model,
  );

  final chunks = <String>[
    _sseData({
      'id': 'chatcmpl_1',
      'created': 1700000000,
      'model': model,
      'choices': [
        {
          'index': 0,
          'delta': {'role': 'assistant'},
        }
      ],
    }),
    _sseData({
      'id': 'chatcmpl_1',
      'model': model,
      'choices': [
        {
          'index': 0,
          'delta': {'content': 'Hello'},
          'finish_reason': 'stop',
        }
      ],
      'usage': {
        'prompt_tokens': 1,
        'completion_tokens': 1,
        'total_tokens': 2,
      },
    }),
    'data: [DONE]\n\n',
  ];

  final client = FakeOpenAIClient(config)
    ..streamResponse = Stream<String>.fromIterable(chunks);
  final provider = OpenAICompatibleChatProvider(
    client,
    config,
    const {LLMCapability.chat, LLMCapability.streaming},
  );

  return provider.chatStreamParts([ChatMessage.user('hi')]).toList();
}

void main() {
  group('providerMetadata alias equivalence (conformance)', () {
    test('OpenAI Chat Completions emits openai + openai.chat aliases',
        () async {
      final config = OpenAIConfig(
        providerId: 'openai.chat',
        providerName: 'OpenAI (Chat)',
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: false,
      );

      final chunks = <String>[
        _sseData({
          'id': 'chatcmpl_1',
          'created': 1700000000,
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'role': 'assistant'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'Hello'},
              'finish_reason': 'stop',
            }
          ],
          'usage': {
            'prompt_tokens': 1,
            'completion_tokens': 1,
            'total_tokens': 2,
          },
        }),
        'data: [DONE]\n\n',
      ];

      final client = FakeOpenAIClient(config)
        ..streamResponse = Stream<String>.fromIterable(chunks);
      final provider = OpenAIProvider(config, client: client);

      final parts =
          await provider.chatStreamParts([ChatMessage.user('hi')]).toList();
      final finish = parts.whereType<LLMFinishPart>().single;

      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);
      _expectAliasesMirrorCanonical(meta!, canonicalKey: 'openai');
      expect(meta.containsKey('openai.chat'), isTrue);
      expect(meta.containsKey('openai.chat.chat'), isFalse);
      expect(meta['openai.chat'], equals(meta['openai']));

      final metaParts = parts.whereType<LLMProviderMetadataPart>().toList();
      expect(metaParts, isNotEmpty);
      for (final p in metaParts) {
        _expectOpenAICompatibleChatAliases(
          p.providerMetadata,
          providerId: 'openai.chat',
        );
      }
    });

    test('OpenAI provider emits openai.responses alias equal to openai',
        () async {
      final config = OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
      );

      final chunks = <String>[
        _sseData({
          'type': 'response.created',
          'response': {
            'object': 'response',
            'id': 'resp_1',
            'created_at': 1700000000,
            'model': 'gpt-4o',
            'status': 'in_progress',
            'output': [],
          },
        }),
        _sseData({
          'type': 'response.output_text.delta',
          'delta': 'Hello',
        }),
        _sseData({
          'type': 'response.completed',
          'response': {
            'object': 'response',
            'id': 'resp_1',
            'created_at': 1700000000,
            'model': 'gpt-4o',
            'status': 'completed',
            'output': [
              {
                'type': 'message',
                'id': 'msg_1',
                'role': 'assistant',
                'status': 'completed',
                'content': [
                  {
                    'type': 'output_text',
                    'text': 'Hello',
                    'annotations': [],
                  },
                ],
              },
            ],
            'usage': {
              'input_tokens': 1,
              'output_tokens': 1,
              'total_tokens': 2,
            },
          },
        }),
        'data: [DONE]\n\n',
      ];

      final client = FakeOpenAIClient(config)
        ..streamResponse = Stream<String>.fromIterable(chunks);
      final provider = OpenAIProvider(config, client: client);

      final parts =
          await provider.chatStreamParts([ChatMessage.user('hi')]).toList();
      final finish = parts.whereType<LLMFinishPart>().single;

      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);
      _expectAliasesMirrorCanonical(meta!, canonicalKey: 'openai');
      expect(meta.containsKey('openai.responses'), isTrue);

      final metaParts = parts.whereType<LLMProviderMetadataPart>().toList();
      for (final p in metaParts) {
        expect(p.providerMetadata['openai.responses'],
            equals(p.providerMetadata['openai']));
      }
    });

    test('Azure provider emits azure.responses alias equal to azure', () async {
      final config = AzureOpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.openai.azure.com/openai/v1/',
        model: 'deployment_1',
        useResponsesAPI: true,
        apiVersion: '2024-10-01-preview',
      );

      final chunks = <String>[
        _sseData({
          'type': 'response.created',
          'response': {
            'object': 'response',
            'id': 'resp_1',
            'created_at': 1700000000,
            'model': 'deployment_1',
            'status': 'in_progress',
            'output': [],
          },
        }),
        _sseData({
          'type': 'response.output_text.delta',
          'delta': 'Hello',
        }),
        _sseData({
          'type': 'response.completed',
          'response': {
            'object': 'response',
            'id': 'resp_1',
            'created_at': 1700000000,
            'model': 'deployment_1',
            'status': 'completed',
            'output': [
              {
                'type': 'message',
                'id': 'msg_1',
                'role': 'assistant',
                'status': 'completed',
                'content': [
                  {
                    'type': 'output_text',
                    'text': 'Hello',
                    'annotations': [],
                  },
                ],
              },
            ],
          },
        }),
        'data: [DONE]\n\n',
      ];

      final client = FakeOpenAIClient(config)
        ..streamResponse = Stream<String>.fromIterable(chunks);
      final provider = AzureOpenAIProvider(config, client: client);

      final parts =
          await provider.chatStreamParts([ChatMessage.user('hi')]).toList();
      final finish = parts.whereType<LLMFinishPart>().single;

      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);
      _expectAliasesMirrorCanonical(meta!, canonicalKey: 'azure');
      expect(meta.containsKey('azure.responses'), isTrue);

      final metaParts = parts.whereType<LLMProviderMetadataPart>().toList();
      for (final p in metaParts) {
        expect(p.providerMetadata['azure.responses'],
            equals(p.providerMetadata['azure']));
      }
    });

    test('Azure Chat Completions emits azure + azure.chat aliases', () async {
      final config = AzureOpenAIConfig(
        providerId: 'azure.chat',
        apiKey: 'test-key',
        baseUrl: 'https://example.openai.azure.com/openai/v1/',
        model: 'deployment_1',
        useResponsesAPI: false,
        apiVersion: '2024-10-01-preview',
      );

      final chunks = <String>[
        _sseData({
          'id': 'chatcmpl_1',
          'created': 1700000000,
          'model': 'deployment_1',
          'choices': [
            {
              'index': 0,
              'delta': {'role': 'assistant'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'deployment_1',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'Hello'},
              'finish_reason': 'stop',
            }
          ],
          'usage': {
            'prompt_tokens': 1,
            'completion_tokens': 1,
            'total_tokens': 2,
          },
        }),
        'data: [DONE]\n\n',
      ];

      final client = FakeOpenAIClient(config)
        ..streamResponse = Stream<String>.fromIterable(chunks);
      final provider = AzureOpenAIProvider(config, client: client);

      final parts =
          await provider.chatStreamParts([ChatMessage.user('hi')]).toList();
      final finish = parts.whereType<LLMFinishPart>().single;

      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);
      _expectAliasesMirrorCanonical(meta!, canonicalKey: 'azure');
      expect(meta.containsKey('azure.chat'), isTrue);
      expect(meta.containsKey('azure.chat.chat'), isFalse);
      expect(meta['azure.chat'], equals(meta['azure']));

      final metaParts = parts.whereType<LLMProviderMetadataPart>().toList();
      expect(metaParts, isNotEmpty);
      for (final p in metaParts) {
        _expectOpenAICompatibleChatAliases(
          p.providerMetadata,
          providerId: 'azure.chat',
        );
      }
    });

    test('Google emits google.chat alias equal to google', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-flash',
        stream: true,
      );

      final client = FakeGoogleClient(config)
        ..streamResponse = Stream<String>.fromIterable(const [
          'data: {"modelVersion":"gemini-2.5-flash","candidates":[{"content":{"parts":[{"text":"Hi"}]},"finishReason":"STOP"}]}\n\n',
        ]);
      final chat = GoogleChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('hello')]).toList();
      final finish = parts.whereType<LLMFinishPart>().single;

      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);
      _expectAliasesMirrorCanonical(meta!, canonicalKey: 'google');
      expect(meta.containsKey('google.chat'), isTrue);
    });

    test('Google Vertex emits vertex.chat alias equal to vertex', () async {
      final config = GoogleConfig(
        providerId: 'vertex',
        providerOptionsName: 'vertex',
        providerOptionsFallbackIds: const ['google-vertex', 'google'],
        apiKey: 'test-key',
        baseUrl: 'https://aiplatform.googleapis.com/v1/publishers/google/',
        model: 'gemini-2.5-flash',
        stream: true,
      );

      final client = FakeGoogleClient(config)
        ..streamResponse = Stream<String>.fromIterable(const [
          'data: {"modelVersion":"gemini-2.5-flash","candidates":[{"content":{"parts":[{"text":"Hi"}]},"finishReason":"STOP"}]}\n\n',
        ]);
      final chat = GoogleChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('hello')]).toList();
      final finish = parts.whereType<LLMFinishPart>().single;

      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);
      _expectAliasesMirrorCanonical(meta!, canonicalKey: 'vertex');
      expect(meta.containsKey('vertex.chat'), isTrue);
    });

    test('DeepSeek (OpenAI-compatible) emits deepseek + deepseek.chat aliases',
        () async {
      final parts = await _runOpenAICompatibleChatCompletionsStreamParts(
        providerId: 'deepseek',
        model: 'deepseek-chat',
      );

      final metaParts = parts.whereType<LLMProviderMetadataPart>().toList();
      expect(metaParts, isNotEmpty);
      for (final p in metaParts) {
        _expectOpenAICompatibleChatAliases(
          p.providerMetadata,
          providerId: 'deepseek',
        );
      }

      final finish = parts.whereType<LLMFinishPart>().single;
      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);
      _expectAliasesMirrorCanonical(meta!, canonicalKey: 'deepseek');
      expect(meta.containsKey('deepseek.chat'), isTrue);
      expect(meta.containsKey('deepseek.chat.chat'), isFalse);
      expect(meta['deepseek.chat'], equals(meta['deepseek']));
    });

    test('Groq (OpenAI-compatible) emits groq + groq.chat aliases', () async {
      final parts = await _runOpenAICompatibleChatCompletionsStreamParts(
        providerId: 'groq',
        model: 'qwen/qwen3-32b',
      );

      final metaParts = parts.whereType<LLMProviderMetadataPart>().toList();
      expect(metaParts, isNotEmpty);
      for (final p in metaParts) {
        _expectOpenAICompatibleChatAliases(
          p.providerMetadata,
          providerId: 'groq',
        );
      }

      final finish = parts.whereType<LLMFinishPart>().single;
      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);
      _expectAliasesMirrorCanonical(meta!, canonicalKey: 'groq');
      expect(meta.containsKey('groq.chat'), isTrue);
      expect(meta.containsKey('groq.chat.chat'), isFalse);
      expect(meta['groq.chat'], equals(meta['groq']));
    });

    test('OpenRouter (OpenAI-compatible) emits openrouter + openrouter.chat',
        () async {
      final parts = await _runOpenAICompatibleChatCompletionsStreamParts(
        providerId: 'openrouter',
        model: 'anthropic/claude-3.5-sonnet',
      );

      final metaParts = parts.whereType<LLMProviderMetadataPart>().toList();
      expect(metaParts, isNotEmpty);
      for (final p in metaParts) {
        _expectOpenAICompatibleChatAliases(
          p.providerMetadata,
          providerId: 'openrouter',
        );
      }

      final finish = parts.whereType<LLMFinishPart>().single;
      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);
      _expectAliasesMirrorCanonical(meta!, canonicalKey: 'openrouter');
      expect(meta.containsKey('openrouter.chat'), isTrue);
      expect(meta.containsKey('openrouter.chat.chat'), isFalse);
      expect(meta['openrouter.chat'], equals(meta['openrouter']));
    });

    test('xAI Chat (OpenAI-compatible) emits xai + xai.chat aliases', () async {
      final parts = await _runOpenAICompatibleChatCompletionsStreamParts(
        providerId: 'xai',
        model: 'grok-3',
      );

      final metaParts = parts.whereType<LLMProviderMetadataPart>().toList();
      expect(metaParts, isNotEmpty);
      for (final p in metaParts) {
        _expectOpenAICompatibleChatAliases(
          p.providerMetadata,
          providerId: 'xai',
        );
      }

      final finish = parts.whereType<LLMFinishPart>().single;
      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);
      _expectAliasesMirrorCanonical(meta!, canonicalKey: 'xai');
      expect(meta.containsKey('xai.chat'), isTrue);
      expect(meta.containsKey('xai.chat.chat'), isFalse);
      expect(meta['xai.chat'], equals(meta['xai']));
    });
  });
}

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

void main() {
  group('providerMetadata alias equivalence (conformance)', () {
    test('OpenAI Chat Completions emits openai + openai.chat aliases', () async {
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

    test('Google Vertex emits google-vertex.chat alias equal to google-vertex',
        () async {
      final config = GoogleConfig(
        providerOptionsName: 'google-vertex',
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
      _expectAliasesMirrorCanonical(meta!, canonicalKey: 'google-vertex');
      expect(meta.containsKey('google-vertex.chat'), isTrue);
    });
  });
}

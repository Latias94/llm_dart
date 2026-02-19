import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_azure/provider.dart';
import 'package:llm_dart_openai/provider.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_xai/responses.dart';
import 'package:test/test.dart';

import '../utils/fakes/openai_fake_client.dart';

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

void _expectCanonicalOnly(
  Map<String, dynamic> meta, {
  required String providerId,
}) {
  final baseKey = providerId.split('.').first;
  expect(meta.containsKey(baseKey), isTrue);
  expect(meta.keys.where((k) => k.startsWith('$baseKey.')), isEmpty);
}

void main() {
  group('providerMetadata canonicalization (conformance)', () {
    test('OpenAI chat completions emits canonical openai key', () async {
      final config = OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: false,
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = {
          'id': 'chatcmpl_1',
          'object': 'chat.completion',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'message': {'role': 'assistant', 'content': 'hi'},
              'finish_reason': 'stop',
            }
          ],
          'usage': {
            'prompt_tokens': 1,
            'completion_tokens': 1,
            'total_tokens': 2,
          },
        };

      final provider = OpenAIProvider(config, client: client);
      final response = await provider.chat([ChatMessage.user('hi')]);

      final meta = response.providerMetadata;
      expect(meta, isNotNull);
      _expectCanonicalOnly(meta!, providerId: config.providerId);

      expect(readProviderMetadata<Map>(meta, 'openai.chat'), equals(meta['openai']));
      expect(
          readProviderMetadata<Map>(meta, 'openai.responses'), equals(meta['openai']));
    });

    test('OpenAI responses emits canonical openai key', () async {
      final config = OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = {
          'id': 'resp_1',
          'object': 'response',
          'status': 'completed',
          'model': 'gpt-4o',
          'output': [
            {
              'id': 'msg_1',
              'type': 'message',
              'status': 'completed',
              'role': 'assistant',
              'content': [
                {
                  'type': 'output_text',
                  'text': 'hi',
                  'annotations': [],
                  'logprobs': [],
                }
              ],
            }
          ],
          'usage': {
            'input_tokens': 1,
            'output_tokens': 1,
            'total_tokens': 2,
          },
        };

      final provider = OpenAIProvider(config, client: client);
      final response = await provider.chat([ChatMessage.user('hi')]);

      final meta = response.providerMetadata;
      expect(meta, isNotNull);
      _expectCanonicalOnly(meta!, providerId: config.providerId);
      expect(
          readProviderMetadata<Map>(meta, 'openai.responses'), equals(meta['openai']));
    });

    test('Azure responses emits canonical azure key', () async {
      const providerId = 'azure';
      final config = AzureOpenAIConfig(
        providerId: providerId,
        providerName: 'Azure',
        apiKey: 'test-key',
        baseUrl: 'https://example.openai.azure.com/openai/v1/',
        model: 'deployment_1',
        apiVersion: '2024-10-01-preview',
        useDeploymentBasedUrls: false,
        useResponsesAPI: true,
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = {
          'id': 'resp_1',
          'object': 'response',
          'status': 'completed',
          'model': 'gpt-4o',
          'output': [
            {
              'id': 'msg_1',
              'type': 'message',
              'status': 'completed',
              'role': 'assistant',
              'content': [
                {
                  'type': 'output_text',
                  'text': 'hi',
                  'annotations': [],
                  'logprobs': [],
                }
              ],
            }
          ],
          'usage': {
            'input_tokens': 1,
            'output_tokens': 1,
            'total_tokens': 2,
          },
        };

      final provider = AzureOpenAIProvider(config, client: client);
      final response = await provider.chat([ChatMessage.user('hi')]);

      final meta = response.providerMetadata;
      expect(meta, isNotNull);
      _expectCanonicalOnly(meta!, providerId: config.providerId);
      expect(readProviderMetadata<Map>(meta, 'azure.responses'), equals(meta['azure']));
    });

    test('OpenAI-compatible namespaced providerId emits canonical base key', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-4-fast',
      );

      final chunks = <String>[
        _sseData({
          'type': 'response.completed',
          'response': {
            'object': 'response',
            'id': 'resp_1',
            'model': 'grok-4-fast',
            'status': 'completed',
            'output': [
              {
                'type': 'message',
                'id': 'msg_1',
                'role': 'assistant',
                'status': 'completed',
                'content': [
                  {'type': 'output_text', 'text': 'hi', 'annotations': []},
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
      ];

      final client = FakeOpenAIClient(config)
        ..streamResponse = Stream<String>.fromIterable(chunks);
      final responses = XAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('hi')]).toList();
      final finish = parts.whereType<LLMFinishPart>().single;

      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);
      _expectCanonicalOnly(meta!, providerId: config.providerId);
      expect(readProviderMetadata<Map>(meta, 'xai.responses'), equals(meta['xai']));
    });
  });
}


import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

void main() {
  group('Google grounding sources (AI SDK parity)', () {
    test('extracts document source from retrievedContext file uri', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-flash',
        stream: true,
      );

      final client = FakeGoogleClient(config)
        ..streamResponse = Stream<String>.fromIterable([
          _sseData({
            'modelVersion': config.model,
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Hi'}
                  ],
                },
                'groundingMetadata': {
                  'groundingChunks': [
                    {
                      'retrievedContext': {
                        'uri': 'gs://bucket/path/doc.pdf',
                      },
                    },
                  ],
                },
              },
            ],
          }),
          _sseData({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': '!'}
                  ],
                },
                'finishReason': 'STOP',
              },
            ],
          }),
        ]);

      final chat = GoogleChat(client, config);
      final parts = await chat.chatStreamParts(
        [ChatMessage.user('hello')],
        tools: const [],
      ).toList();

      final docs = parts.whereType<LLMSourceDocumentPart>().toList();
      expect(docs, hasLength(1));
      expect(docs.single.title, equals('Unknown Document'));
      expect(docs.single.mediaType, equals('application/pdf'));
      expect(docs.single.filename, equals('doc.pdf'));

      final finish = parts.whereType<LLMFinishPart>().single;
      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);
      expect((meta!['google'] as Map)['groundingMetadata'], isNotNull);
    });

    test('extracts document source from retrievedContext fileSearchStore',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-flash',
        stream: true,
      );

      final client = FakeGoogleClient(config)
        ..streamResponse = Stream<String>.fromIterable([
          _sseData({
            'modelVersion': config.model,
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Hi'}
                  ],
                },
                'groundingMetadata': {
                  'groundingChunks': [
                    {
                      'retrievedContext': {
                        'title': 'My doc',
                        'fileSearchStore':
                            'projects/foo/fileSearchStores/bar/docs/readme.md',
                      },
                    },
                  ],
                },
              },
            ],
          }),
          _sseData({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': '!'}
                  ],
                },
                'finishReason': 'STOP',
              },
            ],
          }),
        ]);

      final chat = GoogleChat(client, config);
      final parts = await chat.chatStreamParts(
        [ChatMessage.user('hello')],
        tools: const [],
      ).toList();

      final docs = parts.whereType<LLMSourceDocumentPart>().toList();
      expect(docs, hasLength(1));
      expect(docs.single.title, equals('My doc'));
      expect(docs.single.mediaType, equals('application/octet-stream'));
      expect(docs.single.filename, equals('readme.md'));
    });

    test('extracts URL source from maps grounding metadata', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-flash',
        stream: true,
      );

      final client = FakeGoogleClient(config)
        ..streamResponse = Stream<String>.fromIterable([
          _sseData({
            'modelVersion': config.model,
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Hi'}
                  ],
                },
                'groundingMetadata': {
                  'groundingChunks': [
                    {
                      'maps': {
                        'uri': 'https://maps.example.com/place/123',
                        'title': 'Place',
                      },
                    },
                  ],
                },
              },
            ],
          }),
          _sseData({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': '!'}
                  ],
                },
                'finishReason': 'STOP',
              },
            ],
          }),
        ]);

      final chat = GoogleChat(client, config);
      final parts = await chat.chatStreamParts(
        [ChatMessage.user('hello')],
        tools: const [],
      ).toList();

      final urls = parts.whereType<LLMSourceUrlPart>().toList();
      expect(urls, hasLength(1));
      expect(urls.single.url, equals('https://maps.example.com/place/123'));
      expect(urls.single.title, equals('Place'));
    });

    test('deduplicates sources across chunks', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-flash',
        stream: true,
      );

      final client = FakeGoogleClient(config)
        ..streamResponse = Stream<String>.fromIterable([
          _sseData({
            'modelVersion': config.model,
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'A'}
                  ],
                },
                'groundingMetadata': {
                  'groundingChunks': [
                    {
                      'web': {
                        'uri': 'https://example.com',
                        'title': 'Example',
                      },
                    },
                  ],
                },
              },
            ],
          }),
          _sseData({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'B'}
                  ],
                },
                'groundingMetadata': {
                  'groundingChunks': [
                    {
                      'web': {
                        'uri': 'https://example.com',
                        'title': 'Example',
                      },
                    },
                  ],
                },
              },
            ],
          }),
          _sseData({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': ''}
                  ],
                },
                'finishReason': 'STOP',
              },
            ],
          }),
        ]);

      final chat = GoogleChat(client, config);
      final parts = await chat.chatStreamParts(
        [ChatMessage.user('hello')],
        tools: const [],
      ).toList();

      final urls = parts.whereType<LLMSourceUrlPart>().toList();
      expect(urls, hasLength(1));
      expect(urls.single.url, equals('https://example.com'));
    });
  });
}


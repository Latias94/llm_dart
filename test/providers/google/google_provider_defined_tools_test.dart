// Tests for provider-defined tools integration with the Google provider.
// These tests exercise the LanguageModelCallOptions.callTools path and
// ensure that provider-defined tool specs are converted into the correct
// Google API "tools" payload.

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import 'google_test_utils.dart';

void main() {
  group('Google provider-defined tools (callTools)', () {
    test('google.google_search uses googleSearch for Gemini 2.x', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.0-pro',
      );

      final client = CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      final messages = [ModelMessage.userText('hello')];

      final options = LanguageModelCallOptions(
        callTools: const [
          ProviderDefinedToolSpec(
            id: 'google.google_search',
          ),
        ],
      );

      await chat.chat(messages, options: options);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final tools = (body!['tools'] as List).cast<Map<String, dynamic>>();
      expect(tools.length, equals(1));
      expect(tools.first, equals({'googleSearch': <String, dynamic>{}}));
      expect(body.containsKey('toolConfig'), isFalse);
    });

    test(
        'google.google_search uses googleSearchRetrieval with dynamicRetrievalConfig for Gemini 1.5 Flash',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
      );

      final client = CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      final messages = [ModelMessage.userText('hello')];

      final options = LanguageModelCallOptions(
        callTools: const [
          ProviderDefinedToolSpec(
            id: 'google.google_search',
            args: {
              'mode': 'MODE_DYNAMIC',
              'dynamicThreshold': 1.5,
            },
          ),
        ],
      );

      await chat.chat(messages, options: options);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final tools = (body!['tools'] as List).cast<Map<String, dynamic>>();
      expect(tools.length, equals(1));

      final retrieval =
          tools.first['googleSearchRetrieval'] as Map<String, dynamic>?;
      expect(retrieval, isNotNull);

      final dynamicConfig =
          retrieval!['dynamicRetrievalConfig'] as Map<String, dynamic>?;
      expect(dynamicConfig, isNotNull);
      expect(dynamicConfig!['mode'], equals('MODE_DYNAMIC'));
      expect(dynamicConfig['dynamicThreshold'], equals(1.5));
    });

    test(
        'google.google_search falls back to basic googleSearchRetrieval for non-dynamic models',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash-8b',
      );

      final client = CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      final messages = [ModelMessage.userText('hello')];

      final options = LanguageModelCallOptions(
        callTools: const [
          ProviderDefinedToolSpec(
            id: 'google.google_search',
            args: {
              'mode': 'MODE_DYNAMIC',
            },
          ),
        ],
      );

      await chat.chat(messages, options: options);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final tools = (body!['tools'] as List).cast<Map<String, dynamic>>();
      expect(tools.length, equals(1));
      expect(
        tools.first,
        equals({'googleSearchRetrieval': <String, dynamic>{}}),
      );
    });

    test(
        'mixing function tools and provider-defined tools prefers provider-defined tools',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.0-pro',
      );

      final client = CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      final messages = [ModelMessage.userText('hello')];

      final functionTool = Tool.function(
        name: 'get_weather',
        description: 'Get weather information',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'location': ParameterProperty(
              propertyType: 'string',
              description: 'City name',
            ),
          },
          required: const ['location'],
        ),
      );

      final options = LanguageModelCallOptions(
        callTools: [
          FunctionCallToolSpec(functionTool),
          const ProviderDefinedToolSpec(id: 'google.google_search'),
        ],
      );

      await chat.chat(messages, options: options);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final tools = (body!['tools'] as List).cast<Map<String, dynamic>>();
      expect(tools.length, equals(1));
      expect(tools.first.keys, contains('googleSearch'));
      expect(tools.first.keys, isNot(contains('functionDeclarations')));
    });

    test('function tools in callTools behave like legacy tools list', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
      );

      final client = CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      final messages = [ModelMessage.userText('hello')];

      final functionTool = Tool.function(
        name: 'get_weather',
        description: 'Get weather information',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'location': ParameterProperty(
              propertyType: 'string',
              description: 'City name',
            ),
          },
          required: const ['location'],
        ),
      );

      final options = LanguageModelCallOptions(
        callTools: [FunctionCallToolSpec(functionTool)],
        toolChoice: const SpecificToolChoice('get_weather'),
      );

      await chat.chat(messages, options: options);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final tools = (body!['tools'] as List).cast<Map<String, dynamic>>();
      expect(tools.length, equals(1));

      final first = tools.first;
      expect(first.containsKey('functionDeclarations'), isTrue);

      final toolConfig = body['toolConfig'] as Map<String, dynamic>?;
      expect(toolConfig, isNotNull);

      final functionCallingConfig =
          toolConfig!['functionCallingConfig'] as Map<String, dynamic>?;
      expect(functionCallingConfig, isNotNull);
      expect(functionCallingConfig!['mode'], equals('ANY'));
      final allowedNames =
          (functionCallingConfig['allowedFunctionNames'] as List?) ?? const [];
      expect(allowedNames, contains('get_weather'));
    });
  });
}

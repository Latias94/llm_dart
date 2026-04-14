import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:llm_dart_openai/src/openai_chat_completions_codec.dart';
import 'package:llm_dart_openai/src/openai_options.dart';
import 'package:llm_dart_openai/src/openai_responses_codec.dart';
import 'package:llm_dart_openai/src/resolved_openai_options.dart';
import 'package:test/test.dart';

void main() {
  group('Prompt normalization contract', () {
    test('normalizes the common text-and-tool replay subset across providers',
        () {
      const anthropic = AnthropicMessagesCodec();
      const google = GoogleGenerateContentCodec();
      const openaiResponses = OpenAIResponsesCodec();
      const openaiChat = OpenAIChatCompletionsCodec();

      final prompt = <PromptMessage>[
        SystemPromptMessage.text('You are concise.'),
        UserPromptMessage.text('What is the weather in Hong Kong?'),
        AssistantPromptMessage(
          parts: const [
            TextPromptPart('Checking.'),
            ToolCallPromptPart(
              toolCallId: 'tool_1',
              toolName: 'weather',
              input: {
                'city': 'Hong Kong',
              },
            ),
          ],
        ),
        ToolPromptMessage(
          toolName: 'weather',
          parts: const [
            ToolResultPromptPart(
              toolCallId: 'tool_1',
              toolName: 'weather',
              output: {
                'temperature': 28,
              },
            ),
          ],
        ),
      ];

      final anthropicRequest = anthropic.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: prompt,
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const AnthropicChatModelSettings(),
        providerOptions: const AnthropicGenerateTextOptions(),
        stream: false,
      );

      expect(anthropicRequest.warnings, isEmpty);
      expect(
        anthropicRequest.body['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'What is the weather in Hong Kong?',
              },
            ],
          },
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'text',
                'text': 'Checking.',
              },
              {
                'type': 'tool_use',
                'id': 'tool_1',
                'name': 'weather',
                'input': {
                  'city': 'Hong Kong',
                },
              },
            ],
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'tool_1',
                'content': '{"temperature":28}',
              },
            ],
          },
        ],
      );

      final googleRequest = google.encodeRequest(
        modelId: 'gemini-2.5-flash',
        prompt: prompt,
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const GoogleChatModelSettings(),
        providerOptions: const GoogleGenerateTextOptions(),
      );

      expect(googleRequest.warnings, isEmpty);
      expect(
        googleRequest.body['contents'],
        [
          {
            'role': 'user',
            'parts': [
              {
                'text': 'What is the weather in Hong Kong?',
              },
            ],
          },
          {
            'role': 'model',
            'parts': [
              {
                'text': 'Checking.',
              },
              {
                'functionCall': {
                  'name': 'weather',
                  'args': {
                    'city': 'Hong Kong',
                  },
                },
              },
            ],
          },
          {
            'role': 'user',
            'parts': [
              {
                'functionResponse': {
                  'name': 'weather',
                  'response': {
                    'name': 'weather',
                    'content': {
                      'temperature': 28,
                    },
                  },
                },
              },
            ],
          },
        ],
      );

      final openaiResponsesRequest = openaiResponses.encodeRequest(
        modelId: 'gpt-4.1-mini',
        prompt: prompt,
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        providerOptions: const OpenAIGenerateTextOptions(),
        stream: false,
      );

      expect(openaiResponsesRequest.warnings, isEmpty);
      expect(
        openaiResponsesRequest.body['input'],
        [
          {
            'role': 'system',
            'content': 'You are concise.',
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': 'What is the weather in Hong Kong?',
              },
            ],
          },
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'output_text',
                'text': 'Checking.',
              },
            ],
          },
          {
            'type': 'function_call',
            'call_id': 'tool_1',
            'name': 'weather',
            'arguments': '{"city":"Hong Kong"}',
          },
          {
            'type': 'function_call_output',
            'call_id': 'tool_1',
            'output': '{"temperature":28}',
          },
        ],
      );

      final openaiChatRequest = openaiChat.encodeRequest(
        modelId: 'gpt-4.1-mini',
        prompt: prompt,
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        providerOptions: const ResolvedOpenAIGenerateTextOptions(),
        stream: false,
      );

      expect(openaiChatRequest.warnings, isEmpty);
      expect(
        openaiChatRequest.body['messages'],
        [
          {
            'role': 'system',
            'content': 'You are concise.',
          },
          {
            'role': 'user',
            'content': 'What is the weather in Hong Kong?',
          },
          {
            'role': 'assistant',
            'content': 'Checking.',
            'tool_calls': [
              {
                'id': 'tool_1',
                'type': 'function',
                'function': {
                  'name': 'weather',
                  'arguments': '{"city":"Hong Kong"}',
                },
              },
            ],
          },
          {
            'role': 'tool',
            'tool_call_id': 'tool_1',
            'content': '{"temperature":28}',
          },
        ],
      );
    });

    test(
        'multimodal user prompts are normalized according to each provider codec',
        () {
      const anthropic = AnthropicMessagesCodec();
      const google = GoogleGenerateContentCodec();
      const openaiResponses = OpenAIResponsesCodec();
      const openaiChat = OpenAIChatCompletionsCodec();

      final prompt = <PromptMessage>[
        UserPromptMessage(
          parts: [
            const TextPromptPart('Inspect the attachment.'),
            const ImagePromptPart(
              mediaType: 'image/png',
              bytes: [1, 2, 3],
            ),
            FilePromptPart(
              mediaType: 'application/pdf',
              uri: Uri.parse('https://example.com/spec.pdf'),
            ),
          ],
        ),
      ];

      final anthropicRequest = anthropic.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: prompt,
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const AnthropicChatModelSettings(),
        providerOptions: const AnthropicGenerateTextOptions(),
        stream: false,
      );

      expect(
        anthropicRequest.body['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Inspect the attachment.',
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
                  'type': 'url',
                  'url': 'https://example.com/spec.pdf',
                },
              },
            ],
          },
        ],
      );

      final googleRequest = google.encodeRequest(
        modelId: 'gemini-2.5-flash',
        prompt: prompt,
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const GoogleChatModelSettings(),
        providerOptions: const GoogleGenerateTextOptions(),
      );

      expect(
        googleRequest.body['contents'],
        [
          {
            'role': 'user',
            'parts': [
              {
                'text': 'Inspect the attachment.',
              },
              {
                'inlineData': {
                  'mimeType': 'image/png',
                  'data': 'AQID',
                },
              },
              {
                'fileData': {
                  'mimeType': 'application/pdf',
                  'fileUri': 'https://example.com/spec.pdf',
                },
              },
            ],
          },
        ],
      );

      final openaiResponsesRequest = openaiResponses.encodeRequest(
        modelId: 'gpt-4.1-mini',
        prompt: prompt,
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        providerOptions: const OpenAIGenerateTextOptions(),
        stream: false,
      );

      expect(
        openaiResponsesRequest.body['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': 'Inspect the attachment.',
              },
              {
                'type': 'input_image',
                'image_url': 'data:image/png;base64,AQID',
              },
              {
                'type': 'input_file',
                'file_url': 'https://example.com/spec.pdf',
              },
            ],
          },
        ],
      );

      expect(
        () => openaiChat.encodeRequest(
          modelId: 'gpt-4.1-mini',
          prompt: prompt,
          tools: const [],
          toolChoice: null,
          options: const GenerateTextOptions(),
          providerOptions: const ResolvedOpenAIGenerateTextOptions(),
          stream: false,
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('PDF file prompt parts do not support URIs'),
          ),
        ),
      );
    });

    test(
        'provider replay keeps provider-executed calls filtered and approval items provider-specific',
        () {
      const anthropic = AnthropicMessagesCodec();
      const google = GoogleGenerateContentCodec();
      const openaiResponses = OpenAIResponsesCodec();
      const openaiChat = OpenAIChatCompletionsCodec();

      final prompt = <PromptMessage>[
        UserPromptMessage.text('Open the browser tool.'),
        AssistantPromptMessage(
          parts: const [
            ToolCallPromptPart(
              toolCallId: 'tool_1',
              toolName: 'mcp.open_browser',
              input: {
                'url': 'https://example.com',
              },
              providerExecuted: true,
              isDynamic: true,
              title: 'workspace',
            ),
            ToolApprovalRequestPromptPart(
              approvalId: 'approval_1',
              toolCallId: 'tool_1',
            ),
          ],
        ),
        ToolPromptMessage(
          toolName: 'mcp.open_browser',
          parts: const [
            ToolApprovalResponsePromptPart(
              approvalId: 'approval_1',
              toolCallId: 'tool_1',
              approved: true,
              reason: 'User approved the action.',
            ),
            ToolResultPromptPart(
              toolCallId: 'tool_1',
              toolName: 'mcp.open_browser',
              output: {
                'status': 'ok',
              },
            ),
          ],
        ),
      ];

      final anthropicRequest = anthropic.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: prompt,
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const AnthropicChatModelSettings(),
        providerOptions: const AnthropicGenerateTextOptions(),
        stream: false,
      );

      expect(anthropicRequest.warnings, isEmpty);
      expect(
        anthropicRequest.body['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Open the browser tool.',
              },
            ],
          },
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'mcp_tool_use',
                'id': 'tool_1',
                'name': 'open_browser',
                'server_name': 'workspace',
                'input': {
                  'url': 'https://example.com',
                },
              },
            ],
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'mcp_tool_result',
                'tool_use_id': 'tool_1',
                'content': {
                  'status': 'ok',
                },
              },
            ],
          },
        ],
      );

      final googleRequest = google.encodeRequest(
        modelId: 'gemini-2.5-flash',
        prompt: prompt,
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const GoogleChatModelSettings(),
        providerOptions: const GoogleGenerateTextOptions(),
      );

      expect(googleRequest.warnings, isEmpty);
      expect(
        googleRequest.body['contents'],
        [
          {
            'role': 'user',
            'parts': [
              {
                'text': 'Open the browser tool.',
              },
            ],
          },
          {
            'role': 'model',
            'parts': [
              {
                'functionCall': {
                  'name': 'mcp.open_browser',
                  'args': {
                    'url': 'https://example.com',
                  },
                },
              },
            ],
          },
          {
            'role': 'user',
            'parts': [
              {
                'functionResponse': {
                  'name': 'mcp.open_browser',
                  'response': {
                    'name': 'mcp.open_browser',
                    'content': {
                      'status': 'ok',
                    },
                  },
                },
              },
            ],
          },
        ],
      );

      final openaiResponsesRequest = openaiResponses.encodeRequest(
        modelId: 'gpt-4.1-mini',
        prompt: prompt,
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        providerOptions: const OpenAIGenerateTextOptions(),
        stream: false,
      );

      expect(openaiResponsesRequest.warnings, isEmpty);
      expect(
        openaiResponsesRequest.body['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': 'Open the browser tool.',
              },
            ],
          },
          {
            'type': 'item_reference',
            'id': 'approval_1',
          },
          {
            'type': 'mcp_approval_response',
            'approval_request_id': 'approval_1',
            'approve': true,
          },
          {
            'type': 'function_call_output',
            'call_id': 'tool_1',
            'output': '{"status":"ok"}',
          },
        ],
      );

      final openaiChatRequest = openaiChat.encodeRequest(
        modelId: 'gpt-4.1-mini',
        prompt: prompt,
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        providerOptions: const ResolvedOpenAIGenerateTextOptions(),
        stream: false,
      );

      expect(
        openaiChatRequest.body['messages'],
        [
          {
            'role': 'user',
            'content': 'Open the browser tool.',
          },
        ],
      );
      expect(
        openaiChatRequest.warnings.map((warning) => warning.field),
        [
          'prompt.assistant.parts',
          'prompt.assistant.parts',
          'prompt.tool.parts',
          'prompt.tool.parts',
        ],
      );
    });

    test('assistant reasoning replay is provider-owned and metadata-sensitive',
        () {
      const anthropic = AnthropicMessagesCodec();
      const google = GoogleGenerateContentCodec();
      const openaiResponses = OpenAIResponsesCodec();
      const openaiChat = OpenAIChatCompletionsCodec();

      final prompt = <PromptMessage>[
        UserPromptMessage.text('Continue from the previous reasoning.'),
        AssistantPromptMessage(
          parts: const [
            ReasoningPromptPart('Plan the answer.'),
            TextPromptPart('Visible answer.'),
          ],
        ),
      ];

      final anthropicRequest = anthropic.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: prompt,
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const AnthropicChatModelSettings(),
        providerOptions: const AnthropicGenerateTextOptions(),
        stream: false,
      );

      expect(
        anthropicRequest.warnings.map((warning) => warning.field),
        ['assistant.reasoning'],
      );
      expect(
        anthropicRequest.body['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Continue from the previous reasoning.',
              },
            ],
          },
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'text',
                'text': 'Visible answer.',
              },
            ],
          },
        ],
      );

      final googleRequest = google.encodeRequest(
        modelId: 'gemini-2.5-flash',
        prompt: prompt,
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const GoogleChatModelSettings(),
        providerOptions: const GoogleGenerateTextOptions(),
      );

      expect(googleRequest.warnings, isEmpty);
      expect(
        googleRequest.body['contents'],
        [
          {
            'role': 'user',
            'parts': [
              {
                'text': 'Continue from the previous reasoning.',
              },
            ],
          },
          {
            'role': 'model',
            'parts': [
              {
                'text': 'Plan the answer.',
                'thought': true,
              },
              {
                'text': 'Visible answer.',
              },
            ],
          },
        ],
      );

      final openaiResponsesRequest = openaiResponses.encodeRequest(
        modelId: 'gpt-4.1-mini',
        prompt: prompt,
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        providerOptions: const OpenAIGenerateTextOptions(),
        stream: false,
      );

      expect(
        openaiResponsesRequest.warnings.map((warning) => warning.field),
        ['prompt.assistant.reasoning'],
      );
      expect(
        openaiResponsesRequest.body['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': 'Continue from the previous reasoning.',
              },
            ],
          },
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'output_text',
                'text': 'Visible answer.',
              },
            ],
          },
        ],
      );

      final openaiChatRequest = openaiChat.encodeRequest(
        modelId: 'gpt-4.1-mini',
        prompt: prompt,
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        providerOptions: const ResolvedOpenAIGenerateTextOptions(),
        stream: false,
      );

      expect(
        openaiChatRequest.warnings.map((warning) => warning.field),
        ['prompt.assistant.parts'],
      );
      expect(
        openaiChatRequest.body['messages'],
        [
          {
            'role': 'user',
            'content': 'Continue from the previous reasoning.',
          },
          {
            'role': 'assistant',
            'content': 'Visible answer.',
          },
        ],
      );
    });
  });
}

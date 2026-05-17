import 'dart:convert';

import 'package:llm_dart_ollama/llm_dart_ollama.dart';
import 'package:llm_dart_ollama/src/ollama_chat_request_codec.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OllamaChatRequestCodec', () {
    test('projects shared and provider options into Ollama request body',
        () async {
      final codec = OllamaChatRequestCodec(
        modelId: 'llama3.2',
        settings: const OllamaChatModelSettings(),
      );

      final prepared = await codec.encode(
        request: GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Say hi.'),
          ],
          options: GenerateTextOptions(
            temperature: 0.3,
            topP: 0.8,
            topK: 40,
            maxOutputTokens: 128,
            seed: 123,
            stopSequences: const ['STOP'],
            presencePenalty: 0.1,
            frequencyPenalty: 0.2,
            reasoning: const GenerateTextReasoningOptions.enabled(
              effort: ReasoningEffort.low,
              budgetTokens: 256,
            ),
            responseFormat: JsonResponseFormat(
              schema: JsonSchema.object(
                properties: {
                  'answer': {
                    'type': 'string',
                  },
                },
                required: ['answer'],
              ),
              name: 'answer',
              description: 'A structured answer.',
              strict: true,
            ),
          ),
          callOptions: const CallOptions(
            providerOptions: OllamaGenerateTextOptions(
              numCtx: 4096,
              numGpu: 1,
              numThread: 8,
              numBatch: 64,
              numa: true,
              keepAlive: '5m',
              raw: false,
              reasoning: false,
            ),
          ),
        ),
        stream: true,
      );

      expect(
        prepared.body,
        {
          'model': 'llama3.2',
          'messages': [
            {
              'role': 'user',
              'content': 'Say hi.',
            },
          ],
          'stream': true,
          'options': {
            'temperature': 0.3,
            'top_p': 0.8,
            'top_k': 40,
            'num_predict': 128,
            'seed': 123,
            'stop': ['STOP'],
            'num_ctx': 4096,
            'num_gpu': 1,
            'num_thread': 8,
            'num_batch': 64,
            'numa': true,
          },
          'format': {
            'type': 'object',
            'properties': {
              'answer': {
                'type': 'string',
              },
            },
            'required': ['answer'],
          },
          'keep_alive': '5m',
          'raw': false,
          'think': false,
        },
      );
      expect(
        prepared.warnings.map((warning) => warning.field),
        containsAll([
          'options.reasoning.effort',
          'options.reasoning.budgetTokens',
          'options.reasoning',
          'options.frequencyPenalty',
          'options.presencePenalty',
          'options.responseFormat',
        ]),
      );
    });

    test('uses call-level binary resolver for image file prompt parts',
        () async {
      final codec = OllamaChatRequestCodec(
        modelId: 'llama3.2-vision',
        settings: OllamaChatModelSettings(
          binaryResolver: (uri, {required mediaType, filename}) {
            return utf8.encode('model-bytes');
          },
        ),
      );

      final prepared = await codec.encode(
        request: GenerateTextRequest(
          prompt: [
            UserPromptMessage(
              parts: [
                const TextPromptPart('Describe this image'),
                FilePromptPart(
                  mediaType: 'image/png',
                  filename: 'cat.png',
                  data: FileUrlData(Uri.parse('https://example.test/cat.png')),
                ),
              ],
            ),
          ],
          callOptions: CallOptions(
            providerOptions: OllamaGenerateTextOptions(
              binaryResolver: (uri, {required mediaType, filename}) {
                expect(uri.toString(), 'https://example.test/cat.png');
                expect(mediaType, 'image/png');
                expect(filename, 'cat.png');
                return utf8.encode('call-bytes');
              },
            ),
          ),
        ),
        stream: false,
      );

      expect(
        prepared.body,
        {
          'model': 'llama3.2-vision',
          'messages': [
            {
              'role': 'user',
              'content': 'Describe this image',
              'images': [base64Encode(utf8.encode('call-bytes'))],
            },
          ],
          'stream': false,
        },
      );
    });

    test('rejects non-image file prompt parts on the chat path', () async {
      final codec = OllamaChatRequestCodec(
        modelId: 'llama3.2',
        settings: const OllamaChatModelSettings(),
      );

      await expectLater(
        () => codec.encode(
          request: GenerateTextRequest(
            prompt: [
              UserPromptMessage(
                parts: [
                  FilePromptPart(
                    mediaType: 'application/pdf',
                    data: FileBytesData.constBytes([1, 2, 3]),
                  ),
                ],
              ),
            ],
          ),
          stream: false,
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('only supports image multimodal file prompt parts'),
          ),
        ),
      );
    });
  });
}

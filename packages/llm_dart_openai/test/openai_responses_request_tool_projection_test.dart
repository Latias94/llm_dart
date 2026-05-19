import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_openai/src/openai_responses_request_tool_codec.dart';
import 'package:llm_dart_openai/src/openai_responses_request_tool_projection.dart';
import 'package:llm_dart_openai/src/openai_responses_tool_choice_projection.dart';
import 'package:llm_dart_openai/src/openai_responses_tool_output_projection.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses request tool projection', () {
    test('encodes function and built-in tools in request order', () {
      const projection = OpenAIResponsesRequestToolProjection();

      expect(
        projection.encode(
          tools: [
            FunctionToolDefinition(
              name: 'weather',
              description: 'Get weather.',
              inputSchema: ToolJsonSchema.object(
                properties: {
                  'city': {'type': 'string'},
                },
                required: ['city'],
              ),
              strict: false,
            ),
          ],
          builtInTools: const [
            OpenAIWebSearchTool(),
            OpenAIWebSearchTool.current(
              externalWebAccess: true,
              filters: OpenAIWebSearchFilters(
                allowedDomains: ['example.com'],
              ),
            ),
            OpenAIFileSearchTool(vectorStoreIds: ['vs_1']),
          ],
        ),
        [
          {
            'type': 'function',
            'name': 'weather',
            'description': 'Get weather.',
            'parameters': {
              'type': 'object',
              'properties': {
                'city': {'type': 'string'},
              },
              'required': ['city'],
            },
            'strict': false,
          },
          {
            'type': 'web_search_preview',
          },
          {
            'type': 'web_search',
            'filters': {
              'allowed_domains': ['example.com'],
            },
            'external_web_access': true,
          },
          {
            'type': 'file_search',
            'vector_store_ids': ['vs_1'],
          },
        ],
      );
    });

    test('encodes OpenAI function tool provider options', () {
      const projection = OpenAIResponsesRequestToolProjection();

      expect(
        projection.encode(
          tools: [
            FunctionToolDefinition(
              name: 'weather',
              inputSchema: ToolJsonSchema.object(),
              strict: true,
              providerOptions: const OpenAIToolOptions(
                strict: false,
                deferLoading: true,
              ),
            ),
          ],
          builtInTools: null,
        ),
        [
          {
            'type': 'function',
            'name': 'weather',
            'parameters': {
              'type': 'object',
            },
            'strict': false,
            'defer_loading': true,
          },
        ],
      );
    });
  });

  group('OpenAI Responses tool choice projection', () {
    test('encodes function and provider-native tool choices', () {
      const projection = OpenAIResponsesToolChoiceProjection();

      expect(
        projection.encode(
          const SpecificToolChoice('weather'),
          hasFunctionTools: true,
        ),
        {
          'type': 'function',
          'name': 'weather',
        },
      );
      expect(
        projection.encode(
          const SpecificToolChoice('file_search'),
          hasFunctionTools: false,
          builtInTools: const [
            OpenAIFileSearchTool(vectorStoreIds: ['vs_1']),
          ],
        ),
        {'type': 'file_search'},
      );
      expect(
        projection.encode(
          const SpecificToolChoice('web_search'),
          hasFunctionTools: false,
          builtInTools: const [
            OpenAIWebSearchTool.current(),
          ],
        ),
        {'type': 'web_search'},
      );
      expect(
        projection.encode(
          const SpecificToolChoice('grammar'),
          hasFunctionTools: false,
          builtInTools: const [
            OpenAICustomTool(name: 'grammar'),
          ],
        ),
        {
          'type': 'custom',
          'name': 'grammar',
        },
      );
      expect(
        projection.encode(const AutoToolChoice(), hasFunctionTools: true),
        'auto',
      );
      expect(
        projection.encode(const RequiredToolChoice(), hasFunctionTools: true),
        'required',
      );
      expect(
        projection.encode(const NoneToolChoice(), hasFunctionTools: true),
        'none',
      );
      expect(
        projection.encode(const SpecificToolChoice('weather'),
            hasFunctionTools: false),
        isNull,
      );
    });
  });

  group('OpenAI Responses tool output projection', () {
    test('encodes structured content tool outputs', () {
      const projection = OpenAIResponsesToolOutputProjection();

      expect(
        projection.encode(
          ContentToolOutput(
            parts: const [
              TextToolOutputContentPart('forecast'),
              JsonToolOutputContentPart({'summary': 'ok'}),
              FileToolOutputContentPart(
                mediaType: 'image/png',
                filename: 'chart.png',
                data: FileBytesData.constBytes([1, 2, 3]),
                providerOptions: OpenAIPromptPartOptions(
                  imageDetail: 'high',
                ),
              ),
              FileToolOutputContentPart(
                mediaType: 'application/pdf',
                filename: 'report.pdf',
                data: FileProviderReferenceData(
                  ProviderReference({'openai': 'file_pdf_1'}),
                ),
              ),
              CustomToolOutputContentPart(
                kind: 'demo.custom',
                data: {'flag': true},
              ),
            ],
          ),
        ),
        [
          {
            'type': 'input_text',
            'text': 'forecast',
          },
          {
            'type': 'input_text',
            'text': '{"summary":"ok"}',
          },
          {
            'type': 'input_image',
            'image_url': 'data:image/png;base64,AQID',
            'detail': 'high',
          },
          {
            'type': 'input_file',
            'file_id': 'file_pdf_1',
          },
          {
            'type': 'input_text',
            'text':
                '{"type":"custom","kind":"demo.custom","data":{"flag":true}}',
          },
        ],
      );
    });

    test('reports unsupported file output data shapes', () {
      const projection = OpenAIResponsesToolOutputProjection();

      expect(
        () => projection.encode(
          ContentToolOutput(
            parts: const [
              FileToolOutputContentPart(
                mediaType: 'image/png',
                data: FileTextData('not image bytes'),
              ),
            ],
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('tool output image parts require in-memory bytes'),
          ),
        ),
      );

      expect(
        () => projection.encode(
          ContentToolOutput(
            parts: const [
              FileToolOutputContentPart(
                mediaType: 'application/pdf',
                data: FileProviderReferenceData(
                  ProviderReference({'anthropic': 'file_1'}),
                ),
              ),
            ],
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('tool output file part requires in-memory bytes'),
          ),
        ),
      );
    });

    test('keeps codec facade compatible', () {
      const codec = OpenAIResponsesRequestToolCodec();

      expect(
        codec.encodeToolOutput(const TextToolOutput('done')),
        'done',
      );
    });
  });
}

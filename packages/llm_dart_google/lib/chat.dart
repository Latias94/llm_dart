import 'dart:convert';

import 'package:dio/dio.dart' hide CancelToken;
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_provider_utils/utils/request_metadata_sanitizer.dart';
import 'client.dart';
import 'config.dart';
import 'model_path.dart';

class _GoogleBuiltRequest {
  final Map<String, dynamic> body;
  final ToolNameMapping toolNameMapping;
  final List<Map<String, dynamic>> toolWarnings;

  const _GoogleBuiltRequest({
    required this.body,
    required this.toolNameMapping,
    required this.toolWarnings,
  });
}

class _GoogleBuiltContents {
  final List<Map<String, dynamic>> contents;
  final List<Map<String, dynamic>> systemInstructionParts;

  const _GoogleBuiltContents({
    required this.contents,
    required this.systemInstructionParts,
  });
}

/// Google file upload response
class GoogleFile {
  final String name;
  final String displayName;
  final String mimeType;
  final int sizeBytes;
  final String state;
  final String? uri;

  const GoogleFile({
    required this.name,
    required this.displayName,
    required this.mimeType,
    required this.sizeBytes,
    required this.state,
    this.uri,
  });

  factory GoogleFile.fromJson(Map<String, dynamic> json) => GoogleFile(
        name: json['name'] as String,
        displayName: json['displayName'] as String,
        mimeType: json['mimeType'] as String,
        sizeBytes: int.parse(json['sizeBytes'] as String),
        state: json['state'] as String,
        uri: json['uri'] as String?,
      );

  bool get isActive => state == 'ACTIVE';
}

/// Google Chat capability implementation
///
/// This module handles all chat-related functionality for Google providers,
/// including streaming, tool calling, and reasoning model support.
class GoogleChat
    implements
        ChatCapability,
        ModelIdentityCapability,
        ChatStreamPartsCapability,
        PromptChatCapability,
        PromptChatStreamPartsCapability {
  final GoogleClient client;
  final GoogleConfig config;

  /// Cache for uploaded files to avoid re-uploading
  static final Map<String, GoogleFile> _fileCache = {};

  GoogleChat(this.client, this.config);

  @override
  String get providerId => config.providerId;

  @override
  String get modelId => config.model;

  String get _providerOptionsId => config.providerId;

  String get _providerOptionsName => config.providerOptionsName;

  Map<String, dynamic>? _scopedProviderOptions(
      ProviderOptions providerOptions) {
    final primary = providerOptions[_providerOptionsId];
    if (primary != null) return primary;

    final byName = providerOptions[_providerOptionsName];
    if (byName != null) return byName;

    return null;
  }

  String? _thoughtSignatureFromProviderOptions(
      ProviderOptions providerOptions) {
    final scoped = _scopedProviderOptions(providerOptions);
    final value = scoped?['thoughtSignature'];
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }

  bool _emitRequestMetadataEnabled() {
    final original = config.originalConfig;
    if (original == null) return false;

    final scoped = _scopedProviderOptions(original.providerOptions);
    if (scoped == null) return false;

    final direct = scoped['emitRequestMetadata'];
    if (direct is bool) return direct;

    final legacy = scoped['emit_request_metadata'];
    if (legacy is bool) return legacy;

    return false;
  }

  bool _supportedFileUrlsOnlyFromProviderOptions(
    ProviderOptions providerOptions,
  ) {
    final scoped = _scopedProviderOptions(providerOptions);
    if (scoped == null) return false;

    final direct = scoped['supportedFileUrlsOnly'];
    if (direct == true) return true;

    final raw = scoped['supportedFileUrl'] ?? scoped['supportedFileUrls'];
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map['enabled'] == true) return true;
      return map.isNotEmpty;
    }

    return false;
  }

  String get _chatEndpoint =>
      '${googleModelPath(config.model)}:generateContent';

  bool get _isVertexLikeBaseUrl {
    final url = config.baseUrl;
    return url.contains('aiplatform.googleapis.com');
  }

  bool get _shouldUseAltSseParam {
    // Gemini API (generativelanguage.googleapis.com) needs `alt=sse`.
    // Vertex AI Gemini streaming uses `:streamGenerateContent` and is already
    // streamed as SSE, so `alt=sse` is unnecessary and may be rejected by
    // strict gateways. Align with Vercel AI SDK behavior.
    if (_isVertexLikeBaseUrl) return false;
    return true;
  }

  String get _chatStreamEndpoint {
    final base = '${googleModelPath(config.model)}:streamGenerateContent';
    return _shouldUseAltSseParam ? '$base?alt=sse' : base;
  }

  Future<_GoogleBuiltRequest> _buildRequestAsync(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
    CancelToken? cancelToken,
  ) async {
    final effectiveTools = tools ?? config.tools;
    final toolNameMapping = _createToolNameMapping(effectiveTools);
    final preparedMessages = await _prepareMessages(
      messages,
      toolNameMapping: toolNameMapping,
      cancelToken: cancelToken,
    );
    final toolWarnings = <Map<String, dynamic>>[];
    return _GoogleBuiltRequest(
      body: _buildRequestBody(
          preparedMessages, effectiveTools, stream, toolNameMapping,
          toolWarnings: toolWarnings),
      toolNameMapping: toolNameMapping,
      toolWarnings: List<Map<String, dynamic>>.unmodifiable(toolWarnings),
    );
  }

  Future<_GoogleBuiltRequest> _buildPromptRequestAsync(
    Prompt prompt,
    List<Tool>? tools,
    bool stream,
    CancelToken? cancelToken,
  ) async {
    final effectiveTools = tools ?? config.tools;
    final toolNameMapping = _createToolNameMapping(effectiveTools);

    final built = await _buildPromptContentsAsync(
      prompt,
      toolNameMapping: toolNameMapping,
      cancelToken: cancelToken,
    );

    final toolWarnings = <Map<String, dynamic>>[];
    return _GoogleBuiltRequest(
      body: _buildRequestBodyFromContents(
        built.contents,
        built.systemInstructionParts,
        effectiveTools,
        stream,
        toolNameMapping,
        toolWarnings: toolWarnings,
      ),
      toolNameMapping: toolNameMapping,
      toolWarnings: List<Map<String, dynamic>>.unmodifiable(toolWarnings),
    );
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    final built = await _buildRequestAsync(messages, tools, false, cancelToken);
    final requestMetadata = _emitRequestMetadataEnabled()
        ? LLMRequestMetadataPart(
            body: sanitizeRequestBodyForMetadata(built.body),
          )
        : null;
    final responseWithHeaders = await client.postJsonWithHeaders(
      _chatEndpoint,
      built.body,
      cancelToken: cancelToken,
    );
    return _parseResponse(
      responseWithHeaders.json,
      built.toolNameMapping,
      toolWarnings: built.toolWarnings,
      responseHeaders: responseWithHeaders.headers,
      requestMetadata: requestMetadata,
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final effectiveTools = tools ?? config.tools;
    final built =
        await _buildRequestAsync(messages, effectiveTools, true, cancelToken);
    yield* _chatStreamPartsFromBuilt(built, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatPrompt(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async {
    final built =
        await _buildPromptRequestAsync(prompt, tools, false, cancelToken);
    final requestMetadata = _emitRequestMetadataEnabled()
        ? LLMRequestMetadataPart(
            body: sanitizeRequestBodyForMetadata(built.body),
          )
        : null;
    final responseWithHeaders = await client.postJsonWithHeaders(
      _chatEndpoint,
      built.body,
      cancelToken: cancelToken,
    );
    return _parseResponse(
      responseWithHeaders.json,
      built.toolNameMapping,
      toolWarnings: built.toolWarnings,
      responseHeaders: responseWithHeaders.headers,
      requestMetadata: requestMetadata,
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final built =
        await _buildPromptRequestAsync(prompt, tools, true, cancelToken);
    yield* _chatStreamPartsFromBuilt(built, cancelToken: cancelToken);
  }

  Stream<LLMStreamPart> _chatStreamPartsFromBuilt(
    _GoogleBuiltRequest built, {
    CancelToken? cancelToken,
  }) async* {
    final requestBody = built.body;
    final toolNameMapping = built.toolNameMapping;
    final toolWarnings = built.toolWarnings;

    if (_emitRequestMetadataEnabled()) {
      yield LLMRequestMetadataPart(
        body: sanitizeRequestBodyForMetadata(requestBody),
      );
    }

    if (toolWarnings.isNotEmpty) {
      yield LLMStreamStartPart(warnings: toolWarnings);
    }

    final sseParser = SseChunkParser();
    bool? useSse;
    var streamBuffer = '';
    final nameCounts = <String, int>{};

    var inText = false;
    var inThinking = false;

    final fullText = StringBuffer();
    final fullThinking = StringBuffer();
    final currentText = StringBuffer();
    final currentThinking = StringBuffer();

    String? currentTextBlockId;
    String? currentThinkingBlockId;
    var blockCounter = 0;

    final functionCallParts = <Map<String, dynamic>>[];
    Map<String, dynamic>? usageMetadata;

    String? modelVersion;
    var didEmitResponseMetadata = false;
    dynamic promptFeedback;
    dynamic safetyRatings;
    dynamic groundingMetadata;
    dynamic urlContextMetadata;

    final sources = SourcePartEmitter(
      providerMetadataNamespace: _providerOptionsName,
      defaultProviderMetadataPayload: {'type': 'groundingMetadata'},
    );

    String mediaTypeForUri(String uri) {
      if (uri.endsWith('.pdf')) return 'application/pdf';
      if (uri.endsWith('.txt')) return 'text/plain';
      if (uri.endsWith('.docx')) {
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      }
      if (uri.endsWith('.doc')) return 'application/msword';
      if (RegExp(r'\.(md|markdown)$').hasMatch(uri)) return 'text/markdown';
      return 'application/octet-stream';
    }

    final startedToolCalls = <String>{};
    final endedToolCalls = <String>{};
    var codeExecutionSeq = 0;
    String? lastCodeExecutionToolCallId;
    final providerToolParts = ProviderToolPartEmitter(
      providerMetadataNamespace: _providerOptionsName,
    );

    List<Map<String, dynamic>> extractJsonObjects(String chunk) {
      streamBuffer += chunk;
      final results = <Map<String, dynamic>>[];

      while (true) {
        final start = streamBuffer.indexOf('{');
        if (start == -1) {
          // Keep at most a small tail to avoid unbounded growth on junk.
          if (streamBuffer.length > 8192) {
            streamBuffer = streamBuffer.substring(streamBuffer.length - 8192);
          }
          return results;
        }

        if (start > 0) {
          streamBuffer = streamBuffer.substring(start);
        }

        var depth = 0;
        var inString = false;
        var escaped = false;
        int? end;

        for (var i = 0; i < streamBuffer.length; i++) {
          final ch = streamBuffer.codeUnitAt(i);

          if (inString) {
            if (escaped) {
              escaped = false;
              continue;
            }
            if (ch == 0x5C) {
              escaped = true;
              continue;
            }
            if (ch == 0x22) {
              inString = false;
            }
            continue;
          }

          if (ch == 0x22) {
            inString = true;
            continue;
          }

          if (ch == 0x7B) {
            depth++;
            continue;
          }
          if (ch == 0x7D) {
            depth--;
            if (depth == 0) {
              end = i;
              break;
            }
          }
        }

        if (end == null) {
          return results; // Need more data.
        }

        final jsonStr = streamBuffer.substring(0, end + 1);
        try {
          final decoded = jsonDecode(jsonStr);
          if (decoded is Map<String, dynamic>) {
            results.add(decoded);
          }
        } catch (_) {
          // Ignore malformed object and continue searching.
        }

        streamBuffer = streamBuffer.substring(end + 1);
      }
    }

    Iterable<Map<String, dynamic>> decodeEventPayload(String data) sync* {
      if (data.isEmpty || data == '[DONE]') return;

      Object? decoded;
      try {
        decoded = jsonDecode(data);
      } catch (_) {
        return;
      }

      if (decoded is Map) {
        yield Map<String, dynamic>.from(decoded);
        return;
      }

      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            yield Map<String, dynamic>.from(item);
          }
        }
      }
    }

    Iterable<Map<String, dynamic>> jsonObjectsFromChunk(String chunk) sync* {
      if (useSse == true) {
        for (final event in sseParser.parse(chunk)) {
          yield* decodeEventPayload(event.data);
        }
        return;
      }
      yield* extractJsonObjects(chunk);
    }

    String nextToolCallId(String name) {
      final count = nameCounts[name] ?? 0;
      nameCounts[name] = count + 1;
      return count == 0 ? 'call_$name' : 'call_${name}_$count';
    }

    List<LLMStreamPart> closeOpenBlocks() {
      final parts = <LLMStreamPart>[];
      if (inText) {
        inText = false;
        parts.add(
          LLMTextEndPart(
            currentText.toString(),
            blockId: currentTextBlockId,
          ),
        );
        currentText.clear();
        currentTextBlockId = null;
      }
      if (inThinking) {
        inThinking = false;
        parts.add(
          LLMReasoningEndPart(
            currentThinking.toString(),
            blockId: currentThinkingBlockId,
          ),
        );
        currentThinking.clear();
        currentThinkingBlockId = null;
      }
      for (final id in startedToolCalls) {
        if (endedToolCalls.add(id)) {
          parts.add(LLMToolCallEndPart(id));
        }
      }
      return parts;
    }

    final streamed = await client.postStreamRawWithHeaders(
      _chatStreamEndpoint,
      requestBody,
      cancelToken: cancelToken,
    );
    final responseHeaders = streamed.headers;
    final stream = streamed.stream;

    await for (final chunk in stream) {
      if (useSse == null) {
        final trimmed = chunk.trimLeft();
        if (trimmed.isEmpty) continue;
        useSse = !(trimmed.startsWith('[') || trimmed.startsWith('{'));
      }

      for (final json in jsonObjectsFromChunk(chunk)) {
        if (json.containsKey('error')) {
          try {
            throw _handleGoogleApiError(json);
          } catch (e) {
            final err =
                e is LLMError ? e : ProviderError('Google API error: $e');
            yield LLMErrorPart(err);
            return;
          }
        }

        final candidates = json['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) continue;

        final candidate = candidates.first as Map<String, dynamic>;

        final mv = json['modelVersion'] as String?;
        if (mv != null && mv.isNotEmpty) {
          modelVersion = mv;
          if (!didEmitResponseMetadata) {
            didEmitResponseMetadata = true;
            yield LLMResponseMetadataPart(
              model: modelVersion,
              headers: responseHeaders.isEmpty ? null : responseHeaders,
              raw: {'modelVersion': modelVersion},
            );
          }
        }

        final pf = json['promptFeedback'];
        if (pf != null) promptFeedback = pf;

        final sr = candidate['safetyRatings'];
        if (sr != null) safetyRatings = sr;

        final gm = candidate['groundingMetadata'];
        if (gm != null) {
          groundingMetadata = gm;
          if (gm is Map) {
            final chunks = gm['groundingChunks'];
            if (chunks is List) {
              for (final chunk in chunks) {
                if (chunk is! Map) continue;

                final web = chunk['web'];
                if (web is Map) {
                  final uri = web['uri'];
                  if (uri is String && uri.isNotEmpty) {
                    final p = sources.url(
                      uri,
                      title: web['title'] is String
                          ? web['title'] as String
                          : null,
                    );
                    if (p != null) yield p;
                  }
                }

                final retrieved = chunk['retrievedContext'];
                if (retrieved is Map) {
                  final uri = retrieved['uri'];
                  final fileSearchStore = retrieved['fileSearchStore'];
                  final urlTitle = retrieved['title'] is String
                      ? retrieved['title'] as String
                      : null;
                  final docTitle = urlTitle ?? 'Unknown Document';

                  if (uri is String && uri.isNotEmpty) {
                    if (uri.startsWith('http://') ||
                        uri.startsWith('https://')) {
                      final p = sources.url(uri, title: urlTitle);
                      if (p != null) yield p;
                    } else {
                      final filename =
                          uri.split('/').isEmpty ? null : uri.split('/').last;
                      final p = sources.document(
                        docTitle,
                        mediaType: mediaTypeForUri(uri),
                        filename: filename,
                        dedupeKey: 'docUri:$uri',
                      );
                      if (p != null) yield p;
                    }
                  } else if (fileSearchStore is String &&
                      fileSearchStore.isNotEmpty) {
                    final filename = fileSearchStore.split('/').isEmpty
                        ? null
                        : fileSearchStore.split('/').last;
                    final p = sources.document(
                      docTitle,
                      mediaType: 'application/octet-stream',
                      filename: filename,
                      dedupeKey: 'fileSearchStore:$fileSearchStore',
                    );
                    if (p != null) yield p;
                  }
                }

                final maps = chunk['maps'];
                if (maps is Map) {
                  final uri = maps['uri'];
                  if (uri is String && uri.isNotEmpty) {
                    final p = sources.url(
                      uri,
                      title: maps['title'] is String
                          ? maps['title'] as String
                          : null,
                    );
                    if (p != null) yield p;
                  }
                }
              }
            }
          }
        }

        final ucm = candidate['urlContextMetadata'];
        if (ucm != null) urlContextMetadata = ucm;

        final content = candidate['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List?;

        if (json['usageMetadata'] is Map<String, dynamic>) {
          usageMetadata = json['usageMetadata'] as Map<String, dynamic>;
        } else if (json['usageMetadata'] is Map) {
          usageMetadata =
              Map<String, dynamic>.from(json['usageMetadata'] as Map);
        }

        if (parts != null) {
          for (final part in parts) {
            if (part is! Map<String, dynamic>) continue;

            final executableCode =
                part['executableCode'] as Map<String, dynamic>?;
            if (executableCode != null) {
              final code = executableCode['code'] as String?;
              if (code != null && code.isNotEmpty) {
                final id = 'code_execution_${codeExecutionSeq++}';
                lastCodeExecutionToolCallId = id;
                final toolName = resolveProviderToolName(
                  providerId: config.providerId,
                  rawToolName: 'code_execution',
                  providerTools: config.originalConfig?.providerTools,
                );
                final part = providerToolParts.call(
                  toolCallId: id,
                  toolName: toolName,
                  input: executableCode,
                  providerExecuted: true,
                  supportsDeferredResults: true,
                  providerMetadataPayload: const {'type': 'code_execution'},
                );
                if (part != null) yield part;
              }
              continue;
            }

            final codeExecutionResult =
                part['codeExecutionResult'] as Map<String, dynamic>?;
            if (codeExecutionResult != null) {
              final toolCallId = lastCodeExecutionToolCallId;
              if (toolCallId != null) {
                final part = providerToolParts.result(
                  toolCallId: toolCallId,
                  toolName: 'code_execution',
                  result: {
                    'outcome': codeExecutionResult['outcome'],
                    'output': codeExecutionResult['output'],
                  },
                  providerMetadataPayload: const {
                    'type': 'code_execution_result',
                  },
                );
                if (part != null) yield part;
                lastCodeExecutionToolCallId = null;
              }
              continue;
            }

            final functionCall = part['functionCall'] as Map<String, dynamic>?;
            if (functionCall != null) {
              final requestName = functionCall['name'] as String? ?? '';
              final args = functionCall['args'] as Map<String, dynamic>? ?? {};
              if (requestName.isNotEmpty) {
                if (toolNameMapping.providerToolIdForRequestName(requestName) !=
                    null) {
                  continue;
                }
                final name = toolNameMapping
                        .originalFunctionNameForRequestName(requestName) ??
                    requestName;
                final id = nextToolCallId(name);
                final thoughtSignature = part['thoughtSignature'];
                final providerOptions = thoughtSignature == null
                    ? const <String, Map<String, dynamic>>{}
                    : <String, Map<String, dynamic>>{
                        _providerOptionsName: {
                          'thoughtSignature': thoughtSignature.toString(),
                        },
                      };
                final toolCall = ToolCall(
                  id: id,
                  callType: 'function',
                  function: FunctionCall(
                    name: name,
                    arguments: jsonEncode(args),
                  ),
                  providerOptions: providerOptions,
                );
                startedToolCalls.add(id);
                functionCallParts.add({
                  'functionCall': {
                    'name': name,
                    'args': args,
                  },
                });
                yield LLMToolCallStartPart(toolCall);
                if (endedToolCalls.add(id)) {
                  yield LLMToolCallEndPart(id);
                }
              }
              continue;
            }

            final inlineData = part['inlineData'] as Map<String, dynamic>?;
            if (inlineData != null) {
              final mimeType = inlineData['mimeType'] as String?;
              final data = inlineData['data'] as String?;
              if (mimeType != null &&
                  mimeType.isNotEmpty &&
                  data != null &&
                  data.isNotEmpty) {
                // Gemini returns generated outputs (images/audio) as inlineData.
                // Preserve the raw base64 payload as a v3 `file` part.
                yield LLMFilePart(mediaType: mimeType, data: data);
              }
              continue;
            }

            final isThought = part['thought'] as bool? ?? false;
            final text = part['text'] as String?;
            if (text != null && text.isNotEmpty) {
              final thoughtSignature = part['thoughtSignature'];
              final partProviderMetadata = thoughtSignature == null
                  ? null
                  : <String, dynamic>{
                      _providerOptionsName: {
                        'thoughtSignature': thoughtSignature.toString(),
                      },
                    };
              if (isThought) {
                if (inText) {
                  inText = false;
                  yield LLMTextEndPart(
                    currentText.toString(),
                    blockId: currentTextBlockId,
                  );
                  currentText.clear();
                  currentTextBlockId = null;
                }
                if (!inThinking) {
                  inThinking = true;
                  currentThinkingBlockId ??= '${blockCounter++}';
                  yield LLMReasoningStartPart(
                    blockId: currentThinkingBlockId,
                    providerMetadata: partProviderMetadata,
                  );
                  currentThinking.clear();
                }
                fullThinking.write(text);
                currentThinking.write(text);
                yield LLMReasoningDeltaPart(
                  text,
                  blockId: currentThinkingBlockId,
                  providerMetadata: partProviderMetadata,
                );
              } else {
                if (inThinking) {
                  inThinking = false;
                  yield LLMReasoningEndPart(
                    currentThinking.toString(),
                    blockId: currentThinkingBlockId,
                  );
                  currentThinking.clear();
                  currentThinkingBlockId = null;
                }
                if (!inText) {
                  inText = true;
                  currentTextBlockId ??= '${blockCounter++}';
                  yield LLMTextStartPart(
                    blockId: currentTextBlockId,
                    providerMetadata: partProviderMetadata,
                  );
                  currentText.clear();
                }
                fullText.write(text);
                currentText.write(text);
                yield LLMTextDeltaPart(
                  text,
                  blockId: currentTextBlockId,
                  providerMetadata: partProviderMetadata,
                );
              }
            }
          }
        }

        final finishReason = candidate['finishReason'] as String?;
        if (finishReason != null) {
          for (final part in closeOpenBlocks()) {
            yield part;
          }

          final responseParts = <Map<String, dynamic>>[
            if (fullThinking.isNotEmpty)
              {'text': fullThinking.toString(), 'thought': true},
            if (fullText.isNotEmpty) {'text': fullText.toString()},
            ...functionCallParts,
          ];

          final response = GoogleChatResponse({
            'modelVersion': modelVersion ?? config.model,
            'candidates': [
              {
                'content': {'parts': responseParts},
                'finishReason': finishReason,
                if (safetyRatings != null) 'safetyRatings': safetyRatings,
                if (groundingMetadata != null)
                  'groundingMetadata': groundingMetadata,
                if (urlContextMetadata != null)
                  'urlContextMetadata': urlContextMetadata,
              },
            ],
            if (promptFeedback != null) 'promptFeedback': promptFeedback,
            if (usageMetadata != null) 'usageMetadata': usageMetadata,
          },
              toolNameMapping: toolNameMapping,
              toolWarnings: toolWarnings,
              providerOptionsName: _providerOptionsName);

          final metadata = response.providerMetadata;
          if (metadata != null && metadata.isNotEmpty) {
            yield LLMProviderMetadataPart(metadata);
          }
          yield LLMFinishPart(
            response,
            usage: response.usage,
            finishReason: response.finishReason,
          );
          return;
        }
      }
    }

    // Best-effort finish if stream ends unexpectedly.
    for (final part in closeOpenBlocks()) {
      yield part;
    }
    final responseParts = <Map<String, dynamic>>[
      if (fullThinking.isNotEmpty)
        {'text': fullThinking.toString(), 'thought': true},
      if (fullText.isNotEmpty) {'text': fullText.toString()},
      ...functionCallParts,
    ];
    final response = GoogleChatResponse({
      'modelVersion': modelVersion ?? config.model,
      'candidates': [
        {
          'content': {'parts': responseParts},
          if (safetyRatings != null) 'safetyRatings': safetyRatings,
          if (groundingMetadata != null) 'groundingMetadata': groundingMetadata,
          if (urlContextMetadata != null)
            'urlContextMetadata': urlContextMetadata,
        },
      ],
      if (promptFeedback != null) 'promptFeedback': promptFeedback,
      if (usageMetadata != null) 'usageMetadata': usageMetadata,
    },
        toolNameMapping: toolNameMapping,
        toolWarnings: toolWarnings,
        providerOptionsName: _providerOptionsName);
    final metadata = response.providerMetadata;
    if (metadata != null && metadata.isNotEmpty) {
      yield LLMProviderMetadataPart(metadata);
    }
    yield LLMFinishPart(
      response,
      usage: response.usage,
      finishReason: response.finishReason,
    );
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    final prompt =
        'Summarize in 2-3 sentences:\n${messages.map((m) => '${m.role.name}: ${m.content}').join('\n')}';
    final request = [ChatMessage.user(prompt)];
    final response = await chat(request);
    final text = response.text;
    if (text == null) {
      throw const GenericError('no text in summary response');
    }
    return text;
  }

  /// Upload a file to Google AI Files API
  Future<GoogleFile> uploadFile({
    required List<int> data,
    required String mimeType,
    required String displayName,
    CancelToken? cancelToken,
  }) async {
    try {
      // Create file metadata
      final metadata = {
        'file': {
          'displayName': displayName,
          'mimeType': mimeType,
        }
      };

      // Create multipart form data
      final formData = FormData.fromMap({
        'metadata': jsonEncode(metadata),
        'data': MultipartFile.fromBytes(
          data,
          filename: displayName,
        ),
      });

      final uri = _buildUploadUri();
      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => client.dio.postUri(
          uri,
          data: formData,
          options: Options(
            headers: {
              'X-Goog-Upload-Protocol': 'multipart',
            },
          ),
          cancelToken: dioToken,
        ),
      );

      if (response.statusCode != 200) {
        final errorMessage = response.data?['error']?['message'] ??
            'File upload failed: ${response.statusCode}';
        throw ProviderError(errorMessage);
      }

      final fileData = response.data['file'] as Map<String, dynamic>;
      final uploadedFile = GoogleFile.fromJson(fileData);

      // Cache the uploaded file
      final cacheKey = '${displayName}_${data.length}_$mimeType';
      _fileCache[cacheKey] = uploadedFile;

      return uploadedFile;
    } on DioException catch (e) {
      throw await _handleDioError(e);
    } catch (e) {
      throw GenericError('File upload error: $e');
    }
  }

  /// Get or upload a file, using cache when possible
  Future<GoogleFile?> getOrUploadFile({
    required List<int> data,
    required String mimeType,
    required String displayName,
    CancelToken? cancelToken,
  }) async {
    final cacheKey = '${displayName}_${data.length}_$mimeType';

    // Check cache first
    final cachedFile = _fileCache[cacheKey];
    if (cachedFile != null && cachedFile.isActive) {
      return cachedFile;
    }

    // Upload new file
    try {
      return await uploadFile(
        data: data,
        mimeType: mimeType,
        displayName: displayName,
        cancelToken: cancelToken,
      );
    } catch (e) {
      client.logger.warning('File upload failed: $e');
      return null;
    }
  }

  /// Handle Dio errors and convert to appropriate LLM errors
  Future<LLMError> _handleDioError(DioException e) async {
    // Handle Google-specific error response format first
    if (e.response?.data is Map<String, dynamic>) {
      final errorData = e.response!.data as Map<String, dynamic>;
      try {
        return _handleGoogleApiError(errorData);
      } catch (googleError) {
        if (googleError is LLMError) {
          return googleError;
        }
      }
    }

    // Fall back to standard error handling
    return await DioErrorHandler.handleDioError(e, 'Google');
  }

  /// Handle Google API error response format
  LLMError _handleGoogleApiError(Map<String, dynamic> responseData) {
    if (!responseData.containsKey('error')) {
      throw ArgumentError('No error found in response data');
    }

    final error = responseData['error'] as Map<String, dynamic>;
    final message = error['message'] as String? ?? 'Unknown error';
    final details = error['details'] as List?;

    // Handle specific Google API error types
    if (details != null) {
      for (final detail in details) {
        if (detail is Map && detail['reason'] == 'API_KEY_INVALID') {
          return const AuthError('Invalid Google API key');
        }
      }
    }

    return ProviderError('Google API error: $message');
  }

  /// Parse response from Google API
  GoogleChatResponse _parseResponse(
    Map<String, dynamic> responseData,
    ToolNameMapping toolNameMapping, {
    List<Map<String, dynamic>> toolWarnings = const [],
    Map<String, String>? responseHeaders,
    LLMRequestMetadataPart? requestMetadata,
  }) {
    // Check for Google API errors first
    if (responseData.containsKey('error')) {
      throw _handleGoogleApiError(responseData);
    }

    final mv = responseData['modelVersion'] as String?;
    final model =
        (mv != null && mv.isNotEmpty) ? mv : (responseData['model'] as String?);
    final headers = (responseHeaders != null && responseHeaders.isNotEmpty)
        ? responseHeaders
        : null;

    final responseMetadata = (model != null || headers != null)
        ? LLMResponseMetadataPart(
            model: model,
            headers: headers,
            body: responseData,
            raw: {
              if (mv != null && mv.isNotEmpty) 'modelVersion': mv,
            },
          )
        : null;

    return GoogleChatResponse(
      responseData,
      toolNameMapping: toolNameMapping,
      toolWarnings: toolWarnings,
      providerOptionsName: _providerOptionsName,
      responseMetadata: responseMetadata,
      requestMetadata: requestMetadata,
    );
  }

  /// Build request body for Google API
  Map<String, dynamic> _buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
    ToolNameMapping toolNameMapping, {
    required List<Map<String, dynamic>> toolWarnings,
  }) {
    final contents = <Map<String, dynamic>>[];

    final systemInstructionParts = <Map<String, dynamic>>[];

    // Convert messages to Google format
    var systemMessagesAllowed = true;
    for (final message in messages) {
      if (message.role == ChatRole.system) {
        if (!systemMessagesAllowed) {
          throw const InvalidRequestError(
            'Google system messages are only supported at the beginning of the conversation.',
          );
        }
        if (message.messageType is! TextMessage) {
          throw const InvalidRequestError(
            'Google system messages must be plain text.',
          );
        }
        if (message.content.trim().isNotEmpty) {
          systemInstructionParts.add({'text': message.content});
        }
        continue;
      }

      systemMessagesAllowed = false;

      contents.add(_convertMessage(message, toolNameMapping));
    }

    return _buildRequestBodyFromContents(
      contents,
      systemInstructionParts,
      tools,
      stream,
      toolNameMapping,
      toolWarnings: toolWarnings,
    );
  }

  Map<String, dynamic> _buildRequestBodyFromContents(
    List<Map<String, dynamic>> contents,
    List<Map<String, dynamic>> systemInstructionParts,
    List<Tool>? tools,
    bool stream,
    ToolNameMapping toolNameMapping, {
    required List<Map<String, dynamic>> toolWarnings,
  }) {
    // Prefer explicit system messages over config.systemPrompt.
    if (systemInstructionParts.isEmpty &&
        config.systemPrompt != null &&
        config.systemPrompt!.trim().isNotEmpty) {
      systemInstructionParts.add({'text': config.systemPrompt});
    }

    if (_isGemmaModel() &&
        systemInstructionParts.isNotEmpty &&
        contents.isNotEmpty &&
        contents.first['role'] == 'user') {
      final systemText = systemInstructionParts
          .map((p) => p['text'])
          .whereType<String>()
          .join('\n\n');

      final firstParts = contents.first['parts'];
      if (firstParts is List) {
        firstParts.insert(0, {'text': '$systemText\n\n'});
      }
    }

    final body = _buildBodyWithConfig(
      contents,
      tools,
      stream,
      toolNameMapping,
      toolWarnings: toolWarnings,
    );
    if (!_isGemmaModel() && systemInstructionParts.isNotEmpty) {
      body['systemInstruction'] = {
        'parts': systemInstructionParts,
      };
    }
    return body;
  }

  Future<_GoogleBuiltContents> _buildPromptContentsAsync(
    Prompt prompt, {
    required ToolNameMapping toolNameMapping,
    CancelToken? cancelToken,
  }) async {
    final contents = <Map<String, dynamic>>[];
    final systemInstructionParts = <Map<String, dynamic>>[];

    var systemMessagesAllowed = true;

    for (final message in prompt.messages) {
      if (message.role == PromptRole.system) {
        if (!systemMessagesAllowed) {
          throw const InvalidRequestError(
            'Google system messages are only supported at the beginning of the conversation.',
          );
        }
        for (final part in message.parts) {
          if (part case TextPart(:final text)) {
            if (text.trim().isNotEmpty) {
              systemInstructionParts.add({'text': text});
            }
            continue;
          }
          throw const InvalidRequestError(
            'Google system messages must be plain text.',
          );
        }
        continue;
      }

      systemMessagesAllowed = false;

      String? currentRole;
      final currentParts = <Map<String, dynamic>>[];

      ProviderOptions mergeProviderOptions(
        ProviderOptions base,
        ProviderOptions override,
      ) {
        if (base.isEmpty) return override;
        if (override.isEmpty) return base;

        final merged = <String, Map<String, dynamic>>{...base};
        for (final entry in override.entries) {
          final existing = merged[entry.key];
          merged[entry.key] = {...?existing, ...entry.value};
        }
        return merged;
      }

      void flush() {
        if (currentRole == null || currentParts.isEmpty) return;
        contents.add({
          'role': currentRole,
          'parts': List<Map<String, dynamic>>.from(currentParts),
        });
        currentRole = null;
        currentParts.clear();
      }

      String roleToGoogle(PromptRole role) =>
          (role == PromptRole.user || role == PromptRole.tool)
              ? 'user'
              : 'model';

      for (final part in message.parts) {
        PromptRole partRole;
        if (part case ToolCallPart(:final overrideRole)) {
          partRole = overrideRole ?? message.role;
        } else if (part case ToolResultPart(:final overrideRole)) {
          partRole = overrideRole ?? message.role;
        } else {
          partRole = message.role;
        }

        final googleRole = roleToGoogle(partRole);
        if (currentRole != null && currentRole != googleRole) {
          flush();
        }
        currentRole ??= googleRole;

        final effectiveProviderOptions =
            mergeProviderOptions(message.providerOptions, part.providerOptions);
        final thoughtSignature = partRole == PromptRole.assistant
            ? _thoughtSignatureFromProviderOptions(effectiveProviderOptions)
            : null;

        switch (part) {
          case TextPart(:final text):
            currentParts.add({
              'text': text,
              if (thoughtSignature != null)
                'thoughtSignature': thoughtSignature,
            });

          case ImagePart(:final mime, :final data, :final text):
            if (text != null && text.trim().isNotEmpty) {
              currentParts.add({
                'text': text,
                if (thoughtSignature != null)
                  'thoughtSignature': thoughtSignature,
              });
            }
            currentParts.add({
              'inlineData': {
                'mimeType': mime.mimeType,
                'data': base64Encode(data),
              },
              if (thoughtSignature != null)
                'thoughtSignature': thoughtSignature,
            });

          case ImageUrlPart(:final url, :final text):
            if (googleRole == 'model') {
              throw const InvalidRequestError(
                'Google does not support fileData URLs in assistant messages.',
              );
            }
            if (text != null && text.trim().isNotEmpty) {
              currentParts.add({'text': text});
            }
            final supportedOnly = config.supportedFileUrlsOnly ||
                _supportedFileUrlsOnlyFromProviderOptions(
                  effectiveProviderOptions,
                );
            final normalizedUrl = _normalizeGoogleFileUri(
              url,
              supportedFileUrlsOnly: supportedOnly,
            );
            currentParts.add({
              'fileData': {
                'fileUri': normalizedUrl,
                'mimeType':
                    _guessImageMimeTypeFromUrl(normalizedUrl) ?? 'image/png',
              },
            });

          case FilePart(:final mime, :final data, :final text):
            if (text != null && text.trim().isNotEmpty) {
              currentParts.add({
                'text': text,
                if (thoughtSignature != null)
                  'thoughtSignature': thoughtSignature,
              });
            }
            if (data.length > config.maxInlineDataSize) {
              if (googleRole == 'model') {
                throw InvalidRequestError(
                  'File too large for Google inlineData in assistant messages: '
                  '${data.length} bytes (maxInlineDataSize=${config.maxInlineDataSize}).',
                );
              }
              final displayName = _defaultUploadDisplayName(
                  mimeType: mime.mimeType, data: data);
              final uploaded = await getOrUploadFile(
                data: data,
                mimeType: mime.mimeType,
                displayName: displayName,
                cancelToken: cancelToken,
              );

              if (uploaded == null) {
                throw InvalidRequestError(
                  'File too large for Google inlineData and upload failed: '
                  '${data.length} bytes (maxInlineDataSize=${config.maxInlineDataSize}).',
                );
              }

              final uri = uploaded.uri ?? uploaded.name;
              if (uri.isEmpty) {
                throw ProviderError(
                  'Google file upload returned no uri/name for displayName="$displayName".',
                );
              }

              currentParts.add({
                'fileData': {
                  'fileUri': uri,
                  'mimeType': uploaded.mimeType.isEmpty
                      ? mime.mimeType
                      : uploaded.mimeType,
                },
              });
            } else {
              currentParts.add({
                'inlineData': {
                  'mimeType': mime.mimeType,
                  'data': base64Encode(data),
                },
                if (thoughtSignature != null)
                  'thoughtSignature': thoughtSignature,
              });
            }

          case FileUrlPart(:final mime, :final url, :final text):
            if (googleRole == 'model') {
              throw const InvalidRequestError(
                'Google does not support fileData URLs in assistant messages.',
              );
            }
            if (text != null && text.trim().isNotEmpty) {
              currentParts.add({'text': text});
            }
            final supportedOnly = config.supportedFileUrlsOnly ||
                _supportedFileUrlsOnlyFromProviderOptions(
                  effectiveProviderOptions,
                );
            final trimmed = _normalizeGoogleFileUri(
              url,
              supportedFileUrlsOnly: supportedOnly,
            );
            currentParts.add({
              'fileData': {
                'fileUri': trimmed,
                'mimeType': mime.mimeType,
              },
            });

          case FileIdPart(:final mime, :final id, :final text):
            if (googleRole == 'model') {
              throw const InvalidRequestError(
                'Google does not support fileData URLs in assistant messages.',
              );
            }
            if (text != null && text.trim().isNotEmpty) {
              currentParts.add({'text': text});
            }
            final trimmed = id.trim();
            if (trimmed.isEmpty) {
              throw const InvalidRequestError(
                  'Google file id cannot be empty.');
            }
            currentParts.add({
              'fileData': {
                'fileUri': trimmed,
                'mimeType': mime.mimeType,
              },
            });

          case ToolCallPart(
              :final toolName,
              :final input,
              :final overrideRole,
            ):
            final effectiveRole = overrideRole ?? message.role;
            if (effectiveRole != PromptRole.assistant) {
              throw const InvalidRequestError(
                'ToolCallPart must be emitted from an assistant message.',
              );
            }
            final callThoughtSignature = _thoughtSignatureFromProviderOptions(
                    effectiveProviderOptions) ??
                thoughtSignature;
            final args = input is Map
                ? Map<String, dynamic>.from(input)
                : const <String, dynamic>{};
            final requestName =
                toolNameMapping.requestNameForFunction(toolName);
            currentParts.add({
              'functionCall': {
                'name': requestName,
                'args': args,
              },
              if (callThoughtSignature != null)
                'thoughtSignature': callThoughtSignature,
            });

          case ToolResultPart(
              :final toolName,
              :final output,
              :final overrideRole,
            ):
            final effectiveRole = overrideRole ?? message.role;
            if (effectiveRole != PromptRole.tool) {
              throw const InvalidRequestError(
                'ToolResultPart must be emitted from a tool message.',
              );
            }
            final requestName =
                toolNameMapping.requestNameForFunction(toolName);
            final Object content = switch (output) {
              ToolResultTextOutput(:final value) => value,
              ToolResultErrorTextOutput(:final value) => value,
              ToolResultExecutionDeniedOutput(:final reason) =>
                (reason != null && reason.trim().isNotEmpty)
                    ? reason.trim()
                    : 'Tool execution denied.',
              ToolResultJsonOutput(:final value) => value,
              ToolResultErrorJsonOutput(:final value) => value,
              ToolResultContentOutput() => output.toJson()['value']!,
            };
            currentParts.add({
              'functionResponse': {
                'name': requestName,
                'response': {
                  'name': requestName,
                  'content': content,
                },
              },
            });

          case ToolApprovalResponsePart():
            throw const InvalidRequestError(
              'ToolApprovalResponsePart is not supported by the Google provider.',
            );

          case ToolApprovalRequestPart():
            // Prompt metadata only; not required for provider requests.
            break;
        }
      }

      flush();
    }

    return _GoogleBuiltContents(
      contents: List<Map<String, dynamic>>.unmodifiable(contents),
      systemInstructionParts:
          List<Map<String, dynamic>>.unmodifiable(systemInstructionParts),
    );
  }

  /// Create request body with configuration
  Map<String, dynamic> _buildBodyWithConfig(
    List<Map<String, dynamic>> contents,
    List<Tool>? tools,
    bool isStreaming,
    ToolNameMapping toolNameMapping, {
    required List<Map<String, dynamic>> toolWarnings,
  }) {
    final body = <String, dynamic>{'contents': contents};

    // Add generation config if needed
    final generationConfig = <String, dynamic>{};

    // Standard GenerationConfig fields
    if (config.candidateCount != null) {
      generationConfig['candidateCount'] = config.candidateCount;
    }
    if (config.stopSequences != null && config.stopSequences!.isNotEmpty) {
      generationConfig['stopSequences'] = config.stopSequences;
    }
    if (config.maxTokens != null) {
      generationConfig['maxOutputTokens'] = config.maxTokens;
    }
    if (config.temperature != null) {
      generationConfig['temperature'] = config.temperature;
    }
    if (config.topP != null) {
      generationConfig['topP'] = config.topP;
    }
    if (config.topK != null) {
      generationConfig['topK'] = config.topK;
    }

    // Add structured output if configured
    if (config.jsonSchema != null && config.jsonSchema!.schema != null) {
      generationConfig['responseMimeType'] = 'application/json';

      // Remove additionalProperties if present (Google API doesn't support it)
      final schema = Map<String, dynamic>.from(config.jsonSchema!.schema!);
      schema.remove('additionalProperties');

      generationConfig['responseSchema'] = schema;
    }

    // Add thinking configuration for reasoning models
    if (config.reasoningEffort != null ||
        config.thinkingBudgetTokens != null ||
        config.includeThoughts != null) {
      final thinkingConfig = <String, dynamic>{};

      // Include thoughts in response (for getting thinking summaries)
      if (config.includeThoughts != null) {
        thinkingConfig['includeThoughts'] = config.includeThoughts;
      } else if (isStreaming) {
        // For streaming, we want to include thoughts by default to get thinking deltas
        thinkingConfig['includeThoughts'] = true;
      }

      // Set thinking budget (token limit for thinking)
      if (config.thinkingBudgetTokens != null) {
        thinkingConfig['thinkingBudget'] = config.thinkingBudgetTokens;
      }

      if (thinkingConfig.isNotEmpty) {
        generationConfig['thinkingConfig'] = thinkingConfig;
      }
    } else if (isStreaming) {
      // For streaming without explicit thinking config, still enable includeThoughts
      // to get thinking deltas in the stream
      generationConfig['thinkingConfig'] = {
        'includeThoughts': true,
      };
    }

    // Add image generation configuration
    if (config.enableImageGeneration == true) {
      if (config.responseModalities != null) {
        generationConfig['responseModalities'] = config.responseModalities;
      } else {
        // Default to text and image modalities for image generation
        generationConfig['responseModalities'] = ['TEXT', 'IMAGE'];
      }
      generationConfig['responseMimeType'] = 'text/plain';
    }

    if (generationConfig.isNotEmpty) {
      body['generationConfig'] = generationConfig;
    }

    // Add safety settings
    final effectiveSafetySettings =
        config.safetySettings ?? GoogleConfig.defaultSafetySettings;
    if (effectiveSafetySettings.isNotEmpty) {
      body['safetySettings'] =
          effectiveSafetySettings.map((s) => s.toJson()).toList();
    }

    // Add tools if provided
    final effectiveTools = tools ?? config.tools;
    final providerToolsEnabled =
        (config.originalConfig?.providerTools ?? const <ProviderTool>[])
            .any(_isProviderToolEnabled);
    final hasProviderDefinedTools =
        providerToolsEnabled || config.webSearchEnabled;

    if (hasProviderDefinedTools) {
      if (effectiveTools != null && effectiveTools.isNotEmpty) {
        toolWarnings.add({
          'type': 'unsupported',
          'feature': 'combination of function and provider-defined tools',
        });
      }
    } else {
      if (effectiveTools != null && effectiveTools.isNotEmpty) {
        body['tools'] = <Map<String, dynamic>>[
          {
            'functionDeclarations': effectiveTools
                .map((t) => _convertFunctionTool(t, toolNameMapping))
                .toList(),
          },
        ];

        final effectiveToolChoice = config.toolChoice;
        if (effectiveToolChoice != null) {
          body['toolConfig'] = _convertToolChoice(
            effectiveToolChoice,
            effectiveTools,
            toolNameMapping,
          );
        }
      }
    }

    final providerTools = config.originalConfig?.providerTools;
    if (providerTools != null && providerTools.isNotEmpty) {
      _addProviderToolsToBody(
        body,
        providerTools: providerTools,
        toolWarnings: toolWarnings,
      );
    }

    if (config.webSearchEnabled) {
      body['tools'] ??= [];
      (body['tools'] as List).add(_buildGoogleSearchTool());
    }

    return body;
  }

  Map<String, dynamic> _buildGoogleSearchTool() {
    final modelId = config.model;
    final isLatest = const [
      'gemini-flash-latest',
      'gemini-flash-lite-latest',
      'gemini-pro-latest',
    ].contains(modelId);
    final isGemini2OrNewer = modelId.contains('gemini-2') ||
        modelId.contains('gemini-3') ||
        isLatest;

    if (isGemini2OrNewer) {
      return <String, dynamic>{
        'googleSearch': <String, dynamic>{},
      };
    }

    final supportsDynamicRetrieval = _supportsDynamicRetrieval();
    final options = config.webSearchToolOptions;
    final dynamicConfig = options == null || !supportsDynamicRetrieval
        ? null
        : <String, dynamic>{
            if (options.mode != null) 'mode': options.mode!.apiValue,
            if (options.dynamicThreshold != null)
              'dynamicThreshold': options.dynamicThreshold,
          };

    return <String, dynamic>{
      'googleSearchRetrieval': <String, dynamic>{
        if (dynamicConfig != null && dynamicConfig.isNotEmpty)
          'dynamicRetrievalConfig': dynamicConfig,
      },
    };
  }

  bool _isGemini2OrNewerModel() {
    final modelId = config.model;
    final isLatest = const [
      'gemini-flash-latest',
      'gemini-flash-lite-latest',
      'gemini-pro-latest',
    ].contains(modelId);

    return modelId.contains('gemini-2') ||
        modelId.contains('gemini-3') ||
        isLatest;
  }

  bool _supportsDynamicRetrieval() {
    final modelId = config.model;
    return modelId.contains('gemini-1.5-flash') && !modelId.contains('-8b');
  }

  bool _supportsFileSearch() {
    final modelId = config.model;
    return modelId.contains('gemini-2.5') || modelId.contains('gemini-3');
  }

  void _addProviderToolsToBody(
    Map<String, dynamic> body, {
    required List<ProviderTool> providerTools,
    required List<Map<String, dynamic>> toolWarnings,
  }) {
    final enabled = providerTools.where(_isProviderToolEnabled);
    if (enabled.isEmpty) return;

    final isGemini2OrNewer = _isGemini2OrNewerModel();
    final supportsFileSearch = _supportsFileSearch();

    for (final tool in enabled) {
      Map<String, dynamic>? entry;
      String? warningDetails;

      switch (tool.id) {
        case 'google.code_execution':
          if (!isGemini2OrNewer) {
            warningDetails =
                'The code execution tools is not supported with other Gemini models than Gemini 2.';
            break;
          }
          entry = <String, dynamic>{'codeExecution': <String, dynamic>{}};
          break;

        case 'google.url_context':
          if (!isGemini2OrNewer) {
            warningDetails =
                'The URL context tool is not supported with other Gemini models than Gemini 2.';
            break;
          }
          entry = <String, dynamic>{'urlContext': <String, dynamic>{}};
          break;

        case 'google.enterprise_web_search':
          if (!isGemini2OrNewer) {
            warningDetails =
                'Enterprise Web Search requires Gemini 2.0 or newer.';
            break;
          }
          entry = <String, dynamic>{'enterpriseWebSearch': <String, dynamic>{}};
          break;

        case 'google.google_maps':
          if (!isGemini2OrNewer) {
            warningDetails =
                'The Google Maps grounding tool is not supported with Gemini models other than Gemini 2 or newer.';
            break;
          }
          entry = <String, dynamic>{'googleMaps': <String, dynamic>{}};
          break;

        case 'google.file_search':
          if (!supportsFileSearch) {
            warningDetails =
                'The file search tool is only supported with Gemini 2.5 models and Gemini 3 models.';
            break;
          }
          entry = <String, dynamic>{
            'fileSearch': <String, dynamic>{
              ...tool.options,
            }..remove('enabled'),
          };
          break;

        case 'google.vertex_rag_store':
          if (!isGemini2OrNewer) {
            warningDetails =
                'The RAG store tool is not supported with other Gemini models than Gemini 2.';
            break;
          }
          final ragCorpus = tool.options['ragCorpus'];
          if (ragCorpus is! String || ragCorpus.isEmpty) {
            client.logger.warning(
              'google.vertex_rag_store is enabled but options.ragCorpus is missing.',
            );
            toolWarnings.add({
              'type': 'unsupported',
              'feature': 'provider-defined tool google.vertex_rag_store',
              'details': 'Missing required option: ragCorpus.',
            });
            break;
          }
          final topK = tool.options['topK'];
          entry = <String, dynamic>{
            'retrieval': <String, dynamic>{
              'vertex_rag_store': <String, dynamic>{
                'rag_resources': <String, dynamic>{
                  'rag_corpus': ragCorpus,
                },
                if (topK is num) 'similarity_top_k': topK,
              },
            },
          };
          break;
      }

      if (entry == null) {
        toolWarnings.add({
          'type': 'unsupported',
          'feature': 'provider-defined tool ${tool.id}',
          if (warningDetails != null) 'details': warningDetails,
        });
        continue;
      }

      body['tools'] ??= <Map<String, dynamic>>[];
      (body['tools'] as List).add(entry);
    }
  }

  bool _isProviderToolEnabled(ProviderTool tool) {
    final enabled = tool.options['enabled'];
    if (enabled is bool) return enabled;
    return true;
  }

  bool _isGemmaModel() {
    final lower = config.model.toLowerCase();
    return lower.startsWith('gemma-');
  }

  Uri _buildUploadUri() {
    final base = Uri.parse(config.baseUrl);
    final useHeaderAuth = base.host.endsWith('aiplatform.googleapis.com');

    final baseSegments = List<String>.from(base.pathSegments);
    while (baseSegments.isNotEmpty && baseSegments.last.isEmpty) {
      baseSegments.removeLast();
    }
    if (baseSegments.isNotEmpty && baseSegments.last == 'v1beta') {
      baseSegments.removeLast();
    }

    return base.replace(
      pathSegments: [...baseSegments, 'upload', 'v1beta', 'files'],
      queryParameters: useHeaderAuth ? null : {'key': config.apiKey},
    );
  }

  /// Convert ChatMessage to Google format
  Map<String, dynamic> _convertMessage(
    ChatMessage message,
    ToolNameMapping toolNameMapping,
  ) {
    final parts = <Map<String, dynamic>>[];

    // Determine role - Google API uses 'user', 'model', 'function'
    String role;
    switch (message.messageType) {
      case ToolResultMessage():
        role = 'user';
        break;
      default:
        role = message.role == ChatRole.user ? 'user' : 'model';
    }

    switch (message.messageType) {
      case TextMessage():
        final thoughtSignature = message.role == ChatRole.assistant
            ? _thoughtSignatureFromProviderOptions(message.providerOptions)
            : null;
        parts.add({
          'text': message.content,
          if (thoughtSignature != null) 'thoughtSignature': thoughtSignature,
        });
        break;
      case ImageMessage(mime: final mime, data: final data):
        final thoughtSignature = message.role == ChatRole.assistant
            ? _thoughtSignatureFromProviderOptions(message.providerOptions)
            : null;
        if (message.content.trim().isNotEmpty) {
          parts.add({
            'text': message.content,
            if (thoughtSignature != null) 'thoughtSignature': thoughtSignature,
          });
        }
        parts.add({
          'inlineData': {
            'mimeType': mime.mimeType,
            'data': base64Encode(data),
          },
          if (thoughtSignature != null) 'thoughtSignature': thoughtSignature,
        });
        break;
      case FileMessage(mime: final mime, data: final data):
        final thoughtSignature = message.role == ChatRole.assistant
            ? _thoughtSignatureFromProviderOptions(message.providerOptions)
            : null;
        if (message.content.trim().isNotEmpty) {
          parts.add({
            'text': message.content,
            if (thoughtSignature != null) 'thoughtSignature': thoughtSignature,
          });
        }
        final uploaded = message.getProtocolPayload<Map<String, dynamic>>(
          'google',
        );
        final fileUri = uploaded?['fileUri'] as String?;
        final uploadedMimeType = uploaded?['mimeType'] as String?;

        if (fileUri != null && fileUri.isNotEmpty) {
          if (message.role == ChatRole.assistant) {
            throw const InvalidRequestError(
              'Google does not support fileData URLs in assistant messages.',
            );
          }
          final supportedOnly = config.supportedFileUrlsOnly ||
              _supportedFileUrlsOnlyFromProviderOptions(
                  message.providerOptions);
          final normalizedFileUri = _normalizeGoogleFileUri(
            fileUri,
            supportedFileUrlsOnly: supportedOnly,
          );
          parts.add({
            'fileData': {
              'fileUri': normalizedFileUri,
              'mimeType': uploadedMimeType ?? mime.mimeType,
            },
          });
          break;
        }

        if (data.length > config.maxInlineDataSize) {
          throw InvalidRequestError(
            'File too large for Google inlineData: ${data.length} bytes '
            '(maxInlineDataSize=${config.maxInlineDataSize}).',
          );
        }
        parts.add({
          'inlineData': {
            'mimeType': mime.mimeType,
            'data': base64Encode(data),
          },
          if (thoughtSignature != null) 'thoughtSignature': thoughtSignature,
        });
        break;
      case ImageUrlMessage(url: final url):
        if (message.role == ChatRole.assistant) {
          throw const InvalidRequestError(
            'Google does not support fileData URLs in assistant messages.',
          );
        }
        if (message.content.trim().isNotEmpty) {
          parts.add({'text': message.content});
        }
        final supportedOnly = config.supportedFileUrlsOnly ||
            _supportedFileUrlsOnlyFromProviderOptions(message.providerOptions);
        final normalizedUrl = _normalizeGoogleFileUri(
          url,
          supportedFileUrlsOnly: supportedOnly,
        );
        parts.add({
          'fileData': {
            'fileUri': normalizedUrl,
            'mimeType':
                _guessImageMimeTypeFromUrl(normalizedUrl) ?? 'image/png',
          },
        });
        break;
      case ToolUseMessage(toolCalls: final toolCalls):
        for (final toolCall in toolCalls) {
          try {
            final args = jsonDecode(toolCall.function.arguments);
            final requestName =
                toolNameMapping.requestNameForFunction(toolCall.function.name);
            final thoughtSignature = message.role == ChatRole.assistant
                ? _thoughtSignatureFromProviderOptions(toolCall.providerOptions)
                : null;
            parts.add({
              'functionCall': {
                'name': requestName,
                'args': args,
              },
              if (thoughtSignature != null)
                'thoughtSignature': thoughtSignature,
            });
          } catch (e) {
            client.logger.warning(
                'Failed to parse tool call arguments: ${toolCall.function.arguments}, error: $e');
            parts.add({
              'text':
                  '[Error: Invalid tool call arguments for ${toolCall.function.name}]',
            });
          }
        }
        break;
      case ToolResultMessage(results: final results):
        for (final result in results) {
          final requestName =
              toolNameMapping.requestNameForFunction(result.function.name);
          final raw = result.function.arguments;
          Object content;
          try {
            content = jsonDecode(raw);
          } catch (_) {
            content = raw;
          }
          parts.add({
            'functionResponse': {
              'name': requestName,
              'response': {
                'name': requestName,
                'content': content,
              },
            },
          });
        }
        break;
    }

    return {
      'role': role,
      'parts': parts,
    };
  }

  Future<List<ChatMessage>> _prepareMessages(
    List<ChatMessage> messages, {
    required ToolNameMapping toolNameMapping,
    CancelToken? cancelToken,
  }) async {
    final prepared = <ChatMessage>[];

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];

      if (message.messageType
          case FileMessage(mime: final mime, data: final data)) {
        if (data.length > config.maxInlineDataSize) {
          if (message.role == ChatRole.assistant) {
            throw const InvalidRequestError(
              'Google does not support file uploads from assistant messages.',
            );
          }
          final displayName =
              _defaultUploadDisplayName(mimeType: mime.mimeType, data: data);
          final uploaded = await getOrUploadFile(
            data: data,
            mimeType: mime.mimeType,
            displayName: displayName,
            cancelToken: cancelToken,
          );

          if (uploaded == null) {
            throw InvalidRequestError(
              'File too large for Google inlineData and upload failed: '
              '${data.length} bytes (maxInlineDataSize=${config.maxInlineDataSize}).',
            );
          }

          final uri = uploaded.uri ?? uploaded.name;
          if (uri.isEmpty) {
            throw ProviderError(
              'Google file upload returned no uri/name for displayName="$displayName".',
            );
          }

          prepared.add(
            ChatMessage(
              role: message.role,
              messageType: message.messageType,
              content: message.content,
              name: message.name,
              protocolPayloads: {
                ...message.protocolPayloads,
                'google': {
                  'fileUri': uri,
                  'mimeType': mime.mimeType,
                },
              },
              providerOptions: message.providerOptions,
            ),
          );
          continue;
        }
      }

      prepared.add(message);
    }

    return prepared;
  }

  String _defaultUploadDisplayName({
    required String mimeType,
    required List<int> data,
  }) {
    final ext = _guessFileExtensionFromMimeType(mimeType);
    final sample =
        data.take(8).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final suffix = sample.isEmpty ? '${data.length}' : '${data.length}_$sample';
    return 'llm_dart_$suffix.$ext';
  }

  String _guessFileExtensionFromMimeType(String mimeType) {
    final lower = mimeType.toLowerCase();
    final slash = lower.indexOf('/');
    if (slash == -1 || slash == lower.length - 1) return 'bin';
    final subtype = lower.substring(slash + 1);
    if (subtype.contains('+json')) return 'json';
    if (subtype == 'plain') return 'txt';
    return subtype;
  }

  static final RegExp _youtubeWatchUrlRegex = RegExp(
    r'^https:\/\/(?:www\.)?youtube\.com\/watch\?v=[\w-]+(?:&[\w=&.-]*)?$',
  );
  static final RegExp _youtubeShortUrlRegex = RegExp(
    r'^https:\/\/youtu\.be\/[\w-]+(?:\?[\w=&.-]*)?$',
  );

  static bool _isSupportedGoogleHttpsFileUrl(String urlString) {
    // Google Generative Language files API.
    if (urlString.startsWith(
      'https://generativelanguage.googleapis.com/v1beta/files/',
    )) {
      return true;
    }

    // YouTube URLs (public or unlisted videos).
    return _youtubeWatchUrlRegex.hasMatch(urlString) ||
        _youtubeShortUrlRegex.hasMatch(urlString);
  }

  static String _normalizeGoogleFileUri(
    String uri, {
    required bool supportedFileUrlsOnly,
  }) {
    final trimmed = uri.trim();
    if (trimmed.isEmpty) {
      throw const InvalidRequestError('Google file URI cannot be empty.');
    }

    // Google Generative Language files API supports file names like `files/123`.
    if (trimmed.startsWith('files/')) return trimmed;

    final parsed = Uri.tryParse(trimmed);
    final scheme = parsed?.scheme ?? '';

    // Allow explicit URLs and GCS URIs.
    if (scheme == 'http' || scheme == 'https' || scheme == 'gs') {
      if (supportedFileUrlsOnly && (scheme == 'http' || scheme == 'https')) {
        if (_isSupportedGoogleHttpsFileUrl(trimmed)) return trimmed;
        throw InvalidRequestError(
          'Unsupported Google file URL: "$uri". '
          'When supportedFileUrlsOnly=true, only Google Files API URLs and '
          'YouTube URLs are allowed.',
        );
      }
      return trimmed;
    }

    throw InvalidRequestError(
      'Unsupported Google file URI: "$uri". '
      'Expected an http(s) URL, a gs:// URI, or a `files/...` resource name.',
    );
  }

  static String? _guessImageMimeTypeFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return null;
  }

  /// Convert Tool to Google format
  Map<String, dynamic> _convertTool(Tool tool) {
    try {
      final schema = tool.function.parameters.toJson();
      final hasEmptyObjectSchema = schema['type'] == 'object' &&
          (schema['properties'] is Map) &&
          (schema['properties'] as Map).isEmpty &&
          (schema['required'] is List) &&
          (schema['required'] as List).isEmpty;

      return {
        'name': tool.function.name,
        'description': tool.function.description,
        if (!hasEmptyObjectSchema) 'parameters': schema,
      };
    } catch (e) {
      client.logger.warning('Failed to convert tool ${tool.function.name}: $e');
      // Return a minimal valid tool definition
      return {
        'name': tool.function.name,
        'description': tool.function.description.isNotEmpty
            ? tool.function.description
            : 'Tool with invalid schema',
        'parameters': {
          'type': 'object',
          'properties': {},
        },
      };
    }
  }

  Map<String, dynamic> _convertFunctionTool(
    Tool tool,
    ToolNameMapping toolNameMapping,
  ) {
    final converted = _convertTool(tool);
    final requestName =
        toolNameMapping.requestNameForFunction(tool.function.name);
    if (requestName != tool.function.name) {
      converted['name'] = requestName;
    }
    return converted;
  }

  /// Convert ToolChoice to Google format
  ///
  /// https://ai.google.dev/gemini-api/docs/function-calling?example=meeting#function_calling_modes
  ///
  Map<String, dynamic> _convertToolChoice(
    ToolChoice toolChoice,
    List<Tool> tools,
    ToolNameMapping toolNameMapping,
  ) {
    switch (toolChoice) {
      case AutoToolChoice():
        return {
          'functionCallingConfig': {
            'mode': 'AUTO',
          },
        };
      case AnyToolChoice():
        return {
          'functionCallingConfig': {
            'mode': 'ANY',
          },
        };
      case SpecificToolChoice(toolName: final toolName):
        // Validate that the specified tool exists in the available tools
        final toolExists = tools.any((tool) => tool.function.name == toolName);
        if (!toolExists) {
          client.logger.warning(
              'Tool "$toolName" specified in SpecificToolChoice not found in available tools');
          // Fall back to AUTO mode if tool not found
          return {
            'functionCallingConfig': {
              'mode': 'AUTO',
            },
          };
        }
        final requestName = toolNameMapping.requestNameForFunction(toolName);
        return {
          'functionCallingConfig': {
            'mode': 'ANY',
            'allowedFunctionNames': [requestName],
          },
        };
      case NoneToolChoice():
        return {
          'functionCallingConfig': {
            'mode': 'NONE',
          },
        };
    }
  }

  ToolNameMapping _createToolNameMapping(List<Tool>? tools) {
    final functionToolNames =
        (tools ?? const <Tool>[]).map((t) => t.function.name);

    final providerToolRequestNamesById = <String, String>{};

    // Reserve provider-native web search tool name when enabled.
    if (config.webSearchEnabled) {
      providerToolRequestNamesById['google.google_search'] = 'google_search';
    }

    final providerTools =
        config.originalConfig?.providerTools ?? const <ProviderTool>[];
    final enabledIds =
        providerTools.where(_isProviderToolEnabled).map((t) => t.id).toSet();
    final supportsGemini2OrNewer = _isGemini2OrNewerModel();

    if (supportsGemini2OrNewer) {
      if (enabledIds.contains('google.code_execution')) {
        providerToolRequestNamesById['google.code_execution'] =
            'code_execution';
      }
      if (enabledIds.contains('google.url_context')) {
        providerToolRequestNamesById['google.url_context'] = 'url_context';
      }
      if (enabledIds.contains('google.enterprise_web_search')) {
        providerToolRequestNamesById['google.enterprise_web_search'] =
            'enterprise_web_search';
      }
      if (enabledIds.contains('google.google_maps')) {
        providerToolRequestNamesById['google.google_maps'] = 'google_maps';
      }
      if (enabledIds.contains('google.vertex_rag_store')) {
        providerToolRequestNamesById['google.vertex_rag_store'] =
            'vertex_rag_store';
      }
    }

    if (_supportsFileSearch() && enabledIds.contains('google.file_search')) {
      providerToolRequestNamesById['google.file_search'] = 'file_search';
    }

    return createToolNameMapping(
      functionToolNames: functionToolNames,
      providerToolRequestNamesById: providerToolRequestNamesById,
    );
  }
}

/// Google chat response implementation
class GoogleChatResponse
    implements
        ChatResponseWithFinishReason,
        ChatResponseWithResponseMetadata,
        ChatResponseWithRequestMetadata {
  final Map<String, dynamic> _rawResponse;
  final ToolNameMapping? _toolNameMapping;
  final List<Map<String, dynamic>> _toolWarnings;
  final String _providerOptionsName;
  final LLMResponseMetadataPart? _responseMetadata;
  final LLMRequestMetadataPart? _requestMetadata;

  GoogleChatResponse(
    this._rawResponse, {
    ToolNameMapping? toolNameMapping,
    List<Map<String, dynamic>> toolWarnings = const [],
    String providerOptionsName = 'google',
    LLMResponseMetadataPart? responseMetadata,
    LLMRequestMetadataPart? requestMetadata,
  })  : _toolNameMapping = toolNameMapping,
        _toolWarnings = List<Map<String, dynamic>>.unmodifiable(toolWarnings),
        _providerOptionsName = providerOptionsName,
        _responseMetadata = responseMetadata,
        _requestMetadata = requestMetadata;

  @override
  LLMResponseMetadataPart? get responseMetadata => _responseMetadata;

  @override
  LLMRequestMetadataPart? get requestMetadata => _requestMetadata;

  @override
  String? get text {
    final candidates = _rawResponse['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final content = candidates.first['content'] as Map<String, dynamic>?;
    if (content == null) return null;

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;

    // According to Google API docs, only return non-thinking content
    // Thinking content has thought: true flag, regular content has thought: false or no thought field
    final textParts = parts
        .where((part) {
          final isThought = part['thought'] as bool? ?? false;
          final text = part['text'] as String?;
          return !isThought && text != null && text.isNotEmpty;
        })
        .map((part) => part['text'] as String)
        .toList();

    return textParts.isEmpty ? null : textParts.join('\n');
  }

  @override
  String? get thinking {
    // Extract thinking content from candidates
    final candidates = _rawResponse['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final content = candidates.first['content'] as Map<String, dynamic>?;
    if (content == null) return null;

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;

    // According to Google API docs, thinking content has thought: true flag
    final thinkingParts = parts
        .where((part) {
          final isThought = part['thought'] as bool? ?? false;
          final text = part['text'] as String?;
          return isThought && text != null && text.isNotEmpty;
        })
        .map((part) => part['text'] as String)
        .toList();

    return thinkingParts.isEmpty ? null : thinkingParts.join('\n');
  }

  @override
  Map<String, dynamic>? get providerMetadata {
    final modelVersion = _rawResponse['modelVersion'] as String? ??
        _rawResponse['model'] as String?;

    final candidates = _rawResponse['candidates'] as List?;
    final firstCandidate =
        (candidates != null && candidates.isNotEmpty && candidates.first is Map)
            ? Map<String, dynamic>.from(candidates.first as Map)
            : null;

    final finishReason = firstCandidate?['finishReason'] as String?;
    final safetyRatings = firstCandidate?['safetyRatings'];
    final groundingMetadata = firstCandidate?['groundingMetadata'];
    final urlContextMetadata = firstCandidate?['urlContextMetadata'];
    final promptFeedback = _rawResponse['promptFeedback'];

    final rawUsageMetadata = _rawResponse['usageMetadata'];
    final Map<String, dynamic>? usageMetadata;
    if (rawUsageMetadata is Map<String, dynamic>) {
      usageMetadata = rawUsageMetadata;
    } else if (rawUsageMetadata is Map) {
      usageMetadata = Map<String, dynamic>.from(rawUsageMetadata);
    } else {
      usageMetadata = null;
    }

    final hasAnyMetadata = modelVersion != null ||
        finishReason != null ||
        safetyRatings != null ||
        groundingMetadata != null ||
        urlContextMetadata != null ||
        promptFeedback != null ||
        usageMetadata != null ||
        _toolWarnings.isNotEmpty;

    if (!hasAnyMetadata) return null;

    final payload = <String, dynamic>{
      if (modelVersion != null) 'model': modelVersion,
      if (finishReason != null) 'finishReason': finishReason,
      if (finishReason != null) 'stopReason': finishReason,
      if (_toolWarnings.isNotEmpty) 'toolWarnings': _toolWarnings,
      if (usageMetadata != null)
        'usage': {
          if (usageMetadata['promptTokenCount'] != null)
            'promptTokens': usageMetadata['promptTokenCount'],
          if (usageMetadata['candidatesTokenCount'] != null)
            'completionTokens': usageMetadata['candidatesTokenCount'],
          if (usageMetadata['totalTokenCount'] != null)
            'totalTokens': usageMetadata['totalTokenCount'],
          if (usageMetadata['thoughtsTokenCount'] != null)
            'reasoningTokens': usageMetadata['thoughtsTokenCount'],
        },
      if (usageMetadata != null) 'usageMetadata': usageMetadata,
      if (promptFeedback != null) 'promptFeedback': promptFeedback,
      if (safetyRatings != null) 'safetyRatings': safetyRatings,
      if (groundingMetadata != null) 'groundingMetadata': groundingMetadata,
      if (urlContextMetadata != null) 'urlContextMetadata': urlContextMetadata,
    };

    final baseKey = _providerOptionsName;
    final metadata = <String, dynamic>{
      baseKey: payload,
      '$baseKey.chat': payload,
    };

    // AI SDK default provider name for Google Generative AI (Gemini API only).
    if (baseKey == 'google') {
      metadata['google.generative-ai'] = payload;
    }

    return metadata;
  }

  @override
  LLMFinishReason? get finishReason {
    final candidates = _rawResponse['candidates'] as List?;
    final firstCandidate =
        (candidates != null && candidates.isNotEmpty && candidates.first is Map)
            ? Map<String, dynamic>.from(candidates.first as Map)
            : null;

    final raw = firstCandidate?['finishReason'] as String?;
    if (raw == null || raw.isEmpty) return null;

    final hasToolCalls = (toolCalls?.isNotEmpty ?? false);
    final unified = _mapFinishReason(raw, hasToolCalls: hasToolCalls);

    return LLMFinishReason(unified: unified, raw: raw);
  }

  static LLMUnifiedFinishReason _mapFinishReason(
    String raw, {
    required bool hasToolCalls,
  }) {
    switch (raw.toUpperCase()) {
      case 'STOP':
        return hasToolCalls
            ? LLMUnifiedFinishReason.toolCalls
            : LLMUnifiedFinishReason.stop;
      case 'MAX_TOKENS':
        return LLMUnifiedFinishReason.length;
      case 'IMAGE_SAFETY':
      case 'SAFETY':
      case 'RECITATION':
      case 'BLOCKLIST':
      case 'PROHIBITED_CONTENT':
      case 'SPII':
        return LLMUnifiedFinishReason.contentFilter;
      case 'MALFORMED_FUNCTION_CALL':
        return LLMUnifiedFinishReason.error;
      case 'FINISH_REASON_UNSPECIFIED':
      case 'OTHER':
      default:
        return LLMUnifiedFinishReason.other;
    }
  }

  @override
  List<ToolCall>? get toolCalls {
    final candidates = _rawResponse['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final content = candidates.first['content'] as Map<String, dynamic>?;
    if (content == null) return null;

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;

    final functionCalls = <ToolCall>[];
    final nameCounts = <String, int>{};

    for (final part in parts) {
      final functionCall = part['functionCall'] as Map<String, dynamic>?;
      if (functionCall != null) {
        final requestName = functionCall['name'] as String;
        final args = functionCall['args'] as Map<String, dynamic>? ?? {};

        if (requestName == 'google_search') {
          continue;
        }

        final name =
            _toolNameMapping?.originalFunctionNameForRequestName(requestName) ??
                requestName;
        final count = nameCounts[name] ?? 0;
        nameCounts[name] = count + 1;
        final id = count == 0 ? 'call_$name' : 'call_${name}_$count';

        final thoughtSignature = part['thoughtSignature'];
        functionCalls.add(
          ToolCall(
            id: id,
            callType: 'function',
            function: FunctionCall(name: name, arguments: jsonEncode(args)),
            providerOptions: thoughtSignature == null
                ? const <String, Map<String, dynamic>>{}
                : <String, Map<String, dynamic>>{
                    _providerOptionsName: {
                      'thoughtSignature': thoughtSignature.toString(),
                    },
                  },
          ),
        );
      }
    }

    return functionCalls.isEmpty ? null : functionCalls;
  }

  @override
  UsageInfo? get usage {
    final rawUsageMetadata = _rawResponse['usageMetadata'];
    if (rawUsageMetadata == null) return null;

    // Safely convert Map<dynamic, dynamic> to Map<String, dynamic>
    final Map<String, dynamic> usageMetadata;
    if (rawUsageMetadata is Map<String, dynamic>) {
      usageMetadata = rawUsageMetadata;
    } else if (rawUsageMetadata is Map) {
      usageMetadata = Map<String, dynamic>.from(rawUsageMetadata);
    } else {
      return null;
    }

    return UsageInfo.fromProviderUsage(usageMetadata);
  }

  @override
  String toString() {
    final textContent = text;
    final calls = toolCalls;
    final thinkingContent = thinking;

    final parts = <String>[];

    if (thinkingContent != null) {
      parts.add('Thinking: $thinkingContent');
    }

    if (calls != null) {
      parts.add(calls.map((c) => c.toString()).join('\n'));
    }

    if (textContent != null) {
      parts.add(textContent);
    }

    return parts.join('\n');
  }
}

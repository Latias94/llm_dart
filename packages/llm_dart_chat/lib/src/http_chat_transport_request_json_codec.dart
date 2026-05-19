import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_json_support.dart';
import 'http_chat_transport_request_payload.dart';
import 'http_chat_transport_stream_protocol.dart';

final class HttpChatTransportRequestJsonCodec {
  static const envelopeKind = 'http-chat-transport-request';
  static const reconnectEnvelopeKind = 'http-chat-transport-reconnect-request';

  final PromptJsonCodec promptCodec;
  final List<ProviderToolOptionsJsonCodec> providerToolOptionsCodecs;

  const HttpChatTransportRequestJsonCodec({
    this.promptCodec = const PromptJsonCodec(),
    this.providerToolOptionsCodecs = const [],
  });

  Map<String, Object?> encodeRequest(HttpChatTransportRequestPayload request) {
    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': envelopeKind,
      'data': {
        'chatId': request.chatId,
        'prompt': promptCodec.encodeMessages(request.prompt),
        'generateOptions': _encodeGenerateTextOptions(request.generateOptions),
        if (request.tools.isNotEmpty) 'tools': _encodeTools(request.tools),
        if (request.toolChoice != null)
          'toolChoice': _encodeToolChoice(request.toolChoice!),
        if (!request.callOptions.isEmpty)
          'callOptions': _encodeCallOptions(request.callOptions),
        'streamProtocol': request.streamProtocol.wireValue,
        if (request.metadata.isNotEmpty) 'metadata': request.metadata,
      },
    };
  }

  HttpChatTransportRequestPayload decodeRequest(Object? envelope) {
    final root = HttpChatTransportJson.asMap(envelope, path: r'$');
    final kind = HttpChatTransportJson.asString(root['kind'], path: r'$.kind');
    if (kind != envelopeKind) {
      throw FormatException(
        'Expected envelope kind "$envelopeKind", received "$kind".',
      );
    }

    final data = HttpChatTransportJson.asMap(root['data'], path: r'$.data');
    return HttpChatTransportRequestPayload(
      chatId: HttpChatTransportJson.asString(
        data['chatId'],
        path: r'$.data.chatId',
      ),
      prompt: promptCodec.decodeMessages(data['prompt']),
      generateOptions: _decodeGenerateTextOptions(
        data['generateOptions'],
        path: r'$.data.generateOptions',
      ),
      tools: _decodeTools(data['tools'], path: r'$.data.tools'),
      toolChoice: _decodeToolChoice(
        data['toolChoice'],
        path: r'$.data.toolChoice',
      ),
      callOptions: _decodeCallOptions(
        data['callOptions'],
        path: r'$.data.callOptions',
      ),
      streamProtocol: switch (HttpChatTransportJson.asNullableString(
        data['streamProtocol'],
        path: r'$.data.streamProtocol',
      )) {
        final String value => HttpChatTransportStreamProtocol.decode(
            value,
            path: r'$.data.streamProtocol',
          ),
        null => HttpChatTransportStreamProtocol.eventStreamV1,
      },
      metadata: data['metadata'] == null
          ? const {}
          : HttpChatTransportJson.asMap(
              data['metadata'],
              path: r'$.data.metadata',
            ),
    );
  }

  List<HttpChatTransportJsonMap> _encodeTools(
    List<FunctionToolDefinition> tools,
  ) {
    return [
      for (final tool in tools)
        {
          'type': 'function',
          'name': tool.name,
          if (tool.description != null) 'description': tool.description,
          'inputSchema': tool.inputSchema.toJson(),
          if (tool.strict != null) 'strict': tool.strict,
          if (tool.providerOptions case final providerOptions?)
            'providerOptions': _encodeProviderToolOptions(
              providerOptions,
              path: r'$.data.tools[].providerOptions',
            ),
        },
    ];
  }

  List<FunctionToolDefinition> _decodeTools(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return const [];
    }

    final list = HttpChatTransportJson.asList(value, path: path);
    return [
      for (final entry in list.asMap().entries)
        _decodeTool(entry.value, path: '$path[${entry.key}]'),
    ];
  }

  FunctionToolDefinition _decodeTool(
    Object? value, {
    required String path,
  }) {
    final map = HttpChatTransportJson.asMap(value, path: path);
    final type =
        HttpChatTransportJson.asString(map['type'], path: '$path.type');
    if (type != 'function') {
      throw FormatException(
        'Unsupported tool type "$type" at $path.type.',
      );
    }

    return FunctionToolDefinition(
      name: HttpChatTransportJson.asString(map['name'], path: '$path.name'),
      description: HttpChatTransportJson.asNullableString(
        map['description'],
        path: '$path.description',
      ),
      inputSchema: ToolJsonSchema.raw(
        HttpChatTransportJson.asMap(
          map['inputSchema'],
          path: '$path.inputSchema',
        ),
      ),
      strict: HttpChatTransportJson.asNullableBool(
        map['strict'],
        path: '$path.strict',
      ),
      providerOptions: _decodeProviderToolOptions(
        map['providerOptions'],
        path: '$path.providerOptions',
      ),
    );
  }

  HttpChatTransportJsonMap _encodeToolChoice(ToolChoice toolChoice) {
    return switch (toolChoice) {
      AutoToolChoice() => const {
          'type': 'auto',
        },
      RequiredToolChoice() => const {
          'type': 'required',
        },
      NoneToolChoice() => const {
          'type': 'none',
        },
      SpecificToolChoice(:final toolName) => {
          'type': 'tool',
          'toolName': toolName,
        },
    };
  }

  ToolChoice? _decodeToolChoice(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    final map = HttpChatTransportJson.asMap(value, path: path);
    final type =
        HttpChatTransportJson.asString(map['type'], path: '$path.type');
    return switch (type) {
      'auto' => const AutoToolChoice(),
      'required' => const RequiredToolChoice(),
      'none' => const NoneToolChoice(),
      'tool' => SpecificToolChoice(
          HttpChatTransportJson.asString(
            map['toolName'],
            path: '$path.toolName',
          ),
        ),
      _ => throw FormatException(
          'Unsupported tool choice type "$type" at $path.type.',
        ),
    };
  }

  HttpChatTransportJsonMap _encodeProviderToolOptions(
    ProviderToolOptions options, {
    required String path,
  }) {
    for (final codec in providerToolOptionsCodecs) {
      if (codec.canEncode(options)) {
        return {
          'type': codec.type,
          'data': codec.encode(options),
        };
      }
    }

    throw UnsupportedError(
      'Cannot serialize providerOptions at $path because no '
      'ProviderToolOptionsJsonCodec was registered for '
      '${options.runtimeType}.',
    );
  }

  ProviderToolOptions? _decodeProviderToolOptions(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    final map = HttpChatTransportJson.asMap(value, path: path);
    final type = HttpChatTransportJson.asString(
      map['type'],
      path: '$path.type',
    );
    final data = HttpChatTransportJson.asMap(
      map['data'],
      path: '$path.data',
    );
    for (final codec in providerToolOptionsCodecs) {
      if (codec.type == type) {
        return codec.decode(data);
      }
    }

    throw FormatException(
      'Unsupported providerOptions type "$type" at $path. Register a '
      'ProviderToolOptionsJsonCodec for this type.',
    );
  }

  Map<String, Object?> encodeReconnectRequest(
    HttpChatTransportReconnectRequestPayload request,
  ) {
    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': reconnectEnvelopeKind,
      'data': {
        'chatId': request.chatId,
        'resumeToken': request.resumeToken,
        if (!request.callOptions.isEmpty)
          'callOptions': _encodeCallOptions(request.callOptions),
        'streamProtocol': request.streamProtocol.wireValue,
        if (request.metadata.isNotEmpty) 'metadata': request.metadata,
      },
    };
  }

  HttpChatTransportReconnectRequestPayload decodeReconnectRequest(
    Object? envelope,
  ) {
    final root = HttpChatTransportJson.asMap(envelope, path: r'$');
    final kind = HttpChatTransportJson.asString(root['kind'], path: r'$.kind');
    if (kind != reconnectEnvelopeKind) {
      throw FormatException(
        'Expected envelope kind "$reconnectEnvelopeKind", received "$kind".',
      );
    }

    final data = HttpChatTransportJson.asMap(root['data'], path: r'$.data');
    return HttpChatTransportReconnectRequestPayload(
      chatId: HttpChatTransportJson.asString(
        data['chatId'],
        path: r'$.data.chatId',
      ),
      resumeToken: HttpChatTransportJson.asString(
        data['resumeToken'],
        path: r'$.data.resumeToken',
      ),
      callOptions: _decodeCallOptions(
        data['callOptions'],
        path: r'$.data.callOptions',
      ),
      streamProtocol: switch (HttpChatTransportJson.asNullableString(
        data['streamProtocol'],
        path: r'$.data.streamProtocol',
      )) {
        final String value => HttpChatTransportStreamProtocol.decode(
            value,
            path: r'$.data.streamProtocol',
          ),
        null => HttpChatTransportStreamProtocol.eventStreamV1,
      },
      metadata: data['metadata'] == null
          ? const {}
          : HttpChatTransportJson.asMap(
              data['metadata'],
              path: r'$.data.metadata',
            ),
    );
  }

  HttpChatTransportJsonMap _encodeGenerateTextOptions(
    GenerateTextOptions options,
  ) {
    return {
      if (options.maxOutputTokens != null)
        'maxOutputTokens': options.maxOutputTokens,
      if (options.temperature != null) 'temperature': options.temperature,
      if (options.stopSequences != null) 'stopSequences': options.stopSequences,
      if (options.topP != null) 'topP': options.topP,
      if (options.topK != null) 'topK': options.topK,
      if (options.presencePenalty != null)
        'presencePenalty': options.presencePenalty,
      if (options.frequencyPenalty != null)
        'frequencyPenalty': options.frequencyPenalty,
      if (options.seed != null) 'seed': options.seed,
      if (options.reasoning != null)
        'reasoning': _encodeGenerateTextReasoningOptions(options.reasoning!),
      if (options.includeRawChunks) 'includeRawChunks': true,
    };
  }

  GenerateTextOptions _decodeGenerateTextOptions(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return const GenerateTextOptions();
    }

    final map = HttpChatTransportJson.asMap(value, path: path);
    return GenerateTextOptions(
      maxOutputTokens: HttpChatTransportJson.asNullableInt(
        map['maxOutputTokens'],
        path: '$path.maxOutputTokens',
      ),
      temperature: HttpChatTransportJson.asNullableDouble(
        map['temperature'],
        path: '$path.temperature',
      ),
      stopSequences: map['stopSequences'] == null
          ? null
          : HttpChatTransportJson.asList(
              map['stopSequences'],
              path: '$path.stopSequences',
            )
              .asMap()
              .entries
              .map(
                (entry) => HttpChatTransportJson.asString(
                  entry.value,
                  path: '$path.stopSequences[${entry.key}]',
                ),
              )
              .toList(growable: false),
      topP: HttpChatTransportJson.asNullableDouble(
        map['topP'],
        path: '$path.topP',
      ),
      topK: HttpChatTransportJson.asNullableInt(
        map['topK'],
        path: '$path.topK',
      ),
      presencePenalty: HttpChatTransportJson.asNullableDouble(
        map['presencePenalty'],
        path: '$path.presencePenalty',
      ),
      frequencyPenalty: HttpChatTransportJson.asNullableDouble(
        map['frequencyPenalty'],
        path: '$path.frequencyPenalty',
      ),
      seed: HttpChatTransportJson.asNullableInt(
        map['seed'],
        path: '$path.seed',
      ),
      reasoning: map['reasoning'] == null
          ? null
          : _decodeGenerateTextReasoningOptions(
              map['reasoning'],
              path: '$path.reasoning',
            ),
      includeRawChunks: HttpChatTransportJson.asNullableBool(
            map['includeRawChunks'],
            path: '$path.includeRawChunks',
          ) ??
          false,
    );
  }

  HttpChatTransportJsonMap _encodeGenerateTextReasoningOptions(
    GenerateTextReasoningOptions options,
  ) {
    return {
      if (options.enabled != null) 'enabled': options.enabled,
      if (options.effort != null) 'effort': options.effort!.value,
      if (options.budgetTokens != null) 'budgetTokens': options.budgetTokens,
    };
  }

  GenerateTextReasoningOptions _decodeGenerateTextReasoningOptions(
    Object? value, {
    required String path,
  }) {
    final map = HttpChatTransportJson.asMap(value, path: path);
    return GenerateTextReasoningOptions(
      enabled: HttpChatTransportJson.asNullableBool(
        map['enabled'],
        path: '$path.enabled',
      ),
      effort: _decodeReasoningEffort(map['effort'], path: '$path.effort'),
      budgetTokens: HttpChatTransportJson.asNullableInt(
        map['budgetTokens'],
        path: '$path.budgetTokens',
      ),
    );
  }

  HttpChatTransportJsonMap _encodeCallOptions(
    HttpChatTransportCallOptionsPayload options,
  ) {
    return {
      if (options.timeout != null)
        'timeoutMilliseconds': options.timeout!.inMilliseconds,
      if (options.headers.isNotEmpty) 'headers': options.headers,
      if (options.maxRetries != null) 'maxRetries': options.maxRetries,
      if (options.providerOptions.isNotEmpty)
        'providerOptions': options.providerOptions,
    };
  }

  HttpChatTransportCallOptionsPayload _decodeCallOptions(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return HttpChatTransportCallOptionsPayload.empty;
    }

    final map = HttpChatTransportJson.asMap(value, path: path);
    final timeoutMilliseconds = HttpChatTransportJson.asNullableNonNegativeInt(
      map['timeoutMilliseconds'],
      path: '$path.timeoutMilliseconds',
    );

    return HttpChatTransportCallOptionsPayload(
      timeout: timeoutMilliseconds == null
          ? null
          : Duration(milliseconds: timeoutMilliseconds),
      headers: map['headers'] == null
          ? const {}
          : HttpChatTransportJson.asStringMap(
              map['headers'],
              path: '$path.headers',
            ),
      maxRetries: HttpChatTransportJson.asNullableNonNegativeInt(
        map['maxRetries'],
        path: '$path.maxRetries',
      ),
      providerOptions: map['providerOptions'] == null
          ? const {}
          : HttpChatTransportJson.asMap(
              map['providerOptions'],
              path: '$path.providerOptions',
            ),
    );
  }
}

ReasoningEffort? _decodeReasoningEffort(
  Object? value, {
  required String path,
}) {
  final stringValue = HttpChatTransportJson.asNullableString(
    value,
    path: path,
  );
  if (stringValue == null) {
    return null;
  }

  for (final effort in ReasoningEffort.values) {
    if (effort.value == stringValue) {
      return effort;
    }
  }

  throw FormatException(
    'Unsupported reasoning effort "$stringValue" at $path.',
  );
}

import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_json_support.dart';

final class HttpChatTransportToolJsonCodec {
  final List<ProviderToolOptionsJsonCodec> providerToolOptionsCodecs;

  const HttpChatTransportToolJsonCodec({
    this.providerToolOptionsCodecs = const [],
  });

  List<HttpChatTransportJsonMap> encodeTools(
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

  List<FunctionToolDefinition> decodeTools(
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

  HttpChatTransportJsonMap encodeToolChoice(ToolChoice toolChoice) {
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

  ToolChoice? decodeToolChoice(
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
}

import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_json_support.dart';
import 'http_chat_transport_provider_tool_options_codec.dart';

final class HttpChatTransportToolJsonCodec {
  final List<ProviderToolOptionsJsonCodec> providerToolOptionsCodecs;
  late final HttpChatTransportProviderToolOptionsCodec _providerOptionsCodec;

  HttpChatTransportToolJsonCodec({
    this.providerToolOptionsCodecs = const [],
  }) : _providerOptionsCodec = HttpChatTransportProviderToolOptionsCodec(
          codecs: providerToolOptionsCodecs,
        );

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
            'providerOptions': _providerOptionsCodec.encode(
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
      providerOptions: _providerOptionsCodec.decode(
        map['providerOptions'],
        path: '$path.providerOptions',
      ),
    );
  }
}

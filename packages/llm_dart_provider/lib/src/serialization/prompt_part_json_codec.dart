import '../common/json_codec_common.dart';
import '../common/provider_options.dart';
import '../prompt/prompt_message.dart';
import 'prompt_content_part_json_codec.dart';
import 'prompt_part_provider_options_json_codec.dart';
import 'prompt_tool_part_json_codec.dart';

final class PromptPartJsonCodec {
  const PromptPartJsonCodec({
    required this.providerPromptPartOptionsCodecs,
  });

  final Iterable<ProviderPromptPartOptionsJsonCodec>
      providerPromptPartOptionsCodecs;

  PromptPartProviderOptionsJsonCodec get _providerOptionsCodec =>
      PromptPartProviderOptionsJsonCodec(
        providerPromptPartOptionsCodecs: providerPromptPartOptionsCodecs,
      );

  JsonMap encode(PromptPart part) {
    final JsonMap encoded = switch (part) {
      TextPromptPart() ||
      FilePromptPart() ||
      ImagePromptPart() ||
      ReasoningPromptPart() ||
      ReasoningFilePromptPart() ||
      CustomPromptPart() =>
        const PromptContentPartJsonCodec().encode(part),
      ToolCallPromptPart() ||
      ToolApprovalRequestPromptPart() ||
      ToolResultPromptPart() ||
      ToolApprovalResponsePromptPart() =>
        const PromptToolPartJsonCodec().encode(
          part,
          encodeProviderOptions: _encodeProviderPromptPartOptions,
        ),
    };

    if (part.providerOptions case final providerOptions?) {
      encoded['providerOptions'] = _encodeProviderPromptPartOptions(
        providerOptions,
        path: r'$.part.providerOptions',
      );
    }

    return encoded;
  }

  PromptPart decode(
    Object? value, {
    String path = r'$',
  }) {
    final map = asJsonMap(value, path: path);
    final type = asJsonString(map['type'], path: '$path.type');
    final providerOptions = _decodeProviderPromptPartOptions(
      map['providerOptions'],
      path: '$path.providerOptions',
    );
    _rejectLegacyPromptMetadata(map, path: path);

    return switch (type) {
      'text' ||
      'file' ||
      'image' ||
      'reasoning' ||
      'reasoning-file' ||
      'custom' =>
        const PromptContentPartJsonCodec().decode(
          map,
          type: type,
          path: path,
          providerOptions: providerOptions,
        ),
      'tool-call' ||
      'tool-approval-request' ||
      'tool-result' ||
      'tool-approval-response' =>
        const PromptToolPartJsonCodec().decode(
          map,
          type: type,
          path: path,
          providerOptions: providerOptions,
          decodeProviderOptions: _decodeProviderPromptPartOptions,
        ),
      _ =>
        throw FormatException('Unsupported prompt part type "$type" at $path.'),
    };
  }

  void _rejectLegacyPromptMetadata(
    JsonMap map, {
    required String path,
  }) {
    if (!map.containsKey('providerMetadata')) {
      return;
    }

    throw FormatException(
      'Legacy prompt replay metadata is no longer supported at $path.providerMetadata. '
      'Use ProviderReplayPromptPartOptions instead.',
    );
  }

  JsonMap _encodeProviderPromptPartOptions(
    ProviderPromptPartOptions options, {
    required String path,
  }) =>
      _providerOptionsCodec.encode(options, path: path);

  ProviderPromptPartOptions? _decodeProviderPromptPartOptions(
    Object? value, {
    required String path,
  }) =>
      _providerOptionsCodec.decode(value, path: path);
}

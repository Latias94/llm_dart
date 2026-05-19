import '../prompt/prompt_message.dart';
import '../common/json_codec_common.dart';
import '../common/provider_options.dart';
import 'prompt_part_json_codec.dart';
import 'serialization_protocol.dart';

final class PromptJsonCodec {
  static const envelopeKind = 'prompt-messages';

  final List<ProviderPromptPartOptionsJsonCodec>
      providerPromptPartOptionsCodecs;

  const PromptJsonCodec({
    this.providerPromptPartOptionsCodecs = const [],
  });

  PromptPartJsonCodec get _partCodec => PromptPartJsonCodec(
        providerPromptPartOptionsCodecs: _allProviderPromptPartOptionsCodecs(),
      );

  JsonMap encodeMessages(List<PromptMessage> messages) {
    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': envelopeKind,
      'data': {
        'messages': messages.map(encodeMessage).toList(growable: false),
      },
    };
  }

  List<PromptMessage> decodeMessages(Object? envelope) {
    final root = asJsonMap(envelope, path: r'$');
    final kind = asJsonString(root['kind'], path: r'$.kind');
    if (kind != envelopeKind) {
      throw FormatException(
        'Expected envelope kind "$envelopeKind", received "$kind".',
      );
    }

    final data = asJsonMap(root['data'], path: r'$.data');
    return asJsonList(data['messages'], path: r'$.data.messages')
        .asMap()
        .entries
        .map(
          (entry) => decodeMessage(
            entry.value,
            path: '\$.data.messages[${entry.key}]',
          ),
        )
        .toList(growable: false);
  }

  JsonMap encodeMessage(PromptMessage message) {
    return {
      'role': message.role.name,
      'parts': message.parts.map(encodePart).toList(growable: false),
      if (message case ToolPromptMessage(:final toolName)) 'toolName': toolName,
    };
  }

  PromptMessage decodeMessage(
    Object? value, {
    String path = r'$',
  }) {
    final map = asJsonMap(value, path: path);
    final role = PromptRole.values.byName(
      asJsonString(map['role'], path: '$path.role'),
    );
    final parts = asJsonList(map['parts'], path: '$path.parts')
        .asMap()
        .entries
        .map((entry) =>
            decodePart(entry.value, path: '$path.parts[${entry.key}]'))
        .toList(growable: false);

    return switch (role) {
      PromptRole.system => SystemPromptMessage(parts: parts),
      PromptRole.user => UserPromptMessage(parts: parts),
      PromptRole.assistant => AssistantPromptMessage(parts: parts),
      PromptRole.tool => ToolPromptMessage(
          toolName: asJsonString(map['toolName'], path: '$path.toolName'),
          parts: parts,
        ),
    };
  }

  JsonMap encodePart(PromptPart part) {
    return _partCodec.encode(part);
  }

  PromptPart decodePart(
    Object? value, {
    String path = r'$',
  }) {
    return _partCodec.decode(value, path: path);
  }

  Iterable<ProviderPromptPartOptionsJsonCodec>
      _allProviderPromptPartOptionsCodecs() sync* {
    yield providerReplayPromptPartOptionsJsonCodec;
    yield* providerPromptPartOptionsCodecs;
  }
}

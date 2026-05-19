import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../ui/chat_ui_message.dart';

final class ChatUiMetadataJsonCodec {
  const ChatUiMetadataJsonCodec();

  JsonMap encode(Map<String, Object?> metadata) {
    final result = <String, Object?>{};

    for (final entry in metadata.entries) {
      result[entry.key] = _encodeValue(entry.key, entry.value);
    }

    return result;
  }

  Map<String, Object?> decode(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return const {};
    }

    final map = asJsonMap(value, path: path);
    final result = <String, Object?>{};

    for (final entry in map.entries) {
      result[entry.key] = _decodeValue(
        entry.key,
        entry.value,
        path: '$path.${entry.key}',
      );
    }

    return result;
  }

  Object? _encodeValue(String key, Object? value) {
    return switch (key) {
      ChatUiMetadataKeys.warnings => _encodeModelWarnings(
          value,
          path: r'$.metadata.warnings',
        ),
      ChatUiMetadataKeys.responseTimestamp =>
        (value as DateTime?)?.toIso8601String(),
      ChatUiMetadataKeys.responseProviderMetadata ||
      ChatUiMetadataKeys.finishProviderMetadata =>
        value == null
            ? null
            : SerializationJsonSupport.encodeProviderMetadata(
                value as ProviderMetadata),
      ChatUiMetadataKeys.errors => _encodeModelErrors(
          value,
          path: r'$.metadata.errors',
        ),
      ChatUiMetadataKeys.finishReason ||
      ChatUiMetadataKeys.runFinishReason =>
        (value as FinishReason?)?.name,
      ChatUiMetadataKeys.usage || ChatUiMetadataKeys.runUsage => value == null
          ? null
          : SerializationJsonSupport.encodeUsageStats(value as UsageStats),
      _ => ensureJsonValue(value, path: r'$.metadata'),
    };
  }

  Object? _decodeValue(
    String key,
    Object? value, {
    required String path,
  }) {
    return switch (key) {
      ChatUiMetadataKeys.warnings => asJsonList(value, path: path)
          .asMap()
          .entries
          .map(
            (entry) => SerializationJsonSupport.decodeModelWarning(
              entry.value,
              path: '$path[${entry.key}]',
            ),
          )
          .toList(growable: false),
      ChatUiMetadataKeys.responseTimestamp =>
        value == null ? null : DateTime.parse(asJsonString(value, path: path)),
      ChatUiMetadataKeys.responseProviderMetadata ||
      ChatUiMetadataKeys.finishProviderMetadata =>
        SerializationJsonSupport.decodeProviderMetadata(value, path: path),
      ChatUiMetadataKeys.errors => asJsonList(value, path: path)
          .asMap()
          .entries
          .map(
            (entry) => SerializationJsonSupport.decodeModelError(
              entry.value,
              path: '$path[${entry.key}]',
            ),
          )
          .toList(growable: false),
      ChatUiMetadataKeys.finishReason ||
      ChatUiMetadataKeys.runFinishReason =>
        value == null
            ? null
            : FinishReason.values.byName(asJsonString(value, path: path)),
      ChatUiMetadataKeys.usage ||
      ChatUiMetadataKeys.runUsage =>
        SerializationJsonSupport.decodeUsageStats(value, path: path),
      _ => value,
    };
  }

  List<JsonMap> _encodeModelWarnings(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return const [];
    }

    if (value is! List) {
      throw FormatException('Expected warnings list at $path.');
    }

    return value.asMap().entries.map((entry) {
      final warning = entry.value;
      if (warning is! ModelWarning) {
        throw FormatException(
          'Expected ModelWarning at $path[${entry.key}], received ${warning.runtimeType}.',
        );
      }

      return SerializationJsonSupport.encodeModelWarning(warning);
    }).toList(growable: false);
  }

  List<JsonMap> _encodeModelErrors(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return const [];
    }

    if (value is! List) {
      throw FormatException('Expected errors list at $path.');
    }

    return value
        .map((entry) => SerializationJsonSupport.encodeModelError(
              ModelError.fromUnknown(entry),
            ))
        .toList(growable: false);
  }
}

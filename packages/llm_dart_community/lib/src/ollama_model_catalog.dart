import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'ollama_api.dart';

final class OllamaCatalogSettings {
  final Map<String, String> headers;

  const OllamaCatalogSettings({
    this.headers = const {},
  });
}

final class OllamaInstalledModelDetails {
  final String? format;
  final String? family;
  final List<String> families;
  final String? parameterSize;
  final String? quantizationLevel;

  const OllamaInstalledModelDetails({
    this.format,
    this.family,
    this.families = const [],
    this.parameterSize,
    this.quantizationLevel,
  });

  factory OllamaInstalledModelDetails.fromJson(Map<String, Object?> json) {
    return OllamaInstalledModelDetails(
      format: _optionalString(json['format'], path: 'details.format'),
      family: _optionalString(json['family'], path: 'details.family'),
      families: _optionalStringList(
        json['families'],
        path: 'details.families',
      ),
      parameterSize: _optionalString(
        json['parameter_size'],
        path: 'details.parameter_size',
      ),
      quantizationLevel: _optionalString(
        json['quantization_level'],
        path: 'details.quantization_level',
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      if (format != null) 'format': format,
      if (family != null) 'family': family,
      if (families.isNotEmpty) 'families': families,
      if (parameterSize != null) 'parameter_size': parameterSize,
      if (quantizationLevel != null) 'quantization_level': quantizationLevel,
    };
  }
}

final class OllamaInstalledModel {
  final String name;
  final DateTime? modifiedAt;
  final int? sizeBytes;
  final String? digest;
  final OllamaInstalledModelDetails? details;

  const OllamaInstalledModel({
    required this.name,
    this.modifiedAt,
    this.sizeBytes,
    this.digest,
    this.details,
  });

  factory OllamaInstalledModel.fromJson(Map<String, Object?> json) {
    return OllamaInstalledModel(
      name: _requiredNonEmptyString(json['name'], path: 'model.name'),
      modifiedAt: _optionalDateTime(
        json['modified_at'],
        path: 'model.modified_at',
      ),
      sizeBytes: _optionalInt(json['size'], path: 'model.size'),
      digest: _optionalString(json['digest'], path: 'model.digest'),
      details: switch (json['details']) {
        null => null,
        final value => OllamaInstalledModelDetails.fromJson(
            _requiredMap(value, path: 'model.details'),
          ),
      },
    );
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      if (modifiedAt != null) 'modified_at': modifiedAt!.toIso8601String(),
      if (sizeBytes != null) 'size': sizeBytes,
      if (digest != null) 'digest': digest,
      if (details != null) 'details': details!.toJson(),
    };
  }
}

final class OllamaModelCatalogClient {
  final String? apiKey;
  final String baseUrl;
  final TransportClient transport;
  final OllamaCatalogSettings settings;

  OllamaModelCatalogClient({
    required this.transport,
    String? apiKey,
    String? baseUrl,
    this.settings = const OllamaCatalogSettings(),
  })  : apiKey = normalizeOllamaApiKey(apiKey),
        baseUrl = normalizeOllamaBaseUrl(baseUrl);

  Uri get tagsUri => resolveOllamaUri(baseUrl, '/api/tags');

  Future<List<OllamaInstalledModel>> listModels({
    Duration? timeout,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await transport.send(
      TransportRequest(
        uri: tagsUri,
        method: TransportMethod.get,
        headers: buildOllamaHeaders(
          apiKey: apiKey,
          headers: {
            ...settings.headers,
            if (headers != null) ...headers,
          },
        ),
        timeout: timeout,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    final json = decodeOllamaJsonObject(
      response.body,
      responseName: 'model catalog response',
    );
    return _requiredList(json['models'], path: 'catalog.models')
        .asMap()
        .entries
        .map((entry) {
      return OllamaInstalledModel.fromJson(
        _requiredMap(
          entry.value,
          path: 'catalog.models[${entry.key}]',
        ),
      );
    }).toList(growable: false);
  }
}

Map<String, Object?> _requiredMap(
  Object? value, {
  required String path,
}) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  throw FormatException('Expected a JSON object at $path.');
}

List<Object?> _requiredList(
  Object? value, {
  required String path,
}) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  throw FormatException('Expected a list at $path.');
}

String _requiredNonEmptyString(
  Object? value, {
  required String path,
}) {
  final normalized = _optionalString(value, path: path);
  if (normalized == null || normalized.isEmpty) {
    throw FormatException('Expected a non-empty string at $path.');
  }

  return normalized;
}

String? _optionalString(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  if (value is String) {
    return value;
  }

  throw FormatException('Expected a string at $path.');
}

List<String> _optionalStringList(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return const [];
  }

  if (value is! List) {
    throw FormatException('Expected a string list at $path.');
  }

  return List<String>.generate(
    value.length,
    (index) => _requiredNonEmptyString(
      value[index],
      path: '$path[$index]',
    ),
    growable: false,
  );
}

int? _optionalInt(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  throw FormatException('Expected an int at $path.');
}

DateTime? _optionalDateTime(
  Object? value, {
  required String path,
}) {
  final text = _optionalString(value, path: path);
  if (text == null) {
    return null;
  }

  final parsed = DateTime.tryParse(text);
  if (parsed == null) {
    throw FormatException('Expected an ISO-8601 datetime at $path.');
  }

  return parsed;
}

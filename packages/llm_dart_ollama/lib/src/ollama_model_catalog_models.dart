import 'ollama_model_catalog_json.dart';

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
      format: optionalOllamaString(json['format'], path: 'details.format'),
      family: optionalOllamaString(json['family'], path: 'details.family'),
      families: optionalOllamaStringList(
        json['families'],
        path: 'details.families',
      ),
      parameterSize: optionalOllamaString(
        json['parameter_size'],
        path: 'details.parameter_size',
      ),
      quantizationLevel: optionalOllamaString(
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
      name: requiredOllamaNonEmptyString(json['name'], path: 'model.name'),
      modifiedAt: optionalOllamaDateTime(
        json['modified_at'],
        path: 'model.modified_at',
      ),
      sizeBytes: optionalOllamaInt(json['size'], path: 'model.size'),
      digest: optionalOllamaString(json['digest'], path: 'model.digest'),
      details: switch (json['details']) {
        null => null,
        final value => OllamaInstalledModelDetails.fromJson(
            requiredOllamaJsonMap(value, path: 'model.details'),
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

List<OllamaInstalledModel> decodeOllamaInstalledModelsList(
  Map<String, Object?> json,
) {
  return requiredOllamaJsonList(json['models'], path: 'catalog.models')
      .asMap()
      .entries
      .map((entry) {
    return OllamaInstalledModel.fromJson(
      requiredOllamaJsonMap(
        entry.value,
        path: 'catalog.models[${entry.key}]',
      ),
    );
  }).toList(growable: false);
}

import 'dart:convert';

import '../common/json_codec_common.dart';
import '../common/provider_reference.dart';
import '../content/content_part.dart';
import '../content/file_data.dart';

final class SerializationFileJsonCodec {
  const SerializationFileJsonCodec();

  JsonMap encodeGeneratedFile(GeneratedFile file) {
    return {
      'mediaType': file.mediaType,
      if (file.filename != null) 'filename': file.filename,
      'data': encodeFileData(file.data),
    };
  }

  GeneratedFile decodeGeneratedFile(
    Object? value, {
    required String path,
  }) {
    final map = asJsonMap(value, path: path);

    return GeneratedFile(
      mediaType: asJsonString(map['mediaType'], path: '$path.mediaType'),
      filename: asNullableJsonString(map['filename'], path: '$path.filename'),
      data: decodeRequiredFileDataFromMap(map, path: path),
    );
  }

  FileData decodeRequiredFileDataFromMap(
    JsonMap map, {
    required String path,
  }) {
    final data = decodeFileData(map['data'], path: '$path.data') ??
        fileDataFromLegacy(
          uri: decodeUri(map['uri'], path: '$path.uri'),
          bytes: map.containsKey('data')
              ? null
              : decodeBytes(map['bytes'], path: '$path.bytes'),
        );

    if (data == null) {
      throw FormatException('Expected file data, uri, or bytes at $path.');
    }

    return data;
  }

  JsonMap encodeFileData(FileData data) {
    return switch (data) {
      FileBytesData(:final bytes) => {
          'type': 'bytes',
          'bytes': encodeBytes(bytes),
        },
      FileUrlData(:final uri) => {
          'type': 'url',
          'uri': uri.toString(),
        },
      FileTextData(:final text) => {
          'type': 'text',
          'text': text,
        },
      FileProviderReferenceData(:final providerReference) => {
          'type': 'provider-reference',
          'providerReference': providerReference.toJsonMap(),
        },
    };
  }

  FileData? decodeFileData(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    final map = asJsonMap(value, path: path);
    final type = asJsonString(map['type'], path: '$path.type');

    return switch (type) {
      'bytes' => FileBytesData(
          decodeBytes(map['bytes'], path: '$path.bytes') ??
              (throw FormatException('Expected bytes at $path.bytes.')),
        ),
      'url' => FileUrlData(
          decodeUri(map['uri'], path: '$path.uri') ??
              (throw FormatException('Expected URI at $path.uri.')),
        ),
      'text' => FileTextData(
          asJsonString(map['text'], path: '$path.text'),
        ),
      'provider-reference' => FileProviderReferenceData(
          ProviderReference.fromJson(
            map['providerReference'],
            path: '$path.providerReference',
          ),
        ),
      _ =>
        throw FormatException('Unsupported file data type "$type" at $path.'),
    };
  }

  JsonMap encodeBytes(List<int> bytes) {
    return {
      'encoding': 'base64',
      'data': base64Encode(bytes),
    };
  }

  List<int>? decodeBytes(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    final map = asJsonMap(value, path: path);
    final encoding = asJsonString(map['encoding'], path: '$path.encoding');
    if (encoding != 'base64') {
      throw FormatException('Unsupported byte encoding "$encoding" at $path.');
    }

    return base64Decode(asJsonString(map['data'], path: '$path.data'));
  }

  Uri? decodeUri(
    Object? value, {
    required String path,
  }) {
    final stringValue = asNullableJsonString(value, path: path);
    return stringValue == null ? null : Uri.parse(stringValue);
  }
}

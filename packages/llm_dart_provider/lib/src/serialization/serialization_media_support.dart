import '../common/json_codec_common.dart';
import '../content/content_part.dart';
import '../content/file_data.dart';
import 'serialization_file_json_codec.dart';
import 'serialization_source_reference_json_codec.dart';

final class SerializationMediaSupport {
  const SerializationMediaSupport._();

  static const _fileCodec = SerializationFileJsonCodec();
  static const _sourceReferenceCodec = SerializationSourceReferenceJsonCodec();

  static JsonMap encodeSourceReference(SourceReference source) =>
      _sourceReferenceCodec.encodeSourceReference(source);

  static SourceReference decodeSourceReference(
    Object? value, {
    required String path,
  }) =>
      _sourceReferenceCodec.decodeSourceReference(value, path: path);

  static String encodeSourceReferenceKind(SourceReferenceKind kind) =>
      _sourceReferenceCodec.encodeSourceReferenceKind(kind);

  static SourceReferenceKind decodeSourceReferenceKind(
    Object? value, {
    required String path,
    required Object? uri,
  }) =>
      _sourceReferenceCodec.decodeSourceReferenceKind(
        value,
        path: path,
        uri: uri,
      );

  static JsonMap encodeGeneratedFile(GeneratedFile file) =>
      _fileCodec.encodeGeneratedFile(file);

  static GeneratedFile decodeGeneratedFile(
    Object? value, {
    required String path,
  }) =>
      _fileCodec.decodeGeneratedFile(value, path: path);

  static FileData decodeRequiredFileDataFromMap(
    JsonMap map, {
    required String path,
  }) =>
      _fileCodec.decodeRequiredFileDataFromMap(map, path: path);

  static JsonMap encodeFileData(FileData data) =>
      _fileCodec.encodeFileData(data);

  static FileData? decodeFileData(
    Object? value, {
    required String path,
  }) =>
      _fileCodec.decodeFileData(value, path: path);

  static JsonMap encodeBytes(List<int> bytes) => _fileCodec.encodeBytes(bytes);

  static List<int>? decodeBytes(
    Object? value, {
    required String path,
  }) =>
      _fileCodec.decodeBytes(value, path: path);

  static Uri? decodeUri(
    Object? value, {
    required String path,
  }) =>
      _fileCodec.decodeUri(value, path: path);
}

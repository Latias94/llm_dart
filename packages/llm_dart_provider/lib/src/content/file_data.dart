import '../common/provider_reference.dart';

sealed class FileData {
  const FileData();

  Uri? get uri => null;

  List<int>? get bytes => null;

  String? get text => null;

  ProviderReference? get providerReference => null;
}

final class FileBytesData extends FileData {
  @override
  final List<int> bytes;

  FileBytesData(List<int> bytes) : bytes = List<int>.unmodifiable(bytes);

  const FileBytesData.constBytes(this.bytes);
}

final class FileUrlData extends FileData {
  @override
  final Uri uri;

  const FileUrlData(this.uri);
}

final class FileTextData extends FileData {
  @override
  final String text;

  const FileTextData(this.text);
}

final class FileProviderReferenceData extends FileData {
  @override
  final ProviderReference providerReference;

  const FileProviderReferenceData(this.providerReference);
}

FileData? fileDataFromLegacy({
  Uri? uri,
  List<int>? bytes,
}) {
  if (bytes != null) {
    return FileBytesData(bytes);
  }

  if (uri != null) {
    return FileUrlData(uri);
  }

  return null;
}

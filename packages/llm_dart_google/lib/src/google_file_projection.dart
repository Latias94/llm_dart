import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_shared.dart';

final class GoogleProjectedFile {
  final GeneratedFile file;
  final bool isThought;
  final ProviderMetadata? providerMetadata;

  const GoogleProjectedFile({
    required this.file,
    required this.isThought,
    this.providerMetadata,
  });
}

GoogleProjectedFile? projectGoogleInlineDataFile({
  required Object? inlineDataValue,
  required bool isThought,
  ProviderMetadata? providerMetadata,
}) {
  final inlineData = asMap(inlineDataValue);
  final mediaType = asString(inlineData?['mimeType']);
  final data = asString(inlineData?['data']);
  if (mediaType == null || data == null) {
    return null;
  }

  return GoogleProjectedFile(
    file: GeneratedFile(
      mediaType: mediaType,
      data: FileBytesData(
        decodeBase64(data) ??
            (throw FormatException(
              'Expected Google inlineData.data to be base64.',
            )),
      ),
    ),
    isThought: isThought,
    providerMetadata: providerMetadata,
  );
}

ContentPart googleProjectedFileContentPart(GoogleProjectedFile projected) {
  if (projected.isThought) {
    return ReasoningFileContentPart(
      projected.file,
      providerMetadata: projected.providerMetadata,
    );
  }

  return FileContentPart(
    projected.file,
    providerMetadata: projected.providerMetadata,
  );
}

LanguageModelStreamEvent googleProjectedFileEvent(
  GoogleProjectedFile projected,
) {
  if (projected.isThought) {
    return ReasoningFileEvent(
      projected.file,
      providerMetadata: projected.providerMetadata,
    );
  }

  return FileEvent(
    projected.file,
    providerMetadata: projected.providerMetadata,
  );
}

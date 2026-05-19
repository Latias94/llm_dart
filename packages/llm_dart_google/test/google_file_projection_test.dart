import 'package:llm_dart_google/src/google_file_projection.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('Google file projection', () {
    test('projects inlineData into file content parts and events', () {
      const metadata = ProviderMetadata({
        'google': {
          'thoughtSignature': 'sig_file',
        },
      });
      final projected = projectGoogleInlineDataFile(
        inlineDataValue: {
          'mimeType': 'application/pdf',
          'data': 'AQID',
        },
        isThought: false,
        providerMetadata: metadata,
      );

      expect(projected, isNotNull);
      expect(projected!.file.mediaType, 'application/pdf');
      expect(projected.file.bytes, [1, 2, 3]);
      expect(projected.isThought, isFalse);
      expect(projected.providerMetadata, metadata);

      final contentPart = googleProjectedFileContentPart(projected);
      expect(contentPart, isA<FileContentPart>());
      final filePart = contentPart as FileContentPart;
      expect(filePart.file.mediaType, 'application/pdf');
      expect(filePart.file.bytes, [1, 2, 3]);
      expect(filePart.providerMetadata, metadata);

      final event = googleProjectedFileEvent(projected);
      expect(event, isA<FileEvent>());
      final fileEvent = event as FileEvent;
      expect(fileEvent.file.mediaType, 'application/pdf');
      expect(fileEvent.file.bytes, [1, 2, 3]);
      expect(fileEvent.providerMetadata, metadata);
    });

    test('projects thought inlineData into reasoning file content and events',
        () {
      const metadata = ProviderMetadata({
        'google': {
          'thoughtSignature': 'sig_reasoning_file',
          'thought': true,
        },
      });
      final projected = projectGoogleInlineDataFile(
        inlineDataValue: {
          'mimeType': 'image/png',
          'data': 'BAUG',
        },
        isThought: true,
        providerMetadata: metadata,
      );

      expect(projected, isNotNull);
      expect(projected!.file.mediaType, 'image/png');
      expect(projected.file.bytes, [4, 5, 6]);
      expect(projected.isThought, isTrue);

      final contentPart = googleProjectedFileContentPart(projected);
      expect(contentPart, isA<ReasoningFileContentPart>());
      final reasoningFilePart = contentPart as ReasoningFileContentPart;
      expect(reasoningFilePart.file.mediaType, 'image/png');
      expect(reasoningFilePart.file.bytes, [4, 5, 6]);
      expect(reasoningFilePart.providerMetadata, metadata);

      final event = googleProjectedFileEvent(projected);
      expect(event, isA<ReasoningFileEvent>());
      final reasoningFileEvent = event as ReasoningFileEvent;
      expect(reasoningFileEvent.file.mediaType, 'image/png');
      expect(reasoningFileEvent.file.bytes, [4, 5, 6]);
      expect(reasoningFileEvent.providerMetadata, metadata);
    });

    test('ignores inlineData without media type or data', () {
      expect(
        projectGoogleInlineDataFile(
          inlineDataValue: {
            'mimeType': 'image/png',
          },
          isThought: false,
        ),
        isNull,
      );
      expect(
        projectGoogleInlineDataFile(
          inlineDataValue: {
            'data': 'AQID',
          },
          isThought: false,
        ),
        isNull,
      );
    });
  });
}

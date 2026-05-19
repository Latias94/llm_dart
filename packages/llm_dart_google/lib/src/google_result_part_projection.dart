import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_content_projection_support.dart';
import 'google_provider_metadata_support.dart';
import 'google_result_non_text_part_projection.dart';
import 'google_shared.dart';

final class GoogleGenerateContentResultPartProjection {
  final List<ContentPart> content;
  final bool hasClientToolCalls;

  const GoogleGenerateContentResultPartProjection({
    required this.content,
    required this.hasClientToolCalls,
  });
}

final class GoogleGenerateContentResultPartProjector {
  final GoogleCodeExecutionTracker _codeExecutionTracker;

  bool _hasClientToolCalls = false;

  GoogleGenerateContentResultPartProjector({
    GoogleCodeExecutionTracker? codeExecutionTracker,
  }) : _codeExecutionTracker =
            codeExecutionTracker ?? GoogleCodeExecutionTracker();

  GoogleGenerateContentResultPartProjection project(
    List<Object?> parts,
  ) {
    final content = <ContentPart>[];

    for (var index = 0; index < parts.length; index++) {
      final part = asMap(parts[index]);
      if (part == null) {
        continue;
      }

      final projectedParts = projectPart(part, index: index, content: content);
      content.addAll(projectedParts);
    }

    return GoogleGenerateContentResultPartProjection(
      content: content,
      hasClientToolCalls: _hasClientToolCalls,
    );
  }

  Iterable<ContentPart> projectPart(
    Map<String, Object?> part, {
    required int index,
    required List<ContentPart> content,
  }) sync* {
    final metadata = googleThoughtSignatureMetadata(
      asString(part['thoughtSignature']),
      isThought: part['thought'] == true,
    );

    if (part case {'executableCode': final Object? executableCode}) {
      yield* projectGoogleResultExecutableCodePart(
        tracker: _codeExecutionTracker,
        executableCode: executableCode,
        metadata: metadata,
      );
      return;
    }

    if (part case {'codeExecutionResult': final Object? executionResult}) {
      yield* projectGoogleResultCodeExecutionResultPart(
        tracker: _codeExecutionTracker,
        executionResult: executionResult,
        metadata: metadata,
      );
      return;
    }

    if (part case {'functionCall': final Object? functionCallValue}) {
      final projection = projectGoogleResultFunctionCallPart(
        functionCallValue: functionCallValue,
        fallbackToolCallId: 'tool-$index',
        metadata: metadata,
      );
      if (projection.hasClientToolCalls) {
        _hasClientToolCalls = true;
      }
      yield* projection.content;
      return;
    }

    if (part case {'toolCall': final Object? toolCallValue}) {
      yield* projectGoogleResultServerToolCallPart(
        toolCallValue: toolCallValue,
        metadata: metadata,
      );
      return;
    }

    if (part case {'toolResponse': final Object? toolResponseValue}) {
      yield* projectGoogleResultServerToolResponsePart(
        toolResponseValue: toolResponseValue,
        metadata: metadata,
      );
      return;
    }

    if (part case {'text': final Object? textValue}) {
      final text = asString(textValue) ?? '';
      if (text.isEmpty) {
        attachGoogleMetadataToLastContent(content, metadata);
        return;
      }

      if (part['thought'] == true) {
        yield ReasoningContentPart(
          text,
          providerMetadata: metadata,
        );
      } else {
        yield TextContentPart(
          text,
          providerMetadata: metadata,
        );
      }
      return;
    }

    if (part case {'inlineData': final Object? inlineDataValue}) {
      yield* projectGoogleResultInlineDataPart(
        part: part,
        inlineDataValue: inlineDataValue,
        metadata: metadata,
      );
    }
  }
}

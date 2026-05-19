import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_content_projection_support.dart';
import 'google_file_projection.dart';
import 'google_provider_metadata_support.dart';
import 'google_server_tool_replay.dart';
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
      final projectedToolCall = projectGoogleCodeExecutionToolCall(
        tracker: _codeExecutionTracker,
        executableCode: executableCode,
        providerMetadata: metadata,
      );
      yield googleProjectedToolCallContentPart(projectedToolCall);
      return;
    }

    if (part case {'codeExecutionResult': final Object? executionResult}) {
      final projectedToolResult = projectGoogleCodeExecutionToolResult(
        tracker: _codeExecutionTracker,
        executionResult: executionResult,
        providerMetadata: metadata,
      );
      yield googleProjectedToolResultContentPart(projectedToolResult);
      return;
    }

    if (part case {'functionCall': final Object? functionCallValue}) {
      final functionCall = asMap(functionCallValue);
      final projectedToolCall = projectGoogleFunctionToolCall(
        functionCall: functionCall,
        fallbackToolCallId: 'tool-$index',
        providerMetadata: metadata,
      );
      if (projectedToolCall != null) {
        _hasClientToolCalls = true;
        yield googleProjectedToolCallContentPart(projectedToolCall);
      }
      return;
    }

    if (part case {'toolCall': final Object? toolCallValue}) {
      final toolCall = asMap(toolCallValue);
      if (toolCall != null) {
        final replay = GoogleToolCallReplay.fromToolCall(
          toolCall,
          providerMetadata: metadata,
        );
        yield replay.toCustomContentPart();
      }
      return;
    }

    if (part case {'toolResponse': final Object? toolResponseValue}) {
      final toolResponse = asMap(toolResponseValue);
      if (toolResponse != null) {
        final replay = GoogleToolResponseReplay.fromToolResponse(
          toolResponse,
          providerMetadata: metadata,
        );
        yield replay.toCustomContentPart();
      }
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
      final projectedFile = projectGoogleInlineDataFile(
        inlineDataValue: inlineDataValue,
        isThought: part['thought'] == true,
        providerMetadata: metadata,
      );
      if (projectedFile != null) {
        yield googleProjectedFileContentPart(projectedFile);
      }
    }
  }
}

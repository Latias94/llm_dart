import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_content_projection_support.dart';
import 'google_file_projection.dart';
import 'google_grounding_projection.dart';
import 'google_provider_metadata_support.dart';
import 'google_server_tool_replay.dart';
import 'google_shared.dart';

final class GoogleGenerateContentResultCodec {
  const GoogleGenerateContentResultCodec();

  GenerateTextResult decodeResponse(
    Map<String, Object?> response, {
    List<ModelWarning> warnings = const [],
  }) {
    final responseId = asString(response['responseId']);
    final responseModelId = asString(response['modelVersion']);
    final promptFeedback = asMap(response['promptFeedback']);
    final usageMetadata = asMap(response['usageMetadata']);
    final candidates = asList(response['candidates']);
    final candidate = candidates.isEmpty ? null : asMap(candidates.first);
    final content = <ContentPart>[];
    var hasClientToolCalls = false;
    final codeExecutionTracker = GoogleCodeExecutionTracker();

    if (candidate != null) {
      final candidateContent = asMap(candidate['content']);
      final parts = asList(candidateContent?['parts']);

      for (var index = 0; index < parts.length; index++) {
        final part = asMap(parts[index]);
        if (part == null) {
          continue;
        }

        final signatureMetadata = googleThoughtSignatureMetadata(
          asString(part['thoughtSignature']),
          isThought: part['thought'] == true,
        );

        if (part case {'executableCode': final Object? executableCode}) {
          final projectedToolCall = projectGoogleCodeExecutionToolCall(
            tracker: codeExecutionTracker,
            executableCode: executableCode,
            providerMetadata: signatureMetadata,
          );
          content.add(googleProjectedToolCallContentPart(projectedToolCall));
          continue;
        }

        if (part case {'codeExecutionResult': final Object? executionResult}) {
          final projectedToolResult = projectGoogleCodeExecutionToolResult(
            tracker: codeExecutionTracker,
            executionResult: executionResult,
            providerMetadata: signatureMetadata,
          );
          content
              .add(googleProjectedToolResultContentPart(projectedToolResult));
          continue;
        }

        if (part case {'functionCall': final Object? functionCallValue}) {
          final functionCall = asMap(functionCallValue);
          final projectedToolCall = projectGoogleFunctionToolCall(
            functionCall: functionCall,
            fallbackToolCallId: 'tool-$index',
            providerMetadata: signatureMetadata,
          );
          if (projectedToolCall != null) {
            hasClientToolCalls = true;
            content.add(googleProjectedToolCallContentPart(projectedToolCall));
          }
          continue;
        }

        if (part case {'toolCall': final Object? toolCallValue}) {
          final toolCall = asMap(toolCallValue);
          if (toolCall != null) {
            final replay = GoogleToolCallReplay.fromToolCall(
              toolCall,
              providerMetadata: signatureMetadata,
            );
            content.add(replay.toCustomContentPart());
          }
          continue;
        }

        if (part case {'toolResponse': final Object? toolResponseValue}) {
          final toolResponse = asMap(toolResponseValue);
          if (toolResponse != null) {
            final replay = GoogleToolResponseReplay.fromToolResponse(
              toolResponse,
              providerMetadata: signatureMetadata,
            );
            content.add(replay.toCustomContentPart());
          }
          continue;
        }

        if (part case {'text': final Object? textValue}) {
          final text = asString(textValue) ?? '';
          if (text.isEmpty) {
            attachGoogleMetadataToLastContent(content, signatureMetadata);
            continue;
          }

          if (part['thought'] == true) {
            content.add(
              ReasoningContentPart(
                text,
                providerMetadata: signatureMetadata,
              ),
            );
          } else {
            content.add(
              TextContentPart(
                text,
                providerMetadata: signatureMetadata,
              ),
            );
          }
          continue;
        }

        if (part case {'inlineData': final Object? inlineDataValue}) {
          final projectedFile = projectGoogleInlineDataFile(
            inlineDataValue: inlineDataValue,
            isThought: part['thought'] == true,
            providerMetadata: signatureMetadata,
          );
          if (projectedFile != null) {
            content.add(googleProjectedFileContentPart(projectedFile));
          }
        }
      }

      for (final sourcePart in projectGoogleGroundingContentParts(
        asMap(candidate['groundingMetadata']),
      )) {
        content.add(sourcePart);
      }
    }

    final rawFinishReason = asString(candidate?['finishReason']) ??
        asString(promptFeedback?['blockReason']);

    return GenerateTextResult(
      content: content,
      finishReason: mapGoogleFinishReason(
        rawFinishReason,
        hasClientToolCalls: hasClientToolCalls,
      ),
      rawFinishReason: rawFinishReason,
      responseMetadata: ModelResponseMetadata(
        id: responseId,
        modelId: responseModelId,
      ),
      usage: decodeGoogleUsage(usageMetadata),
      providerMetadata: buildGoogleGenerationMetadata(
        promptFeedback: promptFeedback,
        groundingMetadata: asMap(candidate?['groundingMetadata']),
        urlContextMetadata: asMap(candidate?['urlContextMetadata']),
        safetyRatings: asList(candidate?['safetyRatings']),
        usageMetadata: usageMetadata,
        finishMessage: asString(candidate?['finishMessage']),
      ),
      warnings: warnings,
    );
  }
}

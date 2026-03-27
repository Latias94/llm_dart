import 'package:llm_dart_core/llm_dart_core.dart';

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
    var codeExecutionCounter = 0;
    String? lastCodeExecutionToolCallId;

    if (candidate != null) {
      final candidateContent = asMap(candidate['content']);
      final parts = asList(candidateContent?['parts']);

      for (var index = 0; index < parts.length; index++) {
        final part = asMap(parts[index]);
        if (part == null) {
          continue;
        }

        final signatureMetadata = _thoughtSignatureMetadata(
          asString(part['thoughtSignature']),
          isThought: part['thought'] == true,
        );

        if (part case {'executableCode': final Object? executableCode}) {
          final toolCallId = 'code-execution-${codeExecutionCounter++}';
          lastCodeExecutionToolCallId = toolCallId;
          content.add(
            ToolCallContentPart(
              ToolCallContent(
                toolCallId: toolCallId,
                toolName: 'code_execution',
                input: normalizeJsonValue(executableCode),
                providerExecuted: true,
                isDynamic: true,
              ),
              providerMetadata: signatureMetadata,
            ),
          );
          continue;
        }

        if (part case {'codeExecutionResult': final Object? executionResult}) {
          final toolCallId = lastCodeExecutionToolCallId ??
              'code-execution-${codeExecutionCounter++}';
          final result = asMap(executionResult);
          content.add(
            ToolResultContentPart(
              ToolResultContent(
                toolCallId: toolCallId,
                toolName: 'code_execution',
                output: normalizeJsonValue(executionResult),
                isError: _isCodeExecutionError(result),
                isDynamic: true,
              ),
              providerMetadata: signatureMetadata,
            ),
          );
          lastCodeExecutionToolCallId = null;
          continue;
        }

        if (part case {'functionCall': final Object? functionCallValue}) {
          final functionCall = asMap(functionCallValue);
          final toolName = asString(functionCall?['name']);
          if (toolName != null) {
            hasClientToolCalls = true;
            content.add(
              ToolCallContentPart(
                ToolCallContent(
                  toolCallId: 'tool-$index',
                  toolName: toolName,
                  input: normalizeJsonValue(functionCall?['args']),
                ),
                providerMetadata: signatureMetadata,
              ),
            );
          }
          continue;
        }

        if (part case {'text': final Object? textValue}) {
          final text = asString(textValue) ?? '';
          if (text.isEmpty) {
            _attachMetadataToLastContent(content, signatureMetadata);
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
          final inlineData = asMap(inlineDataValue);
          final mediaType = asString(inlineData?['mimeType']);
          final data = asString(inlineData?['data']);
          if (mediaType != null && data != null) {
            content.add(
              FileContentPart(
                GeneratedFile(
                  mediaType: mediaType,
                  bytes: decodeBase64(data),
                ),
                providerMetadata: signatureMetadata,
              ),
            );
          }
        }
      }

      for (final source in extractGroundingSources(
        asMap(candidate['groundingMetadata']),
      )) {
        content.add(SourceContentPart(source));
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
      responseId: responseId,
      responseModelId: responseModelId,
      usage: decodeGoogleUsage(usageMetadata),
      providerMetadata: googleProviderMetadata({
        'promptFeedback': promptFeedback,
        'groundingMetadata': asMap(candidate?['groundingMetadata']),
        'urlContextMetadata': asMap(candidate?['urlContextMetadata']),
        'safetyRatings': asList(candidate?['safetyRatings']),
        'usageMetadata': usageMetadata,
        'finishMessage': asString(candidate?['finishMessage']),
      }),
      warnings: warnings,
    );
  }

  ProviderMetadata? _thoughtSignatureMetadata(
    String? thoughtSignature, {
    required bool isThought,
  }) {
    if (thoughtSignature == null && !isThought) {
      return null;
    }

    return googleProviderMetadata({
      'thoughtSignature': thoughtSignature,
      if (isThought) 'thought': true,
    });
  }

  void _attachMetadataToLastContent(
    List<ContentPart> content,
    ProviderMetadata? metadata,
  ) {
    if (metadata == null || content.isEmpty) {
      return;
    }

    final last = content.removeLast();
    switch (last) {
      case TextContentPart(:final text, :final providerMetadata):
        content.add(
          TextContentPart(
            text,
            providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
          ),
        );
      case ReasoningContentPart(:final text, :final providerMetadata):
        content.add(
          ReasoningContentPart(
            text,
            providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
          ),
        );
      case ToolCallContentPart(:final toolCall, :final providerMetadata):
        content.add(
          ToolCallContentPart(
            toolCall,
            providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
          ),
        );
      case FileContentPart(:final file, :final providerMetadata):
        content.add(
          FileContentPart(
            file,
            providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
          ),
        );
      case CustomContentPart(
          :final kind,
          :final data,
          :final providerMetadata,
        ):
        content.add(
          CustomContentPart(
            kind: kind,
            data: data,
            providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
          ),
        );
      default:
        content.add(last);
    }
  }

  bool _isCodeExecutionError(Map<String, Object?>? result) {
    final outcome = asString(result?['outcome'])?.toLowerCase();
    if (outcome == null) {
      return false;
    }

    return outcome.contains('error') || outcome.contains('fail');
  }
}

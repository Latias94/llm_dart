import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_function_response_replay.dart';
import 'google_language_model_policy.dart';
import 'google_prompt_limitations.dart';
import 'google_prompt_replay_metadata.dart';

final class GoogleToolPromptProjection {
  const GoogleToolPromptProjection();

  Map<String, Object?>? encodePart(
    PromptPart part, {
    required GoogleLanguageModelPolicy policy,
  }) {
    if (part is ToolApprovalResponsePromptPart) {
      return null;
    }

    if (part is ToolResultPromptPart) {
      final providerMetadata = googlePromptPartProviderMetadata(part);
      final functionCallId = googleFunctionCallId(
        providerMetadata,
        part.toolOutput.providerMetadata,
      );
      final replay = GoogleFunctionResponseReplay.fromToolOutput(
        toolCallId: part.toolCallId,
        toolName: part.toolName,
        toolOutput: part.toolOutput,
        functionCallId: functionCallId,
        providerMetadata: providerMetadata,
      );
      final functionResponse = replay.toFunctionResponseJson();
      if (shouldReplayGoogleFunctionCallId(policy, functionCallId) &&
          !functionResponse.containsKey('id')) {
        functionResponse['id'] = functionCallId;
      }

      return {
        'functionResponse': {
          ...functionResponse,
        },
      };
    }

    if (part is CustomPromptPart) {
      if (part.kind == GoogleFunctionResponseReplay.kind) {
        final providerMetadata = googlePromptPartProviderMetadata(part);
        final replay = GoogleFunctionResponseReplay.parseData(
          part.data,
          providerMetadata: providerMetadata,
        );
        final functionResponse = replay.toFunctionResponseJson();
        final functionCallId =
            replay.functionCallId ?? googleFunctionCallId(providerMetadata);
        if (shouldReplayGoogleFunctionCallId(policy, functionCallId) &&
            !functionResponse.containsKey('id')) {
          functionResponse['id'] = functionCallId;
        }

        return {
          'functionResponse': functionResponse,
        };
      }
    }

    throw unsupportedGooglePromptPart(
      role: 'tool',
      part: part,
    );
  }
}

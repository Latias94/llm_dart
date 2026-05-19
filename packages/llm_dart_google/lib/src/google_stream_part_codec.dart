import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_provider_metadata_support.dart';
import 'google_shared.dart';
import 'google_stream_block_projection.dart';
import 'google_stream_non_text_part_projection.dart';
import 'google_stream_state.dart';

final class GoogleStreamPartCodec {
  const GoogleStreamPartCodec();

  Iterable<LanguageModelStreamEvent> decodePart(
    Map<String, Object?> part,
    GoogleGenerateContentStreamState state,
  ) sync* {
    final metadata = googleThoughtSignatureMetadata(
      asString(part['thoughtSignature']),
      isThought: part['thought'] == true,
    );

    if (part case {'executableCode': final Object? executableCode}) {
      yield* decodeGoogleStreamExecutableCodePart(
        executableCode,
        state,
        metadata,
      );
      return;
    }

    if (part case {'codeExecutionResult': final Object? executionResult}) {
      yield* decodeGoogleStreamCodeExecutionResultPart(
        executionResult,
        state,
        metadata,
      );
      return;
    }

    if (part case {'functionCall': final Object? functionCallValue}) {
      yield* decodeGoogleStreamFunctionCallPart(
        functionCallValue,
        state,
        metadata,
      );
      return;
    }

    if (part case {'toolCall': final Object? toolCallValue}) {
      yield* decodeGoogleStreamServerToolCallPart(
        toolCallValue,
        state,
        metadata,
      );
      return;
    }

    if (part case {'toolResponse': final Object? toolResponseValue}) {
      yield* decodeGoogleStreamServerToolResponsePart(
        toolResponseValue,
        state,
        metadata,
      );
      return;
    }

    if (part case {'text': final Object? textValue}) {
      yield* decodeGoogleStreamTextPart(
        part,
        textValue: textValue,
        metadata: metadata,
        state: state,
      );
      return;
    }

    if (part case {'inlineData': final Object? inlineDataValue}) {
      yield* decodeGoogleStreamInlineDataPart(
        part,
        inlineDataValue,
        state,
        metadata,
      );
    }
  }
}

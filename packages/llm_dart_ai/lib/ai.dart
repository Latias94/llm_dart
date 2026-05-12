/// Framework-neutral AI runtime helpers.
///
/// This entrypoint is intentionally built on provider contracts only. It owns
/// orchestration helpers, multi-step runners, result accumulation, and
/// structured output utilities without importing transport, chat, Flutter, or
/// concrete provider implementations.
library;

export 'package:llm_dart_provider/llm_dart_provider.dart';

export 'src/model/embed.dart';
export 'src/model/generate_image.dart';
export 'src/model/generate_speech.dart';
export 'src/model/generate_text_result_accumulator.dart';
export 'src/model/generate_text_run_result.dart';
export 'src/model/generate_text_runner.dart';
export 'src/model/generate_text_runner_support.dart'
    show
        GenerateTextFunctionToolExecutionRequest,
        GenerateTextFunctionToolExecutor,
        GenerateTextOnError,
        GenerateTextOnFinish,
        GenerateTextOnStepFinish,
        GenerateTextOnStepStart,
        GenerateTextRunnerSupport,
        GenerateTextToolExecutionResult,
        StreamTextOnChunk;
export 'src/model/generate_text_step_result.dart';
export 'src/model/generate_text_step_start_event.dart';
export 'src/model/language_model.dart' show generateText, streamText;
export 'src/model/output_spec.dart';
export 'src/model/stream_text_runner.dart';
export 'src/model/text_call.dart';
export 'src/model/transcribe.dart';
export 'src/prompt/model_message.dart';
export 'src/prompt/prompt_normalization.dart';
export 'src/serialization/chat_ui_json_codec.dart';
export 'src/ui/chat_message_mapper.dart';
export 'src/ui/chat_ui_accumulator.dart';
export 'src/ui/chat_ui_message.dart';
export 'src/ui/chat_ui_stream_accumulator.dart';
export 'src/ui/chat_ui_stream_chunk.dart';
export 'src/ui/chat_ui_stream_projection.dart';
export 'src/ui/chat_ui_stream_reader.dart';

/// Shared model specifications, capability helpers, and runner APIs.
///
/// This entrypoint is self-contained for provider implementations and
/// framework-neutral generation utilities. It also exports the foundation and
/// raw stream event contracts needed by model method signatures.
library;

export 'foundation.dart';

export 'src/model/embed.dart';
export 'src/model/embedding_model.dart';
export 'src/model/generate_image.dart';
export 'src/model/generate_speech.dart';
export 'src/model/generate_text_result_accumulator.dart';
export 'src/model/generate_text_run_result.dart';
export 'src/model/generate_text_runner.dart';
export 'src/model/generate_text_runner_support.dart'
    show
        GenerateTextFunctionToolExecutionRequest,
        GenerateTextFunctionToolExecutor,
        GenerateTextOnFinish,
        GenerateTextOnStepFinish,
        GenerateTextOnStepStart,
        GenerateTextToolExecutionResult;
export 'src/model/generate_text_step_result.dart';
export 'src/model/generate_text_step_start_event.dart';
export 'src/model/image_model.dart';
export 'src/model/language_model.dart';
export 'src/model/model_capability_profile.dart';
export 'src/model/model_response_metadata.dart';
export 'src/model/output_spec.dart';
export 'src/model/response_format.dart';
export 'src/model/speech_model.dart';
export 'src/model/stream_text_runner.dart';
export 'src/model/text_call.dart';
export 'src/model/transcribe.dart';
export 'src/model/transcription_model.dart';
export 'src/stream/text_stream_event.dart';

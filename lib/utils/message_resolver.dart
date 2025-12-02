@Deprecated(
  'Message resolver utilities have moved to llm_dart_core. '
  'Use resolveMessagesForTextGeneration / resolvePromptMessagesForTextGeneration '
  'from package:llm_dart_core/llm_dart_core.dart instead. '
  'This shim will be removed in a future release.',
)
library;

export 'package:llm_dart_core/llm_dart_core.dart'
    show
        resolveMessagesForTextGeneration,
        resolvePromptMessagesForTextGeneration;

@Deprecated(
  'Capability utilities have moved to llm_dart_core. '
  'Import CapabilityUtils / CapabilityError / CapabilityValidationReport from '
  'package:llm_dart_core/llm_dart_core.dart instead. '
  'This shim will be removed in a future release.',
)
library;

export 'package:llm_dart_core/llm_dart_core.dart'
    show CapabilityUtils, CapabilityError, CapabilityValidationReport;

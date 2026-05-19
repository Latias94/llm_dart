import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_language_model_policy.dart';
import 'google_tools.dart';

List<Object?> projectGoogleNativeTools({
  required GoogleLanguageModelPolicy policy,
  required List<GoogleNativeTool> tools,
  required List<ModelWarning> warnings,
}) {
  if (tools.isEmpty) {
    return const [];
  }

  final encoded = <Object?>[];

  for (final tool in tools) {
    if (!policy.supportsNativeTools) {
      warnings.add(
        ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'tools',
          message:
              'Google native tool "${tool.name}" requires Gemini 2.0 or newer compatible models.',
        ),
      );
      continue;
    }

    encoded.add(tool.toJson());
  }

  return encoded;
}

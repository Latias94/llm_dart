import 'openai_moderation_options.dart';

Map<String, Object?> buildOpenAIModerationRequestBody({
  required Object input,
  required String? model,
  required OpenAIModerationSettings settings,
}) {
  final resolvedModel = resolveOpenAIModerationModel(model, settings);
  return {
    'input': normalizeOpenAIModerationInput(input),
    if (resolvedModel != null) 'model': resolvedModel,
  };
}

String? resolveOpenAIModerationModel(
  String? model,
  OpenAIModerationSettings settings,
) {
  if (model != null) {
    return model;
  }

  return settings.defaultModel;
}

Object normalizeOpenAIModerationInput(Object input) {
  if (input is String) {
    return input;
  }

  if (input is List<String>) {
    return List<String>.unmodifiable(input);
  }

  if (input is List) {
    return List<String>.generate(
      input.length,
      (index) {
        final value = input[index];
        if (value is! String) {
          throw ArgumentError.value(
            input,
            'input',
            'Expected moderation input to be a String or List<String>.',
          );
        }
        return value;
      },
      growable: false,
    );
  }

  throw ArgumentError.value(
    input,
    'input',
    'Expected moderation input to be a String or List<String>.',
  );
}

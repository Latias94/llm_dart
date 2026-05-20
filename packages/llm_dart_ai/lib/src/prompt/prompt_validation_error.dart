void requireNonEmptyPromptField(
  String value,
  String fieldName, {
  required String context,
  required int messageIndex,
  required int partIndex,
}) {
  if (value.isNotEmpty) {
    return;
  }

  throwPromptValidationError(
    context: context,
    messageIndex: messageIndex,
    partIndex: partIndex,
    message: '$fieldName must not be empty.',
  );
}

void requireMatchingPromptToolName({
  required String expected,
  required String actual,
  required String context,
  required int messageIndex,
  required int partIndex,
}) {
  if (expected == actual) {
    return;
  }

  throwPromptValidationError(
    context: context,
    messageIndex: messageIndex,
    partIndex: partIndex,
    message: 'tool name "$actual" does not match expected tool "$expected".',
  );
}

Never throwPromptValidationError({
  required String context,
  required int messageIndex,
  required int? partIndex,
  required String message,
}) {
  throw ArgumentError(
    '${promptValidationPath(
      context: context,
      messageIndex: messageIndex,
      partIndex: partIndex,
    )} is invalid: $message',
  );
}

String promptValidationPath({
  required String context,
  required int messageIndex,
  required int? partIndex,
}) {
  return partIndex == null
      ? '$context[$messageIndex]'
      : '$context[$messageIndex].parts[$partIndex]';
}

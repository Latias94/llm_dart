final class ModelReference {
  static final RegExp _providerIdPattern = RegExp(
    r'^[a-z0-9]+(?:[._-][a-z0-9]+)*$',
  );

  final String providerId;
  final String modelId;

  const ModelReference({
    required this.providerId,
    required this.modelId,
  });

  factory ModelReference.parse(
    String reference, {
    String parameterName = 'reference',
  }) {
    final trimmed = reference.trim();
    final separator = trimmed.indexOf(':');

    if (separator <= 0 || separator == trimmed.length - 1) {
      throw ArgumentError.value(
        reference,
        parameterName,
        'Expected model reference in "provider:modelId" form.',
      );
    }

    final providerId = trimmed.substring(0, separator).trim();
    final modelId = trimmed.substring(separator + 1).trim();

    validateProviderId(providerId, parameterName: parameterName);

    if (modelId.isEmpty) {
      throw ArgumentError.value(
        reference,
        parameterName,
        'Expected non-empty model ID in "provider:modelId" form.',
      );
    }

    return ModelReference(providerId: providerId, modelId: modelId);
  }

  static void validateProviderId(
    String providerId, {
    required String parameterName,
  }) {
    if (_providerIdPattern.hasMatch(providerId)) {
      return;
    }

    throw ArgumentError.value(
      providerId,
      parameterName,
      'Expected a lowercase provider ID such as "openai" or "anthropic".',
    );
  }
}

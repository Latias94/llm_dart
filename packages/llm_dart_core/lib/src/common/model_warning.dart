enum ModelWarningType {
  unsupported,
  compatibility,
  other,
}

final class ModelWarning {
  final ModelWarningType type;
  final String message;
  final String? field;

  const ModelWarning({
    required this.type,
    required this.message,
    this.field,
  });
}

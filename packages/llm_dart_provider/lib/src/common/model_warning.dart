enum ModelWarningType {
  unsupported,
  compatibility,
  deprecated,
  other,
}

final class ModelWarning {
  final ModelWarningType type;
  final String message;

  /// Stable shared feature name for unsupported or compatibility warnings.
  final String? feature;

  /// Stable setting or option name for deprecated warnings.
  final String? setting;

  /// Legacy warning target alias.
  ///
  /// New provider code should prefer [feature] or [setting]. This field remains
  /// available for older callers and serialized payloads.
  final String? field;

  const ModelWarning({
    required this.type,
    required this.message,
    String? feature,
    String? setting,
    String? field,
  })  : feature = feature ??
            (type == ModelWarningType.unsupported ||
                    type == ModelWarningType.compatibility
                ? field
                : null),
        setting =
            setting ?? (type == ModelWarningType.deprecated ? field : null),
        field = field ?? feature ?? setting;

  @override
  bool operator ==(Object other) {
    return other is ModelWarning &&
        other.type == type &&
        other.message == message &&
        other._featureTarget == _featureTarget &&
        other._settingTarget == _settingTarget;
  }

  @override
  int get hashCode => Object.hash(
        type,
        message,
        _featureTarget,
        _settingTarget,
      );

  @override
  String toString() {
    return 'ModelWarning('
        'type: $type, '
        'message: $message, '
        'feature: $feature, '
        'setting: $setting, '
        'field: $field'
        ')';
  }

  String? get _featureTarget => feature ?? field;

  String? get _settingTarget => setting ?? field;
}

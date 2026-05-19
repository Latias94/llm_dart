Map<String, Object?> projectOpenAIResponsesShellOutputEntry(
  Object? value,
) {
  final entry = _asMap(value) ?? const <String, Object?>{};
  return {
    'stdout': entry['stdout'],
    'stderr': entry['stderr'],
    'outcome': _projectUnifiedShellOutcome(_asMap(entry['outcome'])),
  };
}

Map<String, Object?> projectOpenAIResponsesShellReplayOutputEntry(
  Object? value,
) {
  final entry = _asMap(value) ?? const <String, Object?>{};
  return {
    'stdout': entry['stdout'],
    'stderr': entry['stderr'],
    'outcome': _projectNativeShellOutcome(_asMap(entry['outcome'])),
  };
}

Map<String, Object?>? _projectUnifiedShellOutcome(
  Map<String, Object?>? outcome,
) {
  final type = _asString(outcome?['type']);
  if (type == 'timeout') {
    return const {'type': 'timeout'};
  }

  if (type == 'exit') {
    return {
      'type': 'exit',
      'exitCode': outcome?['exit_code'] ?? outcome?['exitCode'],
    };
  }

  return outcome;
}

Map<String, Object?>? _projectNativeShellOutcome(
  Map<String, Object?>? outcome,
) {
  final type = _asString(outcome?['type']);
  if (type == 'timeout') {
    return const {'type': 'timeout'};
  }

  if (type == 'exit') {
    return {
      'type': 'exit',
      'exit_code': outcome?['exitCode'] ?? outcome?['exit_code'],
    };
  }

  return outcome;
}

Map<String, Object?>? _asMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return null;
}

String? _asString(Object? value) => value is String ? value : null;

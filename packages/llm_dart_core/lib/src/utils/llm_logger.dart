/// Lightweight, dependency-free logging abstraction for llm_dart.
///
/// Provider packages should use this interface instead of depending on
/// `package:logging` directly. Callers can inject an implementation via
/// `LLMConfig.extensions[LLMConfigKeys.logger]`.
library;

abstract interface class LLMLogger {
  void info(String message);
  void fine(String message);
  void finer(String message);
  void warning(String message);
  void severe(String message, [Object? error, StackTrace? stackTrace]);
}

/// A simple stdout logger implementation that does not require any
/// external dependencies.
///
/// This is primarily meant as a default logger when users enable HTTP logging
/// but did not provide a custom logger implementation.
class ConsoleLLMLogger implements LLMLogger {
  final String name;
  final bool includeTimestamp;
  final bool includeFine;
  final bool includeFiner;

  const ConsoleLLMLogger({
    this.name = 'llm_dart',
    this.includeTimestamp = false,
    this.includeFine = true,
    this.includeFiner = true,
  });

  void _print(String level, String message) {
    final time = includeTimestamp ? '${DateTime.now().toIso8601String()} ' : '';
    print('$time$level $name: $message');
  }

  @override
  void info(String message) => _print('INFO', message);

  @override
  void fine(String message) {
    if (!includeFine) return;
    _print('FINE', message);
  }

  @override
  void finer(String message) {
    if (!includeFiner) return;
    _print('FINER', message);
  }

  @override
  void warning(String message) => _print('WARN', message);

  @override
  void severe(String message, [Object? error, StackTrace? stackTrace]) {
    _print('ERROR', message);
    if (error != null) {
      print('error: $error');
    }
    if (stackTrace != null) {
      print(stackTrace);
    }
  }
}

/// A no-op logger used when no logger is configured.
class NoopLLMLogger implements LLMLogger {
  const NoopLLMLogger();

  @override
  void fine(String message) {}

  @override
  void finer(String message) {}

  @override
  void info(String message) {}

  @override
  void severe(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void warning(String message) {}
}

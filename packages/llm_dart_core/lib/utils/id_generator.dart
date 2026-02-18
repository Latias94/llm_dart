import 'dart:math';

import '../core/llm_error.dart';

/// A function that generates an ID.
///
/// Mirrors the AI SDK `IdGenerator` type.
typedef IdGenerator = String Function();

/// Creates an ID generator.
///
/// The total length of the ID is the sum of:
/// - [prefix] (optional)
/// - [separator]
/// - random part length ([size])
///
/// Not cryptographically secure.
IdGenerator createIdGenerator({
  String? prefix,
  String separator = '-',
  int size = 16,
  String alphabet =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',
}) {
  if (size <= 0) {
    throw InvalidArgumentError(
      argument: 'size',
      value: size,
      message: 'size must be > 0.',
    );
  }

  if (alphabet.isEmpty) {
    throw const InvalidArgumentError(
      argument: 'alphabet',
      message: 'alphabet must not be empty.',
    );
  }

  // Guard rail from the upstream AI SDK:
  // if the separator is part of the alphabet, prefix checking can fail randomly.
  if (alphabet.contains(separator)) {
    throw InvalidArgumentError(
      argument: 'separator',
      value: separator,
      message:
          'The separator must not be part of the alphabet (to avoid ambiguous ids).',
    );
  }

  final random = Random();

  String generateRandomPart() {
    final buffer = StringBuffer();
    for (var i = 0; i < size; i++) {
      buffer.write(alphabet[random.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }

  final p = prefix?.trim();
  if (p == null || p.isEmpty) {
    return generateRandomPart;
  }

  return () => '$p$separator${generateRandomPart()}';
}

/// Generates a 16-character random string to use for IDs.
///
/// Not cryptographically secure.
final IdGenerator generateId = createIdGenerator();

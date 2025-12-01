library;

import 'dart:convert';

import '../core/llm_error.dart';
import '../models/tool_models.dart';

/// Parse structured JSON output for a given [StructuredOutputFormat].
///
/// This helper centralizes the logic used by both high-level helpers
/// (such as `generateObject` / `streamObject`) and agents when working
/// with structured outputs:
///
/// - Attempts to parse the raw text as JSON directly.
/// - Falls back to extracting JSON from ```json fenced code blocks.
/// - As a last resort, extracts the first balanced JSON object from
///   mixed text.
/// - Ensures the top-level value is a JSON object.
/// - Optionally validates the object against the schema attached to
///   [format], raising [StructuredOutputError] on mismatch.
///
/// Throws:
/// - [ResponseFormatError] if JSON cannot be parsed or the top-level
///   value is not an object.
/// - [StructuredOutputError] if the JSON object does not conform to
///   the provided schema.
Map<String, dynamic> parseStructuredObjectJson(
  String rawText,
  StructuredOutputFormat format,
) {
  final json = _parseStructuredJsonObject(rawText);

  final schema = format.schema;
  if (schema != null) {
    final errors = <String>[];
    _validateJsonAgainstSchema(json, schema, r'$', errors);
    if (errors.isNotEmpty) {
      throw StructuredOutputError(
        'Structured output does not match schema: ${errors.join('; ')}',
        schemaName: format.name,
        schema: schema,
        actualOutput: rawText,
      );
    }
  }

  return json;
}

/// Try to parse a JSON object out of [rawText] using several strategies.
///
/// This mirrors the behavior used by the streaming structured output
/// helper in the main `llm_dart` package.
Map<String, dynamic> _parseStructuredJsonObject(String rawText) {
  Map<String, dynamic>? tryParse(String input) {
    try {
      final decoded = jsonDecode(input);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Ignore and try next strategy.
    }
    return null;
  }

  // 1) Direct parse
  final direct = tryParse(rawText);
  if (direct != null) return direct;

  // 2) Parse from fenced code block ```json ... ```
  final fenceMatch =
      RegExp(r'```(?:json)?\s*(.*?)\s*```', dotAll: true).firstMatch(rawText);
  if (fenceMatch != null) {
    final candidate = fenceMatch.group(1);
    if (candidate != null) {
      final parsed = tryParse(candidate);
      if (parsed != null) return parsed;
    }
  }

  // 3) Extract first balanced JSON object from the text
  final start = rawText.indexOf('{');
  if (start != -1) {
    var depth = 0;
    for (var i = start; i < rawText.length; i++) {
      final ch = rawText[i];
      if (ch == '{') depth++;
      if (ch == '}') {
        depth--;
        if (depth == 0) {
          final candidate = rawText.substring(start, i + 1);
          final parsed = tryParse(candidate);
          if (parsed != null) return parsed;
          break;
        }
      }
    }
  }

  throw ResponseFormatError(
    'Failed to parse structured JSON output',
    rawText,
  );
}

/// Validate [value] against a JSON-schema-like [schema] definition.
///
/// This is intentionally minimal and aligned with the subset of schema
/// used by [OutputSpec] / [StructuredOutputFormat].
void _validateJsonAgainstSchema(
  dynamic value,
  Map<String, dynamic> schema,
  String path,
  List<String> errors,
) {
  final type = schema['type'];

  switch (type) {
    case 'string':
      if (value is! String) {
        errors.add('Expected string at $path, got ${value.runtimeType}');
      }
      break;
    case 'number':
      if (value is! num) {
        errors.add('Expected number at $path, got ${value.runtimeType}');
      }
      break;
    case 'integer':
      if (value is! int) {
        errors.add('Expected integer at $path, got ${value.runtimeType}');
      }
      break;
    case 'boolean':
      if (value is! bool) {
        errors.add('Expected boolean at $path, got ${value.runtimeType}');
      }
      break;
    case 'array':
      if (value is! List) {
        errors.add('Expected array at $path, got ${value.runtimeType}');
        break;
      }
      final itemSchema = schema['items'];
      if (itemSchema is Map<String, dynamic>) {
        for (var i = 0; i < value.length; i++) {
          _validateJsonAgainstSchema(
            value[i],
            itemSchema,
            '$path[$i]',
            errors,
          );
        }
      }
      break;
    case 'object':
      if (value is! Map) {
        errors.add('Expected object at $path, got ${value.runtimeType}');
        break;
      }

      final mapValue = value is Map<String, dynamic>
          ? value
          : Map<String, dynamic>.from(value);

      final requiredProps =
          (schema['required'] as List<dynamic>? ?? const <dynamic>[])
              .cast<String>();
      for (final prop in requiredProps) {
        if (!mapValue.containsKey(prop)) {
          errors.add('Missing required property "$prop" at $path');
        }
      }

      final propertiesRaw = schema['properties'];
      if (propertiesRaw is Map) {
        final properties = propertiesRaw.cast<String, dynamic>();
        for (final entry in properties.entries) {
          final propName = entry.key;
          final propSchema = entry.value;
          if (propSchema is! Map<String, dynamic>) continue;
          if (!mapValue.containsKey(propName)) continue;
          _validateJsonAgainstSchema(
            mapValue[propName],
            propSchema,
            '$path.$propName',
            errors,
          );
        }
      }
      break;
    default:
      break;
  }
}

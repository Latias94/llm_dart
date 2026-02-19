import 'dart:async';

import '../models/tool_models.dart';

/// A validation result for schema validation.
sealed class ValidationResult<T> {
  const ValidationResult();

  bool get success;
}

final class ValidationSuccess<T> extends ValidationResult<T> {
  final T value;

  const ValidationSuccess(this.value);

  @override
  bool get success => true;
}

final class ValidationFailure<T> extends ValidationResult<T> {
  final Object error;

  const ValidationFailure(this.error);

  @override
  bool get success => false;
}

typedef SchemaValidate<T> = FutureOr<ValidationResult<T>> Function(Object? value);

/// A lightweight schema wrapper inspired by Vercel AI SDK `Schema`.
///
/// Notes:
/// - This intentionally stays Dart-native and does not depend on external
///   validation libraries.
/// - JSON Schema is represented as a JSON-like map ([JsonSchema]).
/// - [validate] is optional. When present, it can provide stronger validation
///   than best-effort JSON Schema checks.
final class FlexibleSchema<T> {
  final JsonSchema Function() _jsonSchema;
  final SchemaValidate<T>? _validate;

  FlexibleSchema._(this._jsonSchema, this._validate);

  /// Create a schema from a JSON schema map.
  factory FlexibleSchema.jsonSchema(
    JsonSchema jsonSchema, {
    SchemaValidate<T>? validate,
  }) {
    return FlexibleSchema._(() => jsonSchema, validate);
  }

  /// Create a schema with deferred construction.
  ///
  /// This mirrors the AI SDK `lazySchema(...)` utility.
  factory FlexibleSchema.lazy(FlexibleSchema<T> Function() create) {
    FlexibleSchema<T>? cached;
    return FlexibleSchema._(
      () {
        cached ??= create();
        return cached!.jsonSchema;
      },
      (value) async {
        cached ??= create();
        final validate = cached!._validate;
        if (validate == null) {
          return ValidationFailure<T>(
            StateError('No validator available for this schema.'),
          );
        }
        return await Future.value(validate(value));
      },
    );
  }

  JsonSchema get jsonSchema => _jsonSchema();

  SchemaValidate<T>? get validate => _validate;
}

/// Create a [FlexibleSchema] from a JSON Schema map.
FlexibleSchema<T> jsonSchema<T>(
  JsonSchema schema, {
  SchemaValidate<T>? validate,
}) =>
    FlexibleSchema<T>.jsonSchema(schema, validate: validate);

/// Create a schema with deferred construction.
FlexibleSchema<T> lazySchema<T>(FlexibleSchema<T> Function() create) =>
    FlexibleSchema<T>.lazy(create);

/// Normalize a schema-like value into a [FlexibleSchema].
///
/// Supported inputs:
/// - `null` -> empty object schema with `additionalProperties: false`
/// - [FlexibleSchema]
/// - [JsonSchema] / [Map]
FlexibleSchema<T> asSchema<T>(Object? schema) {
  if (schema == null) {
    return FlexibleSchema<T>.jsonSchema(<String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{},
      'additionalProperties': false,
    });
  }

  if (schema is FlexibleSchema<T>) return schema;

  if (schema is FlexibleSchema) {
    return schema as FlexibleSchema<T>;
  }

  if (schema is Map<String, dynamic>) {
    return FlexibleSchema<T>.jsonSchema(schema);
  }

  if (schema is Map) {
    return FlexibleSchema<T>.jsonSchema(
      Map<String, dynamic>.from(schema),
    );
  }

  throw ArgumentError.value(
    schema,
    'schema',
    'Unsupported schema type. Expected Map or FlexibleSchema.',
  );
}

/// Recursively adds `additionalProperties: false` to JSON schemas that
/// represent objects.
///
/// This mirrors upstream `addAdditionalPropertiesToJsonSchema(...)`.
JsonSchema addAdditionalPropertiesToJsonSchema(JsonSchema jsonSchema) {
  JsonSchema visit(JsonSchema schema) {
    final out = Map<String, dynamic>.from(schema);

    final schemaType = out['type'];
    final isObjectType = schemaType == 'object' ||
        (schemaType is List && schemaType.contains('object'));

    if (isObjectType) {
      out['additionalProperties'] = false;

      final props = out['properties'];
      if (props is Map) {
        final newProps = <String, dynamic>{};
        for (final entry in props.entries) {
          final key = entry.key;
          if (key is! String) continue;
          final value = entry.value;
          if (value is Map) {
            newProps[key] = visit(Map<String, dynamic>.from(value));
          } else {
            newProps[key] = value;
          }
        }
        out['properties'] = newProps;
      }
    }

    final items = out['items'];
    if (items is Map) {
      out['items'] = visit(Map<String, dynamic>.from(items));
    } else if (items is List) {
      out['items'] = items.map((v) {
        if (v is Map) return visit(Map<String, dynamic>.from(v));
        return v;
      }).toList(growable: false);
    }

    for (final key in const ['anyOf', 'allOf', 'oneOf']) {
      final raw = out[key];
      if (raw is List) {
        out[key] = raw.map((v) {
          if (v is Map) return visit(Map<String, dynamic>.from(v));
          return v;
        }).toList(growable: false);
      }
    }

    final definitions = out['definitions'] ?? out[r'$defs'];
    if (definitions is Map) {
      final newDefs = <String, dynamic>{};
      for (final entry in definitions.entries) {
        final key = entry.key;
        if (key is! String) continue;
        final value = entry.value;
        if (value is Map) {
          newDefs[key] = visit(Map<String, dynamic>.from(value));
        } else {
          newDefs[key] = value;
        }
      }
      if (out.containsKey('definitions')) {
        out['definitions'] = newDefs;
      } else {
        out[r'$defs'] = newDefs;
      }
    }

    return out;
  }

  return visit(jsonSchema);
}


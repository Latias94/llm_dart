import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'tool_set.dart';
import 'tool_execution_options.dart';
import 'tool_types.dart';

/// Vercel AI SDK-style convenience alias for [functionTool].
///
/// This is intentionally Dart-flavored:
/// - [execute] is a [ToolCallHandler] (Future/Stream friendly),
/// - schema stays as [ParametersSchema].
LocalTool tool({
  required String name,
  required String description,
  required ParametersSchema parameters,
  required ToolCallHandler execute,
  bool? strict,
  List<Map<String, dynamic>>? inputExamples,
  ProviderOptions providerOptions = const {},
  ParameterProperty? outputSchema,
  ToolToModelOutput? toModelOutput,
  ToolApprovalCheck? needsApproval,
  ToolInputStartHandler? onInputStart,
  ToolInputDeltaHandler? onInputDelta,
  ToolInputAvailableHandler? onInputAvailable,
  ToolInputErrorHandler? onInputError,
}) {
  return functionTool(
    name: name,
    description: description,
    parameters: parameters,
    strict: strict,
    inputExamples: inputExamples,
    providerOptions: providerOptions,
    handler: execute,
    outputSchema: outputSchema,
    toModelOutput: toModelOutput,
    needsApproval: needsApproval,
    onInputStart: onInputStart,
    onInputDelta: onInputDelta,
    onInputAvailable: onInputAvailable,
    onInputError: onInputError,
  );
}

ParametersSchema _parametersFromObjectSchema(ParameterProperty inputSchema) {
  if (inputSchema.propertyType != 'object') {
    throw ArgumentError.value(
      inputSchema.propertyType,
      'inputSchema.propertyType',
      'dynamicTool inputSchema must be an object schema (propertyType="object").',
    );
  }
  return ParametersSchema(
    schemaType: 'object',
    properties: inputSchema.properties ?? const <String, ParameterProperty>{},
    required: inputSchema.required ?? const <String>[],
  );
}

/// Defines a "dynamic tool" (AI SDK-style) using an object [inputSchema].
///
/// In Vercel AI SDK, dynamic tools use a `FlexibleSchema` for input validation.
/// In llm_dart, we keep the underlying tool model ([ParametersSchema]) but
/// allow callers to define tool inputs using the same schema node type as
/// [outputSchema] ([ParameterProperty]).
///
/// Notes:
/// - [inputSchema] must be `propertyType="object"`.
/// - Local execution still receives a parsed JSON object `Map<String, dynamic>`.
/// - Schema validation is controlled by `ToolSchemas` in the tool loop.
LocalTool dynamicTool({
  required String name,
  required String description,
  required ParameterProperty inputSchema,
  required ToolCallHandler execute,
  bool? strict,
  List<Map<String, dynamic>>? inputExamples,
  ProviderOptions providerOptions = const {},
  ParameterProperty? outputSchema,
  ToolToModelOutput? toModelOutput,
  ToolApprovalCheck? needsApproval,
  ToolInputStartHandler? onInputStart,
  ToolInputDeltaHandler? onInputDelta,
  ToolInputAvailableHandler? onInputAvailable,
  ToolInputErrorHandler? onInputError,
}) {
  return tool(
    name: name,
    description: description,
    parameters: _parametersFromObjectSchema(inputSchema),
    execute: execute,
    strict: strict,
    inputExamples: inputExamples,
    providerOptions: providerOptions,
    outputSchema: outputSchema,
    toModelOutput: toModelOutput,
    needsApproval: needsApproval,
    onInputStart: onInputStart,
    onInputDelta: onInputDelta,
    onInputAvailable: onInputAvailable,
    onInputError: onInputError,
  );
}

/// Wrap a Dart-friendly positional callback into a [ToolToModelOutput].
///
/// This avoids record-style named-parameter closures at call sites.
ToolToModelOutput toModelOutput(
  FutureOr<ToolResultOutput> Function(
    String toolCallId,
    Map<String, dynamic> input,
    Object? output,
    ToolExecutionOptions options,
  ) fn,
) {
  return ({
    required toolCallId,
    required input,
    required output,
    required options,
  }) =>
      fn(toolCallId, input, output, options);
}

/// Build a `type=json` v3 tool-result output envelope from a positional callback.
ToolToModelOutput toModelJson(
  FutureOr<Object?> Function(
    String toolCallId,
    Map<String, dynamic> input,
    Object? output,
    ToolExecutionOptions options,
  ) fn,
) {
  return toModelOutput((toolCallId, input, output, options) async {
    final value = await Future.value(fn(toolCallId, input, output, options));
    return ToolResultJsonOutput(value);
  });
}

/// Build a `type=text` v3 tool-result output envelope from a positional callback.
ToolToModelOutput toModelText(
  FutureOr<String> Function(
    String toolCallId,
    Map<String, dynamic> input,
    Object? output,
    ToolExecutionOptions options,
  ) fn,
) {
  return toModelOutput((toolCallId, input, output, options) async {
    final value = await Future.value(fn(toolCallId, input, output, options));
    return ToolResultTextOutput(value);
  });
}

/// Build a `type=content` v3 tool-result output envelope from a positional callback.
ToolToModelOutput toModelContent(
  FutureOr<List<ToolResultContentItem>> Function(
    String toolCallId,
    Map<String, dynamic> input,
    Object? output,
    ToolExecutionOptions options,
  ) fn,
) {
  return toModelOutput((toolCallId, input, output, options) async {
    final value = await Future.value(fn(toolCallId, input, output, options));
    return ToolResultContentOutput(value);
  });
}

/// Build a `type=error-text` v3 tool-result output envelope from a positional callback.
ToolToModelOutput toModelErrorText(
  FutureOr<String> Function(
    String toolCallId,
    Map<String, dynamic> input,
    Object? output,
    ToolExecutionOptions options,
  ) fn,
) {
  return toModelOutput((toolCallId, input, output, options) async {
    final value = await Future.value(fn(toolCallId, input, output, options));
    return ToolResultErrorTextOutput(value);
  });
}

/// Build a `type=execution-denied` v3 tool-result output envelope from a positional callback.
ToolToModelOutput toModelExecutionDenied(
  FutureOr<String?> Function(
    String toolCallId,
    Map<String, dynamic> input,
    Object? output,
    ToolExecutionOptions options,
  ) fn,
) {
  return toModelOutput((toolCallId, input, output, options) async {
    final reason = await Future.value(fn(toolCallId, input, output, options));
    return ToolResultExecutionDeniedOutput(
      reason:
          (reason != null && reason.trim().isNotEmpty) ? reason.trim() : null,
    );
  });
}

/// Output-only variant of [toModelOutput].
///
/// This is useful when callers only care about the tool handler output.
ToolToModelOutput toModelOutputFromOutput(
  FutureOr<ToolResultOutput> Function(Object? output) fn,
) {
  return toModelOutput((toolCallId, input, output, options) => fn(output));
}

/// Output-only variant of [toModelJson].
ToolToModelOutput toModelJsonValue(
  FutureOr<Object?> Function(Object? output) fn,
) {
  return toModelJson((toolCallId, input, output, options) => fn(output));
}

/// Output-only variant of [toModelText].
ToolToModelOutput toModelTextValue(
  FutureOr<String> Function(Object? output) fn,
) {
  return toModelText((toolCallId, input, output, options) => fn(output));
}

/// Output-only variant of [toModelContent].
ToolToModelOutput toModelContentValue(
  FutureOr<List<ToolResultContentItem>> Function(Object? output) fn,
) {
  return toModelContent((toolCallId, input, output, options) => fn(output));
}

/// Output-only variant of [toModelErrorText].
ToolToModelOutput toModelErrorTextValue(
  FutureOr<String> Function(Object? output) fn,
) {
  return toModelErrorText((toolCallId, input, output, options) => fn(output));
}

/// Output-only variant of [toModelExecutionDenied].
ToolToModelOutput toModelExecutionDeniedReason(
  FutureOr<String?> Function(Object? output) fn,
) {
  return toModelExecutionDenied(
      (toolCallId, input, output, options) => fn(output));
}

/// Schema-only tool (advertised to the model but not executed locally).
LocalTool schemaTool({
  required String name,
  required String description,
  required ParametersSchema parameters,
  bool? strict,
  List<Map<String, dynamic>>? inputExamples,
  ProviderOptions providerOptions = const {},
  ParameterProperty? outputSchema,
  ToolToModelOutput? toModelOutput,
  ToolApprovalCheck? needsApproval,
  ToolInputStartHandler? onInputStart,
  ToolInputDeltaHandler? onInputDelta,
  ToolInputAvailableHandler? onInputAvailable,
  ToolInputErrorHandler? onInputError,
}) {
  return schemaOnlyFunctionTool(
    name: name,
    description: description,
    parameters: parameters,
    strict: strict,
    inputExamples: inputExamples,
    providerOptions: providerOptions,
    outputSchema: outputSchema,
    toModelOutput: toModelOutput,
    needsApproval: needsApproval,
    onInputStart: onInputStart,
    onInputDelta: onInputDelta,
    onInputAvailable: onInputAvailable,
    onInputError: onInputError,
  );
}

import 'dart:async';
import 'dart:convert';

import '../common/call_options.dart';
import '../common/json_schema.dart';
import '../common/model_error.dart';
import '../common/provider_metadata.dart';
import '../common/usage_stats.dart';
import '../prompt/prompt_message.dart';
import '../tool/tool_definition.dart';
import 'language_model.dart';
import 'response_format.dart';

typedef JsonOutputDecoder<T> = T Function(Object? json);

final class StructuredOutputContext {
  final String? responseId;
  final DateTime? responseTimestamp;
  final String? responseModelId;
  final FinishReason finishReason;
  final String? rawFinishReason;
  final UsageStats? usage;
  final ProviderMetadata? providerMetadata;

  const StructuredOutputContext({
    this.responseId,
    this.responseTimestamp,
    this.responseModelId,
    required this.finishReason,
    this.rawFinishReason,
    this.usage,
    this.providerMetadata,
  });
}

abstract interface class OutputSpec<T> {
  ResponseFormat? get responseFormat;

  FutureOr<T> parse({
    required String text,
    required StructuredOutputContext context,
  });
}

final class TextOutputSpec implements OutputSpec<String> {
  const TextOutputSpec();

  @override
  ResponseFormat get responseFormat => const TextResponseFormat();

  @override
  String parse({
    required String text,
    required StructuredOutputContext context,
  }) {
    return text;
  }
}

final class JsonOutputSpec<T> implements OutputSpec<T> {
  final JsonSchema schema;
  final String? name;
  final String? description;
  final JsonOutputDecoder<T> decode;

  const JsonOutputSpec({
    required this.schema,
    required this.decode,
    this.name,
    this.description,
  });

  static JsonOutputSpec<Object?> json({
    required JsonSchema schema,
    String? name,
    String? description,
  }) {
    return JsonOutputSpec<Object?>(
      schema: schema,
      name: name,
      description: description,
      decode: (json) => json,
    );
  }

  @override
  ResponseFormat get responseFormat => JsonResponseFormat(
        schema: schema,
        name: name,
        description: description,
      );

  @override
  T parse({
    required String text,
    required StructuredOutputContext context,
  }) {
    final json = _decodeJsonText(
      text,
      context: context,
    );
    return decode(json);
  }
}

final class GenerateOutputResult<T> {
  final GenerateTextResult result;
  final T output;

  const GenerateOutputResult({
    required this.result,
    required this.output,
  });

  String get text => result.text;

  String? get reasoningText => result.reasoningText;

  FinishReason get finishReason => result.finishReason;

  String? get rawFinishReason => result.rawFinishReason;

  String? get responseId => result.responseId;

  DateTime? get responseTimestamp => result.responseTimestamp;

  String? get responseModelId => result.responseModelId;

  UsageStats? get usage => result.usage;

  ProviderMetadata? get providerMetadata => result.providerMetadata;
}

Future<GenerateOutputResult<T>> generateOutput<T>({
  required LanguageModel model,
  required List<PromptMessage> prompt,
  required OutputSpec<T> outputSpec,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
}) async {
  if (options.responseFormat != null) {
    throw ArgumentError(
      'generateOutput uses OutputSpec.responseFormat and does not allow GenerateTextOptions.responseFormat at the same time.',
    );
  }

  final result = await generateText(
    model: model,
    prompt: prompt,
    tools: tools,
    toolChoice: toolChoice,
    options: _withResponseFormat(
      options,
      outputSpec.responseFormat,
    ),
    callOptions: callOptions,
  );

  final context = StructuredOutputContext(
    responseId: result.responseId,
    responseTimestamp: result.responseTimestamp,
    responseModelId: result.responseModelId,
    finishReason: result.finishReason,
    rawFinishReason: result.rawFinishReason,
    usage: result.usage,
    providerMetadata: result.providerMetadata,
  );

  try {
    final output = await outputSpec.parse(
      text: result.text,
      context: context,
    );
    return GenerateOutputResult(
      result: result,
      output: output,
    );
  } catch (error) {
    throw ModelError.fromUnknown(
      error,
      kind: ModelErrorKind.validation,
      details: _structuredOutputErrorDetails(
        text: result.text,
        context: context,
      ),
    );
  }
}

GenerateTextOptions _withResponseFormat(
  GenerateTextOptions options,
  ResponseFormat? responseFormat,
) {
  return GenerateTextOptions(
    maxOutputTokens: options.maxOutputTokens,
    temperature: options.temperature,
    stopSequences: options.stopSequences,
    topP: options.topP,
    topK: options.topK,
    responseFormat: responseFormat,
  );
}

Object? _decodeJsonText(
  String text, {
  required StructuredOutputContext context,
}) {
  try {
    return jsonDecode(text);
  } on FormatException catch (error) {
    throw FormatException(
      'Could not parse structured output JSON: ${error.message}',
      text,
      error.offset,
    );
  }
}

Map<String, Object?> _structuredOutputErrorDetails({
  required String text,
  required StructuredOutputContext context,
}) {
  return {
    'stage': 'structured_output',
    'text': text,
    if (context.responseId != null) 'responseId': context.responseId,
    if (context.responseTimestamp != null)
      'responseTimestamp': context.responseTimestamp!.toIso8601String(),
    if (context.responseModelId != null)
      'responseModelId': context.responseModelId,
    'finishReason': context.finishReason.name,
    if (context.rawFinishReason != null)
      'rawFinishReason': context.rawFinishReason,
    if (context.usage != null) 'usage': _usageToJson(context.usage!),
    if (context.providerMetadata != null)
      'providerMetadata': context.providerMetadata!.toJsonMap(),
  };
}

Map<String, Object?> _usageToJson(UsageStats usage) {
  return {
    if (usage.inputTokens != null) 'inputTokens': usage.inputTokens,
    if (usage.outputTokens != null) 'outputTokens': usage.outputTokens,
    if (usage.totalTokens != null) 'totalTokens': usage.totalTokens,
    if (usage.reasoningTokens != null) 'reasoningTokens': usage.reasoningTokens,
  };
}

import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'middleware.dart';

typedef ToolInputExampleFormatter = String Function(
  Map<String, dynamic> example,
  int index,
);

String _defaultFormatExample(Map<String, dynamic> example, int index) {
  final value = example['input'];
  try {
    return jsonEncode(value ?? example);
  } catch (_) {
    return (value ?? example).toString();
  }
}

/// Appends tool input examples to tool descriptions.
///
/// This is useful for providers that do not support `inputExamples` natively.
/// The middleware serializes examples into the tool's description text.
///
/// This aligns with Vercel AI SDK's `addToolInputExamplesMiddleware`.
class AddToolInputExamplesMiddleware extends LanguageModelMiddleware {
  final String prefix;
  final ToolInputExampleFormatter format;
  final bool remove;

  AddToolInputExamplesMiddleware({
    this.prefix = 'Input Examples:',
    ToolInputExampleFormatter? format,
    this.remove = true,
  }) : format = format ?? _defaultFormatExample;

  @override
  Future<ChatResponse> chat(
    ChatMiddlewareContext context,
    ChatMiddlewareNext next,
  ) {
    final tools = context.tools;
    if (tools == null || tools.isEmpty) return next(context);
    return next(context.copyWith(tools: _transformTools(tools)));
  }

  @override
  Stream<LLMStreamPart> stream(
    ChatStreamMiddlewareContext context,
    ChatStreamMiddlewareNext next,
  ) {
    final tools = context.tools;
    if (tools == null || tools.isEmpty) return next(context);
    return next(context.copyWith(tools: _transformTools(tools)));
  }

  List<Tool> _transformTools(List<Tool> tools) {
    final out = <Tool>[];
    for (final tool in tools) {
      final examples = tool.inputExamples;
      if (tool.toolType != 'function' || examples == null || examples.isEmpty) {
        out.add(tool);
        continue;
      }

      final formatted = <String>[];
      for (var i = 0; i < examples.length; i++) {
        formatted.add(format(examples[i], i));
      }

      final examplesSection = '$prefix\n${formatted.join('\n')}';
      final baseDesc = tool.function.description ?? '';
      final newDesc = baseDesc.trim().isEmpty
          ? examplesSection
          : '$baseDesc\n\n$examplesSection';

      out.add(
        Tool(
          toolType: tool.toolType,
          function: FunctionTool(
            name: tool.function.name,
            description: newDesc,
            inputSchema: tool.function.inputSchema,
          ),
          strict: tool.strict,
          inputExamples: remove ? null : examples,
          providerOptions: tool.providerOptions,
        ),
      );
    }
    return List<Tool>.unmodifiable(out);
  }
}

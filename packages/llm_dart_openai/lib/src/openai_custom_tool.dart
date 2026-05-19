import 'openai_builtin_tool.dart';

enum OpenAICustomToolGrammarSyntax {
  regex('regex'),
  lark('lark');

  const OpenAICustomToolGrammarSyntax(this.value);

  final String value;
}

sealed class OpenAICustomToolFormat {
  const OpenAICustomToolFormat();

  Map<String, Object?> toJson();
}

final class OpenAICustomToolTextFormat extends OpenAICustomToolFormat {
  const OpenAICustomToolTextFormat();

  @override
  Map<String, Object?> toJson() {
    return const {
      'type': 'text',
    };
  }
}

final class OpenAICustomToolGrammarFormat extends OpenAICustomToolFormat {
  final OpenAICustomToolGrammarSyntax syntax;
  final String definition;

  const OpenAICustomToolGrammarFormat({
    required this.syntax,
    required this.definition,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'grammar',
      'syntax': syntax.value,
      'definition': definition,
    };
  }
}

final class OpenAICustomTool implements OpenAIBuiltInTool {
  final String name;
  final String? description;
  final OpenAICustomToolFormat? format;

  const OpenAICustomTool({
    required this.name,
    this.description,
    this.format,
  });

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.custom;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'custom',
      'name': name,
      if (description != null) 'description': description,
      if (format != null) 'format': format!.toJson(),
    };
  }
}

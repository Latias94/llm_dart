import 'openai_builtin_tool.dart';

sealed class OpenAICodeInterpreterContainer {
  const OpenAICodeInterpreterContainer();

  Object toJson();
}

final class OpenAICodeInterpreterAutoContainer
    extends OpenAICodeInterpreterContainer {
  final List<String>? fileIds;

  const OpenAICodeInterpreterAutoContainer({
    this.fileIds,
  });

  @override
  Object toJson() {
    return {
      'type': 'auto',
      if (fileIds != null) 'file_ids': List<String>.unmodifiable(fileIds!),
    };
  }
}

final class OpenAICodeInterpreterContainerReference
    extends OpenAICodeInterpreterContainer {
  final String containerId;

  const OpenAICodeInterpreterContainerReference(this.containerId);

  @override
  Object toJson() => containerId;
}

final class OpenAICodeInterpreterTool implements OpenAIBuiltInTool {
  final OpenAICodeInterpreterContainer? container;
  final Map<String, Object?>? parameters;

  const OpenAICodeInterpreterTool({
    this.container,
    this.parameters,
  });

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.codeInterpreter;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'code_interpreter',
      'container':
          (container ?? const OpenAICodeInterpreterAutoContainer()).toJson(),
      if (parameters != null) ...parameters!,
    };
  }
}

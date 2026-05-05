sealed class ToolOutput {
  const ToolOutput();

  Object? get value;

  bool get isError => false;

  bool get denied => false;
}

final class TextToolOutput extends ToolOutput {
  @override
  final String value;

  const TextToolOutput(this.value);
}

final class JsonToolOutput extends ToolOutput {
  @override
  final Object? value;

  const JsonToolOutput(this.value);
}

final class ErrorTextToolOutput extends ToolOutput {
  @override
  final String value;

  const ErrorTextToolOutput(this.value);

  @override
  bool get isError => true;
}

final class ErrorJsonToolOutput extends ToolOutput {
  @override
  final Object? value;

  const ErrorJsonToolOutput(this.value);

  @override
  bool get isError => true;
}

final class ExecutionDeniedToolOutput extends ToolOutput {
  final String? reason;

  const ExecutionDeniedToolOutput([this.reason]);

  @override
  String? get value => reason;

  @override
  bool get denied => true;
}

final class ContentToolOutput extends ToolOutput {
  final List<ToolOutputContentPart> parts;

  ContentToolOutput({
    required List<ToolOutputContentPart> parts,
  }) : parts = List.unmodifiable(parts);

  @override
  List<ToolOutputContentPart> get value => parts;
}

sealed class ToolOutputContentPart {
  const ToolOutputContentPart();
}

final class TextToolOutputContentPart extends ToolOutputContentPart {
  final String text;

  const TextToolOutputContentPart(this.text);
}

final class JsonToolOutputContentPart extends ToolOutputContentPart {
  final Object? value;

  const JsonToolOutputContentPart(this.value);
}

part of 'anthropic_legacy_extensions.dart';

List<Tool> _parseToolsBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final rawTools = block['tools'];
  if (rawTools is! List) {
    throw UnsupportedError(
      'Anthropic tools block at $path must contain a tools list.',
    );
  }

  final tools = <Tool>[];
  for (var index = 0; index < rawTools.length; index++) {
    final rawTool = rawTools[index];
    final toolMap = _asMap(rawTool, path: '$path.tools[$index]');
    final tool = Tool.fromJson(
      toolMap.map(
        (key, value) => MapEntry(key, _toDynamic(value)),
      ),
    );

    if (tool.toolType != 'function') {
      throw UnsupportedError(
        'Anthropic compatibility only supports function tools in legacy message extensions.',
      );
    }

    tools.add(tool);
  }

  return tools;
}

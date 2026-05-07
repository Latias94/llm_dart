part of 'request_builder.dart';

dynamic _convertAnthropicToolChoice(ToolChoice toolChoice) {
  switch (toolChoice) {
    case AutoToolChoice(disableParallelToolUse: final disableParallel):
      if (disableParallel == true) {
        return {'type': 'auto', 'disable_parallel_tool_use': true};
      }
      return 'auto';
    case AnyToolChoice(disableParallelToolUse: final disableParallel):
      if (disableParallel == true) {
        return {'type': 'any', 'disable_parallel_tool_use': true};
      }
      return 'any';
    case SpecificToolChoice(
        toolName: final toolName,
        disableParallelToolUse: final disableParallel
      ):
      final result = <String, dynamic>{'type': 'tool', 'name': toolName};
      if (disableParallel == true) {
        result['disable_parallel_tool_use'] = true;
      }
      return result;
    case NoneToolChoice():
      return 'none';
  }
}

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_code_interpreter_projection.dart';
import 'openai_responses_computer_use_projection.dart';
import 'openai_responses_custom_projection.dart';
import 'openai_responses_custom_tool_projection.dart';
import 'openai_responses_file_search_projection.dart';
import 'openai_responses_image_generation_projection.dart';
import 'openai_responses_mcp_projection.dart';
import 'openai_responses_shell_projection.dart';
import 'openai_responses_tool_search_projection.dart';
import 'openai_responses_web_search_projection.dart';

ToolCallContentPart? decodeOpenAIResponsesCustomToolCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesCustomToolCall(item);
  if (projection == null) {
    return null;
  }

  return ToolCallContentPart(
    projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolResultContentPart? decodeOpenAIResponsesCustomToolCallOutputItem(
  Map<String, Object?> item, {
  String? fallbackToolName,
}) {
  final projection = projectOpenAIResponsesCustomToolOutput(
    item,
    fallbackToolName: fallbackToolName,
  );
  if (projection == null) {
    return null;
  }

  return ToolResultContentPart(
    projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

List<ContentPart> decodeOpenAIResponsesMcpApprovalRequestOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesMcpApprovalRequest(item);
  if (projection == null) {
    return const [];
  }

  return [
    ToolCallContentPart(
      projection.toToolCall(),
      providerMetadata: projection.providerMetadata,
    ),
    ToolApprovalRequestContentPart(
      projection.toApprovalRequest(),
      providerMetadata: projection.providerMetadata,
    ),
  ];
}

List<ContentPart> decodeOpenAIResponsesMcpCallOutput(
    Map<String, Object?> item) {
  final projection = projectOpenAIResponsesMcpCall(item);
  if (projection == null) {
    return const [];
  }

  return [
    ToolCallContentPart(
      projection.toToolCall(),
      providerMetadata: projection.providerMetadata,
    ),
    ToolResultContentPart(
      projection.toToolResult(),
      providerMetadata: projection.providerMetadata,
    ),
  ];
}

List<ContentPart> decodeOpenAIResponsesCodeInterpreterCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesCodeInterpreterCall(item);
  if (projection == null) {
    return const [];
  }

  return [
    ToolCallContentPart(
      projection.toToolCall(),
      providerMetadata: projection.providerMetadata,
    ),
    ToolResultContentPart(
      projection.toToolResult(),
      providerMetadata: projection.providerMetadata,
    ),
  ];
}

List<ContentPart> decodeOpenAIResponsesImageGenerationCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesImageGenerationCall(item);
  if (projection == null) {
    return const [];
  }

  return [
    ToolCallContentPart(
      projection.toToolCall(),
      providerMetadata: projection.providerMetadata,
    ),
    ToolResultContentPart(
      projection.toToolResult(),
      providerMetadata: projection.providerMetadata,
    ),
  ];
}

List<ContentPart> decodeOpenAIResponsesFileSearchCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesFileSearchCall(item);
  if (projection == null) {
    return const [];
  }

  return [
    ToolCallContentPart(
      projection.toToolCall(),
      providerMetadata: projection.providerMetadata,
    ),
    ToolResultContentPart(
      projection.toToolResult(),
      providerMetadata: projection.providerMetadata,
    ),
  ];
}

List<ContentPart> decodeOpenAIResponsesWebSearchCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesWebSearchCall(item);
  if (projection == null) {
    return const [];
  }

  return [
    ToolCallContentPart(
      projection.toToolCall(),
      providerMetadata: projection.providerMetadata,
    ),
    ToolResultContentPart(
      projection.toToolResult(),
      providerMetadata: projection.providerMetadata,
    ),
  ];
}

List<ContentPart> decodeOpenAIResponsesComputerUseCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesComputerUseCall(item);
  if (projection == null) {
    return const [];
  }

  return [
    ToolCallContentPart(
      projection.toToolCall(),
      providerMetadata: projection.providerMetadata,
    ),
    ToolResultContentPart(
      projection.toToolResult(),
      providerMetadata: projection.providerMetadata,
    ),
  ];
}

ToolCallContentPart? decodeOpenAIResponsesToolSearchCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesToolSearchCall(item);
  if (projection == null) {
    return null;
  }

  return ToolCallContentPart(
    projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolResultContentPart? decodeOpenAIResponsesToolSearchOutput(
  Map<String, Object?> item, {
  String? fallbackToolCallId,
}) {
  final projection = projectOpenAIResponsesToolSearchOutput(
    item,
    fallbackToolCallId: fallbackToolCallId,
  );
  if (projection == null) {
    return null;
  }

  return ToolResultContentPart(
    projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolCallContentPart? decodeOpenAIResponsesLocalShellCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesLocalShellCall(item);
  if (projection == null) {
    return null;
  }

  return ToolCallContentPart(
    projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolResultContentPart? decodeOpenAIResponsesLocalShellCallOutputItem(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesLocalShellOutput(item);
  if (projection == null) {
    return null;
  }

  return ToolResultContentPart(
    projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolCallContentPart? decodeOpenAIResponsesShellCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesShellCall(item);
  if (projection == null) {
    return null;
  }

  return ToolCallContentPart(
    projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolResultContentPart? decodeOpenAIResponsesShellCallOutputItem(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesShellOutput(item);
  if (projection == null) {
    return null;
  }

  return ToolResultContentPart(
    projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolCallContentPart? decodeOpenAIResponsesApplyPatchCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesApplyPatchCall(item);
  if (projection == null) {
    return null;
  }

  return ToolCallContentPart(
    projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolResultContentPart? decodeOpenAIResponsesApplyPatchCallOutputItem(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesApplyPatchOutput(item);
  if (projection == null) {
    return null;
  }

  return ToolResultContentPart(
    projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

CustomContentPart? decodeOpenAIResponsesCustomOutput(
    Map<String, Object?> item) {
  return projectOpenAIResponsesCustomOutputItem(item)?.toContentPart();
}

/// Package-private ownership index for OpenAI Responses projection families.
///
/// This is intentionally not a runtime registry. The concrete projection
/// Modules still own dispatch, parsing, replay, and provider-native behavior.
/// The index gives maintainers one release-frozen map for where each native
/// Responses feature family lives.
const openAIResponsesProjectionFamilies = [
  OpenAIResponsesProjectionFamily(
    id: 'request-assembly',
    description:
        'Request body assembly, prompt conversion, media/file input, tools, and route context.',
    modules: [
      'packages/llm_dart_openai/lib/src/responses/openai_responses_request_codec.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_request_body_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_request_prompt_codec.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_user_part_encoder.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_request_tool_codec.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_request_tool_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_request_context.dart',
    ],
    tests: [
      'packages/llm_dart_openai/test/openai_responses_request_body_projection_test.dart',
      'packages/llm_dart_openai/test/openai_responses_prompt_projection_test.dart',
      'packages/llm_dart_openai/test/openai_responses_request_tool_projection_test.dart',
      'packages/llm_dart_openai/test/openai_responses_request_context_test.dart',
    ],
  ),
  OpenAIResponsesProjectionFamily(
    id: 'assistant-replay',
    description:
        'Assistant replay, reasoning encrypted content, compaction, tool replay, and denied tool output.',
    modules: [
      'packages/llm_dart_openai/lib/src/responses/openai_responses_assistant_replay_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_assistant_prompt_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_assistant_reasoning_replay_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_assistant_tool_replay_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_assistant_compaction_replay_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_denied_tool_replay.dart',
    ],
    tests: [
      'packages/llm_dart_openai/test/openai_responses_prompt_projection_test.dart',
    ],
  ),
  OpenAIResponsesProjectionFamily(
    id: 'stream-lifecycle',
    description:
        'Responses stream event decoding, output item lifecycle, text/reasoning deltas, and stream result projection.',
    modules: [
      'packages/llm_dart_openai/lib/src/responses/openai_responses_stream_event_codec.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_stream_state.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_stream_util.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_stream_result_codec.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_output_item_stream_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_output_item_added_stream_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_output_item_done_stream_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_text_reasoning_stream_projection.dart',
    ],
    tests: [
      'packages/llm_dart_openai/test/openai_responses_stream_codec_test.dart',
    ],
  ),
  OpenAIResponsesProjectionFamily(
    id: 'native-tools',
    description:
        'Provider-native tool projection for code interpreter, computer use, image generation, shell, and apply-patch items.',
    modules: [
      'packages/llm_dart_openai/lib/src/responses/openai_responses_code_interpreter_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_code_interpreter_stream_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_computer_use_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_computer_use_stream_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_image_generation_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_image_generation_stream_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_shell_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_shell_stream_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_apply_patch_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_apply_patch_stream_projection.dart',
    ],
    tests: [
      'packages/llm_dart_openai/test/openai_responses_codec_test.dart',
      'packages/llm_dart_openai/test/openai_responses_stream_codec_test.dart',
    ],
  ),
  OpenAIResponsesProjectionFamily(
    id: 'mcp-and-custom-tools',
    description:
        'MCP approval/call/result projection and custom tool call/input/output projection.',
    modules: [
      'packages/llm_dart_openai/lib/src/responses/openai_responses_mcp_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_mcp_stream_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_mcp_approval_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_mcp_approval_replay_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_custom_tool_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_custom_tool_stream_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_custom_tool_replay_projection.dart',
    ],
    tests: [
      'packages/llm_dart_openai/test/openai_responses_mcp_projection_test.dart',
      'packages/llm_dart_openai/test/openai_responses_custom_projection_test.dart',
    ],
  ),
  OpenAIResponsesProjectionFamily(
    id: 'sources-and-search',
    description:
        'Source annotations, web search, file search, and tool-search projection.',
    modules: [
      'packages/llm_dart_openai/lib/src/responses/openai_responses_source_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_source_annotation_stream_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_web_search_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_web_search_stream_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_file_search_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_file_search_stream_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_tool_search_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_tool_search_stream_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_tool_search_replay_projection.dart',
    ],
    tests: [
      'packages/llm_dart_openai/test/openai_responses_source_projection_test.dart',
      'packages/llm_dart_openai/test/openai_responses_stream_codec_test.dart',
    ],
  ),
  OpenAIResponsesProjectionFamily(
    id: 'result-and-metadata',
    description:
        'Final result content projection, metadata normalization, finish reason, and usage.',
    modules: [
      'packages/llm_dart_openai/lib/src/responses/openai_responses_generate_result_codec.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_result_item_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_output_content_projection.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_metadata.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_finish_support.dart',
      'packages/llm_dart_openai/lib/src/responses/openai_responses_usage_support.dart',
    ],
    tests: [
      'packages/llm_dart_openai/test/openai_responses_generate_result_codec_test.dart',
      'packages/llm_dart_openai/test/openai_responses_finish_usage_support_test.dart',
    ],
  ),
];

final class OpenAIResponsesProjectionFamily {
  final String id;
  final String description;
  final List<String> modules;
  final List<String> tests;

  const OpenAIResponsesProjectionFamily({
    required this.id,
    required this.description,
    required this.modules,
    required this.tests,
  });
}

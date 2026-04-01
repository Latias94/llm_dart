# Tool Models Decomposition

## Goal

This note records the decomposition of the shared `tool_models.dart` file
without changing the public tool-model API.

The goal was narrow:

- keep the existing tool schema and tool-choice types stable
- separate schema, selection, structured output, and execution-result concerns
- make the shared tool boundary easier to evolve without growing another model
  bus file

## 1. Why `tool_models.dart` Was Worth Doing Next

`tool_models.dart` sits closer to the unified interface boundary than some of
the other remaining legacy model files.

Before this slice it mixed:

- function-tool schema value objects
- assistant-facing function objects
- chat-tool entries
- tool-choice policy types
- structured-output schema wrapper
- tool execution result and parallel execution settings

Those all belong to the tool domain, but not to one source block.

## 2. Frozen Decomposition Rule

This slice keeps the public shared tool API stable:

- no rename of tool schema or tool-choice types
- no JSON contract changes
- no provider-specific selection logic moved into the shared model file
- no widening of the existing tool-choice model

The change is purely an internal source decomposition.

## 3. Landed Split

The main `tool_models.dart` file is now reduced to same-library part
declarations:

- `tool_models_schema.dart`
- `tool_models_tool_choice.dart`
- `tool_models_output.dart`
- `tool_models_execution.dart`

This maps to the actual shared boundaries:

- schema and tool entry models stay together
- tool-choice policy types stay separate from schema serialization
- structured-output compatibility stays isolated from tool execution results
- execution result models stop competing with request-shaping types

## 4. Why This Matters Architecturally

The tool boundary is one of the most important shared contracts in this
refactor. Keeping its internal ownership cleaner matters because:

- providers consume these types widely
- compatibility bridges rely on them heavily
- Flutter and runner layers depend on the same shared abstractions

This decomposition improves maintainability without reopening any of the
already-frozen tool-boundary decisions.

## 5. Validation

This slice was validated with:

- `dart analyze lib/models lib/core/config.dart lib/core/tool_validator.dart test/models/tool_models_test.dart test/core/config_test.dart test/core/tool_validator_test.dart test/builder/llm_builder_test.dart`
- `dart test test/models/tool_models_test.dart test/core/config_test.dart test/core/tool_validator_test.dart test/builder/llm_builder_test.dart`

## 6. Next Step

After `tool_models.dart`, the remaining larger shared or legacy model hotspots
are mostly `assistant_models.dart`, `image_models.dart`, and `file_models.dart`
plus configuration-heavy files such as `core/config.dart`.

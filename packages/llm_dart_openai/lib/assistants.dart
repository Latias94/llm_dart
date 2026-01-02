/// (Tier 3 / opt-in) OpenAI Assistants API wrapper.
///
/// This mirrors upstream OpenAI endpoints and is expected to evolve quickly.
/// Prefer the task APIs (`llm_dart_ai`) and the main provider entrypoint unless
/// you explicitly need Assistants.
library;

export 'src/assistants.dart';
export 'src/models/assistant_models.dart';

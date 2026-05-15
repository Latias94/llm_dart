# Goal

Refactor provider implementation internals into clear codec, request builder,
stream parser, replay, and native-helper boundaries, using `repo-ref/ai` as a
reference for narrow provider utilities while preserving Dart-specific provider
features and the existing model-first runtime API.

The desired end state is:

- provider packages stay independent from AI runtime, chat, Flutter, root, and
  compatibility packages
- provider-native features remain provider-owned and typed
- large codecs are split by responsibility instead of hidden behind a broad
  common base class
- repeated helpers graduate to an internal or public utility boundary only
  after at least two providers prove the same stable contract
- every slice keeps release readiness green

This goal is intentionally implementation-facing. It should improve maintainers'
ability to add provider features, fix stream/replay bugs, and review codec
changes without forcing users through another public API break.

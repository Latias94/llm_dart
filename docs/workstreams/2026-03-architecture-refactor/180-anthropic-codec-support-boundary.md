# 180 Anthropic Codec Support Boundary

## Why This Decision Exists

After the Google support-propagation rounds landed, the next obvious question
was whether Anthropic should receive a similar codec-local support extraction
for result and stream decoding.

There is real duplication between:

- `packages/llm_dart_anthropic/lib/src/anthropic_result_codec.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_stream_codec.dart`

But duplication alone is not enough reason to extract a new support module.

## What Was Reviewed

Shared or near-shared helpers currently duplicated across the two codecs include:

- usage decoding
- container decoding
- Anthropic provider-metadata shaping
- citation-source decoding
- fallback tool-result naming
- tool-result error detection
- tool-result custom-kind mapping
- execution replay-payload shaping
- generic JSON normalization
- generic JSON map/list/string/int conversion helpers

## What The Audit Shows

### 1. The repeated helpers are real, but mostly leaf-level

The duplicated functions are mostly small protocol utilities and mapping helpers.

They do not yet form a strong second-layer abstraction comparable to the Google
projection support extraction, where one shared layer clearly owned
cross-result/cross-stream projection semantics.

### 2. The dominant complexity is still stream-local, not shared

`anthropic_stream_codec.dart` still owns the harder architectural behavior:

- block lifecycle sequencing
- prepopulated tool-call emission
- partial JSON accumulation for tool inputs
- block-state transitions
- streaming finish orchestration
- stream-only malformed JSON handling

That means the stream codec is not mainly “waiting for extraction.” It is
mostly doing real stream-specific work.

### 3. A support file created now would likely become a misc bus

If we extracted all repeated helpers immediately, the result would likely be a
wide `anthropic_codec_support.dart` file containing:

- tiny JSON coercion helpers
- metadata wrappers
- citation parsers
- tool-result vocabulary maps
- a few execution replay helpers

That would improve symmetry more than ownership.

## Frozen Decision

Anthropic should **not** extract a codec-local support module right now.

The current rule becomes:

- keep `anthropic_result_codec.dart` and `anthropic_stream_codec.dart` as they
  are for now
- accept the current duplication until a concrete multi-file feature or bug-fix
  creates real parity pressure
- if extraction happens later, keep it narrow and topic-owned rather than
  creating a general codec utility bus

## What Would Justify A Later Extraction

A future Anthropic codec support slice becomes justified only if one change
needs to touch both result and stream decoding in the same subdomain, for
example:

- citation-source decoding rules
- container and provider metadata shaping
- execution or tool-result replay payload rules
- tool-result classification and fallback naming

At that point, the right move would be a narrow support file such as:

- citation and metadata support
- or tool-result replay support

not a generic “all shared codec helpers” module.

## Why This Boundary Is Better

### 1. It keeps Anthropic simpler on purpose

OpenAI needs more internal layering.
Google now benefits from selective support propagation.
Anthropic does not need to match either one mechanically.

### 2. It avoids premature misc abstraction

A broad helper file would collect unrelated leaf utilities without actually
clarifying the ownership of the hard parts.

### 3. It leaves room for a more truthful future extraction

If a later feature really pushes both codecs together in one subdomain, the
repository can then extract the right local support layer with better evidence.

## Non-Goals

This decision does not:

- claim the current Anthropic codec layout is perfect forever
- deny that duplication exists
- prevent a future narrow Anthropic codec extraction
- require Google and Anthropic to share the same internal file topology

## Conclusion

The right Anthropic move is now explicit:

- acknowledge the duplicated leaf helpers
- do not extract a codec support module yet
- wait for a real multi-file change that proves a coherent local ownership slice

So Anthropic remains intentionally simpler than OpenAI and slightly less
support-layered than Google for now.

# 25 OpenAI Compatibility Stream Facade Alignment

## Why This Note Exists

After the architecture-foundation closeout, the remaining OpenAI compatibility
streaming code no longer has a "big parser file" problem.

What remains instead is a smaller layering drift:

- `chat.dart` and `responses.dart` already delegate request shaping to request
  builders
- both already delegate incremental parsing state to dedicated stream parsers
- but both still duplicate the same stream orchestration loop in the public
  compatibility facades

That loop is not provider behavior. It is facade-level wiring:

- reset parser state
- open the transport stream
- feed chunks into the parser
- log per-chunk parse failures without killing the stream
- normalize transport-level errors into legacy compatibility errors

This is a good feature-driven extraction candidate because it clarifies the
three-layer split without reopening shared event design:

- request encoding
- stream parsing
- capability facade orchestration

## Scope

This note covers only the root compatibility OpenAI streaming facade path:

- `lib/src/compatibility/providers/openai/chat.dart`
- `lib/src/compatibility/providers/openai/responses.dart`

It does **not** reopen:

- the shared `TextStreamEvent` surface
- the provider-local incremental parser state machine in
  `stream_parsing_support.dart`
- the modern `packages/llm_dart_openai` stream codec design

## Current Problem

Both compatibility facades currently repeat nearly the same `chatStream(...)`
control flow:

1. build the request body
2. reset the parser
3. call `client.postStreamRaw(...)`
4. parse each chunk
5. yield parsed events
6. warn on chunk parse failure
7. normalize stream setup/runtime errors

The duplication is small, but it weakens the internal structure:

- facade files still carry repeated transport orchestration
- parser ownership becomes less obvious
- future behavior changes such as warning wording or stream error mapping would
  need two compatibility edits

## Decision

Extract a narrow OpenAI compatibility stream-facade helper.

The helper should own only orchestration mechanics:

- parser reset
- raw stream execution
- chunk-to-event delegation
- warning logging
- transport error normalization

The helper should **not** absorb:

- request-body building
- endpoint selection policy
- parser-local event semantics
- provider-specific response reconstruction

That keeps the intended compatibility layering:

- request builders own request encoding
- stream parsers own incremental state and completion reconstruction
- compatibility facades own public method shape and endpoint selection
- the shared helper owns repeated stream plumbing

## Why This Is Worth Doing

This extraction is valuable because it removes real mixed responsibility rather
than file size alone.

It also matches the useful reference-repository lesson:

- keep orchestration separate from codecs
- keep parser state local to the parser
- avoid widening shared contracts when a local facade helper is enough

## Acceptance Criteria

This slice is complete when:

- `chat.dart` and `responses.dart` stop duplicating the same streaming loop
- parsing behavior and emitted compatibility events remain unchanged
- request shaping still stays in request builders
- parser-local state still stays in the existing parser/support modules
- existing OpenAI compatibility streaming tests continue to pass unchanged

## Follow-Up Boundary

After this extraction, the remaining OpenAI compatibility streaming complexity
should be treated as intentionally local unless a real bug identifies a
smaller repeated sub-state.

In particular:

- do **not** widen the shared event model because of this change
- do **not** split `stream_parsing_support.dart` just for symmetry
- do **not** move new modern implementation logic back into the root package

## Bottom Line

This is a narrow structural cleanup that improves the OpenAI compatibility
facade layering without reopening architecture.

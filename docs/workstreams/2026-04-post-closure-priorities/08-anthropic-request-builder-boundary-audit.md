# 08 Anthropic Request Builder Boundary Audit

## Why This Note Exists

After the recent OpenAI compatibility-shell thinning rounds landed, one obvious
question remained:

- should `lib/src/compatibility/providers/anthropic/request_builder.dart` be
  split further for symmetry
- or is it already one honest provider-local boundary

This note answers that question before another micro-splitting round creates
more files than real ownership.

## What Was Reviewed

The current `AnthropicRequestBuilder` still owns one endpoint family:

- Anthropic compatibility `messages` request shaping
- Anthropic compatibility `messages/count_tokens` request shaping

Within that single scope, it currently handles four closely-related concerns:

1. system-message extraction and system block shaping
2. non-system message content encoding
3. tool extraction, tool conversion, and tool-choice shaping
4. optional request parameter shaping such as reasoning, metadata, container,
   and MCP servers

The file is long, but it is not mixing unrelated host responsibilities like:

- streamed event parsing
- HTTP dispatch
- response decoding
- public facade orchestration

Those responsibilities already live elsewhere.

## Short Answer

Do **not** split `AnthropicRequestBuilder` further right now.

## Why It Should Stay Intact

### 1. It is a codec, not a facade bus

The dominant job of the file is still request encoding for one provider and one
API family.

That is a real boundary.

The recent OpenAI refactors were justified because those files mixed facade,
request shaping, streaming state, response parsing, and transport helpers in
the same host.

This Anthropic file does not have that problem anymore.

### 2. The subsections evolve together more than they evolve apart

The apparent subdomains are not actually independent enough yet:

- cache-control markers affect both system content and tool extraction
- message replay shape affects tool-use and tool-result encoding
- Anthropic-native tool policy affects both tool conversion and request-body
  assembly
- reasoning or metadata changes still belong to the same request payload

That means future changes are still likely to touch several of these sections
in one pass.

Splitting now would reduce line count more than it would reduce drift risk.

### 3. A split would likely create misc support files

The most likely extraction candidates today would be:

- tool conversion support
- optional-parameter support
- message/system extraction support

But none of those currently has a second real owner.

They would mostly become small Anthropic-only helper files that exist for
symmetry, not because they represent a new stable layer.

### 4. `repo-ref/ai` teaches ownership, not file-count mimicry

The structural lesson we should keep borrowing from the reference repository is
clear ownership:

- request shaping stays with request shaping
- streaming state stays with streaming state
- facade code stays thin

That lesson is already satisfied here.

Copying the reference repository's appetite for smaller internal files would be
counterproductive if it turns one coherent codec into scattered helpers.

## Honest Cleanup Landed With This Audit

This audit still justified two small honesty improvements in the file:

- the unused `ProcessedMessages.systemCacheControl` field was removed
- tool conversion is now private to the builder again through `_convertTool(...)`

These changes reduce misleading surface area without changing the public
compatibility API.

## Reopen Threshold

This file should only be split later if one of these becomes true:

### 1. Tool policy becomes its own moving target

Reopen the split if Anthropic compatibility starts growing a broader
provider-owned native-tool selection or declaration policy that changes faster
than the rest of request encoding.

### 2. Another Anthropic compatibility path needs the same tool or message logic

If a second Anthropic-owned compatibility endpoint begins sharing the same
message or tool shaping rules, a narrow support file may become justified.

### 3. Token-count shaping diverges materially from main message requests

If `messages/count_tokens` starts requiring materially different encoding rules,
it may deserve a dedicated request-body helper.

## What The Next Better Target Is

The next worthwhile structural step is **not** more Anthropic micro-splitting.

The better target is to keep auditing for the remaining files that still mix:

- compatibility-shell orchestration
- streaming state
- response parsing
- or cross-provider helper ownership

Those are still higher-value refactor candidates than a cohesive Anthropic
request codec.

## Bottom Line

`AnthropicRequestBuilder` is currently **long but honest**.

That means:

- keep it as one provider-local request codec
- avoid symmetry-driven helper extraction
- reopen only when a narrower Anthropic subdomain proves it deserves its own
  file

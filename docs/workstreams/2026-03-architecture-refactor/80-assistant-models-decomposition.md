# Assistant Models Decomposition

## Goal

This note records the decomposition of the legacy/shared
`assistant_models.dart` file without changing the public assistant-management
model API.

The goal was narrow:

- keep the current assistant model names stable
- separate assistant tools/resources, assistant entities, requests, and
  response/query models
- reduce coupling in the assistant-management surface without changing its
  runtime behavior

## 1. Why `assistant_models.dart` Was A Good Next Slice

After the audio and tool model decompositions, `assistant_models.dart` was the
next large shared-model hotspot.

Before this slice it mixed:

- assistant tool and tool-resource types
- assistant entity parsing and serialization
- create/modify request payloads
- list/delete/query response models

Those all belong to the assistant-management domain, but not to one source
block.

## 2. Frozen Decomposition Rule

This slice keeps the public assistant model API stable:

- no rename of assistant tool or request/response types
- no JSON payload changes
- no provider-specific assistant behavior moved into the shared model layer

The change is purely an internal source decomposition.

## 3. Landed Split

The main `assistant_models.dart` file is now reduced to the shell plus
same-library parts:

- `assistant_models_tools.dart`
- `assistant_models_entities.dart`
- `assistant_models_requests.dart`
- `assistant_models_responses.dart`

This maps better to the actual ownership boundaries:

- assistant tools/resources stay separate from assistant entities
- entity parsing stays separate from request payload construction
- list/delete/query models stay separate from mutation requests

## 4. Why This Matters Architecturally

Even though assistant APIs remain provider-owned in the bigger architecture,
their legacy/shared compatibility models still need to stay maintainable.

This split keeps the assistant-management surface readable without pretending it
should become part of the new minimal shared core.

## 5. Validation

This slice was validated with:

- `dart analyze lib/models lib/core/capability_management.dart lib/providers/openai/assistants.dart test/providers/openai/openai_advanced_test.dart test/builder/llm_builder_test.dart`
- `dart test test/providers/openai/openai_advanced_test.dart test/builder/llm_builder_test.dart`

## 6. Next Step

After `assistant_models.dart`, the remaining larger shared-model hotspots are
mostly `image_models.dart`, `file_models.dart`, and config-heavy files such as
`core/config.dart`.

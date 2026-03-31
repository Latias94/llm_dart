# Google Compatibility Modality Status

## Goal

This note reconciles the older Google compatibility TODO wording with the
bridge behavior that now exists in the repository.

The main question is no longer "does Google compatibility only support the text
structured-output path?"

The real question is narrower:

- which Google multimodal request shapes now bridge safely
- which legacy output projections are still intentionally thin
- which remaining Google gaps still matter for the breaking round

## 1. What The Google Compatibility Bridge Now Covers

The current Google compatibility route now already covers the important
image-generation-adjacent request shapes that the old TODO wording treated as
still open:

- legacy user image messages
- legacy user image-url messages
- legacy user and assistant file messages that map into the migrated Google
  prompt model
- legacy `enableImageGeneration`
- legacy `responseModalities` for the current bridged `TEXT` / `IMAGE` subset
- legacy safety settings, candidate count, reasoning settings, and web-search
  migration inputs on the bridged path
- legacy tool-use and tool-result messages for the current function-tool subset

The bridge also now preserves one important old-output behavior:

- streamed generated-image file parts are projected back into the old stream
  surface as the same text marker style the legacy Google provider used,
  e.g. `[Generated image: image/png]`

That means the old TODO item about Google modality coverage was too broad after
the current bridge slice landed.

## 2. What Still Does Not Bridge

The remaining Google compatibility limits are now much narrower:

- text-only structured output still remains incompatible with non-text response
  modalities
- legacy message decorators still stay outside the bridge-safe subset
- the old `ChatResponse` and `ChatStreamEvent` surface still cannot carry real
  generated image or audio payloads
- Google `AUDIO` response modalities still do not become a stable bridged chat
  capability through the deprecated root chat surface

These are not all defects.

Some of them are simply the old legacy surface running out of room.

## 3. Why The Remaining Output Limit Is Acceptable

The reference lesson from `repo-ref/ai` is still the same:

- keep provider-native rich multimodal output in provider-owned or UI-owned
  layers
- do not widen the shared or deprecated compatibility surface just to mimic one
  provider's richer payloads

For `llm_dart`, that means:

- the new Google package and Flutter/session layers remain the real home for
  rich generated files and multimodal rendering
- the compatibility bridge should only preserve the old surface honestly
- preserving the old Google generated-image stream marker is enough for legacy
  continuity

## 4. Roadmap Consequence

The old TODO item about “additional modality coverage beyond the text
structured-output path” should now be treated as closed.

The remaining real Google work is now:

1. provider-owned streamed TTS maturity
2. any future decision about whether the deprecated legacy chat surface should
   ever expose anything richer than the current generated-image text marker
3. ongoing Google mixed-tool and renderer maturity in the new package-owned
   APIs, not in the old compatibility layer

## Conclusion

Google compatibility no longer has a broad unresolved modality-coverage gap.

The current bridge now already covers the meaningful image-generation-adjacent
request shapes and preserves the important legacy generated-image stream marker.

The remaining Google gap is now mainly provider-owned streamed TTS plus the
intentional limit that the deprecated legacy chat surface will not become a
rich multimodal output API.

# Web Search Builder Normalization

## Goal

This note freezes one small but important rule for the root-package migration builder:

- root builder convenience methods must write into the provider-consumed compatibility shape
- they must not create dead extension keys that no migrated path actually reads

## 1. The Problem

The root `LLMBuilder.searchLocation(...)` helper previously wrote:

- `webSearchLocation`

But the migrated and compatibility-aware provider paths already consume:

- `webSearchConfig.location`

That meant `searchLocation(...)` looked like a stable helper while actually producing configuration that most provider paths ignored.

This is worse than an explicit deprecation because it is silent.

## 2. Frozen Rule

Root builder helpers should normalize into the canonical compatibility shape that provider adapters already read.

For search-related builder helpers, the canonical shared migration shape is:

- `webSearchEnabled`
- `webSearchConfig`

So `searchLocation(...)` should merge into `webSearchConfig.location` instead of writing a separate dead key.

## 3. Implementation Rule

`searchLocation(...)` now behaves as follows:

- if `webSearchConfig` does not exist, create one and set `location`
- if `webSearchConfig` already exists, merge `location` into it without dropping the existing fields
- if later root search helpers such as `webSearch(...)`, `newsSearch(...)`, or `advancedWebSearch(...)` run without an explicit new location, they preserve the existing normalized location instead of silently dropping it

This keeps the helper compatible with:

- Anthropic web-search tool shaping
- Google grounding/native search mapping
- xAI compatibility mapping through legacy `webSearchConfig`
- any future compatibility logic that already reads `webSearchConfig`

## 4. Broader Implication

The root migration builder should prefer:

- a smaller number of canonical typed compatibility objects

Instead of:

- many loosely related string-key extensions that each provider has to rediscover separately

This does not mean every root helper is permanently stable.

It means that while the migration builder still exists, each helper should at least write into a shape that the runtime actually consumes.

## 5. Current Conclusion

`searchLocation(...)` is now normalized.

The next cleanup steps should keep following the same rule:

- reduce dead extension keys
- merge root helpers into canonical compatibility objects
- deprecate provider-specific legacy helpers when the new primary API has already frozen a narrower provider-owned replacement

# 161 Provider Shell Remaining-Weight Audit

## Goal

After the recent OpenAI shell-thinning rounds, the next question is no longer
"should we keep compatibility shells at all?" It is:

> which remaining provider-shell files are still too heavy, which ones are now
> healthy enough to leave alone for a while, and what should the next
> decomposition order be?

This note audits the current compatibility provider-shell hotspots and freezes a
practical next priority order.

## Audit Method

This audit uses three signals together:

1. file size / line count as a coarse smell,
2. mixed ownership inside one file,
3. whether the file still acts like a shell or still acts like an
   implementation host.

Large size alone is not enough to call a file a problem. Some files are large
because they contain legitimate provider-local translation logic. The real smell
is mixed ownership that keeps hiding more than one architectural role in one
place.

## Current Snapshot

The heaviest remaining compatibility provider-shell files are currently:

| File | Approx. lines | Current role | Current assessment |
| --- | ---: | --- | --- |
| `lib/src/compatibility/providers/openai_family_compat_provider.dart` | 657 | builder functions + six provider wrappers + provider-specific option shaping | highest-priority remaining shell hotspot |
| `lib/src/compatibility/providers/anthropic_compat_provider.dart` | 519 | builder + compat wrapper + heavy Anthropic legacy adapter conversion logic | large, but more legitimately provider-local |
| `lib/src/compatibility/providers/openai/provider_compat.dart` | 448 | root OpenAI provider shell over residual capability modules | now materially thinner after recent rounds |
| `lib/src/compatibility/providers/google_compat_provider.dart` | 193 | builder + compat wrapper + typed option mapping | acceptable for now |
| `lib/src/compatibility/providers/elevenlabs/provider_compat.dart` | 195 | root compatibility shell over shell support | acceptable for now |
| `lib/src/compatibility/providers/anthropic/provider_compat.dart` | 173 | root Anthropic provider shell over residual modules | acceptable for now |
| `lib/src/compatibility/providers/google/provider_compat.dart` | 163 | root Google provider shell over residual modules | acceptable for now |
| `lib/src/compatibility/providers/ollama/provider_compat.dart` | 97 | thin root compatibility shell | healthy enough for now |

## File-By-File Conclusion

### 1. `openai_family_compat_provider.dart`

This is now the clearest remaining provider-shell hotspot.

It still mixes all of the following in one file:

- compatibility builder functions,
- model/profile construction,
- provider-specific option shaping,
- OpenAI-family route differences,
- and multiple compat provider subclasses:
  - OpenAI
  - DeepSeek
  - OpenRouter
  - Groq
  - xAI

That is too much mixed ownership for one compatibility file.

### Decision

This should be the **next decomposition target**.

The next step should not be a generic inheritance framework. The safer move is
to split by provider/profile slices or by clearly bounded support helpers, for
example:

- family-level builder support,
- OpenAI/OpenRouter support,
- DeepSeek/Groq support,
- xAI-specific live-search support,
- thin compat subclasses per provider.

### Why It Is Highest Priority

The file is not just large. It still mixes several different provider routes in
the same implementation home, which makes every new OpenAI-family compatibility
adjustment too easy to push back into one file.

## 2. `anthropic_compat_provider.dart`

This file is also large, but its situation is different.

A lot of its weight is not "shell plumbing" in the weak sense. It is genuinely
provider-local legacy-to-modern translation logic:

- raw legacy block analysis,
- cache/tool policy merging,
- provider-native replay conversion,
- exact replay-safe prompt construction.

That means the file is still a cleanup candidate, but not the same kind of
hotspot as the OpenAI-family mixed shell.

### Decision

Treat this as a **second-tier decomposition target**.

If it keeps growing, the next step should be to split its legacy adapter
conversion helpers into dedicated Anthropic-local files, while keeping the
overall compatibility adapter boundary intact.

## 3. `openai/provider_compat.dart`

This file was previously a bigger structural problem, but the latest rounds
meaningfully improved its shape:

- request shell logic moved out,
- request-body field shaping moved out,
- streamed parsing state moved out,
- chat bridge/fallback routing moved out.

It still has residual convenience delegation and capability composition, but it
now looks much more like a real compatibility shell than an implementation bus.

### Decision

Leave it alone for now unless a concrete new hotspot appears.

If another cleanup is needed later, it should probably be about capability
grouping or convenience helper placement, not another urgent structural split.

## 4. `google_compat_provider.dart`

This file remains small enough that its current mixed ownership is still
acceptable.

Its remaining weight is mostly:

- builder wiring,
- one compat wrapper,
- Google-specific option mapping.

### Decision

Do not prioritize this yet.

Only reopen it if new mixed-tool or modality-specific bridge logic makes the
file start growing in the same way the OpenAI-family file previously did.

## 5. Root Provider Shells Under Per-Provider Directories

These include files such as:

- `openai/provider_compat.dart`
- `anthropic/provider_compat.dart`
- `google/provider_compat.dart`
- `ollama/provider_compat.dart`
- `elevenlabs/provider_compat.dart`

The current trend is healthy:

- the shells increasingly delegate to support modules,
- the shells increasingly compose capability modules,
- the heavy request/stream logic increasingly lives elsewhere.

### Decision

Keep shrinking them opportunistically, but do not treat them as the main
structural bottleneck right now.

The bigger structural problem is still the mixed family-level builder file
rather than the now-thinner per-provider shells.

## Frozen Next Decomposition Order

The recommended next order is now:

1. `openai_family_compat_provider.dart`
2. `anthropic_compat_provider.dart` only if new replay/adapter work keeps
   growing the same file
3. revisit Google compatibility builder files only if mixed-tool or modality
   routing meaningfully increases their weight
4. continue opportunistic thinning of root provider shells, but treat that as
   maintenance rather than the main frontier

## Practical Recommendation

The next implementation slice should therefore target:

- splitting `openai_family_compat_provider.dart` into provider/profile-specific
  builder slices,
- without inventing a new giant repository-wide compatibility-provider base
  class,
- and without reopening the already-improving per-provider shell files unless a
  concrete new hotspot appears.

That gives the repository the best cost/benefit ratio after the recent OpenAI
request, stream, and facade thinning work.

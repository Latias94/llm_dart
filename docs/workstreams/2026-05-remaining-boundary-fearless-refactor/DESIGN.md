# Remaining Boundary Fearless Refactor

Status: Complete
Last updated: 2026-05-27

## Why This Lane Exists

The core seam refactor closed the root/app/provider-authoring split, text
generation request seam, unified error projection, stream vocabulary bridge,
provider descriptors, and provider call kit. The remaining architecture risk is
now concentrated in provider codec contracts, non-text app requests, capability
enforcement, chat turn/transport protocol, provider options policy, and whether
serialization dispatch needs a deeper registry.

This lane is intentionally breaking where a shallow Interface would otherwise
force another large refactor later.

## Problem

Several Modules are now good enough locally but still shallow at their seams:

- provider request/response/stream/replay codecs are verified mostly by
  provider-local test convention rather than by a reusable provider codec
  contract;
- non-text app helpers still expose broad named-parameter wrappers over
  provider request objects, unlike the new text generation request seam;
- provider descriptors describe facets and input shapes, but runtime request
  validation does not consistently consume that descriptor data;
- chat session turn lifecycle, HTTP transport protocol, replay projection, and
  recovery rules remain spread across multiple Modules;
- provider option policy is typed but OpenAI-family option applicability,
  namespace routing, and compatibility warnings still live in large bag Modules;
- AI/provider/chat serialization uses explicit codecs and type switches; that
  may be the right Interface today, but needs a deliberate deletion-test
  decision before more protocol families appear.

## Target State

When this lane closes:

- provider codec contracts have one reusable golden contract runner or an
  explicit documented reason why provider-local fixtures remain better;
- any non-text app request Module added by this lane passes the deletion test
  and hides meaningful validation/projection complexity;
- app/runtime capability validation can use provider descriptors without
  hard-coding provider families;
- chat turn and HTTP transport protocol ordering, cancellation, recovery, and
  replay invariants have one clear Interface;
- provider option policy has clearer locality without weakening typed
  provider-owned options;
- serialization registry is either implemented where it earns its keep or
  explicitly rejected as speculative;
- guards, package tests, fixture tests, docs, and workstream evidence prevent
  the old shallow seams from returning.

## In Scope

- Provider codec and fixture contract Modules across OpenAI, Anthropic, Google,
  Ollama, ElevenLabs, and provider-utils where repeated policy is stable.
- App-facing non-text request Modules only where they concentrate real
  validation/projection complexity.
- Capability descriptor enforcement for app/runtime helpers and UI gating.
- Chat turn/transport protocol seams in `llm_dart_chat`.
- Provider options policy Modules, especially OpenAI-family policy hot spots.
- Serialization codec registry decision, with implementation only if the
  deletion test justifies it.

## Out Of Scope

- Reopening the root app/provider-authoring split that just closed.
- Flattening provider-native options, replay data, native tools, files,
  assistants, catalogs, voices, moderation, or lifecycle clients into weak
  shared abstractions.
- Copying Vercel AI SDK TypeScript type machinery or package count.
- Publishing packages or changing release process.
- Reverting or formatting unrelated working-tree changes that predate this
  lane.

## Architecture Direction

Use `repo-ref/ai` as an ownership reference:

- app runtime owns orchestration, app request Interfaces, capability gates, and
  UI/session integration;
- provider contracts own provider-facing request/result/event data;
- provider-utils owns repeated transport/error/stream execution policy;
- concrete providers own route codecs, typed options, native tools, and replay
  details;
- root remains a facade and does not become a provider-utils aggregation layer.

The main test for every new Interface is the deletion test: if deleting the
Module merely spreads the same complexity across providers or app helpers, the
Module is earning its keep. If deletion makes the code simpler without losing
locality, keep the design local instead.

## Starting Assumptions

| Assumption | Confidence | Evidence | Consequence if wrong |
| --- | --- | --- | --- |
| Provider codec contract is the highest-leverage next seam. | High | Provider fixture and codec tests are the largest remaining repeated proof surface. | Start with capability enforcement if codec contracts prove already deep enough. |
| Non-text request seams should be selective. | High | Text generation needed a deep request; non-text helpers may not all pass the deletion test. | Reject speculative request Modules and document the reason. |
| Descriptors should inform runtime validation. | Medium | Provider descriptors now own facets/input shapes but are not yet a consistent preflight gate. | Keep descriptors descriptive only and avoid false validation confidence. |
| Chat turn protocol may need a deeper Interface. | Medium | Turn lifecycle and HTTP transport protocol are separated but still cognitively cross-linked. | Record no-op decision if current seams are already deep enough. |
| Serialization registry is speculative. | High | Explicit codecs are verbose but clear. | Do not implement unless repeated boilerplate clearly dominates. |

## Closeout Condition

This lane can close when all RBF tasks are complete, explicitly rejected by the
deletion test, or split into narrower follow-on lanes; fresh package tests,
workspace guards, docs, and workstream evidence prove the shipped state; and no
new public Interface is a pass-through over an old shallow implementation.

## Closeout Summary

Closed on 2026-05-27.

The lane completed all planned seams:

- provider fixture/codecs now share a test-only contract runner;
- capability descriptor enforcement now has provider/model gate Interfaces;
- non-text app helpers now have request seams where validation/projection earns
  the abstraction;
- HTTP chat transport stream consumption now has one protocol session Module;
- OpenAI-family provider options now own provider namespace projection on typed
  option classes;
- serialization kept explicit codec families and extracted only the repeated
  versioned envelope seam.

No candidate was split into a required follow-on. Suggested future work is
opportunistic: extend provider fixture contracts to more provider families when
new repeated fixtures appear, and add provider-specific error golden tests only
after at least two concrete providers repeat the same proof pattern.

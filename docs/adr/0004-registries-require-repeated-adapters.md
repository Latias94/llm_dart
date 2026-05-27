# ADR-0004: Registries Require Repeated Adapters

Status: Accepted
Date: 2026-05-27

## Context

The codebase has several places where a registry-shaped abstraction is tempting:
provider-native response projections, serialization families, runtime tools,
and provider implementation helpers. A registry can improve locality when many
adapters vary behind one stable Interface, but it can also hide provider-native
behavior and make the Interface shallow.

## Decision

Do not introduce a runtime or public registry until at least two real adapters
prove the seam and the deletion test shows that removing the registry would
spread complexity across callers. Before that point, use provider-owned
Modules, package-private indexes, or test-only helpers.

## Consequences

- OpenAI Responses projection family indexing remains package-private.
- Provider fixture helpers may live in non-publishable test support.
- Public registries require a new ADR or an explicit workstream decision.

# Goal

Extend the provider-owned fixture and golden contract convention from OpenAI
to Anthropic so a second complex provider can prove the layout, naming, and
contract-testing approach before deeper provider implementation refactors.

The first Anthropic slice should lock request encoding, request-side beta and
warning metadata, tool replay encoding, stream event projection, reasoning,
and provider metadata while preserving the public API and package graph.

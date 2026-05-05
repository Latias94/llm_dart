# Changelog

## 0.11.0-alpha.1

- Initial provider-spec package scaffold.
- Owns the first migrated provider-facing foundation contracts:
  `JsonSchema`, `ModelWarning`, `UsageStats`, and typed provider option marker
  interfaces.
- Owns the migrated provider-facing metadata, error, prompt, content, and tool
  definition contracts.
- Owns the migrated finish reason, response format, and text stream event
  contracts.
- Owns provider-level cancellation and `CallOptions`; old core
  `TransportCancellation` names remain compatibility aliases.

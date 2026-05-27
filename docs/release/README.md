# Release Ledger

This directory owns the publish-facing release state for the current
SDK-aligned alpha line.

The machine-readable ledger is `release_ledger.json`. It records:

- release posture and maintainer-owned publish action;
- publishable package order;
- non-publishable internal packages;
- workstream evidence that must stay aligned before publish;
- release gates that can run without network credentials;
- known deferrals that are not publish blockers.

Validate it with:

```powershell
dart --suppress-analytics run tool/check_release_ledger.dart
```

The ledger is intentionally narrow. It does not replace `CHANGELOG.md`,
package READMEs, migration docs, or publish dry-run output. It gives maintainers
one authoritative place to see whether release-facing seams are frozen enough
to run the external `pub publish` steps.

# Changelog

## [0.11.0-alpha.1] - 2026-05-12

- Alpha release of the transport package.
- Provides shared HTTP, SSE, UTF-8 streaming, logging, and diagnostics helpers.
- Adds a shared multipart/form-data builder for provider packages that need
  upload request support.
- Remains provider/runtime neutral so concrete providers can share transport
  plumbing without depending on the AI helper, chat, Flutter, or root packages.

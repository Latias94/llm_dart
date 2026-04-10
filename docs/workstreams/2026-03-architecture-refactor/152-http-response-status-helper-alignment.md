# 152 HTTP Response Status Helper Alignment

## Why

Even after the earlier HTTP cleanup rounds, root compatibility code still had a
small but repeated pattern around successful responses:

- log the response status,
- require `200`,
- branch into provider-specific error handling on failure.

That logic appeared in both `HttpResponseHandler` and the remaining OpenAI
compatibility client methods.

At the same time, `HttpResponseHandler.getJson(...)` no longer had any in-repo
consumers, so it was keeping extra compatibility surface alive without helping
the current architecture.

## Decision

Keep `HttpResponseHandler` as a compatibility-owned helper, but narrow it to
the parts that still provide real value:

- JSON object parsing,
- compatibility POST-JSON convenience,
- shared success-status validation with optional provider-owned failure hooks.

Remove the unused `getJson(...)` entrypoint.

## What Changed

- Added `HttpResponseHandler.ensureSuccessStatus(...)` for:
  - shared status logging,
  - `200` validation,
  - default Dio-style failure wrapping,
  - optional provider-specific failure handling.
- Switched the OpenAI compatibility client to reuse that helper across:
  - JSON POST,
  - form POST,
  - raw byte POST,
  - GET,
  - raw byte GET,
  - DELETE,
  - stream POST.
- Removed the unused `HttpResponseHandler.getJson(...)` helper.

## Architectural Effect

This does not move more behavior into transport. That is intentional.

- transport still owns lower-level Dio mechanics,
- root compatibility helpers own compatibility HTTP conventions,
- provider clients still own provider-specific failure semantics.

The result is a smaller and clearer root compatibility HTTP layer:

- fewer dead helpers,
- less repeated status handling,
- a more explicit seam for provider-specific error mapping.

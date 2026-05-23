# TODO

## Setup

- [x] OPH-010 Create the OpenAI family policy hub split workstream
- [x] OPH-020 Record the current hotspot audit
- [x] OPH-030 Define target module boundaries
- [x] OPH-040 Add the workstream to the index

## Generate-Text Compatibility Seam

- [x] OPH-110 Extract generate-text option parsing and encoding into smaller
  modules
- [x] OPH-120 Keep typed override merging and profile-specific rejection
  behavior
- [x] OPH-130 Keep the OpenAI family option resolver tests green

## Feature Option Helpers

- [x] OPH-210 Extract embedding option helpers into feature-local modules
- [x] OPH-220 Extract image option helpers into feature-local modules
- [x] OPH-230 Extract speech option helpers into feature-local modules
- [x] OPH-240 Extract transcription option helpers into feature-local modules
- [x] OPH-250 Keep provider-specific behavior unchanged during each
  extraction

## Resolver Boundary

- [x] OPH-310 Separate common OpenAI family policy from compatibility parsing
- [x] OPH-320 Decide and document the `ProviderOptionsBag` export posture
- [x] OPH-330 Update package docs and tests for the chosen posture

## Validation

- [x] OPH-410 Run focused OpenAI package tests
- [x] OPH-420 Run OpenAI package analysis
- [x] OPH-430 Run workspace dependency guards
- [x] OPH-440 Run root boundary guards
- [x] OPH-450 Run `git diff --check`

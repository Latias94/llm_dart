# 113. Google Transcription Boundary

## Question

Should `llm_dart_google` now gain a package-owned modern
`Google.transcriptionModel(...)` surface, so the shared non-text result work can
 look more symmetric with OpenAI and ElevenLabs?

## Conclusion

Not yet.

The honest current boundary is:

- keep `Google.speechModel(...)`
- keep audio-input transcription through Google's multimodal
  `LanguageModel` path when apps want prompt-shaped transcripts
- do **not** introduce a shared `TranscriptionModel` surface for Google until a
  dedicated provider API or a clearly justified provider-owned helper contract
  exists

## Why

## 1. The Official Google Surface Is Not A Dedicated Transcription Model

The current official Gemini API guidance for audio transcription is prompt-based
audio understanding:

- upload or inline audio
- call `generateContent`
- ask Gemini to generate a transcript or structured transcript

The official docs explicitly describe this as audio understanding and
prompt-based transcript generation, not as a dedicated speech-to-text model
surface.

The same docs also draw a boundary:

- Gemini API does not support real-time transcription on this path
- for real-time transcription, Google points users to the Live API
- for dedicated speech-to-text models, Google points users to Google Cloud
  Speech-to-Text

That means a new shared `TranscriptionModel` in `llm_dart_google` would risk
pretending the provider has a dedicated contract that its public API does not
actually expose.

## 2. `repo-ref/ai` Does Not Model Google This Way Either

The local `repo-ref/ai` snapshot also matters here.

Its Google package exposes:

- language models
- embedding models
- image models
- video models

It does **not** expose a Google transcription model.

That is a useful structural signal:

- this is not a parity gap we must “fix”
- it is a boundary the reference repository also leaves alone

## 3. The Shared `TranscriptionModel` Contract Should Stay Honest

Our current shared `TranscriptionModel` now carries richer result data:

- typed segments
- language
- duration
- warnings
- response metadata

That contract is worth using when the provider actually offers a dedicated
transcription-style API.

Google's current Gemini path is different:

- transcription is one multimodal prompting outcome among several
- prompt wording can shape the output structure heavily
- the same request path also covers summarization, diarization, translation,
  timestamps, and custom JSON output

That is closer to:

- multimodal `LanguageModel`
- or a future provider-owned Google audio-understanding helper

It is not yet a good fit for a dedicated shared `TranscriptionModel`.

## Recommended Boundary

For this repository, the frozen near-term rule should be:

- no package-owned modern `Google.transcriptionModel(...)` for now
- if apps need Google audio transcripts today, use the multimodal
  `Google.chatModel(...)` path with audio input plus prompt or structured output
- only consider a provider-owned helper later if repeated app usage proves a
  stable Google-specific audio-understanding contract

## What A Future Google-Specific Helper Could Be

If a real product need appears, the next honest expansion would be provider-
owned, not shared-first.

Examples:

- `Google.audioUnderstandingModel(...)`
- or a provider-owned helper that builds transcript-oriented multimodal prompts
  on top of `LanguageModel`

That would better match the actual Google API surface:

- multimodal input
- prompt-defined transcript structure
- optional structured output
- no fake dedicated STT endpoint

## Impact On The Workstream

This closes the current open question more explicitly:

- the remaining Google non-text gap is **not** “missing transcription parity”
- the remaining Google gap is provider-owned streamed TTS maturity plus any
  future Google-specific audio-understanding helper decision

So the next rounds should not spend the breaking window on a misleading
`TranscriptionModel` addition for Google.

## Related Documents

- `112-openai-and-google-nontext-result-adoption.md` records the already-landed
  shared non-text result adoption for OpenAI speech/transcription and Google
  speech
- `55-shared-capability-helper-parity.md` records the broader shared-capability
  helper direction for speech and transcription

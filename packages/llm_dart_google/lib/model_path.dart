/// Google model path normalization utilities.
///
/// Vercel AI SDK treats model IDs containing a `/` as already having a full
/// model path (e.g. `models/...`, `tunedModels/...`). Plain IDs are prefixed
/// with `models/`.
library;

String googleModelPath(String modelId) {
  return modelId.contains('/') ? modelId : 'models/$modelId';
}

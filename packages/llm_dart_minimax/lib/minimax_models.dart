library;

/// MiniMax Anthropic-compatible models/constants.
///
/// Reference: https://platform.minimax.io/docs/api-reference/text-anthropic-api
const String minimaxDefaultModel = 'MiniMax-M2.1';

/// MiniMax fast model listed in the Anthropic-compatible docs.
///
/// Reference: https://platform.minimax.io/docs/api-reference/text-anthropic-api
const String minimaxFastModel = 'MiniMax-M2.1-lightning';

/// MiniMax known model ids for the Anthropic-compatible Messages API.
///
/// Reference: https://platform.minimax.io/docs/api-reference/text-anthropic-api
const Set<String> minimaxKnownModels = {
  'MiniMax-M1',
  'MiniMax-M1-80k',
  'MiniMax-M2',
  minimaxDefaultModel,
  minimaxFastModel,
};

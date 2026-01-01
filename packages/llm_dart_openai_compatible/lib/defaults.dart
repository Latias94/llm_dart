/// Default endpoints and model names for OpenAI-compatible providers.
///
/// These are intentionally kept out of `llm_dart_core` to keep the core package
/// provider-agnostic and stable.
library;

const String openaiCompatibleFallbackModel = 'gpt-4o';

// OpenAI-compatible providers (HTTP endpoints).
const String deepseekBaseUrl = 'https://api.deepseek.com/v1/';
const String deepseekDefaultModel = 'deepseek-chat';

const String groqBaseUrl = 'https://api.groq.com/openai/v1/';
const String groqDefaultModel = 'llama-3.3-70b-versatile';

const String xaiBaseUrl = 'https://api.x.ai/v1/';
const String xaiDefaultModel = 'grok-3';

const String phindBaseUrl = 'https://api.phind.com/v1/';
const String phindDefaultModel = 'Phind-70B';

// OpenRouter (OpenAI-compatible).
const String openRouterBaseUrl = 'https://openrouter.ai/api/v1/';
const String openRouterDefaultModel = 'openai/gpt-4';

// Google Gemini OpenAI-compatible endpoint.
const String googleOpenAIBaseUrl =
    'https://generativelanguage.googleapis.com/v1beta/openai/';
const String googleOpenAIDefaultModel = 'gemini-2.0-flash';

// Convenience endpoints used by the umbrella builder extensions.
const String githubCopilotBaseUrl =
    'https://api.githubcopilot.com/chat/completions';
const String githubCopilotDefaultModel = 'gpt-4';

const String togetherAIBaseUrl = 'https://api.together.xyz/v1/';
const String togetherAIDefaultModel = 'meta-llama/Llama-3-70b-chat-hf';

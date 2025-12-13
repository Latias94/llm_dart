// The Google provider facade is prompt-first and re-exports the
// dedicated `llm_dart_google` subpackage.

/// Modular Google Provider
///
/// This library provides a modular implementation of the Google provider
///
/// **Key Benefits:**
/// - Single Responsibility: Each module handles one capability
/// - Easier Testing: Modules can be tested independently
/// - Better Maintainability: Changes isolated to specific modules
/// - Cleaner Code: Smaller, focused classes
/// - Reusability: Modules can be reused across providers
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart/providers/google/google.dart';
///
/// final provider = GoogleProvider(GoogleConfig(
///   apiKey: 'your-api-key',
///   model: 'gemini-1.5-flash',
/// ));
///
/// // Use chat capability
/// final response = await provider.chat(messages);
/// ```
library;

/// Public Google provider surface re-export.
///
/// This mirrors the primary Google provider types while keeping internal
/// implementation details (like HTTP strategies) in the sub-package.
export 'package:llm_dart_google/llm_dart_google.dart'
    show
        // Core config / client / provider
        GoogleConfig,
        GoogleClient,
        GoogleProvider,

        // Chat / embeddings / images
        GoogleChat,
        GoogleChatResponse,
        GoogleEmbeddings,
        GoogleImages,

        // Safety & harm configuration
        SafetySetting,
        HarmCategory,
        HarmBlockThreshold,

        // Files API
        GoogleFilesClient,
        GoogleFile,

        // Vercel AI-style facade
        GoogleGenerativeAIProviderSettings,
        GoogleGenerativeAI,
        GoogleProviderDefinedTools,
        GoogleTools,
        createGoogleGenerativeAI,
        google;

// Builder APIs for configuring Google via LLMBuilder.
export 'builder.dart';

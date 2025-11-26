# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.10.5] - 2025-11-26

### Added

- **Streaming Tool Call Aggregation Helper**: Added `ToolCallAggregator` utility to merge incremental `ToolCallDeltaEvent` chunks into complete tool calls (stable `id`, `function.name`, and full `function.arguments`) for streaming workflows.
  - Exported via `llm_dart.dart` so it can be used by applications that consume streaming tool calls.
  - Updated examples (`example/02_core_features/tool_calling.dart`, `example/04_providers/openai/advanced_features.dart`, and `example/06_mcp_integration/http_examples/simple_stream_client.dart`) to use the aggregator when replaying streamed tool calls into follow-up requests.

### Fixed

- **OpenAI Chat Streaming Tool Calls**: Fixed missing tool call IDs when using streaming tool calls with the OpenAI Chat Completions API ([#27](https://github.com/Latias94/llm_dart/pull/27))
  - Track tool call IDs by `index` across streaming chunks so that each `ToolCallDeltaEvent` has a stable `toolCall.id`.

## [0.10.4] - 2025-11-19

### Fixed

- **Error Message Propagation**: Fixed error responses showing "Instance of 'ResponseBody'" instead of actual API error messages (by [@isegal](https://github.com/isegal) in [#25](https://github.com/Latias94/llm_dart/pull/25))
  - Made `handleDioError` async to properly read ResponseBody streams
  - Added proper error message extraction from streamed error responses
  - Applied fix across all provider clients for consistent error handling
  - Error messages now display actual API error details for better debugging

## [0.10.3] - 2025-11-17

### Added

- **Google Web Search Support**: Added web search (grounding) capability for Google Gemini models (by [@viumvi](https://github.com/viumvi) in [#24](https://github.com/Latias94/llm_dart/pull/24))

### Fixed

- **Error Code Type Handling**: Fixed error code parsing to handle both string and numeric error codes (by [@viumvi](https://github.com/viumvi) in [#22](https://github.com/Latias94/llm_dart/pull/22))
  - Fixed `error['code']` casting issue when API returns numeric error codes
  - Applied fix to OpenAI client SSE stream error handling
  - Applied fix to HTTP error mapper for consistent error code handling

- **Google Image Generation Aspect Ratio**: Added support for aspect ratio configuration in Google image generation (by [@viumvi](https://github.com/viumvi) in [#22](https://github.com/Latias94/llm_dart/pull/22))
  - Added `aspectRatio` parameter to `imageConfig` in generation request
  - Supports custom image sizes through `request.size` parameter

## [0.10.2] - 2025-11-13

### Fixed

- **Anthropic Streaming Tool Use**: Fixed tool call delta events not being emitted during streaming (by [@isegal](https://github.com/isegal) in [#21](https://github.com/Latias94/llm_dart/pull/21))
  - Added local state tracking for tool calls across multiple streaming events
  - Fixed `content_block_stop` event handling (Anthropic only provides index, not full content)
  - Tool calls now properly detected in streaming mode

- **Anthropic SSE Buffering**: Fixed SSE parsing to handle incomplete network chunks that split data mid-line
  - Added line-level buffering similar to OpenAI's implementation
  - Only process complete lines ending with `\n`
  - Prevents data loss when network packets split SSE events (e.g., `data:` → `d` + `ata:`)

- **Anthropic Web Search and Image Upload**: Fixed web search tool configuration and image handling (by [@viumvi](https://github.com/viumvi) in [#20](https://github.com/Latias94/llm_dart/pull/20))
  - Fixed web search tool format to match official API spec (`web_search_20250305` type)
  - Added `ImageUrlMessage` support for Anthropic image URLs
  - Added base64 encoding for Anthropic image data as required by API
  - Fixed web search configuration with proper parameter handling

### Added

- **Anthropic Streaming Tool Example**: Added comprehensive streaming tool calling example in `example/04_providers/anthropic/streaming_tool_calling.dart`

## [0.10.1] - 2025-11-06

### Fixed

- **OpenAI Image and File Message Handling**: Fixed message format compatibility for both Chat Completions API and Responses API (by [@viumvi](https://github.com/viumvi) in [#19](https://github.com/Latias94/llm_dart/pull/19))
  - Fixed image URL format to use correct structure based on `useResponsesAPI` flag
  - Fixed Responses API `input` field to always send message array (was incorrectly sending content array for single messages)
  - Fixed content type names for Responses API (`input_text`, `input_image`, `input_file`)
  - Fixed missing text content when `ImageMessage` or `ImageUrlMessage` includes `content` field
  - Now supports mixed content (text + image/file) in single messages

### Added

- **OpenAI Image and File Examples**: Added comprehensive example in `example/04_providers/openai/image_and_file_messages.dart`
  - Demonstrates image URL messages, base64 encoded images, and file messages
  - Shows mixed content usage (text + image/file)
  - Covers both Chat Completions API and Responses API

## [0.10.0] - 2025-10-19

### Added

- **Request Cancellation Support**: Added comprehensive cancellation support for all operations (by [@PeronGH](https://github.com/PeronGH) in #18)
  - New `CancelToken` parameter for `chat()`, `chatStream()`, `embed()`, `models()`, and all audio operations
  - New `CancelledError` for consistent cancellation error handling
  - New `CancellationHelper` utilities with `isCancelled()` and `getCancellationReason()` methods
  - True network-level cancellation using Dio's CancelToken
  - Comprehensive examples in `example/02_core_features/cancellation_demo.dart`
  - Full documentation in README

### Changed

- Updated `dio` dependency from ^5.8.0 to ^5.9.0
- Updated `test` dependency from ^1.25.15 to ^1.26.3
- Updated `mcp_dart` dependency from ^0.5.1 to ^0.6.3

## [0.9.0] - 2025-8-8

### Added

- **Anthropic Prompt Caching Support**: Added unified MessageBuilder API with Anthropic prompt caching for tools and messages (by [@okandemirofficial](https://github.com/okandemirofficial) in #11)
- **Ollama Thinking/Reasoning Support**: Added full thinking support for Ollama reasoning models (by [@gabber235](https://github.com/gabber235) in #16)
- **GPT-5 Support**: Added support for GPT-5 specific features
  - Added `Verbosity` enum with `low`, `medium`, `high` levels for controlling output detail
  - Added `verbosity()` method to `OpenAIBuilder` for GPT-5 models
  - Added `minimal` option to `ReasoningEffort` enum for faster responses

### Fixed

- **Google Thinking Content Separation**: Fixed GoogleChatResponse.text to correctly exclude thinking content according to Google API specification

## [0.8.0] - 2025-6-20

### Added

- **Google TTS API Support**: Implemented Google Gemini TTS API with 30 prebuilt voices and streaming audio generation
  - Documentation: [Speech Generation API](https://ai.google.dev/gemini-api/docs/speech-generation)
  - Examples in `example/04_providers/google/google_tts_example.dart`

- **Google Image Generation API Support**: Implemented Google Gemini image generation API with multiple aspect ratios
  - Documentation: [Image Generation API](https://ai.google.dev/gemini-api/docs/image-generation)
  - Examples in `example/04_providers/google/image_generation.dart`

### Fixed

- **Usage Data Type Conversion**: Fixed critical type casting issue in streaming responses ([#12](https://github.com/Latias94/llm_dart/issues/12))
- **Web Platform Compatibility**: Resolved `dart:io` compatibility issues to support Web platforms.

## [0.7.2] - 2025-6-13

### Fixed

- **OpenAI Streaming Response Issues**: Fixed another critical bug in SSE (Server-Sent Events) parsing that caused character loss in streaming responses
  - Streaming responses should now be completely reliable without any character loss

## [0.7.1] - 2025-6-13

### Fixed

- **OpenAI Streaming Response Issues**: Fixed critical bug in SSE (Server-Sent Events) parsing that caused missing content in streaming responses

## [0.7.0] - 2025-6-13

### Added

- **Custom Dio Client Support**: Advanced HTTP control with custom Dio client integration
  - `HttpConfig.dioClient()` method for providing custom Dio instances
  - Priority system: Custom Dio > HTTP configuration > Provider defaults
  - Provider-specific interceptors (like Anthropic's beta headers) are automatically added to custom Dio clients
  - Support for custom interceptors, adapters, and advanced HTTP configurations
  - Examples in `example/03_advanced_features/layered_http_config.dart`

- **OpenAI Responses API Support**: Complete implementation of OpenAI's new stateful Responses API
  - Full CRUD operations for responses (create, get, delete, cancel, list input items)
  - Stateful conversation management with `continueConversation()` and `forkConversation()`
  - Background processing for long-running tasks
  - Built-in tools integration: web search, file search, computer use
  - Enhanced builder methods: `useResponsesAPI()`, `webSearchTool()`, `fileSearchTool()`, `computerUseTool()`
  - Type-safe response handling and comprehensive examples in `example/04_providers/openai/responses_api.dart`

### Fixed

- **Google Provider ToolChoice Support**: Complete implementation of tool choice functionality
  - Added `toolChoice` field to `GoogleConfig` with proper serialization
  - Implemented `_convertToolChoice()` method for Google's API format conversion
  - Fixed issue where SpecificToolChoice was ignored by Google provider
  - **Special thanks to [@okandemirofficial](https://github.com/okandemirofficial) for reporting this issue ([#6](https://github.com/Latias94/llm_dart/issues/6)) and providing the fix ([#7](https://github.com/Latias94/llm_dart/pull/7))! 🎉**

- **HTTP Client Architecture**: Unified Dio client creation across all providers
  - Eliminated ~500 lines of duplicate code with new `DioClientFactory`
  - Consistent priority logic across all providers
  - Simplified maintenance and enhanced test coverage

- **xAI User-Agent Cleanup**: Removed unnecessary custom User-Agent header for consistency

## [0.6.0] - 2025-6-12

### Added

- **Enhanced Array Tools**: Support for nested object structures in tool parameters
  - Added `properties` and `required` fields to `ParameterProperty` class for defining complex object schemas
  - Enhanced `ToolValidator` with recursive validation for nested object arrays
  - Support for deep nesting: array → object → array → object structures
  - Complete validation of required properties, unknown properties, and type checking in nested structures
  - Comprehensive test coverage in `enhanced_array_tools_test.dart`
  - Practical examples integrated into `enhanced_tool_calling.dart` demonstrating real-world usage scenarios
  - **Special thanks to [@okandemirofficial](https://github.com/okandemirofficial) for this valuable contribution as our first external contributor! 🎉**

- **Anthropic MCP Connector**: Native support for Anthropic's Model Context Protocol connector
  - `AnthropicMCPServer` - Configuration for remote MCP servers with OAuth support
  - `AnthropicMCPToolConfiguration` - Fine-grained tool filtering and access control
  - `AnthropicMCPToolUse` and `AnthropicMCPToolResult` - Specialized content blocks for MCP interactions
  - Automatic beta header injection (`anthropic-beta: mcp-client-2025-04-04`) when MCP servers are configured
  - Convenience methods: `mcpServers()` and `withMcpServers()` for easy configuration
  - Support for URL-based MCP servers with authentication tokens
  - Distinct from general MCP protocol - provides direct integration with Anthropic's API
  - Example implementation in `example/04_providers/anthropic/mcp_connector.dart`

- **Provider-Specific Builder Pattern**: Complete migration of provider-specific parameters
  - `ElevenLabsBuilder` - Dedicated builder for ElevenLabs TTS parameters (`voiceId`, `stability`, `similarityBoost`, `style`, `useSpeakerBoost`)
  - `OpenAIBuilder` - Dedicated builder for OpenAI-specific parameters (`frequencyPenalty`, `presencePenalty`, `logitBias`, `seed`, `parallelToolCalls`, `logprobs`, `topLogprobs`) and web search methods
  - `OllamaBuilder` - Dedicated builder for Ollama-specific parameters (`numCtx`, `numGpu`, `numThread`, `numa`, `numBatch`, `keepAlive`, `raw`)
  - `AnthropicBuilder` - Dedicated builder for Anthropic-specific parameters (`metadata`, `container`, `mcpServers`)
  - Cleaner separation of concerns between generic and provider-specific configurations
  - Consistent callback-style configuration pattern across all providers

- **Google Embeddings Support**: Full embedding capability for Google provider
  - `GoogleLLMBuilder` class for Google-specific embedding parameters
  - Support for task types (`SEMANTIC_SIMILARITY`, `RETRIEVAL_QUERY`, `RETRIEVAL_DOCUMENT`, etc.)
  - Embedding dimensions configuration and document title support
  - Convenience methods for common embedding tasks (`forSemanticSimilarity()`, `forDocumentRetrieval()`)
  - Integrated callback configuration in `LLMBuilder.google()` method

- **Layered HTTP Configuration**: New organized approach to HTTP settings configuration
  - `HttpConfig` class for clean, organized HTTP settings management
  - Unified HTTP configuration across all providers with consistent API
  - Support for proxy configuration, custom headers, SSL settings, and timeouts
  - HTTP request/response logging for debugging and development
  - `LLMBuilder.http()` method for layered configuration instead of flat methods

- **HTTP Configuration Utils**: Centralized HTTP configuration management
  - `HttpConfigUtils` class for unified Dio instance creation with advanced settings
  - Support for corporate proxy environments and custom SSL certificates

### Fixed

- **Web Search Functionality**: Complete fix for previously non-functional `enableWebSearch()` method
  - **xAI Provider**: Fixed `webSearchEnabled` extension processing in `XAIConfig.fromLLMConfig()`
    - Now properly converts `webSearchEnabled` flag to `liveSearch` activation with default `SearchParameters`
    - Added automatic conversion of `webSearchConfig` to xAI-specific `SearchParameters`
    - Enables Live Search with proper mode, sources, and result limit configuration
  - **Anthropic Provider**: Added missing web search support in `AnthropicConfig.fromLLMConfig()`
    - Now processes `webSearchEnabled` flag to automatically add `web_search` tool
    - Converts `webSearchConfig` to Anthropic's `web_search_20250305` tool specification
    - Supports domain filtering, location-based search, and usage limits
  - **OpenAI Provider**: Enhanced `OpenAIProviderFactory._transformConfig()` with search model switching
    - Automatically switches to search-enabled models (e.g., `gpt-4o` → `gpt-4o-search-preview`) when `webSearchEnabled` is true
    - Supports model mapping for both standard and mini variants
    - Handles `webSearchConfig` for context size control
  - **OpenRouter Provider**: Added web search support in `OpenAICompatibleProviderFactory._transformConfig()`
    - Automatically adds `:online` suffix to models when `webSearchEnabled` is true
    - Supports both simple activation and advanced plugin configuration
  - **Universal Fix**: All providers now properly handle both `enableWebSearch()` method and `webSearchConfig` extensions
  - **Backward Compatibility**: Existing `webSearch()`, `newsSearch()`, and provider-specific methods continue to work unchanged

### Changed

- **Anthropic MCP Models Reorganization**: Moved MCP-related classes to provider-specific location
  - Removed generic `MCPServer` and `MCPToolConfiguration` from `lib/models/chat_models.dart`
  - Created `lib/providers/anthropic/mcp_models.dart` with Anthropic-prefixed classes
  - All MCP classes now clearly identified as Anthropic-specific (`AnthropicMCPServer`, `AnthropicMCPToolConfiguration`, etc.)
  - Prevents confusion with general MCP protocol implementations
  - Updated all imports and references to use new Anthropic-specific models

- **LLMBuilder API Cleanup**: Removed provider-specific methods from main builder
  - Moved ElevenLabs-specific methods (`voiceId`, `stability`, `similarityBoost`, `style`, `useSpeakerBoost`) to `ElevenLabsBuilder`
  - Moved OpenAI-specific methods (`frequencyPenalty`, `presencePenalty`, `logitBias`, `seed`, `parallelToolCalls`, `logprobs`, `topLogprobs`) to `OpenAIBuilder`
  - Moved Ollama-specific methods (`numCtx`, `numGpu`, `numThread`, `numa`, `numBatch`, `keepAlive`, `raw`) to `OllamaBuilder`
  - Moved Anthropic-specific methods (`metadata`, `container`, `mcpServers`) to `AnthropicBuilder`
  - Moved provider-specific web search methods (`openaiWebSearch`, `openRouterWebSearch`, `perplexityWebSearch`) to respective builders
  - Main `LLMBuilder` now focuses on universal parameters and provider selection

- **Provider Configuration Pattern**: Unified callback-style configuration across all providers
  - `LLMBuilder.openai()` now accepts optional configuration callback for OpenAI-specific parameters
  - `LLMBuilder.anthropic()` now accepts optional configuration callback for Anthropic-specific parameters
  - `LLMBuilder.ollama()` now accepts optional configuration callback for Ollama-specific parameters
  - `LLMBuilder.elevenlabs()` now accepts optional configuration callback for ElevenLabs-specific parameters
  - Consistent API pattern following Google provider implementation

- **Google Provider Configuration**: Consolidated callback configuration methods
  - Removed redundant `googleConfig()` method in favor of unified `google()` callback approach
  - `LLMBuilder.google()` now accepts optional configuration callback for provider-specific parameters
  - Maintains backward compatibility while providing cleaner API surface

- **BaseHttpProvider**: Cleaned up unused code and modernized implementation
  - Removed unused `createDio()` method that was not used by any provider
  - Enhanced `createConfiguredDio()` method to use new `HttpConfigUtils`
  - Updated to use modern Dio API patterns and best practices

### Migration Guide

- **Web Search Functionality**: No migration required - previously broken functionality now works
  - **`enableWebSearch()` method**: Now functional across all providers (was previously ignored)
    - xAI: Automatically enables Live Search with default parameters
    - Anthropic: Automatically adds web_search tool to tool list
    - OpenAI: Automatically switches to search-enabled model variants
    - OpenRouter: Automatically adds `:online` suffix to model names
  - **Existing code**: All existing web search code continues to work unchanged
  - **New functionality**: `enableWebSearch()` can now be used as a simple, universal web search activation method

- **Anthropic MCP Models**: Update imports and class references
  - **Before**: `import '../../models/chat_models.dart'; MCPServer(...)`
  - **After**: `import 'package:llm_dart/providers/anthropic/mcp_models.dart'; AnthropicMCPServer(...)`
  - All MCP classes now have `Anthropic` prefix to distinguish from general MCP protocol
  - Update constructor calls: `MCPServer.url()` → `AnthropicMCPServer.url()`

- **Provider-Specific Parameters**: Update usage to new callback-style configuration
  - **Before**: `ai().elevenlabs().voiceId('voice-123').stability(0.5).build()`
  - **After**: `ai().elevenlabs((elevenlabs) => elevenlabs.voiceId('voice-123').stability(0.5)).build()`
  - **Before**: `ai().openai().seed(12345).frequencyPenalty(0.5).build()`
  - **After**: `ai().openai((openai) => openai.seed(12345).frequencyPenalty(0.5)).build()`
  - **Before**: `ai().ollama().numCtx(4096).keepAlive('10m').build()`
  - **After**: `ai().ollama((ollama) => ollama.numCtx(4096).keepAlive('10m')).build()`
  - **Before**: `ai().anthropic().metadata({'user': 'test'}).build()`
  - **After**: `ai().anthropic((anthropic) => anthropic.metadata({'user': 'test'})).build()`
  - **Before**: `ai().openRouter().openRouterWebSearch(maxResults: 5).build()`
  - **After**: `ai().openRouter((openrouter) => openrouter.webSearch(maxResults: 5)).build()`

### Examples

- **Anthropic MCP Connector Examples**: Complete demonstration of MCP connector functionality
  - `example/04_providers/anthropic/mcp_connector.dart` - Comprehensive MCP connector usage examples
  - Basic MCP server configuration with URL-based servers
  - Multiple MCP servers with different configurations and tool filtering
  - OAuth authentication with access tokens for secure MCP servers
  - Updated Anthropic provider README with MCP connector documentation

- **HTTP Configuration Examples**: Comprehensive demonstration of new layered approach
  - `http_configuration.dart` - Complete HTTP configuration examples with all features
  - `layered_http_config.dart` - New layered configuration approach demonstration
- **Provider-Specific Builder Examples**: Updated examples demonstrating new callback-style configuration
  - All provider examples updated to use new builder pattern
  - Consistent API across all providers with provider-specific capabilities

## [0.5.0] - 2025-6-11

### Added

- New examples and restructured the example directory for better clarity.
- **Comprehensive Test Suite**: Added extensive test coverage for core functionality
- **UTF-8 Stream Decoder**: Robust handling of multi-byte characters in streaming responses
  - `Utf8StreamDecoder` class for intelligent buffering of incomplete UTF-8 byte sequences
  - Prevents `FormatException: Unfinished UTF-8 octet sequence` errors in streaming

### Fixed

- **UTF-8 Streaming Issues**: Complete resolution of multi-byte character encoding problems
  - Fixed garbled text output (e.g., `ä½ æ` → `你好`) in streaming responses
  - Updated all provider clients (OpenAI, Anthropic, DeepSeek, Groq, Google, xAI, Ollama) to use UTF-8 stream decoder
  - Proper handling of Chinese, Japanese, Korean, Arabic, and emoji characters in streams
  - Eliminated `FormatException: Unfinished UTF-8 octet sequence` errors when multi-byte characters are split across network chunks
- **BaseProviderFactory**: Improved validation logic in `validateConfigWithDetails` method

## [0.4.0] - 2025-6-11

### Added

- **Unified Web Search API**: Provider-agnostic web search functionality across multiple LLM providers
  - `WebSearchConfig` - Universal configuration class supporting all provider-specific parameters
  - `WebSearchLocation` - Geographic location configuration for localized search results
  - `WebSearchType` - Search type enumeration (web, news, academic, combined)
  - `WebSearchStrategy` - Implementation strategy control (native, tool, plugin, parameter, auto)
  - `WebSearchContextSize` - Context size control for providers that support it
  - **Provider Support**:
    - **xAI Grok**: Live Search with `search_parameters` (mode, sources, date filtering, result limits)
    - **Anthropic Claude**: Web Search Tool with domain filtering and location-based search
    - **OpenAI**: Web Search with context size control for `gpt-4o-search-preview` models
    - **OpenRouter**: Plugin-based search with custom prompts and `:online` model shortcuts
    - **Perplexity**: Native search capabilities with context size control
  - **Ergonomic Builder Methods**:
    - `enableWebSearch()` - Simple web search activation
    - `quickWebSearch()` - Fast configuration with common settings
    - `webSearch()` - Advanced configuration with full parameter control
    - `newsSearch()` - News-specific search configuration
    - `searchLocation()` - Geographic context configuration
    - Provider-specific methods: `openaiWebSearch()`, `openRouterWebSearch()`, `perplexityWebSearch()`
    - `advancedWebSearch()` - Full control over all search parameters
  - **Automatic Provider Adaptation**: Same API automatically translates to provider-specific formats
  - **Rich Configuration Options**: Domain filtering, result limits, date ranges, geographic context
  - **Type Safety**: Strong typing with enums and configuration classes
  - **Comprehensive Examples**: Complete demonstration in `02_core_features/web_search.dart`

- **Enhanced LLM Capability System**: Extended capability detection for web search
  - `LLMCapability.liveSearch` - New capability for real-time web search functionality
  - Updated provider capability declarations to include search support
  - Enhanced capability factory methods to support web search providers

- **Capability Factory Methods**: Type-safe provider building with compile-time capability checking
  - `buildAudio()` → `AudioCapability` - Build providers with audio capabilities
  - `buildImageGeneration()` → `ImageGenerationCapability` - Build providers with image generation
  - `buildEmbedding()` → `EmbeddingCapability` - Build providers with embedding capabilities
  - `buildFileManagement()` → `FileManagementCapability` - Build providers with file management
  - `buildModeration()` → `ModerationCapability` - Build providers with moderation capabilities
  - `buildAssistant()` → `AssistantCapability` - Build providers with assistant capabilities
  - `buildModelListing()` → `ModelListingCapability` - Build providers with model listing
  - Eliminates runtime type casting and provides compile-time type safety
  - Clear error messages with `UnsupportedCapabilityError` when capabilities are not supported
  - Better IDE support and autocomplete for capability-specific methods

- **Enhanced Error Handling**: New error types and improved error handling examples
  - `UnsupportedCapabilityError` - Thrown when building providers with unsupported capabilities
  - Updated `error_handling.dart` example to demonstrate capability factory method errors
  - Clear error messages listing supported providers for each capability

- **Core Features Examples**: New capability detection and model listing examples
  - `capability_detection.dart` - Demonstrates provider capability discovery and comparison
  - `model_listing.dart` - Shows how to explore and filter available models from providers
  - `capability_factory_methods.dart` - Comprehensive demonstration of type-safe capability building

### Changed

- **xAI Provider**: Enhanced with comprehensive Live Search support
  - Updated `XAIConfig` to include `liveSearch` boolean parameter for simple activation
  - Enhanced `SearchParameters` class with factory methods and better documentation
  - Improved `_buildSearchParameters()` method with automatic default configuration
  - Added `isLiveSearchEnabled` getter for configuration validation
  - Updated provider capabilities to include `LLMCapability.liveSearch`
  - Enhanced factory methods and convenience functions to support Live Search

- **LLM Builder**: Significantly improved web search ergonomics
  - Replaced provider-specific search methods with unified, ergonomic API
  - Added comprehensive web search configuration methods with clear documentation
  - Improved method naming for better developer experience
  - Enhanced parameter validation and type safety
  - Better integration with provider-specific implementations

- **Core Features Examples**: Enhanced with web search demonstration
  - Added `web_search.dart` to core features examples
  - Updated `02_core_features/README.md` with web search documentation
  - Comprehensive examples showing unified API across all supported providers
  - Step-by-step learning path including web search integration

- **Provider Examples**: Updated to use new capability factory methods
  - `elevenlabs/audio_capabilities.dart` - Now uses `buildAudio()` for type-safe audio provider building
  - `openai/image_generation.dart` - Now uses `buildImageGeneration()` for type-safe image provider building
  - Demonstrates migration from runtime type casting to compile-time type safety

### Fixed

- **Provider Capabilities**: Standardized capability interface implementations across all providers
- **Legacy Methods Cleanup**: Removed outdated capability checking methods
  - Removed `supportedCapabilitiesLegacy` (string-based capability lists)
  - Removed `supportsCapability(String)` methods across all providers
  - Unified capability checking through `ProviderCapabilities` interface

## [0.3.0] - 2025-6-10

### Changed

- **Web Platform Support**: Removed `dart:io` dependency to enable Web and WASM compatibility
  - Removed `uploadFileFromPath()` method from OpenAI Files API
  - Removed `filePath` property from `ImageInput` class for cross-platform compatibility
  - Enables WASM compatibility for future Dart Web applications
  - Use `uploadFile()` or `uploadFileFromBytes()` methods instead for cross-platform file uploads
  - Use `ImageInput.fromBytes()` or `ImageInput.fromUrl()` instead of file path-based image inputs

## [0.2.0] - 2025-6-10

### Added

- **Anthropic Files API**: Complete file management support
  - Upload, list, retrieve, and delete files
  - Support for MIME types and downloadable flags
  - Cursor-based pagination with `beforeId`, `afterId`, and `limit`
  - Convenience methods: `uploadFileFromBytes()`, `fileExists()`, `getFileContentAsString()`
  - Batch operations: `deleteFiles()`, `getTotalStorageUsed()`
  - Beta API header support (`anthropic-beta: files-api-2025-04-14`)

- **File Management API**: Cross-provider file operations
  - `FileManagementCapability` interface for consistent file operations
  - Universal `FileObject`, `FileUploadRequest`, `FileListResponse` models
  - Support for both OpenAI and Anthropic file formats with automatic conversion
  - Unified `FilePurpose` and `FileStatus` enums
  - Provider-agnostic file operations with format adaptation

- **Provider Configuration Centralization**: Extracted default configurations
  - New `ProviderDefaults` class with all provider endpoints and models
  - `OpenAICompatibleDefaults` for OpenAI-compatible provider configurations
  - Centralized capability definitions for all providers
  - Eliminated configuration duplication across factory classes

- **Unified Audio Capability Interface**: Revolutionary audio processing design
  - Single `AudioCapability` interface for all audio operations (TTS, STT, translation)
  - Feature discovery system with `supportedFeatures` property for runtime capability detection
  - `BaseAudioCapability` class providing default implementations for convenience methods
  - Support for streaming TTS, real-time audio sessions, and advanced audio features
  - Enhanced audio models with character-level timing, speaker diarization, and audio events
  - Graceful degradation with `UnsupportedError` for unsupported features
  - Cross-provider audio functionality comparison and benchmarking support

- **DALL-E Image Generation Support**: Complete OpenAI image API implementation
  - Image generation, editing, and variations with DALL-E 2/3
  - Enhanced `ImageGenerationCapability` interface with new methods
  - Support for multiple formats, sizes, and quality options

### Changed

- **All Providers**: Refactored to modular architecture
  - OpenAI, Anthropic, DeepSeek, Groq, xAI, Phind, ElevenLabs providers now use modular design
  - Consistent file structure across all providers
  - Improved separation of concerns (config, client, capabilities)
  - Better error handling and logging

- **Ollama Provider**: Enhanced implementation with full API compliance
  - Fixed temperature parameter handling (was incorrectly excluded)
  - Added complete Ollama-specific parameter support (`numCtx`, `numGpu`, `numThread`, `numa`, `numBatch`, `keepAlive`, `raw`)
  - Enhanced multimodal support with automatic base64 image conversion
  - Improved message type handling and tool calling support
  - Added LLMBuilder convenience methods for Ollama-specific parameters
  - Full compatibility with official Ollama API specification

- **Streaming Configuration**: Removed stream parameters from configs
  - Stream behavior now controlled at method call time (`chat()` vs `chatStream()`)
  - Simplified configuration classes by removing redundant stream parameters
  - More intuitive API design for streaming operations

- **Factory Classes**: Enhanced with full configuration support
  - All factory methods now support complete provider configurations
  - Removed redundant helper methods in favor of base factory functionality
  - Better parameter validation and error handling

- **Audio Capabilities**: Completely redesigned audio processing architecture
  - Replaced separate `TextToSpeechCapability` and `SpeechToTextCapability` interfaces
  - Unified all audio operations under single `AudioCapability` interface
  - Enhanced audio models with advanced features (timing, diarization, events)
  - Improved OpenAI audio support with translation capabilities
  - Enhanced ElevenLabs audio support with streaming and real-time features
  - Better error handling and feature detection for audio operations

- **Image Generation**: Enhanced OpenAI provider with complete DALL-E support
  - Extended `ImageGenerationCapability` interface with editing and variation methods
  - Updated multi-modal examples with real image generation implementations

### Removed

- **OpenAI Compatible Provider**: Removed `OpenAICompatibleProvider` class
  - Functionality replaced by convenience functions in modular implementation
  - `createDeepSeekProvider()`, `createGroqProvider()`, etc. provide same functionality
  - Simplified architecture with better performance

- **Legacy Provider Files**: Cleaned up deprecated implementations
  - Removed old provider files after modular refactoring
  - Eliminated duplicate code and inconsistent implementations
  - Streamlined provider architecture

- **Stream Configuration Parameters**: Removed from all provider configs
  - `stream` parameter removed from configuration classes
  - Streaming behavior now determined by method choice
  - Cleaner separation between configuration and runtime behavior

### Migration Guide

- **Streaming**: Update streaming usage pattern
  - Replace `config.stream = true` with direct method calls
  - Use `provider.chatStream()` instead of `provider.chat()` with stream config
  - More explicit and intuitive streaming control

- **File Management**: Use unified file API for cross-provider compatibility
  - OpenAI file operations remain unchanged
  - Anthropic now supports file operations through `FileManagementCapability`
  - Use universal file models for provider-agnostic code

- **Audio Capabilities**: Migrate to unified audio interface
  - Replace `TextToSpeechCapability` and `SpeechToTextCapability` checks with `AudioCapability`
  - Use `provider.supportedFeatures.contains(AudioFeature.textToSpeech)` for feature detection
  - Audio translation now available through `translateAudio()` method (OpenAI only)
  - Enhanced audio models support advanced features like character timing and speaker diarization
  - Convenience methods (`speech()`, `transcribe()`, `translate()`) automatically available

- **Image Generation**: Enhanced capabilities with new features
  - New `editImage()` and `createVariation()` methods available for DALL-E 2
  - Use `provider.supportsImageEditing` and `provider.supportsImageVariations` for feature detection

## [0.1.2] - 2025-6-8

### Fixed

- **Package Configuration**: Updated pubspec.yaml repository URLs
  - Fixed homepage, repository, and issue_tracker URLs to point to correct standalone repository
  - Ensures proper package metadata on pub.dev for the independent library

## [0.1.1] - 2025-6-8

### Changed

- **Documentation**: Updated README.md to reflect standalone library status
  - Added pub.dev package badge and link (<https://pub.dev/packages/llm_dart>)
  - Simplified installation instructions (removed unnecessary dio dependency mention)

## [0.1.0] - 2025-6-8

### Added

- Initial release of LLM Dart library
- Multi-provider support for AI interactions
- Unified interface for OpenAI, Anthropic, Google, DeepSeek, Ollama, xAI, Phind, Groq, and ElevenLabs
- Builder pattern API for easy configuration
- Streaming support for real-time responses
- Tool calling capabilities for function execution
- Structured output with JSON schema support
- Comprehensive error handling with specific error types
- Provider registry system for extensibility
- Capability-based design for type safety

#### Supported Providers

- **OpenAI**: GPT models with reasoning support
- **Anthropic**: Claude models with thinking capabilities
- **Google**: Gemini models
- **DeepSeek**: DeepSeek reasoning models
- **Ollama**: Local model support
- **xAI**: Grok models
- **Phind**: Phind models
- **Groq**: Fast inference
- **ElevenLabs**: Text-to-Speech and Speech-to-Text

#### Features

- Chat completion with multiple providers
- Real-time streaming responses
- Function/tool calling
- Structured JSON output
- Provider-specific extensions
- Custom provider registration
- Comprehensive examples and documentation

#### Examples

- Basic usage examples for all providers
- Streaming examples
- Tool calling examples
- Custom provider implementation
- Advanced configuration examples
- ElevenLabs TTS/STT examples

### Technical Details

- Built with Dart 3.0+ support
- Flutter 3.8+ compatibility
- Uses Dio for HTTP requests
- Comprehensive error handling
- Type-safe interfaces
- Modular architecture

### Documentation

- Complete API documentation
- Extensive examples directory
- Setup and configuration guides
- Best practices documentation
- Provider-specific guides

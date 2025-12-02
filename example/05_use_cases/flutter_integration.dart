import 'dart:async';
import 'package:llm_dart/llm_dart.dart';

/// Flutter integration examples for LLM Dart library
///
/// This example demonstrates:
/// - State management with AI providers
/// - Async operations in Flutter widgets
/// - Error handling in UI context
/// - Streaming responses in real-time UI
/// - Background processing
/// - Caching and performance optimization
///
/// Note: This is a conceptual example showing integration patterns.
/// In a real Flutter app, you would use actual Flutter widgets and state management.

/// Main Flutter app integration example
Future<void> main() async {
  print('📱 Flutter Integration Examples\n');

  // Simulate Flutter app initialization
  await demonstrateFlutterIntegration();

  print('✅ Flutter integration examples completed!');
  print('💡 Integration tips:');
  print('   • Use FutureBuilder for async AI operations');
  print('   • Implement proper error boundaries');
  print('   • Cache responses for better UX');
  print('   • Use StreamBuilder for real-time responses');
}

/// Demonstrate Flutter integration patterns
Future<void> demonstrateFlutterIntegration() async {
  print('🔧 Flutter Integration Patterns:\n');

  // Initialize AI service
  final aiService = AIService();
  await aiService.initialize();

  // Demonstrate different integration scenarios
  await demonstrateChatInterface(aiService);
  await demonstrateImageGeneration(aiService);
  await demonstrateVoiceAssistant(aiService);
  await demonstrateBackgroundProcessing(aiService);
  await demonstrateStateManagement(aiService);
}

/// Demonstrate chat interface integration
Future<void> demonstrateChatInterface(AIService aiService) async {
  print('💬 Chat Interface Integration:');

  // Simulate chat controller
  final chatController = ChatController(aiService);

  print('   🔄 Initializing chat...');
  await chatController.initialize();

  // Simulate user messages
  final userMessages = [
    'Hello, how are you?',
    'Can you help me with Flutter development?',
    'What are the best practices for state management?',
  ];

  for (final message in userMessages) {
    print('   👤 User: $message');

    try {
      // Simulate sending message and getting response
      final response = await chatController.sendMessage(message);
      print('   🤖 AI: ${response.substring(0, 60)}...');

      // Simulate typing indicator
      print('   ⏳ Typing indicator shown during response');
    } catch (e) {
      print('   ❌ Error: $e');
      // In Flutter, you would show error snackbar or dialog
    }
  }

  print('   📊 Chat stats: ${chatController.messageCount} messages');
  print('');
}

/// Demonstrate image generation integration
Future<void> demonstrateImageGeneration(AIService aiService) async {
  print('🎨 Image Generation Integration:');

  final imageController = ImageGenerationController(aiService);

  print('   🔄 Setting up image generation...');

  final prompts = [
    'A beautiful sunset over mountains',
    'A futuristic city with flying cars',
    'A cute robot helping with coding',
  ];

  for (final prompt in prompts) {
    print('   🎨 Generating: "$prompt"');

    try {
      // Simulate image generation with progress
      await imageController.generateImage(
        prompt,
        onProgress: (progress) {
          print('      📈 Progress: ${(progress * 100).toInt()}%');
        },
      );

      print('   ✅ Image generated successfully');
    } catch (e) {
      print('   ❌ Generation failed: $e');
    }
  }

  print('');
}

/// Demonstrate voice assistant integration
Future<void> demonstrateVoiceAssistant(AIService aiService) async {
  print('🎤 Voice Assistant Integration:');

  final voiceController = VoiceAssistantController(aiService);

  print('   🔄 Initializing voice assistant...');
  await voiceController.initialize();

  // Simulate voice interactions
  final voiceCommands = [
    'What\'s the weather like today?',
    'Set a reminder for my meeting',
    'Play some relaxing music',
  ];

  for (final command in voiceCommands) {
    print('   🗣️  Voice command: "$command"');

    try {
      // Simulate voice processing
      await voiceController.processVoiceCommand(command);
      print('   🔊 Voice response played');
    } catch (e) {
      print('   ❌ Voice processing failed: $e');
    }
  }

  print('');
}

/// Demonstrate background processing
Future<void> demonstrateBackgroundProcessing(AIService aiService) async {
  print('⚙️ Background Processing:');

  final backgroundProcessor = BackgroundProcessor(aiService);

  print('   🔄 Starting background tasks...');

  // Simulate background tasks
  final tasks = [
    BackgroundTask('document_analysis', 'Analyzing uploaded documents'),
    BackgroundTask('content_generation', 'Generating blog content'),
    BackgroundTask('data_processing', 'Processing user data'),
  ];

  for (final task in tasks) {
    print('   📋 Task: ${task.description}');

    try {
      await backgroundProcessor.processTask(task);
      print('   ✅ Task completed');
    } catch (e) {
      print('   ❌ Task failed: $e');
    }
  }

  print('');
}

/// Demonstrate state management patterns
Future<void> demonstrateStateManagement(AIService aiService) async {
  print('📊 State Management Patterns:');

  // Simulate different state management approaches
  await demonstrateProviderPattern(aiService);
  await demonstrateBlocPattern(aiService);
  await demonstrateRiverpodPattern(aiService);

  print('');
}

/// Provider pattern example
Future<void> demonstrateProviderPattern(AIService aiService) async {
  print('   🔄 Provider Pattern:');

  // Simulate Provider-based state management
  final aiProvider = AIProvider(aiService);
  aiProvider.notifyListeners(); // Use the provider

  print('      📱 Widget tree with Provider');
  print('      🔄 State updates automatically propagated');
  print('      ✅ Clean separation of concerns');
}

/// BLoC pattern example
Future<void> demonstrateBlocPattern(AIService aiService) async {
  print('   🧱 BLoC Pattern:');

  // Simulate BLoC-based state management
  final aiBloc = AIBloc(aiService);
  print('      🧱 BLoC initialized: ${aiBloc.runtimeType}');

  print('      📨 Events trigger state changes');
  print('      🔄 Reactive state management');
  print('      ✅ Testable business logic');
}

/// Riverpod pattern example
Future<void> demonstrateRiverpodPattern(AIService aiService) async {
  print('   🎣 Riverpod Pattern:');

  // Simulate Riverpod-based state management
  final aiNotifier = AINotifier(aiService);
  print('      🎣 Notifier initialized: ${aiNotifier.runtimeType}');

  print('      🔗 Provider dependencies');
  print('      🔄 Automatic disposal');
  print('      ✅ Compile-time safety');
}

// Service classes for Flutter integration

/// Main AI service for Flutter integration
class AIService {
  ChatCapability? _chatProvider;
  LanguageModel? _chatModel;
  ImageGenerationCapability? _imageProvider;
  AudioCapability? _audioProvider;

  bool _isInitialized = false;

  /// Initialize AI providers
  Future<void> initialize() async {
    try {
      // Initialize chat provider and language model
      final builder =
          ai().openai().apiKey('your-api-key').model('gpt-3.5-turbo');

      // Validate configuration and API key by building the provider
      _chatProvider = await builder.build();
      _chatModel = await builder.buildLanguageModel();

      // Initialize image provider (if available)
      if (_chatProvider is ImageGenerationCapability) {
        _imageProvider = _chatProvider as ImageGenerationCapability;
      }

      // Initialize audio provider (if available)
      if (_chatProvider is AudioCapability) {
        _audioProvider = _chatProvider as AudioCapability;
      }

      _isInitialized = true;
      print('✅ AI Service initialized');
    } catch (e) {
      print('❌ AI Service initialization failed: $e');
      throw AIServiceException('Failed to initialize AI service: $e');
    }
  }

  /// Get chat provider
  ChatCapability get chatProvider {
    if (!_isInitialized || _chatProvider == null) {
      throw AIServiceException('Chat provider not initialized');
    }
    return _chatProvider!;
  }

  /// Get language model for prompt-first chat.
  LanguageModel get chatModel {
    if (!_isInitialized || _chatModel == null) {
      throw AIServiceException('Chat model not initialized');
    }
    return _chatModel!;
  }

  /// Get image provider
  ImageGenerationCapability? get imageProvider => _imageProvider;

  /// Get audio provider
  AudioCapability? get audioProvider => _audioProvider;

  /// Check if service is ready
  bool get isReady => _isInitialized;
}

/// Chat controller for Flutter UI
class ChatController {
  final AIService _aiService;
  final List<ModelMessage> _messages = [];
  final StreamController<ModelMessage> _messageController =
      StreamController.broadcast();

  ChatController(this._aiService);

  /// Initialize chat controller
  Future<void> initialize() async {
    if (!_aiService.isReady) {
      throw ChatException('AI service not ready');
    }
  }

  /// Send message and get response
  Future<String> sendMessage(String content) async {
    try {
      // Add user message
      final userMessage = ChatPromptBuilder.user().text(content).build();
      _messages.add(userMessage);
      _messageController.add(userMessage);

      // Get AI response
      final result = await generateTextWithModel(
        _aiService.chatModel,
        promptMessages: _messages,
      );

      // Add AI response
      if (result.text != null && result.text!.isNotEmpty) {
        final aiMessage =
            ChatPromptBuilder.assistant().text(result.text!).build();
        _messages.add(aiMessage);
        _messageController.add(aiMessage);

        return result.text!;
      } else {
        throw ChatException('No response from AI');
      }
    } catch (e) {
      throw ChatException('Failed to send message: $e');
    }
  }

  /// Get message stream for UI updates
  Stream<ModelMessage> get messageStream => _messageController.stream;

  /// Get message count
  int get messageCount => _messages.length;

  /// Clear chat history
  void clearHistory() {
    _messages.clear();
  }

  /// Dispose resources
  void dispose() {
    _messageController.close();
  }
}

/// Image generation controller
class ImageGenerationController {
  final AIService _aiService;

  ImageGenerationController(this._aiService);

  /// Generate image with progress callback
  Future<void> generateImage(
    String prompt, {
    Function(double)? onProgress,
  }) async {
    final imageProvider = _aiService.imageProvider;
    if (imageProvider == null) {
      throw ImageGenerationException('Image generation not available');
    }

    try {
      // Simulate progress updates
      onProgress?.call(0.1);
      await Future.delayed(Duration(milliseconds: 500));

      onProgress?.call(0.5);
      await Future.delayed(Duration(milliseconds: 500));

      // Generate image
      final response = await imageProvider.generateImages(
        ImageGenerationRequest(prompt: prompt),
      );

      onProgress?.call(1.0);

      if (response.images.isEmpty) {
        throw ImageGenerationException('No images generated');
      }
    } catch (e) {
      throw ImageGenerationException('Failed to generate image: $e');
    }
  }
}

/// Voice assistant controller
class VoiceAssistantController {
  final AIService _aiService;
  bool _isListening = false;

  VoiceAssistantController(this._aiService);

  /// Initialize voice assistant
  Future<void> initialize() async {
    final audioProvider = _aiService.audioProvider;
    if (audioProvider == null) {
      throw VoiceException('Audio capabilities not available');
    }
  }

  /// Process voice command
  Future<void> processVoiceCommand(String command) async {
    try {
      // Convert speech to text (simulated)
      print('      🎤 Processing voice input...');

      // Get text response from AI
      final result = await generateTextWithModel(
        _aiService.chatModel,
        promptMessages: [
          ChatPromptBuilder.user().text(command).build(),
        ],
      );

      // Convert response to speech (simulated)
      if (result.text != null && result.text!.isNotEmpty) {
        print('      🔊 Converting to speech...');
        // In real implementation, use TTS
      }
    } catch (e) {
      throw VoiceException('Failed to process voice command: $e');
    }
  }

  /// Start listening
  void startListening() {
    _isListening = true;
  }

  /// Stop listening
  void stopListening() {
    _isListening = false;
  }

  /// Check if listening
  bool get isListening => _isListening;
}

/// Background processor for long-running tasks
class BackgroundProcessor {
  final AIService _aiService;

  BackgroundProcessor(this._aiService);

  /// Process background task
  Future<void> processTask(BackgroundTask task) async {
    try {
      print('      🔄 Processing ${task.id}...');

      // Simulate background processing
      await Future.delayed(Duration(milliseconds: 1000));

      // Use AI service for processing
      switch (task.id) {
        case 'document_analysis':
          await _processDocumentAnalysis();
          break;
        case 'content_generation':
          await _processContentGeneration();
          break;
        case 'data_processing':
          await _processDataProcessing();
          break;
      }
    } catch (e) {
      throw BackgroundProcessingException('Task ${task.id} failed: $e');
    }
  }

  Future<void> _processDocumentAnalysis() async {
    // Simulate document analysis using AI service
    if (_aiService.isReady) {
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  Future<void> _processContentGeneration() async {
    // Simulate content generation using AI service
    if (_aiService.isReady) {
      await Future.delayed(Duration(milliseconds: 800));
    }
  }

  Future<void> _processDataProcessing() async {
    // Simulate data processing using AI service
    if (_aiService.isReady) {
      await Future.delayed(Duration(milliseconds: 600));
    }
  }
}

// State management examples

/// Provider pattern implementation
class AIProvider {
  final AIService _aiService;

  AIProvider(this._aiService);

  // In real Flutter app, this would extend ChangeNotifier
  void notifyListeners() {
    // Notify UI of state changes
  }

  /// Get AI service status
  bool get isReady => _aiService.isReady;
}

/// BLoC pattern implementation
class AIBloc {
  final AIService _aiService;

  AIBloc(this._aiService);

  // In real Flutter app, this would extend Bloc<AIEvent, AIState>

  /// Get AI service status
  bool get isReady => _aiService.isReady;
}

/// Riverpod pattern implementation
class AINotifier {
  final AIService _aiService;

  AINotifier(this._aiService);

  // In real Flutter app, this would extend StateNotifier<AIState>

  /// Get AI service status
  bool get isReady => _aiService.isReady;
}

// Data classes

/// Background task definition
class BackgroundTask {
  final String id;
  final String description;

  BackgroundTask(this.id, this.description);
}

// Exception classes

class AIServiceException implements Exception {
  final String message;
  AIServiceException(this.message);
  @override
  String toString() => 'AIServiceException: $message';
}

class ChatException implements Exception {
  final String message;
  ChatException(this.message);
  @override
  String toString() => 'ChatException: $message';
}

class ImageGenerationException implements Exception {
  final String message;
  ImageGenerationException(this.message);
  @override
  String toString() => 'ImageGenerationException: $message';
}

class VoiceException implements Exception {
  final String message;
  VoiceException(this.message);
  @override
  String toString() => 'VoiceException: $message';
}

class BackgroundProcessingException implements Exception {
  final String message;
  BackgroundProcessingException(this.message);
  @override
  String toString() => 'BackgroundProcessingException: $message';
}

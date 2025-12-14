// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';
import 'package:llm_dart/llm_dart.dart';

/// 🌐 Web Service Integration - HTTP API with AI
///
/// This example demonstrates how to integrate LLM Dart into a web service:
/// - REST API endpoints with AI functionality
/// - Request/response handling and validation
/// - Authentication and rate limiting
/// - Error handling and monitoring
///
/// Before running, set your API key:
/// export OPENAI_API_KEY="your-key"
/// export GROQ_API_KEY="your-key"
///
/// Usage:
/// dart run web_service.dart
///
/// Then test with:
/// curl -X POST http://localhost:8080/api/chat \
///   -H "Content-Type: application/json" \
///   -H "Authorization: Bearer your-api-key" \
///   -d '{"message": "Hello, how are you?"}'
void main() async {
  print('🌐 Web Service Integration - HTTP API with AI\n');

  final service = AIWebService();
  await service.start();
}

/// AI-powered web service
class AIWebService {
  late HttpServer _server;
  late LanguageModel _model;
  final Map<String, int> _rateLimits = {}; // Simple rate limiting
  final List<String> _validApiKeys = [
    'demo-key-123',
    'test-key-456'
  ]; // Demo keys

  /// Start the web service
  Future<void> start() async {
    try {
      // Initialize AI provider
      await _initializeAI();

      // Start HTTP server
      _server = await HttpServer.bind('localhost', 8080);
      print('🚀 AI Web Service started on http://localhost:8080');
      print('📖 Available endpoints:');
      print('   POST /api/chat - Chat with AI');
      print('   POST /api/generate - Generate content');
      print('   GET /api/health - Health check');
      print('   GET /api/models - List available models');
      print('\n💡 Test with:');
      print('   curl -X POST http://localhost:8080/api/chat \\');
      print('     -H "Content-Type: application/json" \\');
      print('     -H "Authorization: Bearer demo-key-123" \\');
      print('     -d \'{"message": "Hello, how are you?"}\'');
      print('\n🛑 Press Ctrl+C to stop the server\n');

      // Handle requests
      await for (final request in _server) {
        _handleRequest(request);
      }
    } catch (e) {
      print('❌ Failed to start web service: $e');
    }
  }

  /// Initialize AI provider
  Future<void> _initializeAI() async {
    final apiKey = Platform.environment['GROQ_API_KEY'] ?? 'gsk-TESTKEY';

    _model = await ai()
        .groq()
        .apiKey(apiKey)
        .model('llama-3.1-8b-instant')
        .temperature(0.7)
        .maxTokens(500)
        .buildLanguageModel();

    print('✅ AI model initialized');
  }

  /// Build system prompt string for a given content generation type.
  String _buildSystemPromptForType(String type) {
    switch (type) {
      case 'blog':
        return 'You are a professional blog writer. Create engaging, well-structured content.';
      case 'email':
        return 'You are a professional email writer. Create clear, concise, and appropriate emails.';
      case 'code':
        return 'You are a senior software developer. Write clean, well-documented code.';
      default:
        return 'You are a helpful content generator. Create high-quality content.';
    }
  }

  /// Build a prompt-first ModelMessage conversation from simple inputs.
  ///
  /// This demonstrates the recommended [ModelMessage] /
  /// [ChatPromptBuilder] pattern for constructing prompts.
  List<ModelMessage> _buildPromptMessages({
    String? systemPrompt,
    required String userMessage,
  }) {
    final messages = <ModelMessage>[];

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add(
        ChatPromptBuilder.system().text(systemPrompt).build(),
      );
    }

    messages.add(
      ChatPromptBuilder.user().text(userMessage).build(),
    );

    return messages;
  }

  /// Handle incoming HTTP requests
  Future<void> _handleRequest(HttpRequest request) async {
    try {
      // Add CORS headers
      _addCorsHeaders(request.response);

      // Handle preflight requests
      if (request.method == 'OPTIONS') {
        request.response.statusCode = 200;
        await request.response.close();
        return;
      }

      // Route requests
      switch (request.uri.path) {
        case '/api/chat':
          await _handleChatRequest(request);
          break;
        case '/api/generate':
          await _handleGenerateRequest(request);
          break;
        case '/api/health':
          await _handleHealthRequest(request);
          break;
        case '/api/models':
          await _handleModelsRequest(request);
          break;
        default:
          await _handleNotFound(request);
      }
    } catch (e) {
      await _handleError(request, e);
    }
  }

  /// Handle chat requests
  Future<void> _handleChatRequest(HttpRequest request) async {
    if (request.method != 'POST') {
      await _sendError(request.response, 405, 'Method not allowed');
      return;
    }

    // Authentication
    if (!await _authenticate(request)) {
      await _sendError(request.response, 401, 'Unauthorized');
      return;
    }

    // Rate limiting
    if (!await _checkRateLimit(request)) {
      await _sendError(request.response, 429, 'Rate limit exceeded');
      return;
    }

    try {
      // Parse request body
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (!data.containsKey('message')) {
        await _sendError(request.response, 400, 'Missing message field');
        return;
      }

      final message = data['message'] as String;
      final systemPrompt = data['system'] as String?;

      print(
          '📨 Chat request: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');

      // Build messages using prompt-first modeling (ModelMessage)
      final messages = _buildPromptMessages(
        systemPrompt: systemPrompt,
        userMessage: message,
      );

      // Get AI response
      final stopwatch = Stopwatch()..start();
      final result = await generateTextPromptWithModel(
        _model,
        messages: messages,
      );
      stopwatch.stop();

      // Send response
      final responseData = {
        'response': result.text,
        'model': _model.modelId,
        'response_time_ms': stopwatch.elapsedMilliseconds,
        'usage': result.usage != null
            ? {
                'prompt_tokens': result.usage!.promptTokens,
                'completion_tokens': result.usage!.completionTokens,
                'total_tokens': result.usage!.totalTokens,
              }
            : null,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _sendJson(request.response, responseData);
      print('✅ Chat response sent (${stopwatch.elapsedMilliseconds}ms)');
    } catch (e) {
      await _sendError(request.response, 500, 'AI processing error: $e');
    }
  }

  /// Handle content generation requests
  Future<void> _handleGenerateRequest(HttpRequest request) async {
    if (request.method != 'POST') {
      await _sendError(request.response, 405, 'Method not allowed');
      return;
    }

    if (!await _authenticate(request)) {
      await _sendError(request.response, 401, 'Unauthorized');
      return;
    }

    if (!await _checkRateLimit(request)) {
      await _sendError(request.response, 429, 'Rate limit exceeded');
      return;
    }

    try {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (!data.containsKey('prompt')) {
        await _sendError(request.response, 400, 'Missing prompt field');
        return;
      }

      final prompt = data['prompt'] as String;
      final type = data['type'] as String? ?? 'general';

      print('📝 Generate request: $type');

      // Build system prompt based on type
      final systemPrompt = _buildSystemPromptForType(type);

      final messages = _buildPromptMessages(
        systemPrompt: systemPrompt,
        userMessage: prompt,
      );

      final stopwatch = Stopwatch()..start();
      final response = await generateTextPromptWithModel(
        _model,
        messages: messages,
      );
      stopwatch.stop();

      final responseData = {
        'content': response.text,
        'type': type,
        'model': _model.modelId,
        'response_time_ms': stopwatch.elapsedMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _sendJson(request.response, responseData);
      print('✅ Content generated (${stopwatch.elapsedMilliseconds}ms)');
    } catch (e) {
      await _sendError(request.response, 500, 'Generation error: $e');
    }
  }

  /// Handle health check requests
  Future<void> _handleHealthRequest(HttpRequest request) async {
    if (request.method != 'GET') {
      await _sendError(request.response, 405, 'Method not allowed');
      return;
    }

    try {
      // Test AI model with a simple prompt-first call
      final testResult = await generateTextPromptWithModel(
        _model,
        messages: [
          ModelMessage.userText('Health check - respond with OK'),
        ],
      );

      final healthData = {
        'status': 'healthy',
        'ai_provider': 'groq',
        'model': _model.modelId,
        'ai_responsive': testResult.text != null,
        'timestamp': DateTime.now().toIso8601String(),
        'uptime_seconds': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      await _sendJson(request.response, healthData);
    } catch (e) {
      final healthData = {
        'status': 'unhealthy',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      request.response.statusCode = 503;
      await _sendJson(request.response, healthData);
    }
  }

  /// Handle models list request
  Future<void> _handleModelsRequest(HttpRequest request) async {
    if (request.method != 'GET') {
      await _sendError(request.response, 405, 'Method not allowed');
      return;
    }

    final modelsData = {
      'models': [
        {
          'id': 'llama-3.1-8b-instant',
          'provider': 'groq',
          'description': 'Fast general-purpose model',
          'max_tokens': 8192,
        },
        {
          'id': 'llama-3.1-70b-versatile',
          'provider': 'groq',
          'description': 'High-quality versatile model',
          'max_tokens': 8192,
        },
      ],
      'current_model': 'llama-3.1-8b-instant',
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _sendJson(request.response, modelsData);
  }

  /// Handle 404 not found
  Future<void> _handleNotFound(HttpRequest request) async {
    await _sendError(request.response, 404, 'Endpoint not found');
  }

  /// Handle errors
  Future<void> _handleError(HttpRequest request, dynamic error) async {
    print('❌ Request error: $error');
    await _sendError(request.response, 500, 'Internal server error');
  }

  /// Authenticate request
  Future<bool> _authenticate(HttpRequest request) async {
    final authHeader = request.headers.value('authorization');
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return false;
    }

    final token = authHeader.substring(7);
    return _validApiKeys.contains(token);
  }

  /// Check rate limiting
  Future<bool> _checkRateLimit(HttpRequest request) async {
    final clientIp = request.connectionInfo?.remoteAddress.address ?? 'unknown';

    // Simple rate limiting: 10 requests per minute per IP
    _rateLimits[clientIp] = (_rateLimits[clientIp] ?? 0) + 1;

    // Reset counter if window expired (simplified)
    if (_rateLimits[clientIp]! > 10) {
      return false;
    }

    return true;
  }

  /// Add CORS headers
  void _addCorsHeaders(HttpResponse response) {
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.headers
        .add('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  }

  /// Send JSON response
  Future<void> _sendJson(
      HttpResponse response, Map<String, dynamic> data) async {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(data));
    await response.close();
  }

  /// Send error response
  Future<void> _sendError(
      HttpResponse response, int statusCode, String message) async {
    response.statusCode = statusCode;
    await _sendJson(response, {
      'error': message,
      'status_code': statusCode,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Stop the web service
  Future<void> stop() async {
    await _server.close();
    print('🛑 Web service stopped');
  }
}

/// 🎯 Key Web Service Integration Concepts Summary:
///
/// API Design:
/// - RESTful endpoints for different AI functions
/// - Consistent request/response formats
/// - Proper HTTP status codes
/// - CORS support for web clients
///
/// Authentication & Security:
/// - Bearer token authentication
/// - API key validation
/// - Rate limiting per client
/// - Input validation and sanitization
///
/// Error Handling:
/// - Graceful error responses
/// - Proper HTTP status codes
/// - Detailed error messages
/// - Logging for debugging
///
/// Performance:
/// - Response time tracking
/// - Usage statistics
/// - Health check endpoints
/// - Efficient request processing
///
/// Production Considerations:
/// - Environment-based configuration
/// - Proper logging and monitoring
/// - Rate limiting and throttling
/// - Scalability and load balancing
///
/// Best Practices:
/// 1. Use proper HTTP methods and status codes
/// 2. Implement authentication and authorization
/// 3. Add rate limiting to prevent abuse
/// 4. Validate all input data
/// 5. Provide comprehensive error messages
/// 6. Monitor performance and usage
///
/// Next Steps:
/// - Add database integration for conversation history
/// - Implement more sophisticated authentication
/// - Add request/response logging
/// - Create client SDKs for different languages
/// - Add WebSocket support for real-time streaming

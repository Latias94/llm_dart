// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

/// Web service example using the stable model API.
Future<void> main() async {
  print('🌐 Web Service Integration - HTTP API with AI\n');

  final service = AIWebService();
  await service.start();
}

class AIWebService {
  late HttpServer _server;
  late core.LanguageModel _model;
  final Map<String, int> _rateLimits = {};
  final List<String> _validApiKeys = ['demo-key-123', 'test-key-456'];

  Future<void> start() async {
    try {
      await _initializeAI();

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

      await for (final request in _server) {
        _handleRequest(request);
      }
    } catch (error) {
      print('❌ Failed to start web service: $error');
    }
  }

  Future<void> _initializeAI() async {
    final groqKey = Platform.environment['GROQ_API_KEY'];
    if (groqKey != null && groqKey.isNotEmpty) {
      _model = openai
          .groq(
            apiKey: groqKey,
          )
          .chatModel('llama-3.3-70b-versatile');
    } else {
      final openaiKey = Platform.environment['OPENAI_API_KEY'];
      if (openaiKey == null || openaiKey.isEmpty) {
        throw StateError(
          'Set GROQ_API_KEY or OPENAI_API_KEY to run this example.',
        );
      }

      _model = openai
          .openai(
            apiKey: openaiKey,
          )
          .chatModel('gpt-4.1-mini');
    }

    print('✅ AI model initialized (${_model.providerId}/${_model.modelId})');
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      _addCorsHeaders(request.response);

      if (request.method == 'OPTIONS') {
        request.response.statusCode = 200;
        await request.response.close();
        return;
      }

      switch (request.uri.path) {
        case '/api/chat':
          await _handleChatRequest(request);
        case '/api/generate':
          await _handleGenerateRequest(request);
        case '/api/health':
          await _handleHealthRequest(request);
        case '/api/models':
          await _handleModelsRequest(request);
        default:
          await _handleNotFound(request);
      }
    } catch (error) {
      await _handleError(request, error);
    }
  }

  Future<void> _handleChatRequest(HttpRequest request) async {
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

      if (!data.containsKey('message')) {
        await _sendError(request.response, 400, 'Missing message field');
        return;
      }

      final message = data['message'] as String;
      final systemPrompt = data['system'] as String?;

      print(
        '📨 Chat request: ${message.substring(0, message.length > 50 ? 50 : message.length)}...',
      );

      final messages = <core.ModelMessage>[
        if (systemPrompt != null) core.SystemModelMessage.text(systemPrompt),
        core.UserModelMessage.text(message),
      ];

      final stopwatch = Stopwatch()..start();
      final result = await _generate(
        messages,
        maxOutputTokens: 500,
      );
      stopwatch.stop();

      final responseData = {
        'response': result.text,
        'model': _model.modelId,
        'provider': _model.providerId,
        'response_time_ms': stopwatch.elapsedMilliseconds,
        'usage': result.usage != null
            ? {
                'input_tokens': result.usage!.inputTokens,
                'output_tokens': result.usage!.outputTokens,
                'total_tokens': result.usage!.totalTokens,
              }
            : null,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _sendJson(request.response, responseData);
      print('✅ Chat response sent (${stopwatch.elapsedMilliseconds}ms)');
    } catch (error) {
      await _sendError(request.response, 500, 'AI processing error: $error');
    }
  }

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

      final result = await _generate(
        [
          core.SystemModelMessage.text(_contentSystemPrompt(type)),
          core.UserModelMessage.text(prompt),
        ],
        maxOutputTokens: 800,
      );

      final responseData = {
        'content': result.text,
        'type': type,
        'provider': _model.providerId,
        'model': _model.modelId,
        'usage': result.usage != null
            ? {
                'input_tokens': result.usage!.inputTokens,
                'output_tokens': result.usage!.outputTokens,
                'total_tokens': result.usage!.totalTokens,
              }
            : null,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _sendJson(request.response, responseData);
      print('✅ Content generated');
    } catch (error) {
      await _sendError(request.response, 500, 'Generation error: $error');
    }
  }

  Future<void> _handleHealthRequest(HttpRequest request) async {
    if (request.method != 'GET') {
      await _sendError(request.response, 405, 'Method not allowed');
      return;
    }

    try {
      final result = await _generate(
        [
          core.UserModelMessage.text('Health check - respond with OK'),
        ],
        maxOutputTokens: 12,
      );

      final healthData = {
        'status': 'healthy',
        'ai_provider': _model.providerId,
        'model': _model.modelId,
        'ai_responsive': result.text.isNotEmpty,
        'timestamp': DateTime.now().toIso8601String(),
        'uptime_seconds': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      await _sendJson(request.response, healthData);
    } catch (error) {
      request.response.statusCode = 503;
      await _sendJson(request.response, {
        'status': 'unhealthy',
        'error': error.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _handleModelsRequest(HttpRequest request) async {
    if (request.method != 'GET') {
      await _sendError(request.response, 405, 'Method not allowed');
      return;
    }

    final modelsData = {
      'configured_model': {
        'id': _model.modelId,
        'provider': _model.providerId,
      },
      'recommended_models': [
        {
          'id': 'gpt-4.1-mini',
          'provider': 'openai',
          'description': 'Balanced general-purpose model',
        },
        {
          'id': 'llama-3.3-70b-versatile',
          'provider': 'groq',
          'description': 'Fast model for API-backed text generation',
        },
        {
          'id': 'claude-sonnet-4-5',
          'provider': 'anthropic',
          'description': 'Strong reasoning and instruction following',
        },
      ],
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _sendJson(request.response, modelsData);
  }

  Future<core.GenerateTextCallResult<Object?>> _generate(
    List<core.ModelMessage> messages, {
    required int maxOutputTokens,
  }) {
    return core.generateTextCall(
      model: _model,
      messages: messages,
      options: core.GenerateTextOptions(
        temperature: 0.7,
        maxOutputTokens: maxOutputTokens,
      ),
    );
  }

  String _contentSystemPrompt(String type) {
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

  Future<void> _handleNotFound(HttpRequest request) async {
    await _sendError(request.response, 404, 'Endpoint not found');
  }

  Future<void> _handleError(HttpRequest request, Object error) async {
    print('❌ Request error: $error');
    await _sendError(request.response, 500, 'Internal server error');
  }

  Future<bool> _authenticate(HttpRequest request) async {
    final authHeader = request.headers.value('authorization');
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return false;
    }

    final token = authHeader.substring(7);
    return _validApiKeys.contains(token);
  }

  Future<bool> _checkRateLimit(HttpRequest request) async {
    final clientIp = request.connectionInfo?.remoteAddress.address ?? 'unknown';
    _rateLimits[clientIp] = (_rateLimits[clientIp] ?? 0) + 1;
    if (_rateLimits[clientIp]! > 10) {
      return false;
    }

    return true;
  }

  void _addCorsHeaders(HttpResponse response) {
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.headers
        .add('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  }

  Future<void> _sendJson(
      HttpResponse response, Map<String, dynamic> data) async {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(data));
    await response.close();
  }

  Future<void> _sendError(
    HttpResponse response,
    int statusCode,
    String message,
  ) async {
    response.statusCode = statusCode;
    await _sendJson(response, {
      'error': message,
      'status_code': statusCode,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> stop() async {
    await _server.close();
    print('🛑 Web service stopped');
  }
}

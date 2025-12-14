import 'dart:async';
import 'dart:math';
import 'package:llm_dart/llm_dart.dart';

/// Real-time audio processing examples using AudioCapability
///
/// This example demonstrates:
/// - Real-time audio streaming
/// - Voice activity detection
/// - Continuous conversation flows
/// - Audio preprocessing and enhancement
/// - Low-latency audio processing
/// - Multi-modal audio interactions
/// - Session management and reconnection
Future<void> main() async {
  print('🎤 Real-time Audio Processing Examples\n');

  // Initialize audio provider
  final audioProvider = await initializeAudioProvider();
  if (audioProvider == null) {
    print('❌ No audio provider available for real-time processing');
    return;
  }

  // Check real-time capabilities
  if (!audioProvider.supportedFeatures
      .contains(AudioFeature.realtimeProcessing)) {
    print('⚠️  Provider does not support real-time audio processing');
    return;
  }

  print('🚀 Starting Real-time Audio Examples...\n');

  // Demonstrate different real-time scenarios
  await demonstrateBasicRealtimeSession(audioProvider);
  await demonstrateVoiceActivityDetection(audioProvider);
  await demonstrateContinuousConversation(audioProvider);
  await demonstrateAudioPreprocessing(audioProvider);
  await demonstrateMultiModalInteraction(audioProvider);
  await demonstrateSessionManagement(audioProvider);

  print('✅ Real-time audio examples completed!');
  print('💡 Real-time audio best practices:');
  print('   • Use appropriate buffer sizes for your latency requirements');
  print('   • Implement proper voice activity detection');
  print('   • Handle network interruptions gracefully');
  print('   • Optimize for your target platform\'s audio capabilities');
}

/// Initialize audio provider for real-time processing
Future<AudioCapability?> initializeAudioProvider() async {
  // Try providers that support real-time audio
  final providers = [
    (
      'OpenAI',
      () async {
        return await ai().openai().apiKey('your-openai-key').buildAudio();
      }
    ),
    (
      'ElevenLabs',
      () async {
        return await ai()
            .elevenlabs()
            .apiKey('your-elevenlabs-key')
            .buildAudio();
      }
    ),
  ];

  for (final (name, factory) in providers) {
    try {
      final provider = await factory();
      print('✅ Using $name for real-time audio');
      return provider;
    } catch (e) {
      print('⚠️  $name not available: $e');
    }
  }

  return null;
}

/// Demonstrate basic real-time audio session
Future<void> demonstrateBasicRealtimeSession(AudioCapability provider) async {
  print('🎙️ Basic Real-time Session:');

  try {
    // Configure real-time session
    final config = RealtimeAudioConfig(
      inputFormat: 'pcm16',
      outputFormat: 'pcm16',
      sampleRate: 16000,
      enableVAD: true,
      enableEchoCancellation: true,
      enableNoiseSuppression: true,
    );

    print('   🔄 Starting real-time session...');
    final session = await provider.startRealtimeSession(config);

    print('   ✅ Session started: ${session.sessionId}');
    print('   🎤 Session is active: ${session.isActive}');

    // Simulate audio input
    final audioSimulator = AudioSimulator();

    // Listen for events
    final eventSubscription = session.events.listen((event) {
      _handleRealtimeEvent(event);
    });

    // Send simulated audio data
    print('   📡 Sending audio data...');
    for (int i = 0; i < 5; i++) {
      final audioChunk = audioSimulator.generateAudioChunk(1024);
      session.sendAudio(audioChunk);
      await Future.delayed(Duration(milliseconds: 100));
    }

    // Wait for processing
    await Future.delayed(Duration(seconds: 2));

    // Clean up
    await eventSubscription.cancel();
    await session.close();
    print('   🔚 Session closed');
  } catch (e) {
    print('   ❌ Real-time session failed: $e');
  }

  print('');
}

/// Demonstrate voice activity detection
Future<void> demonstrateVoiceActivityDetection(AudioCapability provider) async {
  print('🗣️ Voice Activity Detection:');

  try {
    final config = RealtimeAudioConfig(
      enableVAD: true,
      customParams: {
        'vad_sensitivity': 0.7,
        'vad_timeout': 1000, // ms
        'speech_threshold': 0.5,
      },
    );

    final session = await provider.startRealtimeSession(config);
    final vadProcessor = VoiceActivityDetector();

    print('   🔄 Monitoring voice activity...');

    // Simulate different audio scenarios
    final scenarios = [
      {'type': 'silence', 'duration': 1000},
      {'type': 'speech', 'duration': 2000},
      {'type': 'noise', 'duration': 500},
      {'type': 'speech', 'duration': 1500},
      {'type': 'silence', 'duration': 1000},
    ];

    final eventSubscription = session.events.listen((event) {
      if (event is RealtimeTranscriptionEvent) {
        print(
            '   📝 Transcription: "${event.text}" (confidence: ${event.confidence})');
      }
    });

    for (final scenario in scenarios) {
      final type = scenario['type'] as String;
      final duration = scenario['duration'] as int;

      print('   🎵 Simulating $type for ${duration}ms...');

      final audioData = vadProcessor.generateScenarioAudio(type, duration);
      session.sendAudio(audioData);

      await Future.delayed(Duration(milliseconds: duration));
    }

    await Future.delayed(Duration(seconds: 1));
    await eventSubscription.cancel();
    await session.close();
  } catch (e) {
    print('   ❌ Voice activity detection failed: $e');
  }

  print('');
}

/// Demonstrate continuous conversation flow
Future<void> demonstrateContinuousConversation(AudioCapability provider) async {
  print('💬 Continuous Conversation:');

  try {
    final config = RealtimeAudioConfig(
      enableVAD: true,
      enableEchoCancellation: true,
      customParams: {
        'conversation_mode': true,
        'auto_response': true,
        'response_delay': 500,
      },
    );

    final session = await provider.startRealtimeSession(config);
    final conversationManager = ConversationManager();

    print('   🔄 Starting continuous conversation...');

    // Track conversation state
    var turnCount = 0;
    final maxTurns = 3;

    final eventSubscription = session.events.listen((event) async {
      if (event is RealtimeTranscriptionEvent && event.isFinal) {
        turnCount++;
        print('   👤 User (Turn $turnCount): "${event.text}"');

        // Generate response
        final response = await conversationManager.generateResponse(event.text);
        print('   🤖 AI (Turn $turnCount): "$response"');

        // Convert response to audio and send back
        if (turnCount < maxTurns) {
          final responseAudio = await conversationManager.textToAudio(response);
          // In real implementation, you would send this back to the user
          print(
              '   🔊 Audio response generated (${responseAudio.length} bytes)');
        }
      }
    });

    // Simulate user speech inputs
    final userInputs = [
      'Hello, how are you today?',
      'Can you help me with a programming question?',
      'Thank you for your help!',
    ];

    for (final input in userInputs) {
      // Simulate speech-to-text by directly triggering transcription event
      print('      👤 User input: "$input"');
      await Future.delayed(Duration(milliseconds: 500));
      // Note: In real implementation, this would come from actual audio processing
    }

    await Future.delayed(Duration(seconds: 3));
    await eventSubscription.cancel();
    await session.close();
  } catch (e) {
    print('   ❌ Continuous conversation failed: $e');
  }

  print('');
}

/// Demonstrate audio preprocessing and enhancement
Future<void> demonstrateAudioPreprocessing(AudioCapability provider) async {
  print('🔧 Audio Preprocessing:');

  try {
    final config = RealtimeAudioConfig(
      enableNoiseSuppression: true,
      enableEchoCancellation: true,
      customParams: {
        'noise_gate_threshold': -40, // dB
        'compressor_ratio': 3.0,
        'eq_enabled': true,
        'auto_gain_control': true,
      },
    );

    final session = await provider.startRealtimeSession(config);
    final preprocessor = AudioPreprocessor();

    print('   🔄 Processing audio with enhancements...');

    // Simulate different audio quality scenarios
    final audioScenarios = [
      {'name': 'Clean audio', 'noise_level': 0.1},
      {'name': 'Noisy environment', 'noise_level': 0.5},
      {'name': 'Echo-prone room', 'echo_level': 0.3},
      {'name': 'Low volume speech', 'volume_level': 0.3},
    ];

    for (final scenario in audioScenarios) {
      final name = scenario['name'] as String;
      print('   🎵 Testing: $name');

      // Generate test audio with specific characteristics
      final rawAudio = preprocessor.generateTestAudio(scenario);

      // Apply preprocessing
      final processedAudio = preprocessor.enhanceAudio(rawAudio);

      // Send processed audio
      session.sendAudio(processedAudio);

      print(
          '      📊 Enhancement applied: ${processedAudio.length} bytes processed');
      await Future.delayed(Duration(milliseconds: 500));
    }

    await session.close();
  } catch (e) {
    print('   ❌ Audio preprocessing failed: $e');
  }

  print('');
}

/// Demonstrate multi-modal audio interaction
Future<void> demonstrateMultiModalInteraction(AudioCapability provider) async {
  print('🎭 Multi-modal Interaction:');

  try {
    final config = RealtimeAudioConfig(
      customParams: {
        'multimodal_mode': true,
        'visual_context': true,
        'gesture_recognition': true,
      },
    );

    final session = await provider.startRealtimeSession(config);
    final multiModalProcessor = MultiModalProcessor();

    print('   🔄 Starting multi-modal session...');

    // Simulate multi-modal inputs
    final interactions = [
      {
        'type': 'audio_only',
        'content': 'What do you see in this image?',
        'context': null,
      },
      {
        'type': 'audio_with_visual',
        'content': 'Describe what\'s happening here',
        'context': {'image_description': 'A sunset over mountains'},
      },
      {
        'type': 'audio_with_gesture',
        'content': 'Move this object over there',
        'context': {'gesture': 'pointing_right'},
      },
    ];

    for (final interaction in interactions) {
      final type = interaction['type'] as String;
      final content = interaction['content'] as String;
      final context = interaction['context'] as Map<String, dynamic>?;

      print('   🎯 Processing $type interaction...');
      print('      📝 Audio: "$content"');

      if (context != null) {
        print('      🖼️  Context: $context');
      }

      // Process multi-modal input
      final response = await multiModalProcessor.processInteraction(
        audioContent: content,
        visualContext: context?['image_description'],
        gestureContext: context?['gesture'],
      );

      print('      🤖 Response: "$response"');
      await Future.delayed(Duration(milliseconds: 800));
    }

    await session.close();
  } catch (e) {
    print('   ❌ Multi-modal interaction failed: $e');
  }

  print('');
}

/// Demonstrate session management and reconnection
Future<void> demonstrateSessionManagement(AudioCapability provider) async {
  print('🔄 Session Management:');

  try {
    final sessionManager = RealtimeSessionManager(provider);

    print('   🔄 Testing session lifecycle...');

    // Start session
    await sessionManager.startSession();
    print('   ✅ Session started');

    // Simulate session usage
    await sessionManager.sendTestAudio();
    print('   📡 Test audio sent');

    // Simulate network interruption
    print('   📡 Simulating network interruption...');
    await sessionManager.simulateNetworkIssue();

    // Test reconnection
    print('   🔄 Attempting reconnection...');
    await sessionManager.reconnect();
    print('   ✅ Session reconnected');

    // Test graceful shutdown
    print('   🔚 Graceful shutdown...');
    await sessionManager.shutdown();
    print('   ✅ Session management completed');
  } catch (e) {
    print('   ❌ Session management failed: $e');
  }

  print('');
}

/// Handle real-time audio events
void _handleRealtimeEvent(RealtimeAudioEvent event) {
  switch (event.runtimeType) {
    case RealtimeTranscriptionEvent _:
      final transcription = event as RealtimeTranscriptionEvent;
      final status = transcription.isFinal ? 'FINAL' : 'PARTIAL';
      print('      📝 [$status] "${transcription.text}"');
      break;

    case RealtimeAudioResponseEvent _:
      final audioResponse = event as RealtimeAudioResponseEvent;
      print('      🔊 Audio response: ${audioResponse.audioData.length} bytes');
      break;

    case RealtimeSessionStatusEvent _:
      final status = event as RealtimeSessionStatusEvent;
      print('      📊 Status: ${status.status}');
      break;

    case RealtimeErrorEvent _:
      final error = event as RealtimeErrorEvent;
      print('      ❌ Error: ${error.message}');
      break;
  }
}

// Helper classes for real-time audio processing

/// Audio simulator for testing
class AudioSimulator {
  /// Generate simulated audio chunk
  List<int> generateAudioChunk(int size) {
    // Generate simple sine wave or noise for testing
    return List.generate(size, (index) => (index % 256));
  }
}

/// Voice activity detector
class VoiceActivityDetector {
  /// Generate audio data for different scenarios
  List<int> generateScenarioAudio(String type, int durationMs) {
    final sampleRate = 16000;
    final samples = (sampleRate * durationMs / 1000).round();

    switch (type) {
      case 'silence':
        return List.filled(samples, 0);
      case 'speech':
        // Generate speech-like pattern
        return List.generate(samples,
            (i) => (128 + 100 * sin(i * 0.01) * sin(i * 0.001)).round());
      case 'noise':
        // Generate noise pattern
        return List.generate(
            samples, (i) => (128 + (Random().nextDouble() - 0.5) * 50).round());
      default:
        return List.filled(samples, 0);
    }
  }
}

/// Conversation manager for continuous flow
class ConversationManager {
  final List<String> _conversationHistory = [];

  /// Generate response based on input
  Future<String> generateResponse(String input) async {
    _conversationHistory.add('User: $input');

    // Simulate AI response generation
    await Future.delayed(Duration(milliseconds: 300));

    final responses = [
      'I\'m doing well, thank you for asking!',
      'Of course! I\'d be happy to help with programming.',
      'You\'re welcome! Feel free to ask anytime.',
    ];

    final response =
        responses[_conversationHistory.length ~/ 2 % responses.length];
    _conversationHistory.add('AI: $response');

    return response;
  }

  /// Convert text to audio (simulated)
  Future<List<int>> textToAudio(String text) async {
    await Future.delayed(Duration(milliseconds: 200));
    // Simulate TTS conversion
    return List.generate(text.length * 100, (i) => i % 256);
  }
}

/// Audio preprocessor for enhancement
class AudioPreprocessor {
  /// Generate test audio with specific characteristics
  List<int> generateTestAudio(Map<String, dynamic> scenario) {
    final baseAudio =
        List.generate(1024, (i) => 128 + (sin(i * 0.1) * 50).round());

    // Apply scenario-specific modifications
    if (scenario.containsKey('noise_level')) {
      final noiseLevel = scenario['noise_level'] as double;
      for (int i = 0; i < baseAudio.length; i++) {
        baseAudio[i] +=
            ((Random().nextDouble() - 0.5) * noiseLevel * 100).round();
      }
    }

    return baseAudio;
  }

  /// Enhance audio quality
  List<int> enhanceAudio(List<int> rawAudio) {
    // Simulate audio enhancement processing
    return rawAudio.map((sample) {
      // Simple noise reduction and normalization
      var enhanced = sample;
      enhanced = (enhanced * 0.9).round(); // Slight volume reduction
      enhanced = enhanced.clamp(0, 255); // Ensure valid range
      return enhanced;
    }).toList();
  }
}

/// Multi-modal processor
class MultiModalProcessor {
  /// Process multi-modal interaction
  Future<String> processInteraction({
    required String audioContent,
    String? visualContext,
    String? gestureContext,
  }) async {
    await Future.delayed(Duration(milliseconds: 400));

    var response = 'I heard: "$audioContent"';

    if (visualContext != null) {
      response += ' and I can see: $visualContext';
    }

    if (gestureContext != null) {
      response += ' with gesture: $gestureContext';
    }

    return response;
  }
}

/// Session manager for handling connections
class RealtimeSessionManager {
  final AudioCapability _provider;
  RealtimeAudioSession? _session;
  bool _isConnected = false;

  RealtimeSessionManager(this._provider);

  /// Start new session
  Future<void> startSession() async {
    final config = RealtimeAudioConfig(
      enableVAD: true,
      timeoutSeconds: 30,
    );

    _session = await _provider.startRealtimeSession(config);
    _isConnected = true;
  }

  /// Send test audio
  Future<void> sendTestAudio() async {
    if (_session != null && _isConnected) {
      final testAudio = List.generate(512, (i) => i % 256);
      _session!.sendAudio(testAudio);
    }
  }

  /// Simulate network issue
  Future<void> simulateNetworkIssue() async {
    _isConnected = false;
    await Future.delayed(Duration(milliseconds: 500));
  }

  /// Reconnect session
  Future<void> reconnect() async {
    if (!_isConnected) {
      await startSession();
    }
  }

  /// Shutdown session
  Future<void> shutdown() async {
    if (_session != null) {
      await _session!.close();
      _session = null;
      _isConnected = false;
    }
  }
}

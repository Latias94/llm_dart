import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:llm_dart/core/capability.dart' as compat;
import 'package:llm_dart/providers/elevenlabs/elevenlabs.dart'
    as elevenlabs_compat;
import 'package:llm_dart_community/llm_dart_community.dart' as community;

/// Provider-owned realtime audio appendix.
///
/// This example intentionally does not pretend realtime audio already has a
/// shared modern facade. The current boundary is:
///
/// - shared speech/transcription models live in `llm_dart_community`
/// - realtime sessions remain provider-owned compatibility surface
///
/// The example therefore demonstrates:
/// - how to inspect the ElevenLabs compatibility audio surface honestly
/// - how to configure realtime session intent with `RealtimeAudioConfig`
/// - how app-owned event/session orchestration can already be structured
///   without faking a cross-provider realtime abstraction
Future<void> main() async {
  print('Realtime audio compatibility appendix\n');

  final apiKey = Platform.environment['ELEVENLABS_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Set ELEVENLABS_API_KEY to inspect the provider-owned realtime surface.');
    return;
  }

  await _demonstrateSharedAudioBoundary(apiKey);

  final provider = elevenlabs_compat.createElevenLabsProvider(
    apiKey: apiKey,
    voiceId: 'JBFqnCBsd6RMkjVDRZzb',
    model: 'eleven_multilingual_v2',
  );

  _printProviderFeatureBoundary(provider);

  final config = compat.RealtimeAudioConfig(
    inputFormat: 'pcm16',
    outputFormat: 'pcm16',
    sampleRate: 16000,
    enableVAD: true,
    enableEchoCancellation: true,
    enableNoiseSuppression: true,
    timeoutSeconds: 30,
    customParams: const {
      'conversation_mode': true,
      'response_delay_ms': 500,
    },
  );

  _printRealtimeConfig(config);
  await _demonstrateProviderSessionBoundary(
    provider: provider,
    config: config,
  );
  await _demonstrateLocalSessionOrchestration(config);

  print('Completed realtime audio appendix.');
  print('Keep realtime as a provider-owned boundary until a true shared');
  print('cross-provider session contract exists.');
}

Future<void> _demonstrateSharedAudioBoundary(String apiKey) async {
  print('Shared audio boundary:');

  final speechModel = community.ElevenLabs(
    apiKey: apiKey,
  ).speechModel('eleven_multilingual_v2');
  final transcriptionModel = community.ElevenLabs(
    apiKey: apiKey,
  ).transcriptionModel('scribe_v1');

  print(
    '  Shared speech model: ${speechModel.providerId}/${speechModel.modelId}',
  );
  print(
    '  Shared transcription model: '
    '${transcriptionModel.providerId}/${transcriptionModel.modelId}',
  );
  print(
    '  These shared models are the stable path for normal TTS/STT app code.',
  );
  print(
    '  Realtime sessions are still provider-owned and do not yet have a',
  );
  print('  shared modern contract.\n');
}

void _printProviderFeatureBoundary(compat.AudioCapability provider) {
  print('ElevenLabs provider-owned feature surface:');

  for (final feature in compat.AudioFeature.values) {
    final supported = provider.supportedFeatures.contains(feature);
    print('  ${supported ? 'YES' : 'NO '} ${feature.name}');
  }

  print('  Formats: ${provider.getSupportedAudioFormats().join(', ')}');
  print('');
}

void _printRealtimeConfig(compat.RealtimeAudioConfig config) {
  print('Realtime session intent config:');
  print('  ${config.toJson()}');
  print('');
}

Future<void> _demonstrateProviderSessionBoundary({
  required compat.AudioCapability provider,
  required compat.RealtimeAudioConfig config,
}) async {
  print('Provider boundary: realtime session startup');

  if (!provider.supportedFeatures.contains(compat.AudioFeature.realtimeProcessing)) {
    print('  Provider does not advertise realtime processing on this surface.');
    print('');
    return;
  }

  try {
    final session = await provider.startRealtimeSession(config);
    print('  Session unexpectedly started: ${session.sessionId}');
    await session.close();
  } on UnsupportedError catch (error) {
    print('  Compatibility shell reached the provider boundary.');
    print('  Current implementation status: $error');
    print(
      '  This is exactly why realtime is still documented as provider-owned',
    );
    print('  appendix material instead of stable shared API.\n');
  } catch (error) {
    print('  Session startup failed: $error\n');
  }
}

Future<void> _demonstrateLocalSessionOrchestration(
  compat.RealtimeAudioConfig config,
) async {
  print('App-owned session orchestration pattern:');

  final session = _SimulatedRealtimeAudioSession(config: config);
  final subscription = session.events.listen(_handleRealtimeEvent);
  final manager = _RealtimeSessionManager(session);
  final simulator = _AudioChunkSimulator();

  try {
    await manager.start();

    for (final chunk in [
      simulator.generateSpeechChunk(),
      simulator.generateSpeechChunk(),
      simulator.generateSilenceChunk(),
    ]) {
      session.sendAudio(chunk);
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }

    await manager.simulateNetworkRecovery();
    session.sendAudio(simulator.generateSpeechChunk());
    await Future<void>.delayed(const Duration(milliseconds: 250));
  } finally {
    await subscription.cancel();
    await manager.shutdown();
  }

  print('');
}

void _handleRealtimeEvent(compat.RealtimeAudioEvent event) {
  switch (event) {
    case compat.RealtimeSessionStatusEvent(
        :final status,
        :final details,
      ):
      print('  [status] $status ${details ?? const {}}');
    case compat.RealtimeTranscriptionEvent(
        :final text,
        :final isFinal,
        :final confidence,
      ):
      final kind = isFinal ? 'final' : 'partial';
      print(
        '  [transcription/$kind] $text '
        '(confidence=${confidence?.toStringAsFixed(2) ?? 'n/a'})',
      );
    case compat.RealtimeAudioResponseEvent(
        :final audioData,
        :final isFinal,
      ):
      print(
        '  [audio-response] ${audioData.length} bytes '
        'final=$isFinal',
      );
    case compat.RealtimeErrorEvent(:final message, :final code):
      print('  [error] ${code ?? 'unknown'}: $message');
  }
}

final class _AudioChunkSimulator {
  List<int> generateSpeechChunk() {
    return List<int>.generate(
      512,
      (index) => (128 + 70 * math.sin(index * 0.12)).round().clamp(0, 255),
    );
  }

  List<int> generateSilenceChunk() {
    return List<int>.filled(512, 128);
  }
}

final class _SimulatedRealtimeAudioSession extends compat.RealtimeAudioSession {
  final compat.RealtimeAudioConfig config;
  final StreamController<compat.RealtimeAudioEvent> _events =
      StreamController<compat.RealtimeAudioEvent>.broadcast();
  final String _sessionId =
      'sim-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';

  bool _isActive = false;
  int _chunkCount = 0;

  _SimulatedRealtimeAudioSession({
    required this.config,
  });

  @override
  Stream<compat.RealtimeAudioEvent> get events => _events.stream;

  @override
  bool get isActive => _isActive;

  @override
  String get sessionId => _sessionId;

  Future<void> start() async {
    _isActive = true;
    _events.add(
      compat.RealtimeSessionStatusEvent(
        timestamp: DateTime.now(),
        status: 'started',
        details: config.toJson(),
      ),
    );
  }

  @override
  void sendAudio(List<int> audioData) {
    if (!_isActive) {
      _events.add(
        compat.RealtimeErrorEvent(
          timestamp: DateTime.now(),
          message: 'Attempted to send audio to an inactive session.',
          code: 'inactive-session',
        ),
      );
      return;
    }

    _chunkCount++;
    final energy = _estimateEnergy(audioData);
    _events.add(
      compat.RealtimeSessionStatusEvent(
        timestamp: DateTime.now(),
        status: 'audio-received',
        details: {
          'chunk': _chunkCount,
          'energy': energy.toStringAsFixed(3),
        },
      ),
    );

    if (energy < 0.02) {
      _events.add(
        compat.RealtimeSessionStatusEvent(
          timestamp: DateTime.now(),
          status: 'vad-silence',
          details: {
            'chunk': _chunkCount,
          },
        ),
      );
      return;
    }

    _events.add(
      compat.RealtimeTranscriptionEvent(
        timestamp: DateTime.now(),
        text: 'detected speech chunk $_chunkCount',
        isFinal: false,
        confidence: 0.74,
      ),
    );

    if (_chunkCount.isEven) {
      _events.add(
        compat.RealtimeTranscriptionEvent(
          timestamp: DateTime.now(),
          text: 'final user utterance after chunk $_chunkCount',
          isFinal: true,
          confidence: 0.91,
        ),
      );
      _events.add(
        compat.RealtimeAudioResponseEvent(
          timestamp: DateTime.now(),
          audioData: List<int>.filled(256, 42),
          isFinal: true,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    if (!_isActive) {
      return;
    }

    _isActive = false;
    _events.add(
      compat.RealtimeSessionStatusEvent(
        timestamp: DateTime.now(),
        status: 'closed',
      ),
    );
    await _events.close();
  }

  Future<void> markDisconnected() async {
    if (!_isActive) {
      return;
    }

    _isActive = false;
    _events.add(
      compat.RealtimeSessionStatusEvent(
        timestamp: DateTime.now(),
        status: 'disconnected',
      ),
    );
  }

  Future<void> reconnect() async {
    if (_events.isClosed) {
      return;
    }

    _isActive = true;
    _events.add(
      compat.RealtimeSessionStatusEvent(
        timestamp: DateTime.now(),
        status: 'reconnected',
      ),
    );
  }

  double _estimateEnergy(List<int> audioData) {
    if (audioData.isEmpty) {
      return 0.0;
    }

    var total = 0.0;
    for (final value in audioData) {
      total += (value - 128).abs() / 128;
    }
    return total / audioData.length;
  }
}

final class _RealtimeSessionManager {
  final _SimulatedRealtimeAudioSession _session;

  _RealtimeSessionManager(this._session);

  Future<void> start() => _session.start();

  Future<void> simulateNetworkRecovery() async {
    await _session.markDisconnected();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await _session.reconnect();
  }

  Future<void> shutdown() => _session.close();
}

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart' as elevenlabs;

/// App-owned realtime audio orchestration.
///
/// The stable library surface currently exposes normal speech and
/// transcription models. A cross-provider realtime session contract is not
/// frozen, so realtime wiring should stay in application code or a provider
/// package until the event model is mature enough to standardize.
Future<void> main() async {
  print('Realtime audio orchestration pattern\n');

  final apiKey = Platform.environment['ELEVENLABS_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print(
        'Set ELEVENLABS_API_KEY to inspect stable ElevenLabs model surfaces.');
    return;
  }

  await _demonstrateStableAudioBoundary(apiKey);

  final config = const RealtimeAudioSessionConfig(
    inputFormat: 'pcm16',
    outputFormat: 'pcm16',
    sampleRate: 16000,
    enableVad: true,
    enableEchoCancellation: true,
    enableNoiseSuppression: true,
    timeout: Duration(seconds: 30),
    customParams: {
      'conversation_mode': true,
      'response_delay_ms': 500,
    },
  );

  _printRealtimeConfig(config);
  await _demonstrateLocalSessionOrchestration(config);

  print('Completed realtime audio orchestration example.');
}

Future<void> _demonstrateStableAudioBoundary(String apiKey) async {
  print('Stable audio boundary:');

  final provider = elevenlabs.elevenLabs(apiKey: apiKey);
  final speechModel = provider.speechModel('eleven_multilingual_v2');
  final transcriptionModel = provider.transcriptionModel('scribe_v1');

  print(
    '  Speech model: ${speechModel.providerId}/${speechModel.modelId}',
  );
  print(
    '  Transcription model: '
    '${transcriptionModel.providerId}/${transcriptionModel.modelId}',
  );

  final speechProfile = speechModel.capabilityProfile;
  final transcriptionProfile = transcriptionModel.capabilityProfile;
  print(
    '  Speech output format control: '
    '${speechProfile.supports(core.ModelCapabilityFeatureIds.speechOutputFormat)}',
  );
  print(
    '  Transcription timestamps: '
    '${transcriptionProfile.supports(core.ModelCapabilityFeatureIds.transcriptionTimestamps)}',
  );
  print(
    '  Realtime session events are intentionally not part of the shared model contract yet.',
  );
  print('');
}

void _printRealtimeConfig(RealtimeAudioSessionConfig config) {
  print('Realtime session intent config:');
  print('  ${config.toJson()}');
  print('');
}

Future<void> _demonstrateLocalSessionOrchestration(
  RealtimeAudioSessionConfig config,
) async {
  print('App-owned session orchestration pattern:');

  final session = SimulatedRealtimeAudioSession(config: config);
  final subscription = session.events.listen(_handleRealtimeEvent);
  final manager = RealtimeSessionManager(session);
  final simulator = AudioChunkSimulator();

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

void _handleRealtimeEvent(RealtimeAudioEvent event) {
  switch (event) {
    case RealtimeSessionStatusEvent(:final status, :final details):
      print('  [status] $status ${details ?? const {}}');
    case RealtimeTranscriptionEvent(
        :final text,
        :final isFinal,
        :final confidence,
      ):
      final kind = isFinal ? 'final' : 'partial';
      print(
        '  [transcription/$kind] $text '
        '(confidence=${confidence?.toStringAsFixed(2) ?? 'n/a'})',
      );
    case RealtimeAudioResponseEvent(:final audioData, :final isFinal):
      print(
        '  [audio-response] ${audioData.length} bytes '
        'final=$isFinal',
      );
    case RealtimeErrorEvent(:final message, :final code):
      print('  [error] ${code ?? 'unknown'}: $message');
  }
}

final class RealtimeAudioSessionConfig {
  final String inputFormat;
  final String outputFormat;
  final int sampleRate;
  final bool enableVad;
  final bool enableEchoCancellation;
  final bool enableNoiseSuppression;
  final Duration timeout;
  final Map<String, Object?> customParams;

  const RealtimeAudioSessionConfig({
    required this.inputFormat,
    required this.outputFormat,
    required this.sampleRate,
    this.enableVad = false,
    this.enableEchoCancellation = false,
    this.enableNoiseSuppression = false,
    this.timeout = const Duration(seconds: 30),
    this.customParams = const {},
  });

  Map<String, Object?> toJson() {
    return {
      'inputFormat': inputFormat,
      'outputFormat': outputFormat,
      'sampleRate': sampleRate,
      'enableVad': enableVad,
      'enableEchoCancellation': enableEchoCancellation,
      'enableNoiseSuppression': enableNoiseSuppression,
      'timeoutSeconds': timeout.inSeconds,
      if (customParams.isNotEmpty) 'customParams': customParams,
    };
  }
}

sealed class RealtimeAudioEvent {
  final DateTime timestamp;

  const RealtimeAudioEvent({
    required this.timestamp,
  });
}

final class RealtimeSessionStatusEvent extends RealtimeAudioEvent {
  final String status;
  final Map<String, Object?>? details;

  const RealtimeSessionStatusEvent({
    required super.timestamp,
    required this.status,
    this.details,
  });
}

final class RealtimeTranscriptionEvent extends RealtimeAudioEvent {
  final String text;
  final bool isFinal;
  final double? confidence;

  const RealtimeTranscriptionEvent({
    required super.timestamp,
    required this.text,
    required this.isFinal,
    this.confidence,
  });
}

final class RealtimeAudioResponseEvent extends RealtimeAudioEvent {
  final List<int> audioData;
  final bool isFinal;

  const RealtimeAudioResponseEvent({
    required super.timestamp,
    required this.audioData,
    required this.isFinal,
  });
}

final class RealtimeErrorEvent extends RealtimeAudioEvent {
  final String message;
  final String? code;

  const RealtimeErrorEvent({
    required super.timestamp,
    required this.message,
    this.code,
  });
}

final class AudioChunkSimulator {
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

final class SimulatedRealtimeAudioSession {
  final RealtimeAudioSessionConfig config;
  final StreamController<RealtimeAudioEvent> _events =
      StreamController<RealtimeAudioEvent>.broadcast();
  final String sessionId =
      'sim-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';

  bool _isActive = false;
  int _chunkCount = 0;

  SimulatedRealtimeAudioSession({
    required this.config,
  });

  Stream<RealtimeAudioEvent> get events => _events.stream;

  bool get isActive => _isActive;

  Future<void> start() async {
    _isActive = true;
    _events.add(
      RealtimeSessionStatusEvent(
        timestamp: DateTime.now(),
        status: 'started',
        details: config.toJson(),
      ),
    );
  }

  void sendAudio(List<int> audioData) {
    if (!_isActive) {
      _events.add(
        RealtimeErrorEvent(
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
      RealtimeSessionStatusEvent(
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
        RealtimeSessionStatusEvent(
          timestamp: DateTime.now(),
          status: 'vad-silence',
          details: {'chunk': _chunkCount},
        ),
      );
      return;
    }

    _events.add(
      RealtimeTranscriptionEvent(
        timestamp: DateTime.now(),
        text: 'detected speech chunk $_chunkCount',
        isFinal: false,
        confidence: 0.74,
      ),
    );

    if (_chunkCount.isEven) {
      _events.add(
        RealtimeTranscriptionEvent(
          timestamp: DateTime.now(),
          text: 'final user utterance after chunk $_chunkCount',
          isFinal: true,
          confidence: 0.91,
        ),
      );
      _events.add(
        RealtimeAudioResponseEvent(
          timestamp: DateTime.now(),
          audioData: List<int>.filled(256, 42),
          isFinal: true,
        ),
      );
    }
  }

  Future<void> close() async {
    if (!_isActive) {
      return;
    }

    _isActive = false;
    _events.add(
      RealtimeSessionStatusEvent(
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
      RealtimeSessionStatusEvent(
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
      RealtimeSessionStatusEvent(
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

final class RealtimeSessionManager {
  final SimulatedRealtimeAudioSession _session;

  RealtimeSessionManager(this._session);

  Future<void> start() => _session.start();

  Future<void> simulateNetworkRecovery() async {
    await _session.markDisconnected();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await _session.reconnect();
  }

  Future<void> shutdown() => _session.close();
}

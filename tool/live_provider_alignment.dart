import 'dart:async';
import 'dart:io';

import 'package:llm_dart/llm_dart.dart';

/// Live (network) smoke checks for provider alignment.
///
/// This is intentionally NOT a test suite:
/// - It requires real API keys.
/// - It may be flaky due to network/provider status.
/// - CI should not run it.
///
/// Usage:
///   dart run tool/live_provider_alignment.dart
///   dart run tool/live_provider_alignment.dart --stream
///   dart run tool/live_provider_alignment.dart --stream --dump
///   dart run tool/live_provider_alignment.dart --stream --dump=80
///   dart run tool/live_provider_alignment.dart --stream --dump --dump-chat-parts
///   dart run tool/live_provider_alignment.dart --providers=openai,anthropic
///   dart run tool/live_provider_alignment.dart --all
///
/// Notes:
/// - This tool never prints API keys.
/// - Keep prompts tiny to minimize cost.
Future<void> main(List<String> args) async {
  final flags = _parseArgs(args);
  final selectedProviders = flags.providers;
  final includeStreaming = flags.stream;
  final includeAll = flags.all;
  final dumpCount = flags.dumpCount;
  final dumpChatParts = flags.dumpChatParts;

  final specs = <_ProviderSpec>[
    _ProviderSpec(
      providerId: 'openai',
      displayName: 'OpenAI',
      envVars: const ['OPENAI_API_KEY'],
      defaultModel: 'gpt-4o-mini',
    ),
    _ProviderSpec(
      providerId: 'anthropic',
      displayName: 'Anthropic',
      envVars: const ['ANTHROPIC_API_KEY', 'CLAUDE_API_KEY'],
      baseUrlEnvVars: const ['ANTHROPIC_BASE_URL'],
      modelEnvVars: const ['ANTHROPIC_MODEL'],
      defaultModel: ProviderDefaults.anthropicDefaultModel,
    ),
    _ProviderSpec(
      providerId: 'google',
      displayName: 'Google (Gemini)',
      envVars: const ['GEMINI_API_KEY', 'GOOGLE_API_KEY'],
      defaultModel: 'gemini-2.0-flash',
    ),
    _ProviderSpec(
      providerId: 'groq',
      displayName: 'Groq',
      envVars: const ['GROQ_API_KEY'],
      defaultModel: 'llama-3.3-70b-versatile',
    ),
    _ProviderSpec(
      providerId: 'deepseek',
      displayName: 'DeepSeek',
      envVars: const ['DEEPSEEK_API_KEY'],
      defaultModel: 'deepseek-chat',
    ),
    _ProviderSpec(
      providerId: 'xai',
      displayName: 'xAI',
      envVars: const ['XAI_API_KEY'],
      defaultModel: 'grok-3',
    ),
    _ProviderSpec(
      providerId: 'xai.responses',
      displayName: 'xAI (Responses)',
      envVars: const ['XAI_API_KEY'],
      defaultModel: 'grok-4-fast-reasoning',
      chatPrompt: 'What is xAI? Reply in 1 sentence.',
      providerTools: const [
        ProviderTool(id: 'xai.web_search'),
      ],
      providerOptions: const {
        'store': false,
      },
    ),
    _ProviderSpec(
      providerId: 'openrouter',
      displayName: 'OpenRouter',
      envVars: const ['OPENROUTER_API_KEY'],
      defaultModel: 'anthropic/claude-3.5-sonnet',
      providerOptions: const {
        'reasoningEffort': 'low',
      },
    ),
    _ProviderSpec(
      providerId: 'ollama',
      displayName: 'Ollama (local)',
      envVars: const [],
      defaultModel: 'llama3.2',
      requiresKey: false,
    ),
    _ProviderSpec(
      providerId: 'minimax',
      displayName: 'MiniMax',
      envVars: const ['MINIMAX_API_KEY'],
      baseUrlEnvVars: const ['MINIMAX_BASE_URL'],
      modelEnvVars: const ['MINIMAX_MODEL'],
      defaultModel: 'MiniMax-M2.1',
      chatPrompt: 'Reply with exactly the single word: pong',
    ),
    _ProviderSpec(
      providerId: 'elevenlabs',
      displayName: 'ElevenLabs',
      envVars: const ['ELEVENLABS_API_KEY'],
      defaultModel: 'eleven_multilingual_v2',
      liveChecks: const [
        _LiveCheck.textToSpeech,
        _LiveCheck.elevenLabsSpeechToSpeech,
        _LiveCheck.elevenLabsForcedAlignment,
      ],
    ),
    // OpenAI-compatible registries (pre-configured provider ids).
    _ProviderSpec(
      providerId: 'groq-openai',
      displayName: 'Groq (OpenAI-compatible registry)',
      envVars: const ['GROQ_API_KEY'],
      defaultModel: 'llama-3.3-70b-versatile',
      providerOptions: const {
        'structuredOutputs': false,
      },
    ),
    _ProviderSpec(
      providerId: 'deepseek-openai',
      displayName: 'DeepSeek (OpenAI-compatible registry)',
      envVars: const ['DEEPSEEK_API_KEY'],
      defaultModel: 'deepseek-chat',
      chatPrompt: 'Return a JSON object with key "ok" and value true.',
      providerOptions: const {
        'responseFormat': {'type': 'json_object'},
      },
    ),
    _ProviderSpec(
      providerId: 'xai-openai',
      displayName: 'xAI (OpenAI-compatible registry)',
      envVars: const ['XAI_API_KEY'],
      defaultModel: 'grok-3',
      providerOptions: const {
        'liveSearch': false,
      },
    ),
    _ProviderSpec(
      providerId: 'google-openai',
      displayName: 'Google (OpenAI-compatible registry)',
      envVars: const ['GEMINI_API_KEY', 'GOOGLE_API_KEY'],
      defaultModel: 'gemini-2.0-flash',
    ),
  ];

  final filtered = includeAll
      ? specs
      : specs
          .where((s) =>
              selectedProviders.isEmpty ||
              selectedProviders.contains(s.providerId))
          .toList(growable: false);

  if (filtered.isEmpty) {
    stderr.writeln('No providers selected. Use --providers=... or --all.');
    exitCode = 2;
    return;
  }

  stdout.writeln('LLM Dart live provider alignment smoke checks');
  stdout.writeln('Selected: ${filtered.map((s) => s.providerId).join(', ')}');
  stdout.writeln('Streaming checks: ${includeStreaming ? 'ON' : 'OFF'}');
  stdout.writeln(
      'Dump stream parts: ${dumpCount > 0 ? 'ON (max $dumpCount parts)' : 'OFF'}');
  stdout.writeln('Dump chat parts: ${dumpChatParts ? 'ON' : 'OFF'}');
  stdout.writeln('');

  var hadFailure = false;

  for (final spec in filtered) {
    final secret = spec.pickApiKey();
    if (spec.requiresKey && secret == null) {
      stdout.writeln(
          'SKIP  ${spec.providerId} (${spec.displayName}) - missing key (${spec.envVars.join(' or ')})');
      continue;
    }

    final results = await _runProviderChecks(
      spec,
      apiKey: secret,
      includeStreaming: includeStreaming,
      dumpCount: dumpCount,
      dumpChatParts: dumpChatParts,
    );

    final ok = results.every((r) => r.ok);
    hadFailure = hadFailure || !ok;

    final status = ok ? 'OK   ' : 'FAIL ';
    stdout.writeln('$status ${spec.providerId} (${spec.displayName})');
    for (final r in results) {
      final rStatus = r.ok ? '  ✓' : '  ✗';
      var detail =
          r.detail == null || r.detail!.isEmpty ? '' : ' - ${r.detail}';

      if (!r.ok &&
          spec.providerId == 'minimax' &&
          (r.detail ?? '').toLowerCase().contains('api key')) {
        detail =
            '$detail (set MINIMAX_BASE_URL=https://api.minimaxi.com/anthropic/v1/ for China region)';
      }
      stdout.writeln('$rStatus ${r.name}$detail');
    }
    stdout.writeln('');
  }

  if (hadFailure) {
    exitCode = 1;
  }
}

Future<List<_CheckResult>> _runProviderChecks(
  _ProviderSpec spec, {
  required String? apiKey,
  required bool includeStreaming,
  required int dumpCount,
  required bool dumpChatParts,
}) async {
  final redactor = _Redactor(secrets: apiKey == null ? const [] : [apiKey]);
  final checks = <_LiveCheck>[
    ...(() {
      if (spec.liveChecks.isNotEmpty) return spec.liveChecks;
      return const [_LiveCheck.generateText, _LiveCheck.streamText];
    })(),
    if (includeStreaming && dumpChatParts) _LiveCheck.streamChatParts,
  ];

  final results = <_CheckResult>[];

  Future<void> run(String name, Future<_CheckResult> Function() fn) async {
    try {
      results.add(await fn());
    } catch (e) {
      results.add(
        _CheckResult(
          name: name,
          ok: false,
          detail: redactor.redact('${e.runtimeType}: ${e.toString()}'),
        ),
      );
    }
  }

  final model = await _buildProvider(spec, apiKey: apiKey);

  for (final check in checks) {
    switch (check) {
      case _LiveCheck.generateText:
        await run('generateText', () async {
          if (model is! ChatCapability) {
            return const _CheckResult(
              name: 'generateText',
              ok: false,
              detail: 'not a ChatCapability',
            );
          }

          Future<GenerateTextResult> attempt(ChatCapability m) {
            return generateText(
              model: m,
              messages: [ChatMessage.user(spec.chatPrompt)],
            );
          }

          GenerateTextResult result;
          try {
            result = await attempt(model);
          } on AuthError catch (e) {
            return _CheckResult(
              name: 'generateText',
              ok: false,
              detail: redactor.redact(e.toString()),
            );
          }

          final text = (result.text ?? '').trim();
          final thinking = (result.thinking ?? '').trim();
          final toolCallsCount = result.toolCalls?.length ?? 0;

          if (text.isEmpty && thinking.isEmpty && toolCallsCount == 0) {
            final metadataKeys =
                result.providerMetadata?.keys.toList(growable: false) ??
                    const <String>[];

            return _CheckResult(
              name: 'generateText',
              ok: false,
              detail: metadataKeys.isEmpty
                  ? 'empty text'
                  : 'empty text (providerMetadata keys: ${metadataKeys.join(', ')})',
            );
          }

          final metadataOk = result.providerMetadata == null ||
              result.providerMetadata is Map<String, dynamic>;

          return _CheckResult(
            name: 'generateText',
            ok: metadataOk,
            detail: metadataOk ? null : 'providerMetadata is not a map',
          );
        });

      case _LiveCheck.streamText:
        if (!includeStreaming) {
          results.add(const _CheckResult(
            name: 'streamText',
            ok: true,
            detail: 'skipped (enable with --stream)',
          ));
          continue;
        }

        await run('streamText', () async {
          if (model is! ChatCapability) {
            return const _CheckResult(
              name: 'streamText',
              ok: false,
              detail: 'not a ChatCapability',
            );
          }

          Future<_CheckResult> attempt(ChatCapability m) async {
            var sawFinish = false;
            var sawAnyDelta = false;
            var dumped = 0;

            void dump(String line) {
              if (dumpCount <= 0) return;
              if (dumped >= dumpCount) return;
              dumped++;
              stdout.writeln('  [${spec.providerId}] #$dumped $line');
            }

            await for (final part in streamText(
              model: m,
              messages: [ChatMessage.user(spec.chatPrompt)],
            )) {
              switch (part) {
                case TextDeltaPart(:final delta):
                  if (delta.isNotEmpty) sawAnyDelta = true;
                  dump('TextDelta len=${delta.length}');
                case ThinkingDeltaPart(:final delta):
                  if (delta.isNotEmpty) sawAnyDelta = true;
                  dump('ThinkingDelta len=${delta.length}');
                case ToolCallDeltaPart():
                  sawAnyDelta = true;
                  dump('ToolCallDelta');
                case FinishPart(:final result):
                  sawFinish = true;
                  final t = result.text ?? '';
                  final r = result.thinking ?? '';
                  dump(
                      'Finish textLen=${t.length} thinkingLen=${r.length} toolCalls=${result.toolCalls?.length ?? 0}');
                case ErrorPart(:final error):
                  dump('Error ${error.runtimeType}');
                  return _CheckResult(
                    name: 'streamText',
                    ok: false,
                    detail: redactor.redact(error.toString()),
                  );
              }
              if (sawFinish) break;
            }

            if (!sawFinish) {
              return const _CheckResult(
                name: 'streamText',
                ok: false,
                detail: 'did not finish',
              );
            }

            return _CheckResult(
              name: 'streamText',
              ok: true,
              detail: sawAnyDelta ? null : 'no text/thinking delta observed',
            );
          }

          final first = await attempt(model);
          if (first.ok) return first;

          return first;
        });

      case _LiveCheck.streamChatParts:
        if (!includeStreaming) {
          results.add(const _CheckResult(
            name: 'streamChatParts',
            ok: true,
            detail: 'skipped (enable with --stream)',
          ));
          continue;
        }

        await run('streamChatParts', () async {
          if (model is! ChatCapability) {
            return const _CheckResult(
              name: 'streamChatParts',
              ok: false,
              detail: 'not a ChatCapability',
            );
          }

          var sawFinish = false;
          var sawAnyDelta = false;
          var dumped = 0;

          void dump(String line) {
            if (dumpCount <= 0) return;
            if (dumped >= dumpCount) return;
            dumped++;
            stdout.writeln('  [${spec.providerId}] #$dumped $line');
          }

          await for (final part in streamChatParts(
            model: model,
            messages: [ChatMessage.user(spec.chatPrompt)],
          )) {
            switch (part) {
              case LLMTextStartPart():
                dump('TextStart');

              case LLMTextDeltaPart(:final delta):
                if (delta.isNotEmpty) sawAnyDelta = true;
                dump('TextDelta len=${delta.length}');

              case LLMTextEndPart(:final text):
                dump('TextEnd len=${text.length}');

              case LLMReasoningStartPart():
                dump('ThinkingStart');

              case LLMReasoningDeltaPart(:final delta):
                if (delta.isNotEmpty) sawAnyDelta = true;
                dump('ThinkingDelta len=${delta.length}');

              case LLMReasoningEndPart(:final thinking):
                dump('ThinkingEnd len=${thinking.length}');

              case LLMToolCallStartPart(:final toolCall):
                sawAnyDelta = true;
                dump(
                    'ToolCallStart callType=${toolCall.callType} name=${toolCall.function.name} argsLen=${toolCall.function.arguments.length}');

              case LLMToolCallDeltaPart(:final toolCall):
                sawAnyDelta = true;
                dump(
                    'ToolCallDelta callType=${toolCall.callType} name=${toolCall.function.name} argsLen=${toolCall.function.arguments.length}');

              case LLMToolCallEndPart():
                dump('ToolCallEnd');

              case LLMToolResultPart(:final result):
                sawAnyDelta = true;
                dump(
                    'ToolResult toolCallId=${result.toolCallId} len=${result.content.length}');

              case LLMProviderMetadataPart(:final providerMetadata):
                dump(
                    'ProviderMetadata keys=${providerMetadata.keys.toList(growable: false).join(',')}');

              case LLMFinishPart(:final response):
                sawFinish = true;
                var blocksSummary = '';
                if (response is ChatResponseWithAssistantMessage) {
                  final assistant = response.assistantMessage;
                  // Protocol-internal: Anthropic-compatible providers preserve
                  // full content blocks for continuity across requests.
                  final anthropic = assistant.getProtocolPayload<Map<String, dynamic>>(
                    'anthropic',
                  );
                  final blocks = anthropic?['contentBlocks'];
                  if (blocks is List) {
                    final types = blocks
                        .whereType<Map>()
                        .map((b) => b['type'])
                        .whereType<String>()
                        .toList(growable: false);
                    blocksSummary =
                        ' contentBlocks=${types.join(',')} (n=${types.length})';
                  }
                }
                dump('Finish textLen=${response.text?.length ?? 0}'
                    ' thinkingLen=${response.thinking?.length ?? 0}'
                    '$blocksSummary');

              case LLMErrorPart(:final error):
                dump('Error ${error.runtimeType}');
                return _CheckResult(
                  name: 'streamChatParts',
                  ok: false,
                  detail: redactor.redact(error.toString()),
                );
            }

            if (sawFinish) break;
          }

          if (!sawFinish) {
            return const _CheckResult(
              name: 'streamChatParts',
              ok: false,
              detail: 'did not finish',
            );
          }

          return _CheckResult(
            name: 'streamChatParts',
            ok: true,
            detail: sawAnyDelta ? null : 'no text/thinking delta observed',
          );
        });

      case _LiveCheck.textToSpeech:
        await run('textToSpeech', () async {
          if (model is! TextToSpeechCapability) {
            return const _CheckResult(
              name: 'textToSpeech',
              ok: false,
              detail: 'not a TextToSpeechCapability',
            );
          }

          final response = await model.textToSpeech(
            const TTSRequest(
              text: 'hello',
            ),
          );
          final bytes = response.audioData;

          if (bytes.isEmpty) {
            return const _CheckResult(
              name: 'textToSpeech',
              ok: false,
              detail: 'empty audio bytes',
            );
          }

          return const _CheckResult(name: 'textToSpeech', ok: true);
        });

      case _LiveCheck.elevenLabsSpeechToSpeech:
        await run('elevenLabsSpeechToSpeech', () async {
          if (model is! ElevenLabsProvider) {
            return const _CheckResult(
              name: 'elevenLabsSpeechToSpeech',
              ok: false,
              detail: 'not an ElevenLabsProvider',
            );
          }

          final seedAudio = await model.textToSpeech(
            const TTSRequest(text: 'hello'),
          );
          final converted = await model.convertSpeechToSpeech(
            SpeechToSpeechRequest(
              audioData: seedAudio.audioData,
            ),
          );

          if (converted.audioData.isEmpty) {
            return const _CheckResult(
              name: 'elevenLabsSpeechToSpeech',
              ok: false,
              detail: 'empty audio bytes',
            );
          }

          return const _CheckResult(name: 'elevenLabsSpeechToSpeech', ok: true);
        });

      case _LiveCheck.elevenLabsForcedAlignment:
        await run('elevenLabsForcedAlignment', () async {
          if (model is! ElevenLabsProvider) {
            return const _CheckResult(
              name: 'elevenLabsForcedAlignment',
              ok: false,
              detail: 'not an ElevenLabsProvider',
            );
          }

          const text = 'hello';
          final seedAudio = await model.textToSpeech(
            const TTSRequest(text: text),
          );

          final alignment = await model.createForcedAlignment(
            ForcedAlignmentRequest(
              audioData: seedAudio.audioData,
              text: text,
            ),
          );

          final ok = alignment.words.isNotEmpty && alignment.characters.isNotEmpty;
          return _CheckResult(
            name: 'elevenLabsForcedAlignment',
            ok: ok,
            detail: ok
                ? null
                : 'empty alignment (words=${alignment.words.length}, chars=${alignment.characters.length})',
          );
        });
    }
  }

  return results;
}

Future<Object> _buildProvider(_ProviderSpec spec,
    {required String? apiKey, String? overrideBaseUrl}) async {
  var builder = ai().provider(spec.providerId);

  if (spec.requiresKey) {
    builder = builder.apiKey(apiKey!);
  }

  final baseUrl = overrideBaseUrl ?? spec.pickBaseUrl();
  if (baseUrl != null) {
    builder = builder.baseUrl(baseUrl);
  }

  final model = spec.pickModel() ?? spec.defaultModel;
  builder = builder.model(model);

  // Keep costs small by default.
  if (spec.liveChecks.contains(_LiveCheck.textToSpeech) == false) {
    final maxTokens = spec.providerId == 'minimax' ? 128 : 32;
    final timeout = spec.providerId == 'minimax'
        ? const Duration(seconds: 60)
        : const Duration(seconds: 30);
    builder = builder.temperature(0).maxTokens(maxTokens).timeout(timeout);
  }

  if (spec.providerOptions != null && spec.providerOptions!.isNotEmpty) {
    builder = builder.providerOptions(spec.providerId, spec.providerOptions!);
  }

  if (spec.providerTools.isNotEmpty) {
    builder = builder.providerTools(spec.providerTools);
  }

  if (spec.liveChecks.contains(_LiveCheck.textToSpeech)) {
    return builder.buildSpeech();
  }

  return builder.build();
}

enum _LiveCheck {
  generateText,
  streamText,
  streamChatParts,
  textToSpeech,
  elevenLabsSpeechToSpeech,
  elevenLabsForcedAlignment,
}

class _ProviderSpec {
  final String providerId;
  final String displayName;
  final List<String> envVars;
  final List<String> baseUrlEnvVars;
  final List<String> modelEnvVars;
  final String defaultModel;
  final String chatPrompt;
  final bool requiresKey;
  final Map<String, dynamic>? providerOptions;
  final List<ProviderTool> providerTools;
  final List<_LiveCheck> liveChecks;

  const _ProviderSpec({
    required this.providerId,
    required this.displayName,
    required this.envVars,
    this.baseUrlEnvVars = const [],
    this.modelEnvVars = const [],
    required this.defaultModel,
    this.chatPrompt = 'ping',
    this.requiresKey = true,
    this.providerOptions,
    this.providerTools = const [],
    this.liveChecks = const [],
  });

  String? pickApiKey() {
    for (final name in envVars) {
      final value = Platform.environment[name];
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String? pickBaseUrl() {
    for (final name in baseUrlEnvVars) {
      final value = Platform.environment[name];
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String? pickModel() {
    for (final name in modelEnvVars) {
      final value = Platform.environment[name];
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}

class _CheckResult {
  final String name;
  final bool ok;
  final String? detail;

  const _CheckResult({
    required this.name,
    required this.ok,
    this.detail,
  });
}

class _Flags {
  final Set<String> providers;
  final bool stream;
  final bool all;
  final int dumpCount;
  final bool dumpChatParts;

  const _Flags({
    required this.providers,
    required this.stream,
    required this.all,
    required this.dumpCount,
    required this.dumpChatParts,
  });
}

_Flags _parseArgs(List<String> args) {
  var stream = false;
  var all = false;
  var dumpCount = 0;
  var dumpChatParts = false;
  final providers = <String>{};

  for (final a in args) {
    if (a == '--stream') {
      stream = true;
      continue;
    }
    if (a == '--all') {
      all = true;
      continue;
    }
    if (a == '--dump-chat-parts') {
      dumpChatParts = true;
      continue;
    }
    if (a == '--dump') {
      dumpCount = 50;
      continue;
    }
    if (a.startsWith('--dump=')) {
      final raw = a.substring('--dump='.length).trim();
      final parsed = int.tryParse(raw);
      if (parsed != null && parsed >= 0) {
        dumpCount = parsed;
      }
      continue;
    }
    if (a.startsWith('--providers=')) {
      final raw = a.substring('--providers='.length).trim();
      if (raw.isNotEmpty) {
        providers.addAll(
            raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
      }
      continue;
    }
  }

  return _Flags(
    providers: providers,
    stream: stream,
    all: all,
    dumpCount: dumpCount,
    dumpChatParts: dumpChatParts,
  );
}

class _Redactor {
  final List<String> secrets;

  const _Redactor({required this.secrets});

  String redact(String input) {
    var out = input;
    for (final s in secrets) {
      if (s.isEmpty) continue;
      out = out.replaceAll(s, '***');
    }
    return out;
  }
}

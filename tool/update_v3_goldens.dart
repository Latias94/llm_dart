import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart' as llm_ai;
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_azure/config.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_openai_compatible/responses.dart' as openai_compat;
import 'package:llm_dart_xai/responses.dart';

import '../test/utils/fakes/anthropic_fake_client.dart';
import '../test/utils/fakes/openai_fake_client.dart';
import '../test/utils/fixture_replay.dart';

/// Updates/checks AI SDK v3-style JSONL golden files under `test/fixtures/v3_parts`.
///
/// This tool is intended to make fixture-driven refactors "fearless":
/// - Replays vendored AI SDK `.chunks.txt` fixtures in `test/fixtures/**`.
/// - Parses them through our providers into [LLMStreamPart] streams.
/// - Encodes parts to canonical v3 JSON objects via [encodeV3StreamParts].
/// - Writes stable `.jsonl` goldens and ensures a `.meta.json` exists.
///
/// It is intentionally conservative:
/// - It never deletes goldens or metas.
/// - It only writes when `--write` is passed.
///
/// Usage:
///   dart run tool/update_v3_goldens.dart --check
///   dart run tool/update_v3_goldens.dart --write
///   dart run tool/update_v3_goldens.dart --write --only=openai,anthropic
void main(List<String> args) async {
  final flags = _parseArgs(args);

  final templateMeta = _readTemplateMeta();

  final scenarios = flags.scope == _Scope.all
      ? _discoverAllScenarios()
      : _discoverOptInScenarios();

  final selected = flags.onlyProviders.isEmpty
      ? scenarios
      : scenarios
          .where((s) => flags.onlyProviders.contains(s.provider))
          .toList(growable: false);

  if (selected.isEmpty) {
    stderr.writeln(
      'No scenarios selected. Known providers: '
      '${scenarios.map((s) => s.provider).toSet().toList()..sort()}',
    );
    exitCode = 2;
    return;
  }

  var hasDiffs = false;
  var wroteAny = false;

  for (final scenario in selected) {
    final fixturePath = scenario.fixturePath;
    final sessions = scenario.splitSessions(fixturePath);
    if (sessions.isEmpty) {
      stderr.writeln('[${scenario.provider}/${scenario.baseName}] no sessions');
      hasDiffs = true;
      continue;
    }

    for (var i = 0; i < sessions.length; i++) {
      final parts = await scenario.runner(
        fixturePath: fixturePath,
        sessionStream: sessions[i],
      );

      final encoded = encodeV3StreamParts(parts);
      final goldenBasePath =
          'test/fixtures/v3_parts/${scenario.provider}/${scenario.baseName}';
      final goldenPath = sessions.length == 1
          ? '$goldenBasePath.jsonl'
          : '$goldenBasePath.session${i + 1}.jsonl';

      final diff = _checkOrWriteJsonl(
        goldenPath: goldenPath,
        objects: encoded,
        write: flags.write,
      );
      if (diff == _JsonlDiffStatus.wrote) wroteAny = true;
      if (diff == _JsonlDiffStatus.different) hasDiffs = true;
    }

    final metaPath =
        'test/fixtures/v3_parts/${scenario.provider}/${scenario.baseName}.meta.json';
    final metaStatus = _ensureMeta(
      metaPath: metaPath,
      template: templateMeta,
      provider: scenario.provider,
      scenario: scenario.baseName,
      fixturePath: scenario.fixturePath,
      repoRefFixturePath: scenario.repoRefFixturePath,
      write: flags.write,
    );
    if (metaStatus == _MetaStatus.wrote) wroteAny = true;
    if (metaStatus == _MetaStatus.missing) hasDiffs = true;
  }

  if (flags.check) {
    if (hasDiffs) {
      stderr.writeln('Goldens out of date. Run with --write to update.');
      exitCode = 1;
      return;
    }
    stdout.writeln('Goldens OK.');
    exitCode = 0;
    return;
  }

  if (flags.write) {
    stdout.writeln(wroteAny ? 'Goldens updated.' : 'No changes.');
    exitCode = 0;
    return;
  }

  stdout.writeln('Nothing to do. Pass --check or --write.');
  exitCode = 2;
}

typedef _ScenarioRunner = Future<List<LLMStreamPart>> Function({
  required String fixturePath,
  required Stream<String> sessionStream,
});

class _Scenario {
  final String provider;
  final String baseName;
  final String fixturePath;
  final String? repoRefFixturePath;
  final List<Stream<String>> Function(String fixturePath) splitSessions;
  final _ScenarioRunner runner;

  const _Scenario({
    required this.provider,
    required this.baseName,
    required this.fixturePath,
    required this.repoRefFixturePath,
    required this.splitSessions,
    required this.runner,
  });
}

List<_Scenario> _discoverAllScenarios() => <_Scenario>[
      ..._discoverScenarios(
        provider: 'openai',
        fixtureDir: Directory('test/fixtures/openai/responses'),
        fixtureRepoRefDir:
            Directory('repo-ref/ai/packages/openai/src/responses/__fixtures__'),
        runner: _runOpenAIResponsesFixture,
        splitSessions: (path) => sseStreamsFromChunkFileSplitByTerminalEvent(
          path,
          isTerminalEvent: isOpenAIResponsesTerminalEvent,
        ),
      ),
      ..._discoverScenarios(
        provider: 'azure',
        fixtureDir: Directory('test/fixtures/azure/responses'),
        fixtureRepoRefDir:
            Directory('repo-ref/ai/packages/azure/src/__fixtures__'),
        runner: _runAzureResponsesFixture,
        splitSessions: (path) => sseStreamsFromChunkFileSplitByTerminalEvent(
          path,
          isTerminalEvent: isOpenAIResponsesTerminalEvent,
        ),
      ),
      ..._discoverScenarios(
        provider: 'anthropic',
        fixtureDir: Directory('test/fixtures/anthropic/messages'),
        fixtureRepoRefDir:
            Directory('repo-ref/ai/packages/anthropic/src/__fixtures__'),
        runner: _runAnthropicMessagesFixture,
        splitSessions: (path) => sseStreamsFromChunkFileSplitByTerminalEvent(
          path,
          isTerminalEvent: isAnthropicMessagesTerminalEvent,
        ),
      ),
      ..._discoverScenarios(
        provider: 'openai_compatible',
        fixtureDir: Directory('test/fixtures/openai_compatible'),
        fixtureRepoRefDir:
            Directory('repo-ref/ai/packages/deepseek/src/chat/__fixtures__'),
        runner: _runDeepSeekOpenAICompatibleFixture,
        splitSessions: (path) => [sseStreamFromChunkFile(path)],
      ),
      ..._discoverScenarios(
        provider: 'xai',
        fixtureDir: Directory('test/fixtures/xai/responses'),
        fixtureRepoRefDir:
            Directory('repo-ref/ai/packages/xai/src/responses/__fixtures__'),
        runner: _runXAIResponsesFixture,
        splitSessions: (path) => sseStreamsFromChunkFileSplitByTerminalEvent(
          path,
          isTerminalEvent: isOpenAIResponsesTerminalEvent,
        ),
      ),
    ];

List<_Scenario> _discoverOptInScenarios() {
  final dir = Directory('test/fixtures/v3_parts');
  if (!dir.existsSync()) return const [];

  final metas = dir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((f) => f.path.endsWith('.meta.json'))
      .where((f) => !_basename(f.path).startsWith('_template.'))
      .toList(growable: false)
    ..sort((a, b) => a.path.compareTo(b.path));

  final scenarios = <_Scenario>[];

  for (final metaFile in metas) {
    final decoded = jsonDecode(metaFile.readAsStringSync());
    if (decoded is! Map) continue;
    final meta = decoded.cast<String, dynamic>();

    final provider = (meta['provider'] as String?)?.trim();
    final scenario = (meta['scenario'] as String?)?.trim();
    if (provider == null || provider.isEmpty) continue;
    if (scenario == null || scenario.isEmpty) continue;

    final fixturePath = _fixturePathFor(provider, scenario);
    if (fixturePath == null) continue;

    scenarios.add(
      _Scenario(
        provider: provider,
        baseName: scenario,
        fixturePath: fixturePath,
        repoRefFixturePath: _repoRefFixturePathFor(provider, scenario),
        splitSessions: (path) => _splitSessionsFor(provider, path),
        runner: _runnerFor(provider),
      ),
    );
  }

  return scenarios;
}

List<Stream<String>> _splitSessionsFor(String provider, String fixturePath) {
  switch (provider) {
    case 'openai':
    case 'azure':
    case 'xai':
      return sseStreamsFromChunkFileSplitByTerminalEvent(
        fixturePath,
        isTerminalEvent: isOpenAIResponsesTerminalEvent,
      );
    case 'anthropic':
      return sseStreamsFromChunkFileSplitByTerminalEvent(
        fixturePath,
        isTerminalEvent: isAnthropicMessagesTerminalEvent,
      );
    case 'openai_compatible':
      return [sseStreamFromChunkFile(fixturePath)];
    default:
      return [sseStreamFromChunkFile(fixturePath)];
  }
}

_ScenarioRunner _runnerFor(String provider) {
  switch (provider) {
    case 'openai':
      return _runOpenAIResponsesFixture;
    case 'azure':
      return _runAzureResponsesFixture;
    case 'anthropic':
      return _runAnthropicMessagesFixture;
    case 'openai_compatible':
      return _runDeepSeekOpenAICompatibleFixture;
    case 'xai':
      return _runXAIResponsesFixture;
  }
  throw ArgumentError('Unsupported provider: $provider');
}

String? _fixturePathFor(String provider, String scenario) {
  final filename = '$scenario.chunks.txt';
  switch (provider) {
    case 'openai':
      return 'test/fixtures/openai/responses/$filename';
    case 'azure':
      return 'test/fixtures/azure/responses/$filename';
    case 'anthropic':
      return 'test/fixtures/anthropic/messages/$filename';
    case 'openai_compatible':
      return 'test/fixtures/openai_compatible/$filename';
    case 'xai':
      return 'test/fixtures/xai/responses/$filename';
  }
  return null;
}

String? _repoRefFixturePathFor(String provider, String scenario) {
  final filename = '$scenario.chunks.txt';
  switch (provider) {
    case 'openai':
      return 'repo-ref/ai/packages/openai/src/responses/__fixtures__/$filename';
    case 'azure':
      return 'repo-ref/ai/packages/azure/src/__fixtures__/$filename';
    case 'anthropic':
      return 'repo-ref/ai/packages/anthropic/src/__fixtures__/$filename';
    case 'openai_compatible':
      return 'repo-ref/ai/packages/deepseek/src/chat/__fixtures__/$filename';
    case 'xai':
      return 'repo-ref/ai/packages/xai/src/responses/__fixtures__/$filename';
  }
  return null;
}

List<_Scenario> _discoverScenarios({
  required String provider,
  required Directory fixtureDir,
  required Directory fixtureRepoRefDir,
  required _ScenarioRunner runner,
  required List<Stream<String>> Function(String fixturePath) splitSessions,
}) {
  if (!fixtureDir.existsSync()) return const [];

  final repoRefByName = <String, String>{};
  if (fixtureRepoRefDir.existsSync()) {
    for (final f in fixtureRepoRefDir
        .listSync(followLinks: false)
        .whereType<File>()
        .where((f) => f.path.endsWith('.chunks.txt'))) {
      repoRefByName[_basename(f.path)] = f.path.replaceAll('\\', '/');
    }
  }

  final fixtures = fixtureDir
      .listSync(followLinks: false)
      .whereType<File>()
      .where((f) => f.path.endsWith('.chunks.txt'))
      .toList(growable: false)
    ..sort((a, b) => a.path.compareTo(b.path));

  return fixtures.map((f) {
    final name = _basename(f.path);
    final baseName = name.substring(0, name.length - '.chunks.txt'.length);
    return _Scenario(
      provider: provider,
      baseName: baseName,
      fixturePath: f.path.replaceAll('\\', '/'),
      repoRefFixturePath: repoRefByName[name],
      splitSessions: splitSessions,
      runner: runner,
    );
  }).toList(growable: false);
}

Future<List<LLMStreamPart>> _runOpenAIResponsesFixture({
  required String fixturePath,
  required Stream<String> sessionStream,
}) async {
  final config = openai_client.OpenAIConfig(
    apiKey: 'test-key',
    baseUrl: 'https://api.openai.com/v1/',
    model: 'gpt-5-mini',
    useResponsesAPI: true,
  );

  final client = FakeOpenAIClient(config)..streamResponse = sessionStream;
  final responses = openai_responses.OpenAIResponses(client, config);
  return responses.chatStreamParts([ChatMessage.user('Hi')]).toList();
}

Future<List<LLMStreamPart>> _runAzureResponsesFixture({
  required String fixturePath,
  required Stream<String> sessionStream,
}) async {
  final config = AzureOpenAIConfig(
    apiKey: 'test-key',
    baseUrl: 'https://example.azure.com/openai/',
    model: 'gpt-4.1-mini',
    useResponsesAPI: true,
  );

  final client = FakeOpenAIClient(config)..streamResponse = sessionStream;
  final responses = openai_compat.OpenAIResponses(client, config);
  return responses.chatStreamParts([ChatMessage.user('Hi')]).toList();
}

Future<List<LLMStreamPart>> _runAnthropicMessagesFixture({
  required String fixturePath,
  required Stream<String> sessionStream,
}) async {
  final config = AnthropicConfig(
    providerId: 'anthropic',
    apiKey: 'test-key',
    model: 'claude-sonnet-4-20250514',
    baseUrl: 'https://api.anthropic.com/v1/',
    stream: true,
  );

  final client = FakeAnthropicClient(config)..streamResponse = sessionStream;
  final chat = AnthropicChat(client, config);

  return llm_ai.streamChatParts(
      model: chat, messages: [ChatMessage.user('Hi')]).toList();
}

class _DeepSeekFakeClient extends OpenAIClient {
  final Stream<String> _stream;

  _DeepSeekFakeClient(
    super.config, {
    required Stream<String> stream,
  }) : _stream = stream;

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) {
    return _stream;
  }
}

Future<List<LLMStreamPart>> _runDeepSeekOpenAICompatibleFixture({
  required String fixturePath,
  required Stream<String> sessionStream,
}) async {
  const capabilities = {LLMCapability.chat, LLMCapability.streaming};

  final config = OpenAICompatibleConfig(
    providerId: 'deepseek',
    providerName: 'DeepSeek',
    apiKey: 'test-key',
    baseUrl: 'https://api.deepseek.com/',
    model: 'deepseek-chat',
  );

  final client = _DeepSeekFakeClient(config, stream: sessionStream);
  final provider = OpenAICompatibleChatProvider(client, config, capabilities);

  return llm_ai.streamChatParts(
      model: provider, messages: [ChatMessage.user('Hi')]).toList();
}

Future<List<LLMStreamPart>> _runXAIResponsesFixture({
  required String fixturePath,
  required Stream<String> sessionStream,
}) async {
  final config = OpenAICompatibleConfig(
    providerId: 'xai.responses',
    providerName: 'xAI (Responses)',
    apiKey: 'test-key',
    baseUrl: 'https://api.x.ai/v1/',
    model: 'grok-4-fast',
  );

  final client = FakeOpenAIClient(config)..streamResponse = sessionStream;
  final responses = XAIResponses(client, config);
  return responses.chatStreamParts([ChatMessage.user('Hi')]).toList();
}

enum _JsonlDiffStatus { ok, different, wrote }

_JsonlDiffStatus _checkOrWriteJsonl({
  required String goldenPath,
  required Iterable<Object?> objects,
  required bool write,
}) {
  final file = File(goldenPath);
  final actualLines = objects
      .map((o) => _stableJsonEncode(o, omitNulls: true))
      .toList(growable: false);

  if (!file.existsSync()) {
    if (!write) {
      stderr.writeln('Missing golden: $goldenPath');
      return _JsonlDiffStatus.different;
    }
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('${actualLines.join('\n')}\n');
    stdout.writeln('Wrote golden: $goldenPath');
    return _JsonlDiffStatus.wrote;
  }

  final expectedLines = file
      .readAsLinesSync()
      .map((l) => l.trimRight())
      .where((l) => l.isNotEmpty)
      .toList(growable: false);

  final same = expectedLines.length == actualLines.length &&
      Iterable<int>.generate(expectedLines.length)
          .every((i) => expectedLines[i] == actualLines[i]);

  if (same) return _JsonlDiffStatus.ok;

  if (!write) {
    stderr.writeln('Golden mismatch: $goldenPath');
    return _JsonlDiffStatus.different;
  }

  file.writeAsStringSync('${actualLines.join('\n')}\n');
  stdout.writeln('Updated golden: $goldenPath');
  return _JsonlDiffStatus.wrote;
}

enum _MetaStatus { ok, missing, wrote }

_MetaStatus _ensureMeta({
  required String metaPath,
  required Map<String, dynamic> template,
  required String provider,
  required String scenario,
  required String fixturePath,
  required String? repoRefFixturePath,
  required bool write,
}) {
  final file = File(metaPath);
  if (file.existsSync()) return _MetaStatus.ok;

  if (!write) {
    stderr.writeln('Missing meta: $metaPath');
    return _MetaStatus.missing;
  }

  final meta = jsonDecode(jsonEncode(template)) as Map<String, dynamic>;
  meta['provider'] = provider;
  meta['scenario'] = scenario;
  meta['description'] =
      'Auto-generated meta for $provider/$scenario (please edit description).';

  final source = (meta['source'] is Map)
      ? (meta['source'] as Map).cast<String, dynamic>()
      : <String, dynamic>{};
  source['type'] = 'vendored-ai-sdk-fixture';

  final paths = <String>[
    fixturePath.replaceAll('\\', '/'),
    if (repoRefFixturePath != null) repoRefFixturePath,
  ];
  source['paths'] = paths;
  source['notes'] =
      'Generated by tool/update_v3_goldens.dart by replaying the .chunks.txt '
      'fixture via fake clients and encoding canonical v3 parts as JSONL.';
  meta['source'] = source;

  file.parent.createSync(recursive: true);
  file.writeAsStringSync(_prettyJson(meta));
  stdout.writeln('Wrote meta: $metaPath');
  return _MetaStatus.wrote;
}

Map<String, dynamic> _readTemplateMeta() {
  final path = 'test/fixtures/v3_parts/_template.meta.json';
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map) {
    throw StateError('Expected JSON object template at $path');
  }
  return decoded.cast<String, dynamic>();
}

String _prettyJson(Object value) =>
    const JsonEncoder.withIndent('  ').convert(value) + '\n';

String _basename(String path) {
  final sep = Platform.pathSeparator;
  final idx = path.lastIndexOf(sep);
  if (idx < 0) return path;
  return path.substring(idx + 1);
}

class _Flags {
  final bool check;
  final bool write;
  final _Scope scope;
  final Set<String> onlyProviders;

  const _Flags({
    required this.check,
    required this.write,
    required this.scope,
    required this.onlyProviders,
  });
}

_Flags _parseArgs(List<String> args) {
  var check = false;
  var write = false;
  var scope = _Scope.optIn;
  final only = <String>{};

  for (final a in args) {
    if (a == '--check') {
      check = true;
      continue;
    }
    if (a == '--write') {
      write = true;
      continue;
    }
    if (a == '--scope=all') {
      scope = _Scope.all;
      continue;
    }
    if (a == '--scope=opt-in') {
      scope = _Scope.optIn;
      continue;
    }
    if (a.startsWith('--only=')) {
      final raw = a.substring('--only='.length).trim();
      if (raw.isNotEmpty) {
        only.addAll(
          raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
        );
      }
      continue;
    }
  }

  if (!check && !write) check = true;
  if (check && write) {
    throw ArgumentError('Pass at most one of --check or --write.');
  }

  return _Flags(
    check: check,
    write: write,
    scope: scope,
    onlyProviders: only,
  );
}

// ---- Stable JSON helpers (golden-friendly) ----

String _stableJsonEncode(
  Object? value, {
  required bool omitNulls,
}) {
  final normalized = _normalizeJsonLike(value, omitNulls: omitNulls);
  return jsonEncode(normalized);
}

Object? _normalizeJsonLike(
  Object? value, {
  required bool omitNulls,
}) {
  if (value == null) return null;

  if (value is DateTime) return value.toIso8601String();

  if (value is Map) {
    final entries = <MapEntry<String, Object?>>[];
    for (final e in value.entries) {
      final key = e.key.toString();
      final normalizedValue = _normalizeJsonLike(e.value, omitNulls: omitNulls);
      if (omitNulls && normalizedValue == null) continue;
      entries.add(MapEntry(key, normalizedValue));
    }

    final sorted = SplayTreeMap<String, Object?>();
    sorted.addEntries(entries);
    return sorted;
  }

  if (value is Iterable) {
    return value
        .map((v) => _normalizeJsonLike(v, omitNulls: omitNulls))
        .toList(growable: false);
  }

  if (value is String) {
    if (_shouldRedactBase64(value)) {
      return {
        r'$redacted': 'base64',
        'len': value.length,
        'hash': _fnv1a64Hex(value),
      };
    }
    return value;
  }

  if (value is num || value is bool) return value;

  return value.toString();
}

bool _shouldRedactBase64(String value) {
  if (value.length <= 4096) return false;
  return _looksLikeBase64(value);
}

bool _looksLikeBase64(String value) {
  for (var i = 0; i < value.length; i++) {
    final c = value.codeUnitAt(i);
    final isAz = c >= 0x41 && c <= 0x5A;
    final isaz = c >= 0x61 && c <= 0x7A;
    final is09 = c >= 0x30 && c <= 0x39;
    if (isAz || isaz || is09) continue;
    if (c == 0x2B /* + */ || c == 0x2F /* / */ || c == 0x3D /* = */) continue;
    return false;
  }
  return true;
}

String _fnv1a64Hex(String value) {
  var hash = BigInt.parse('14695981039346656037');
  final prime = BigInt.parse('1099511628211');
  final mask = BigInt.parse('18446744073709551615');

  final bytes = utf8.encode(value);
  for (final b in bytes) {
    hash = (hash ^ BigInt.from(b)) * prime;
    hash &= mask;
  }

  final hex = hash.toRadixString(16).padLeft(16, '0');
  return 'fnv1a64:$hex';
}

enum _Scope { optIn, all }

library;

import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_core/llm_dart_core.dart';

/// Reads `request.providerTools` from a v3 golden meta file.
///
/// Returns an empty list when the file or field is missing.
List<ProviderTool> readProviderToolsFromV3Meta({
  required String provider,
  required String scenario,
}) {
  final path = 'test/fixtures/v3_parts/$provider/$scenario.meta.json';
  final file = File(path);
  if (!file.existsSync()) return const [];

  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) return const [];
  final meta = decoded.cast<String, dynamic>();

  final request = meta['request'];
  if (request is! Map) return const [];
  final providerTools = request['providerTools'];
  if (providerTools is! List) return const [];

  final out = <ProviderTool>[];
  for (final raw in providerTools) {
    if (raw is! Map) continue;
    try {
      out.add(ProviderTool.fromJson(raw.cast<String, dynamic>()));
    } catch (_) {
      // Skip invalid entries.
    }
  }
  return out;
}

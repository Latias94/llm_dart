import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_citation_projection.dart';
import 'anthropic_result_util.dart';

Iterable<ContentPart> decodeAnthropicResultTextParts(
  Map<String, Object?> part,
) sync* {
  yield TextContentPart(anthropicResultAsString(part['text']) ?? '');

  for (final source in projectAnthropicCitationSources(part['citations'])) {
    yield SourceContentPart(source);
  }
}

ReasoningContentPart decodeAnthropicResultThinkingPart(
  Map<String, Object?> part,
) {
  return ReasoningContentPart(
    anthropicResultAsString(part['thinking']) ?? '',
    providerMetadata: anthropicResultProviderMetadata({
      'signature': anthropicResultAsString(part['signature']),
    }),
  );
}

ReasoningContentPart decodeAnthropicResultRedactedThinkingPart(
  Map<String, Object?> part,
) {
  return ReasoningContentPart(
    '',
    providerMetadata: anthropicResultProviderMetadata({
      'redactedData': anthropicResultAsString(part['data']),
    }),
  );
}

TextContentPart decodeAnthropicResultCompactionPart(
  Map<String, Object?> part,
) {
  return TextContentPart(
    anthropicResultAsString(part['content']) ?? '',
    providerMetadata: anthropicResultProviderMetadata({
      'type': 'compaction',
    }),
  );
}

CustomContentPart? decodeAnthropicResultCustomPart(
  Map<String, Object?> part,
) {
  final type = anthropicResultAsString(part['type']);
  if (type == null) {
    return null;
  }

  return CustomContentPart(
    kind: 'anthropic.$type',
    data: part,
  );
}

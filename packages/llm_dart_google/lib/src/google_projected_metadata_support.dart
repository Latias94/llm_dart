import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_shared.dart';

void attachGoogleMetadataToLastContent(
  List<ContentPart> content,
  ProviderMetadata? metadata,
) {
  if (metadata == null || content.isEmpty) {
    return;
  }

  final last = content.removeLast();
  switch (last) {
    case TextContentPart(:final text, :final providerMetadata):
      content.add(
        TextContentPart(
          text,
          providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
        ),
      );
    case ReasoningContentPart(:final text, :final providerMetadata):
      content.add(
        ReasoningContentPart(
          text,
          providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
        ),
      );
    case ReasoningFileContentPart(:final file, :final providerMetadata):
      content.add(
        ReasoningFileContentPart(
          file,
          providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
        ),
      );
    case ToolCallContentPart(:final toolCall, :final providerMetadata):
      content.add(
        ToolCallContentPart(
          toolCall,
          providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
        ),
      );
    case ToolResultContentPart(:final toolResult, :final providerMetadata):
      content.add(
        ToolResultContentPart(
          toolResult,
          providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
        ),
      );
    case FileContentPart(:final file, :final providerMetadata):
      content.add(
        FileContentPart(
          file,
          providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
        ),
      );
    case CustomContentPart(
        :final kind,
        :final data,
        :final providerMetadata,
      ):
      content.add(
        CustomContentPart(
          kind: kind,
          data: data,
          providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
        ),
      );
    default:
      content.add(last);
  }
}

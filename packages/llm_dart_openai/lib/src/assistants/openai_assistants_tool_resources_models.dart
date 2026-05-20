import '../common/openai_json_value.dart';

final class OpenAIAssistantToolResources {
  final OpenAIAssistantCodeInterpreterResources? codeInterpreter;
  final OpenAIAssistantFileSearchResources? fileSearch;

  const OpenAIAssistantToolResources({
    this.codeInterpreter,
    this.fileSearch,
  });

  factory OpenAIAssistantToolResources.fromJson(Map<String, Object?> json) {
    return OpenAIAssistantToolResources(
      codeInterpreter: json['code_interpreter'] == null
          ? null
          : OpenAIAssistantCodeInterpreterResources.fromJson(
              openAIRequiredMap(
                json['code_interpreter'],
                path: 'tool_resources.code_interpreter',
              ),
            ),
      fileSearch: json['file_search'] == null
          ? null
          : OpenAIAssistantFileSearchResources.fromJson(
              openAIRequiredMap(
                json['file_search'],
                path: 'tool_resources.file_search',
              ),
            ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      if (codeInterpreter != null)
        'code_interpreter': codeInterpreter!.toJson(),
      if (fileSearch != null) 'file_search': fileSearch!.toJson(),
    };
  }
}

final class OpenAIAssistantCodeInterpreterResources {
  final List<String>? fileIds;

  const OpenAIAssistantCodeInterpreterResources({
    this.fileIds,
  });

  factory OpenAIAssistantCodeInterpreterResources.fromJson(
    Map<String, Object?> json,
  ) {
    return OpenAIAssistantCodeInterpreterResources(
      fileIds: openAIOptionalStringList(
        json['file_ids'],
        path: 'code_interpreter.file_ids',
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      if (fileIds != null) 'file_ids': List<String>.unmodifiable(fileIds!),
    };
  }
}

final class OpenAIAssistantFileSearchResources {
  final List<String>? vectorStoreIds;
  final List<OpenAIAssistantVectorStoreRequest>? vectorStores;

  const OpenAIAssistantFileSearchResources({
    this.vectorStoreIds,
    this.vectorStores,
  });

  factory OpenAIAssistantFileSearchResources.fromJson(
    Map<String, Object?> json,
  ) {
    return OpenAIAssistantFileSearchResources(
      vectorStoreIds: openAIOptionalStringList(
        json['vector_store_ids'],
        path: 'file_search.vector_store_ids',
      ),
      vectorStores: openAIOptionalList(
        json['vector_stores'],
        path: 'file_search.vector_stores',
      )
          ?.asMap()
          .entries
          .map(
            (entry) => OpenAIAssistantVectorStoreRequest.fromJson(
              openAIRequiredMap(
                entry.value,
                path: 'file_search.vector_stores[${entry.key}]',
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, Object?> toJson() {
    return {
      if (vectorStoreIds != null)
        'vector_store_ids': List<String>.unmodifiable(vectorStoreIds!),
      if (vectorStores != null)
        'vector_stores': vectorStores!.map((store) => store.toJson()).toList(),
    };
  }
}

final class OpenAIAssistantVectorStoreRequest {
  final List<String>? fileIds;
  final Map<String, Object?>? chunkingStrategy;
  final Map<String, String>? metadata;

  const OpenAIAssistantVectorStoreRequest({
    this.fileIds,
    this.chunkingStrategy,
    this.metadata,
  });

  factory OpenAIAssistantVectorStoreRequest.fromJson(
    Map<String, Object?> json,
  ) {
    return OpenAIAssistantVectorStoreRequest(
      fileIds: openAIOptionalStringList(
        json['file_ids'],
        path: 'vector_store.file_ids',
      ),
      chunkingStrategy: json['chunking_strategy'] == null
          ? null
          : openAIRequiredMap(
              json['chunking_strategy'],
              path: 'vector_store.chunking_strategy',
            ),
      metadata: openAIOptionalStringMap(
        json['metadata'],
        path: 'vector_store.metadata',
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      if (fileIds != null) 'file_ids': List<String>.unmodifiable(fileIds!),
      if (chunkingStrategy != null)
        'chunking_strategy': Map<String, Object?>.unmodifiable(
          chunkingStrategy!,
        ),
      if (metadata != null)
        'metadata': Map<String, String>.unmodifiable(
          metadata!,
        ),
    };
  }
}

part of 'openai_assistant_support.dart';

final class _OpenAIAssistantQuerySupport {
  const _OpenAIAssistantQuerySupport();

  String buildListEndpoint(ListAssistantsQuery? query) {
    if (query == null) {
      return 'assistants';
    }

    final queryParams = query.toQueryParameters();
    if (queryParams.isEmpty) {
      return 'assistants';
    }

    final queryString = queryParams.entries
        .map((entry) => '${entry.key}=${Uri.encodeComponent('${entry.value}')}')
        .join('&');
    return 'assistants?$queryString';
  }

  Assistant? findAssistantByName(
    List<Assistant> assistants,
    String name,
  ) {
    for (final assistant in assistants) {
      if (assistant.name == name) {
        return assistant;
      }
    }

    return null;
  }

  List<Assistant> filterByModel(
    List<Assistant> assistants,
    String model,
  ) {
    return assistants.where((assistant) => assistant.model == model).toList();
  }

  List<Assistant> searchAssistants(
    List<Assistant> assistants, {
    String? namePattern,
    String? model,
    List<String>? requiredTools,
    Map<String, String>? metadataFilters,
  }) {
    var filtered = assistants;

    if (namePattern != null) {
      final regex = RegExp(namePattern, caseSensitive: false);
      filtered = filtered.where((assistant) {
        final name = assistant.name;
        return name != null && regex.hasMatch(name);
      }).toList();
    }

    if (model != null) {
      filtered =
          filtered.where((assistant) => assistant.model == model).toList();
    }

    if (requiredTools != null && requiredTools.isNotEmpty) {
      filtered = filtered.where((assistant) {
        final assistantTools = assistant.tools.map((tool) => tool.type.value);
        return requiredTools.every(assistantTools.contains);
      }).toList();
    }

    if (metadataFilters != null && metadataFilters.isNotEmpty) {
      filtered = filtered.where((assistant) {
        final metadata = assistant.metadata ?? <String, String>{};
        return metadataFilters.entries
            .every((filter) => metadata[filter.key] == filter.value);
      }).toList();
    }

    return filtered;
  }
}

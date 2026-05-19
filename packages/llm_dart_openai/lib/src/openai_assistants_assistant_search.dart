import 'openai_assistants_assistant_model.dart';

List<OpenAIAssistant> openAISearchAssistants(
  List<OpenAIAssistant> assistants, {
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
    }).toList(growable: false);
  }

  if (model != null) {
    filtered = filtered
        .where((assistant) => assistant.model == model)
        .toList(growable: false);
  }

  if (requiredTools != null && requiredTools.isNotEmpty) {
    filtered = filtered.where((assistant) {
      final toolTypes = assistant.tools
          .map((tool) => tool.toJson()['type'])
          .whereType<String>()
          .toSet();
      return requiredTools.every(toolTypes.contains);
    }).toList(growable: false);
  }

  if (metadataFilters != null && metadataFilters.isNotEmpty) {
    filtered = filtered.where((assistant) {
      final metadata = assistant.metadata ?? const <String, String>{};
      return metadataFilters.entries
          .every((filter) => metadata[filter.key] == filter.value);
    }).toList(growable: false);
  }

  return filtered;
}

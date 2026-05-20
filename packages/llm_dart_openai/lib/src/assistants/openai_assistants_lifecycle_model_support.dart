import '../common/openai_json_value.dart';

Map<String, String> openAIAssistantsPaginationQueryParameters({
  int? limit,
  String? order,
  String? after,
  String? before,
  required String limitParameterName,
  required String limitErrorMessage,
  Map<String, String> extra = const {},
}) {
  if (limit != null && limit < 1) {
    throw ArgumentError.value(limit, limitParameterName, limitErrorMessage);
  }

  return {
    if (limit != null) 'limit': '$limit',
    if (order != null && order.isNotEmpty) 'order': order,
    if (after != null && after.isNotEmpty) 'after': after,
    if (before != null && before.isNotEmpty) 'before': before,
    ...extra,
  };
}

List<Map<String, Object?>> openAIAssistantsMapListFromJson(
  Object? value, {
  required String path,
}) {
  final list = openAIOptionalList(value, path: path);
  if (list == null) {
    return const [];
  }
  return list
      .asMap()
      .entries
      .map(
        (entry) => openAIRequiredMap(
          entry.value,
          path: '$path[${entry.key}]',
        ),
      )
      .toList(growable: false);
}

List<Map<String, Object?>> openAIAssistantsCopyMapList(
  List<Map<String, Object?>> items,
) {
  return items.map((item) => Map<String, Object?>.unmodifiable(item)).toList(
        growable: false,
      );
}

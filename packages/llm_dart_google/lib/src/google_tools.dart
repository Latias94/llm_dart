sealed class GoogleNativeTool {
  const GoogleNativeTool();

  String get name;

  Map<String, Object?> toJson();
}

final class GoogleSearchTypes {
  final bool webSearch;
  final bool imageSearch;

  const GoogleSearchTypes({
    this.webSearch = true,
    this.imageSearch = false,
  });

  Map<String, Object?> toJson() {
    final json = <String, Object?>{};

    if (webSearch) {
      json['webSearch'] = const <String, Object?>{};
    }

    if (imageSearch) {
      json['imageSearch'] = const <String, Object?>{};
    }

    if (json.isEmpty) {
      throw ArgumentError(
        'GoogleSearchTypes must enable at least one search type.',
      );
    }

    return json;
  }
}

final class GoogleTimeRangeFilter {
  final DateTime startTime;
  final DateTime endTime;

  const GoogleTimeRangeFilter({
    required this.startTime,
    required this.endTime,
  });

  Map<String, Object?> toJson() {
    if (endTime.isBefore(startTime)) {
      throw ArgumentError(
        'GoogleTimeRangeFilter.endTime must be on or after startTime.',
      );
    }

    return {
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
    };
  }
}

final class GoogleSearchTool extends GoogleNativeTool {
  final GoogleSearchTypes? searchTypes;
  final GoogleTimeRangeFilter? timeRangeFilter;

  const GoogleSearchTool({
    this.searchTypes,
    this.timeRangeFilter,
  });

  @override
  String get name => 'google_search';

  @override
  Map<String, Object?> toJson() {
    return {
      'googleSearch': {
        if (searchTypes != null) 'searchTypes': searchTypes!.toJson(),
        if (timeRangeFilter != null)
          'timeRangeFilter': timeRangeFilter!.toJson(),
      },
    };
  }
}

final class GoogleCodeExecutionTool extends GoogleNativeTool {
  const GoogleCodeExecutionTool();

  @override
  String get name => 'code_execution';

  @override
  Map<String, Object?> toJson() {
    return const {
      'codeExecution': <String, Object?>{},
    };
  }
}

abstract final class GoogleTools {
  static GoogleSearchTool googleSearch({
    GoogleSearchTypes? searchTypes,
    GoogleTimeRangeFilter? timeRangeFilter,
  }) {
    return GoogleSearchTool(
      searchTypes: searchTypes,
      timeRangeFilter: timeRangeFilter,
    );
  }

  static GoogleCodeExecutionTool codeExecution() {
    return const GoogleCodeExecutionTool();
  }
}

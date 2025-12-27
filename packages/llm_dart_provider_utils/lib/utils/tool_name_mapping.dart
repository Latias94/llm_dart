/// Collision-safe mapping between user-defined tool names and provider request
/// tool names.
///
/// Vercel AI SDK uses a similar idea to avoid collisions between:
/// - locally executed function tools
/// - provider-executed built-in tools (provider-native tools)
///
/// In `llm_dart`, this mapping will gradually replace "reserved tool names +
/// throw" heuristics inside provider packages.
library;

class ToolNameMapping {
  /// Original function tool name -> request name sent to the provider.
  final Map<String, String> functionNameToRequestName;

  /// Request tool name -> original function tool name.
  ///
  /// This is needed to map provider tool-call events back to the local tool.
  final Map<String, String> requestNameToFunctionName;

  /// Provider tool id -> request tool name.
  ///
  /// For provider-native tools, the request name is usually fixed by the
  /// provider protocol. This mapping is still useful to:
  /// - expose stable ids at the SDK surface
  /// - map request events back to stable ids
  final Map<String, String> providerToolIdToRequestName;

  /// Request tool name -> provider tool id.
  final Map<String, String> requestNameToProviderToolId;

  const ToolNameMapping({
    required this.functionNameToRequestName,
    required this.requestNameToFunctionName,
    required this.providerToolIdToRequestName,
    required this.requestNameToProviderToolId,
  });

  String requestNameForFunction(String originalName) =>
      functionNameToRequestName[originalName] ?? originalName;

  String? originalFunctionNameForRequestName(String requestName) =>
      requestNameToFunctionName[requestName];

  String? requestNameForProviderToolId(String id) =>
      providerToolIdToRequestName[id];

  String? providerToolIdForRequestName(String requestName) =>
      requestNameToProviderToolId[requestName];
}

/// Creates a collision-safe mapping for a request.
///
/// - Provider-native tool request names are treated as reserved.
/// - Function tool names are rewritten only when they collide.
ToolNameMapping createToolNameMapping({
  required Iterable<String> functionToolNames,
  required Map<String, String> providerToolRequestNamesById,
  String collisionSeparator = '__',
}) {
  final originalFunctionNames = functionToolNames.toSet();
  final providerReservedNames = providerToolRequestNamesById.values.toSet();

  // Names that should never be assigned as a *rewritten* function tool name.
  //
  // We include all original function names to avoid order-dependent collisions,
  // e.g. if one tool is named `x__1`, we should not rewrite another tool to
  // `x__1` just because it appears later in the list.
  final globallyReservedNames = <String>{
    ...providerReservedNames,
    ...originalFunctionNames,
  };

  // Names already assigned as request names for function tools (ensures
  // uniqueness in the final request).
  final assignedRequestNames = <String>{...providerReservedNames};

  final functionNameToRequestName = <String, String>{};
  final requestNameToFunctionName = <String, String>{};

  for (final original in functionToolNames) {
    var requestName = original;

    final collidesWithProvider =
        providerReservedNames.contains(requestName) || requestName.isEmpty;

    final collidesWithAssigned = assignedRequestNames.contains(requestName);

    if (collidesWithProvider || collidesWithAssigned) {
      var counter = 1;
      while (true) {
        final candidate = '$original$collisionSeparator$counter';

        final collidesWithProviderReserved =
            providerReservedNames.contains(candidate);
        final collidesWithAssignedNames = assignedRequestNames.contains(
          candidate,
        );

        // Avoid collisions with other tools' *original* names to make the
        // mapping order-independent.
        final collidesWithOtherOriginalName =
            globallyReservedNames.contains(candidate) && candidate != original;

        if (!collidesWithProviderReserved &&
            !collidesWithAssignedNames &&
            !collidesWithOtherOriginalName) {
          requestName = candidate;
          break;
        }

        counter++;
      }
    }

    assignedRequestNames.add(requestName);
    functionNameToRequestName[original] = requestName;
    requestNameToFunctionName[requestName] = original;
  }

  final providerToolIdToRequestName =
      Map<String, String>.from(providerToolRequestNamesById);

  final requestNameToProviderToolId = <String, String>{};
  for (final entry in providerToolRequestNamesById.entries) {
    requestNameToProviderToolId[entry.value] = entry.key;
  }

  return ToolNameMapping(
    functionNameToRequestName: functionNameToRequestName,
    requestNameToFunctionName: requestNameToFunctionName,
    providerToolIdToRequestName: providerToolIdToRequestName,
    requestNameToProviderToolId: requestNameToProviderToolId,
  );
}

import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_family_url_support.dart';
import 'openai_json_support.dart';
import 'openai_json_value.dart';
import 'openai_non_text_model_support.dart';
import 'openai_profile_boundary.dart';

final class OpenAIResponsesLifecycleSettings {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAIResponsesLifecycleSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAIRawResponse {
  final Map<String, Object?> json;

  OpenAIRawResponse(Map<String, Object?> json) : json = Map.unmodifiable(json);

  factory OpenAIRawResponse.fromJson(Map<String, Object?> json) {
    return OpenAIRawResponse(json);
  }

  String? get id => openAIOptionalString(json['id'], path: 'response.id');

  String? get status =>
      openAIOptionalString(json['status'], path: 'response.status');

  String? get model =>
      openAIOptionalString(json['model'], path: 'response.model');

  String? get outputText =>
      openAIOptionalString(
        json['output_text'],
        path: 'response.output_text',
      ) ??
      _extractOutputText(json);

  Object? operator [](String key) => json[key];

  Map<String, Object?> toJson() => json;
}

final class OpenAIResponseInputItemsList {
  final String object;
  final List<OpenAIResponseInputItem> data;
  final String? firstId;
  final String? lastId;
  final bool hasMore;

  const OpenAIResponseInputItemsList({
    this.object = 'list',
    required this.data,
    this.firstId,
    this.lastId,
    required this.hasMore,
  });

  factory OpenAIResponseInputItemsList.fromJson(Map<String, Object?> json) {
    return OpenAIResponseInputItemsList(
      object: openAIOptionalString(
            json['object'],
            path: 'input_items.object',
          ) ??
          'list',
      data: openAIRequiredList(json['data'], path: 'input_items.data')
          .asMap()
          .entries
          .map(
            (entry) => OpenAIResponseInputItem.fromJson(
              openAIRequiredMap(
                entry.value,
                path: 'input_items.data[${entry.key}]',
              ),
            ),
          )
          .toList(growable: false),
      firstId: openAIOptionalString(
        json['first_id'],
        path: 'input_items.first_id',
      ),
      lastId: openAIOptionalString(
        json['last_id'],
        path: 'input_items.last_id',
      ),
      hasMore: openAIRequiredBool(
        json['has_more'],
        path: 'input_items.has_more',
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'object': object,
      'data': data.map((item) => item.toJson()).toList(growable: false),
      if (firstId != null) 'first_id': firstId,
      if (lastId != null) 'last_id': lastId,
      'has_more': hasMore,
    };
  }
}

final class OpenAIResponseInputItem {
  final String id;
  final String type;
  final String? role;
  final List<Map<String, Object?>>? content;
  final Map<String, Object?> json;

  OpenAIResponseInputItem({
    required this.id,
    required this.type,
    this.role,
    this.content,
    Map<String, Object?>? json,
  }) : json = Map.unmodifiable(
          json ??
              {
                'id': id,
                'type': type,
                if (role != null) 'role': role,
                if (content != null) 'content': content,
              },
        );

  factory OpenAIResponseInputItem.fromJson(Map<String, Object?> json) {
    return OpenAIResponseInputItem(
      id: openAIRequiredNonEmptyString(json['id'], path: 'input_item.id'),
      type: openAIRequiredNonEmptyString(
        json['type'],
        path: 'input_item.type',
      ),
      role: openAIOptionalString(json['role'], path: 'input_item.role'),
      content: openAIOptionalList(json['content'], path: 'input_item.content')
          ?.asMap()
          .entries
          .map(
            (entry) => openAIRequiredMap(
              entry.value,
              path: 'input_item.content[${entry.key}]',
            ),
          )
          .toList(growable: false),
      json: json,
    );
  }

  Map<String, Object?> toJson() => json;
}

final class OpenAIResponseDeleteResult {
  final String id;
  final String object;
  final bool deleted;

  const OpenAIResponseDeleteResult({
    required this.id,
    this.object = 'response.deleted',
    required this.deleted,
  });

  factory OpenAIResponseDeleteResult.fromJson(Map<String, Object?> json) {
    return OpenAIResponseDeleteResult(
      id: openAIRequiredNonEmptyString(
        json['id'],
        path: 'response_delete.id',
      ),
      object: openAIOptionalString(
            json['object'],
            path: 'response_delete.object',
          ) ??
          'response.deleted',
      deleted: openAIRequiredBool(
        json['deleted'],
        path: 'response_delete.deleted',
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'object': object,
      'deleted': deleted,
    };
  }
}

final class OpenAIResponsesLifecycleClient {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final OpenAIResponsesLifecycleSettings settings;

  OpenAIResponsesLifecycleClient({
    required this.apiKey,
    required this.profile,
    required this.transport,
    this.settings = const OpenAIResponsesLifecycleSettings(),
    String? baseUrl,
  }) : baseUrl = normalizeOpenAIFamilyBaseUrl(baseUrl, profile) {
    requireOpenAIProfile(
      profile,
      featureName: 'OpenAI Responses lifecycle client',
    );
  }

  Uri get responsesUri => Uri.parse('$baseUrl/responses');

  Uri responseUri(
    String responseId, {
    List<String>? include,
    int? startingAfter,
    bool stream = false,
  }) {
    return _uriWithQuery(
      '$baseUrl/responses/${Uri.encodeComponent(_requireNonEmptyId(
        responseId,
        parameterName: 'responseId',
      ))}',
      {
        if (include != null && include.isNotEmpty) 'include': include.join(','),
        if (startingAfter != null) 'starting_after': '$startingAfter',
        if (stream) 'stream': '$stream',
      },
    );
  }

  Uri cancelResponseUri(String responseId) {
    return Uri.parse(
      '$baseUrl/responses/${Uri.encodeComponent(_requireNonEmptyId(
        responseId,
        parameterName: 'responseId',
      ))}/cancel',
    );
  }

  Uri inputItemsUri(
    String responseId, {
    String? after,
    String? before,
    List<String>? include,
    int limit = 20,
    String order = 'desc',
  }) {
    if (limit < 1) {
      throw ArgumentError.value(
        limit,
        'limit',
        'OpenAI response input item list limit must be >= 1.',
      );
    }

    return _uriWithQuery(
      '$baseUrl/responses/${Uri.encodeComponent(_requireNonEmptyId(
        responseId,
        parameterName: 'responseId',
      ))}/input_items',
      {
        'limit': '$limit',
        if (order.isNotEmpty) 'order': order,
        if (after != null && after.isNotEmpty) 'after': after,
        if (before != null && before.isNotEmpty) 'before': before,
        if (include != null && include.isNotEmpty) 'include': include.join(','),
      },
    );
  }

  Future<OpenAIRawResponse> createResponse(
    Map<String, Object?> body, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await transport.send(
      TransportRequest(
        uri: responsesUri,
        method: TransportMethod.post,
        headers: _buildHeaders(extraHeaders: headers, contentType: true),
        body: body,
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return OpenAIRawResponse.fromJson(
      decodeOpenAIJsonObject(
        response.body,
        responseName: 'Responses create response',
      ),
    );
  }

  Future<OpenAIRawResponse> getResponse(
    String responseId, {
    List<String>? include,
    int? startingAfter,
    bool stream = false,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await transport.send(
      TransportRequest(
        uri: responseUri(
          responseId,
          include: include,
          startingAfter: startingAfter,
          stream: stream,
        ),
        method: TransportMethod.get,
        headers: _buildHeaders(extraHeaders: headers),
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return OpenAIRawResponse.fromJson(
      decodeOpenAIJsonObject(
        response.body,
        responseName: 'Responses retrieve response',
      ),
    );
  }

  Future<OpenAIResponseDeleteResult> deleteResponse(
    String responseId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await transport.send(
      TransportRequest(
        uri: responseUri(responseId),
        method: TransportMethod.delete,
        headers: _buildHeaders(extraHeaders: headers),
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return OpenAIResponseDeleteResult.fromJson(
      decodeOpenAIJsonObject(
        response.body,
        responseName: 'Responses delete response',
      ),
    );
  }

  Future<OpenAIRawResponse> cancelResponse(
    String responseId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await transport.send(
      TransportRequest(
        uri: cancelResponseUri(responseId),
        method: TransportMethod.post,
        headers: _buildHeaders(extraHeaders: headers, contentType: true),
        body: const <String, Object?>{},
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return OpenAIRawResponse.fromJson(
      decodeOpenAIJsonObject(
        response.body,
        responseName: 'Responses cancel response',
      ),
    );
  }

  Future<OpenAIResponseInputItemsList> listInputItems(
    String responseId, {
    String? after,
    String? before,
    List<String>? include,
    int limit = 20,
    String order = 'desc',
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await transport.send(
      TransportRequest(
        uri: inputItemsUri(
          responseId,
          after: after,
          before: before,
          include: include,
          limit: limit,
          order: order,
        ),
        method: TransportMethod.get,
        headers: _buildHeaders(extraHeaders: headers),
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return OpenAIResponseInputItemsList.fromJson(
      decodeOpenAIJsonObject(
        response.body,
        responseName: 'Responses input items response',
      ),
    );
  }

  Future<OpenAIRawResponse> continueConversation(
    String previousResponseId,
    Map<String, Object?> body, {
    bool? background,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return createResponse(
      {
        ...body,
        'previous_response_id': _requireNonEmptyId(
          previousResponseId,
          parameterName: 'previousResponseId',
        ),
        if (background != null) 'background': background,
      },
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIRawResponse> forkConversation(
    String fromResponseId,
    Map<String, Object?> body, {
    bool? background,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return continueConversation(
      fromResponseId,
      body,
      background: background,
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Map<String, String> _buildHeaders({
    Map<String, String>? extraHeaders,
    bool contentType = false,
  }) {
    return buildOpenAIFamilyDefaultHeaders(
      profile: profile,
      apiKey: apiKey,
      organization: settings.organization,
      project: settings.project,
      headers: {
        ...settings.headers,
        if (contentType) 'content-type': 'application/json',
        'accept': 'application/json',
        if (extraHeaders != null) ...extraHeaders,
      },
    );
  }
}

Uri _uriWithQuery(String uri, Map<String, String> queryParameters) {
  final parsed = Uri.parse(uri);
  if (queryParameters.isEmpty) {
    return parsed;
  }
  return parsed.replace(queryParameters: queryParameters);
}

String _requireNonEmptyId(
  String value, {
  required String parameterName,
}) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      parameterName,
      'Expected a non-empty OpenAI response ID.',
    );
  }
  return normalized;
}

String? _extractOutputText(Map<String, Object?> json) {
  final output = json['output'];
  if (output is! List) {
    return null;
  }

  for (final item in output) {
    final itemJson = openAIOptionalMap(item, path: 'response.output[]');
    if (itemJson == null || itemJson['type'] != 'message') {
      continue;
    }

    final content = itemJson['content'];
    if (content is! List) {
      continue;
    }

    for (final part in content) {
      final partJson = openAIOptionalMap(
        part,
        path: 'response.output[].content[]',
      );
      if (partJson == null || partJson['type'] != 'output_text') {
        continue;
      }

      final text = openAIOptionalString(
        partJson['text'],
        path: 'response.output[].content[].text',
      );
      if (text != null) {
        return text;
      }
    }
  }

  return null;
}

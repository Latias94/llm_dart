/// Models for OpenAI Responses API
library;

/// Response input items list for Responses API
class ResponseInputItemsList {
  /// The type of object returned, always 'list'
  final String object;

  /// List of input items
  final List<ResponseInputItem> data;

  /// ID of the first item in the list
  final String? firstId;

  /// ID of the last item in the list
  final String? lastId;

  /// Whether there are more items available
  final bool hasMore;

  const ResponseInputItemsList({
    required this.object,
    required this.data,
    this.firstId,
    this.lastId,
    required this.hasMore,
  });

  factory ResponseInputItemsList.fromJson(Map<String, dynamic> json) {
    return ResponseInputItemsList(
      object: json['object'] as String,
      data: (json['data'] as List)
          .map((item) =>
              ResponseInputItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      firstId: json['first_id'] as String?,
      lastId: json['last_id'] as String?,
      hasMore: json['has_more'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'object': object,
      'data': data.map((item) => item.toJson()).toList(),
      if (firstId != null) 'first_id': firstId,
      if (lastId != null) 'last_id': lastId,
      'has_more': hasMore,
    };
  }
}

/// Individual input item in a response
class ResponseInputItem {
  /// Unique identifier for the input item
  final String id;

  /// Type of input item (e.g., 'message')
  final String type;

  /// Role of the message (for message type items)
  final String? role;

  /// Content of the input item
  final List<Map<String, dynamic>>? content;

  const ResponseInputItem({
    required this.id,
    required this.type,
    this.role,
    this.content,
  });

  factory ResponseInputItem.fromJson(Map<String, dynamic> json) {
    return ResponseInputItem(
      id: json['id'] as String,
      type: json['type'] as String,
      role: json['role'] as String?,
      content: (json['content'] as List?)
          ?.map((item) => item as Map<String, dynamic>)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
    };
  }
}

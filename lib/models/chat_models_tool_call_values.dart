import 'dart:convert';

/// Tool call represents a function call that an LLM wants to make.
class ToolCall {
  /// The ID of the tool call.
  final String id;

  /// The type of the tool call (usually "function").
  final String callType;

  /// The function to call.
  final FunctionCall function;

  const ToolCall({
    required this.id,
    required this.callType,
    required this.function,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': callType,
        'function': function.toJson(),
      };

  factory ToolCall.fromJson(Map<String, dynamic> json) => ToolCall(
        id: json['id'] as String,
        callType: json['type'] as String,
        function:
            FunctionCall.fromJson(json['function'] as Map<String, dynamic>),
      );

  @override
  String toString() => jsonEncode(toJson());
}

/// FunctionCall contains details about which function to call and with what arguments.
class FunctionCall {
  /// The name of the function to call.
  final String name;

  /// The arguments to pass to the function, typically serialized as a JSON string.
  final String arguments;

  const FunctionCall({required this.name, required this.arguments});

  Map<String, dynamic> toJson() => {'name': name, 'arguments': arguments};

  factory FunctionCall.fromJson(Map<String, dynamic> json) => FunctionCall(
        name: json['name'] as String,
        arguments: json['arguments'] as String,
      );

  @override
  String toString() => jsonEncode(toJson());
}

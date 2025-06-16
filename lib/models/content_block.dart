/// Interface for provider-specific content blocks
abstract class ContentBlock {
  /// The text representation of this content block
  String get displayText;

  /// The provider identifier for this content block
  String get providerId;

  /// Convert this content block to JSON format
  Map<String, dynamic> toJson();
}
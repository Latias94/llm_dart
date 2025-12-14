import 'dart:convert';

/// Request for content moderation
class ModerationRequest {
  /// The input text to classify
  final dynamic input;

  /// Two content moderations models are available: text-moderation-stable and text-moderation-latest.
  final String? model;

  const ModerationRequest({
    required this.input,
    this.model,
  });

  Map<String, dynamic> toJson() {
    return {
      'input': input,
      if (model != null) 'model': model,
    };
  }
}

/// Categories of content that may be flagged by moderation
class ModerationCategories {
  /// Content that expresses, incites, or promotes hate based on race, gender, ethnicity, religion, nationality, sexual orientation, disability status, or caste.
  final bool hate;

  /// Hateful content that also includes violence or serious harm towards the targeted group based on race, gender, ethnicity, religion, nationality, sexual orientation, disability status, or caste.
  final bool hateThreatening;

  /// Content that expresses, incites, or promotes harassing language towards any target.
  final bool harassment;

  /// Harassment content that also includes violence or serious harm towards any target.
  final bool harassmentThreatening;

  /// Content that promotes, encourages, or depicts acts of self-harm, such as suicide, cutting, and eating disorders.
  final bool selfHarm;

  /// Content where the speaker expresses that they are engaging or intend to engage in acts of self-harm, such as suicide or cutting.
  final bool selfHarmIntent;

  /// Content that encourages performing acts of self-harm, such as suicide, cutting, and eating disorders, or that gives instructions or advice on how to commit such acts.
  final bool selfHarmInstructions;

  /// Content meant to arouse sexual excitement, such as the description of sexual activity, or that promotes sexual services (excluding sex education and wellness).
  final bool sexual;

  /// Sexual content that includes an individual who is under 18 years old.
  final bool sexualMinors;

  /// Content that depicts death, violence, or physical injury.
  final bool violence;

  /// Content that depicts death, violence, or physical injury in graphic detail.
  final bool violenceGraphic;

  const ModerationCategories({
    required this.hate,
    required this.hateThreatening,
    required this.harassment,
    required this.harassmentThreatening,
    required this.selfHarm,
    required this.selfHarmIntent,
    required this.selfHarmInstructions,
    required this.sexual,
    required this.sexualMinors,
    required this.violence,
    required this.violenceGraphic,
  });

  factory ModerationCategories.fromJson(Map<String, dynamic> json) {
    return ModerationCategories(
      hate: json['hate'] as bool,
      hateThreatening: json['hate/threatening'] as bool,
      harassment: json['harassment'] as bool,
      harassmentThreatening: json['harassment/threatening'] as bool,
      selfHarm: json['self-harm'] as bool,
      selfHarmIntent: json['self-harm/intent'] as bool,
      selfHarmInstructions: json['self-harm/instructions'] as bool,
      sexual: json['sexual'] as bool,
      sexualMinors: json['sexual/minors'] as bool,
      violence: json['violence'] as bool,
      violenceGraphic: json['violence/graphic'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hate': hate,
      'hate/threatening': hateThreatening,
      'harassment': harassment,
      'harassment/threatening': harassmentThreatening,
      'self-harm': selfHarm,
      'self-harm/intent': selfHarmIntent,
      'self-harm/instructions': selfHarmInstructions,
      'sexual': sexual,
      'sexual/minors': sexualMinors,
      'violence': violence,
      'violence/graphic': violenceGraphic,
    };
  }
}

/// Confidence scores for each category
class ModerationCategoryScores {
  /// The score for "hate" category
  final double hate;

  /// The score for "hate/threatening" category
  final double hateThreatening;

  /// The score for "harassment" category
  final double harassment;

  /// The score for "harassment/threatening" category
  final double harassmentThreatening;

  /// The score for "self-harm" category
  final double selfHarm;

  /// The score for "self-harm/intent" category
  final double selfHarmIntent;

  /// The score for "self-harm/instructions" category
  final double selfHarmInstructions;

  /// The score for "sexual" category
  final double sexual;

  /// The score for "sexual/minors" category
  final double sexualMinors;

  /// The score for "violence" category
  final double violence;

  /// The score for "violence/graphic" category
  final double violenceGraphic;

  const ModerationCategoryScores({
    required this.hate,
    required this.hateThreatening,
    required this.harassment,
    required this.harassmentThreatening,
    required this.selfHarm,
    required this.selfHarmIntent,
    required this.selfHarmInstructions,
    required this.sexual,
    required this.sexualMinors,
    required this.violence,
    required this.violenceGraphic,
  });

  factory ModerationCategoryScores.fromJson(Map<String, dynamic> json) {
    return ModerationCategoryScores(
      hate: (json['hate'] as num).toDouble(),
      hateThreatening: (json['hate/threatening'] as num).toDouble(),
      harassment: (json['harassment'] as num).toDouble(),
      harassmentThreatening: (json['harassment/threatening'] as num).toDouble(),
      selfHarm: (json['self-harm'] as num).toDouble(),
      selfHarmIntent: (json['self-harm/intent'] as num).toDouble(),
      selfHarmInstructions: (json['self-harm/instructions'] as num).toDouble(),
      sexual: (json['sexual'] as num).toDouble(),
      sexualMinors: (json['sexual/minors'] as num).toDouble(),
      violence: (json['violence'] as num).toDouble(),
      violenceGraphic: (json['violence/graphic'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hate': hate,
      'hate/threatening': hateThreatening,
      'harassment': harassment,
      'harassment/threatening': harassmentThreatening,
      'self-harm': selfHarm,
      'self-harm/intent': selfHarmIntent,
      'self-harm/instructions': selfHarmInstructions,
      'sexual': sexual,
      'sexual/minors': sexualMinors,
      'violence': violence,
      'violence/graphic': violenceGraphic,
    };
  }
}

/// A single moderation result
class ModerationResult {
  /// Whether any of the below categories are flagged.
  final bool flagged;

  /// A list of the categories, and whether they are flagged or not.
  final ModerationCategories categories;

  /// A list of the categories along with their scores as predicted by model.
  final ModerationCategoryScores categoryScores;

  const ModerationResult({
    required this.flagged,
    required this.categories,
    required this.categoryScores,
  });

  factory ModerationResult.fromJson(Map<String, dynamic> json) {
    return ModerationResult(
      flagged: json['flagged'] as bool,
      categories: ModerationCategories.fromJson(
        json['categories'] as Map<String, dynamic>,
      ),
      categoryScores: ModerationCategoryScores.fromJson(
        json['category_scores'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flagged': flagged,
      'categories': categories.toJson(),
      'category_scores': categoryScores.toJson(),
    };
  }
}

/// Response from the moderation API
class ModerationResponse {
  /// The unique identifier for the moderation request.
  final String id;

  /// The model used to generate the moderation results.
  final String model;

  /// A list of moderation objects.
  final List<ModerationResult> results;

  const ModerationResponse({
    required this.id,
    required this.model,
    required this.results,
  });

  factory ModerationResponse.fromJson(Map<String, dynamic> json) {
    return ModerationResponse(
      id: json['id'] as String,
      model: json['model'] as String,
      results: (json['results'] as List)
          .map(
              (item) => ModerationResult.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'model': model,
      'results': results.map((result) => result.toJson()).toList(),
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}

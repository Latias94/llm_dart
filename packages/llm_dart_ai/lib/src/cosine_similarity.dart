import 'dart:math' as math;

import 'package:llm_dart_core/llm_dart_core.dart';

/// Calculates the cosine similarity between two vectors.
///
/// Mirrors Vercel AI SDK's `cosineSimilarity(...)`.
double cosineSimilarity(List<double> vector1, List<double> vector2) {
  if (vector1.length != vector2.length) {
    throw InvalidArgumentError(
      argument: 'vector1,vector2',
      value: {
        'vector1Length': vector1.length,
        'vector2Length': vector2.length,
      },
      message: 'Vectors must have the same length.',
    );
  }

  if (vector1.isEmpty) return 0;

  var magnitudeSquared1 = 0.0;
  var magnitudeSquared2 = 0.0;
  var dotProduct = 0.0;

  for (var i = 0; i < vector1.length; i++) {
    final v1 = vector1[i];
    final v2 = vector2[i];
    magnitudeSquared1 += v1 * v1;
    magnitudeSquared2 += v2 * v2;
    dotProduct += v1 * v2;
  }

  if (magnitudeSquared1 == 0 || magnitudeSquared2 == 0) return 0;
  return dotProduct /
      (math.sqrt(magnitudeSquared1) * math.sqrt(magnitudeSquared2));
}

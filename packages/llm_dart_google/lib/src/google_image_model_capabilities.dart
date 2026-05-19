import 'google_options.dart';

bool isGoogleGeminiImageModel(String modelId) {
  return modelId.toLowerCase().contains('gemini');
}

int resolveGoogleImageMaxImagesPerCall({
  required String modelId,
  required GoogleImageModelSettings settings,
}) {
  return settings.maxImagesPerCall ??
      (isGoogleGeminiImageModel(modelId) ? 1 : 4);
}

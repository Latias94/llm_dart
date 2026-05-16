import '../model/embedding_model.dart';
import '../model/image_model.dart';
import '../model/language_model.dart';
import '../model/speech_model.dart';
import '../model/transcription_model.dart';

abstract interface class Provider {
  String get providerId;
}

abstract interface class LanguageModelProvider implements Provider {
  LanguageModel languageModel(String modelId);
}

abstract interface class EmbeddingModelProvider implements Provider {
  EmbeddingModel embeddingModel(String modelId);
}

abstract interface class ImageModelProvider implements Provider {
  ImageModel imageModel(String modelId);
}

abstract interface class SpeechModelProvider implements Provider {
  SpeechModel speechModel(String modelId);
}

abstract interface class TranscriptionModelProvider implements Provider {
  TranscriptionModel transcriptionModel(String modelId);
}

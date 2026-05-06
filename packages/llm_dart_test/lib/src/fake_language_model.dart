import 'package:llm_dart_provider/llm_dart_provider.dart';

/// Shared language-model fake for workspace tests.
final class FakeLanguageModel implements LanguageModel {
  final String _providerId;
  final String _modelId;
  final Future<GenerateTextResult> Function(GenerateTextRequest request)?
      onGenerate;
  final Stream<TextStreamEvent> Function(GenerateTextRequest request)? onStream;

  GenerateTextRequest? lastRequest;
  GenerateTextRequest? lastGenerateRequest;
  GenerateTextRequest? lastStreamRequest;

  FakeLanguageModel({
    String providerId = 'fake',
    String modelId = 'fake-model',
    this.onGenerate,
    this.onStream,
  })  : _providerId = providerId,
        _modelId = modelId;

  @override
  String get providerId => _providerId;

  @override
  String get modelId => _modelId;

  @override
  Future<GenerateTextResult> generate(GenerateTextRequest request) {
    lastRequest = request;
    lastGenerateRequest = request;

    if (onGenerate == null) {
      throw UnimplementedError('generate() was not configured for this test.');
    }

    return onGenerate!(request);
  }

  @override
  Stream<TextStreamEvent> stream(GenerateTextRequest request) {
    lastRequest = request;
    lastStreamRequest = request;

    if (onStream == null) {
      throw UnimplementedError('stream() was not configured for this test.');
    }

    return onStream!(request);
  }
}

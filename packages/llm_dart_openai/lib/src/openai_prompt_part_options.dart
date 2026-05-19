import 'package:llm_dart_provider/llm_dart_provider.dart';

final class OpenAIPromptPartOptions implements ProviderPromptPartOptions {
  final String? imageDetail;

  const OpenAIPromptPartOptions({
    this.imageDetail,
  });
}

final class OpenAIPromptPartOptionsJsonCodec
    implements ProviderPromptPartOptionsJsonCodec<OpenAIPromptPartOptions> {
  static const typeId = 'openai.promptPartOptions';

  const OpenAIPromptPartOptionsJsonCodec();

  @override
  String get type => typeId;

  @override
  bool canEncode(ProviderPromptPartOptions options) =>
      options is OpenAIPromptPartOptions;

  @override
  JsonMap encode(ProviderPromptPartOptions options) {
    final typed = options as OpenAIPromptPartOptions;
    return {
      if (typed.imageDetail != null) 'imageDetail': typed.imageDetail,
    };
  }

  @override
  OpenAIPromptPartOptions decode(JsonMap json) {
    return OpenAIPromptPartOptions(
      imageDetail: asNullableJsonString(
        json['imageDetail'],
        path: r'$.data.imageDetail',
      ),
    );
  }
}

const openAIPromptPartOptionsJsonCodec = OpenAIPromptPartOptionsJsonCodec();

import 'package:llm_dart_provider/llm_dart_provider.dart';

const Object _unsetOpenAIToolOption = Object();

final class OpenAIToolOptions implements ProviderToolOptions {
  final bool? strict;
  final bool? deferLoading;

  const OpenAIToolOptions({
    this.strict,
    this.deferLoading,
  });

  OpenAIToolOptions copyWith({
    Object? strict = _unsetOpenAIToolOption,
    Object? deferLoading = _unsetOpenAIToolOption,
  }) {
    return OpenAIToolOptions(
      strict: identical(strict, _unsetOpenAIToolOption)
          ? this.strict
          : strict as bool?,
      deferLoading: identical(deferLoading, _unsetOpenAIToolOption)
          ? this.deferLoading
          : deferLoading as bool?,
    );
  }
}

final class OpenAIToolOptionsJsonCodec
    implements ProviderToolOptionsJsonCodec<OpenAIToolOptions> {
  static const typeId = 'openai.toolOptions';

  const OpenAIToolOptionsJsonCodec();

  @override
  String get type => typeId;

  @override
  bool canEncode(ProviderToolOptions options) => options is OpenAIToolOptions;

  @override
  JsonMap encode(ProviderToolOptions options) {
    final typed = options as OpenAIToolOptions;
    return {
      if (typed.strict != null) 'strict': typed.strict,
      if (typed.deferLoading != null) 'deferLoading': typed.deferLoading,
    };
  }

  @override
  OpenAIToolOptions decode(JsonMap json) {
    return OpenAIToolOptions(
      strict: asNullableJsonBool(json['strict'], path: r'$.data.strict'),
      deferLoading: asNullableJsonBool(
        json['deferLoading'],
        path: r'$.data.deferLoading',
      ),
    );
  }
}

const openAIToolOptionsJsonCodec = OpenAIToolOptionsJsonCodec();

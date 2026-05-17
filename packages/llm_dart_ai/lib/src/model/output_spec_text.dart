import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'output_spec_base.dart';
import 'output_spec_foundation.dart';

final class TextOutputSpec extends OutputSpec<String> {
  const TextOutputSpec();

  @override
  ResponseFormat get responseFormat => const TextResponseFormat();

  @override
  String parse({
    required String text,
    required StructuredOutputContext context,
  }) {
    return text;
  }

  @override
  String parsePartial({
    required String text,
  }) {
    return text;
  }
}

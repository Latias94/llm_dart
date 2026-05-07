import 'package:llm_dart/models/tool_models.dart';
import 'package:llm_dart/src/compatibility/providers/openai/openai_tool_choice_codec.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIToolChoiceCodec', () {
    const codec = OpenAIToolChoiceCodec();

    test('maps unified tool choices to OpenAI-compatible JSON', () {
      expect(codec.toJson(const AutoToolChoice()), {'type': 'auto'});
      expect(codec.toJson(const AnyToolChoice()), {'type': 'required'});
      expect(codec.toJson(const NoneToolChoice()), {'type': 'none'});
      expect(codec.toJson(const SpecificToolChoice('get_weather')), {
        'type': 'function',
        'function': {'name': 'get_weather'},
      });
    });

    test('ignores Anthropic-only parallel tool preference', () {
      expect(
        codec.toJson(
          const SpecificToolChoice(
            'get_weather',
            disableParallelToolUse: true,
          ),
        ),
        {
          'type': 'function',
          'function': {'name': 'get_weather'},
        },
      );
    });
  });
}

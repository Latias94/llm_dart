import 'package:llm_dart/llm_dart.dart';

Future<void> main() async {
  final result = await generateText(
    model: 'openai:gpt-4o-mini',
    apiKey: 'YOUR_API_KEY',
    prompt: 'Say hello in one sentence.',
  );

  print(result.text);
}

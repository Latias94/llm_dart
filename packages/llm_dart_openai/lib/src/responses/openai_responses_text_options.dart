enum OpenAIResponseTruncation {
  auto('auto'),
  disabled('disabled');

  const OpenAIResponseTruncation(this.value);

  final String value;
}

enum OpenAIPromptCacheRetention {
  inMemory('in_memory'),
  twentyFourHours('24h');

  const OpenAIPromptCacheRetention(this.value);

  final String value;
}

enum OpenAIResponsesInclude {
  webSearchCallActionSources('web_search_call.action.sources'),
  codeInterpreterCallOutputs('code_interpreter_call.outputs'),
  computerCallOutputImageUrl('computer_call_output.output.image_url'),
  reasoningEncryptedContent('reasoning.encrypted_content'),
  fileSearchCallResults('file_search_call.results'),
  messageInputImageImageUrl('message.input_image.image_url'),
  messageOutputTextLogprobs('message.output_text.logprobs');

  const OpenAIResponsesInclude(this.value);

  final String value;
}

enum OpenAISystemMessageMode {
  system('system'),
  developer('developer'),
  remove('remove');

  const OpenAISystemMessageMode(this.value);

  final String value;
}

enum OpenAIImageStyle {
  vivid('vivid'),
  natural('natural');

  const OpenAIImageStyle(this.value);

  final String value;
}

enum OpenAIImageQuality {
  standard('standard'),
  hd('hd'),
  auto('auto'),
  low('low'),
  medium('medium'),
  high('high');

  const OpenAIImageQuality(this.value);

  final String value;
}

enum OpenAIImageBackground {
  auto('auto'),
  opaque('opaque'),
  transparent('transparent');

  const OpenAIImageBackground(this.value);

  final String value;
}

enum OpenAIImageModeration {
  auto('auto'),
  low('low');

  const OpenAIImageModeration(this.value);

  final String value;
}

enum OpenAIImageOutputFormat {
  png('png'),
  jpeg('jpeg'),
  webp('webp');

  const OpenAIImageOutputFormat(this.value);

  final String value;
}

enum OpenAIImageResponseFormat {
  url('url'),
  base64Json('b64_json');

  const OpenAIImageResponseFormat(this.value);

  final String value;
}

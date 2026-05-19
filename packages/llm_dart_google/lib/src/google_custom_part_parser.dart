part of 'google_custom_part.dart';

GoogleCustomPart? _parseGoogleCustomPromptPart(PromptPart part) {
  if (GoogleToolCallReplay.tryParsePromptPart(part) case final replay?) {
    return GoogleToolCallCustomPart(replay);
  }

  if (GoogleToolResponseReplay.tryParsePromptPart(part) case final replay?) {
    return GoogleToolResponseCustomPart(replay);
  }

  if (GoogleFunctionResponseReplay.tryParsePromptPart(part)
      case final replay?) {
    return GoogleFunctionResponseCustomPart(replay);
  }

  return null;
}

GoogleCustomPart? _parseGoogleCustomContentPart(ContentPart part) {
  if (GoogleToolCallReplay.tryParseContentPart(part) case final replay?) {
    return GoogleToolCallCustomPart(replay);
  }

  if (GoogleToolResponseReplay.tryParseContentPart(part) case final replay?) {
    return GoogleToolResponseCustomPart(replay);
  }

  if (GoogleFunctionResponseReplay.tryParseContentPart(part)
      case final replay?) {
    return GoogleFunctionResponseCustomPart(replay);
  }

  return null;
}

GoogleCustomPart? _parseGoogleCustomEvent(LanguageModelStreamEvent event) {
  if (GoogleToolCallReplay.tryParseEvent(event) case final replay?) {
    return GoogleToolCallCustomPart(replay);
  }

  if (GoogleToolResponseReplay.tryParseEvent(event) case final replay?) {
    return GoogleToolResponseCustomPart(replay);
  }

  if (GoogleFunctionResponseReplay.tryParseEvent(event) case final replay?) {
    return GoogleFunctionResponseCustomPart(replay);
  }

  return null;
}

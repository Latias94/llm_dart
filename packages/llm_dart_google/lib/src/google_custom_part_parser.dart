import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_custom_part_core.dart';
import 'google_custom_part_models.dart';
import 'google_function_response_replay.dart';
import 'google_server_tool_replay.dart';

GoogleCustomPart? parseGoogleCustomPromptPart(PromptPart part) {
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

GoogleCustomPart? parseGoogleCustomContentPart(ContentPart part) {
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

GoogleCustomPart? parseGoogleCustomEvent(LanguageModelStreamEvent event) {
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

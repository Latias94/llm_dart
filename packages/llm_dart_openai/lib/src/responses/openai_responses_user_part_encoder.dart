import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../common/openai_request_encoding_util.dart';
import 'openai_responses_prompt_limitations.dart';

final class OpenAIResponsesUserPartEncoder {
  const OpenAIResponsesUserPartEncoder();

  Object encode(PromptPart part, {required int index}) {
    if (part is TextPromptPart) {
      return {
        'type': 'input_text',
        'text': part.text,
      };
    }

    if (part is ImagePromptPart) {
      return _encodeImage(
        data: part.data,
        mediaType: part.mediaType,
        providerOptions: part.providerOptions,
        optionsPath: 'user.image.providerOptions',
        missingDataMessage:
            'User image prompt parts need either a URI or bytes.',
      );
    }

    if (part is FilePromptPart) {
      if (part.mediaType.startsWith('image/')) {
        return _encodeImage(
          data: part.data,
          mediaType: part.mediaType,
          providerOptions: part.providerOptions,
          optionsPath: 'user.file.providerOptions',
          missingDataMessage:
              'User image file prompt parts need either a URI or bytes.',
        );
      }

      if (part.mediaType == 'application/pdf') {
        return _encodePdfFile(part, index: index);
      }

      if (_openAIFileId(data: part.data) case final fileId?) {
        return {
          'type': 'input_file',
          'file_id': fileId,
        };
      }

      if (part.uri != null) {
        return {
          'type': 'input_file',
          'file_url': part.uri!.toString(),
        };
      }

      throw unsupportedOpenAIResponsesUserFileDataMediaType(part.mediaType);
    }

    throw unsupportedOpenAIResponsesPromptPart(
      role: 'user',
      part: part,
    );
  }

  Object _encodeImage({
    required FileData data,
    required String mediaType,
    required ProviderPromptPartOptions? providerOptions,
    required String optionsPath,
    required String missingDataMessage,
  }) {
    final imageDetail = resolveOpenAIImageDetail(
      providerOptions,
      path: optionsPath,
    );
    if (_openAIFileId(data: data) case final fileId?) {
      return {
        'type': 'input_image',
        'file_id': fileId,
        if (imageDetail != null) 'detail': imageDetail,
      };
    }

    final imageUrl = data.uri?.toString() ??
        (data.bytes == null
            ? null
            : 'data:${normalizeOpenAIImageMediaTypeForDataUrl(mediaType)};base64,'
                '${base64Encode(data.bytes!)}');
    if (imageUrl == null) {
      throw missingOpenAIResponsesUserImageData(missingDataMessage);
    }

    return {
      'type': 'input_image',
      'image_url': imageUrl,
      if (imageDetail != null) 'detail': imageDetail,
    };
  }

  Object _encodePdfFile(FilePromptPart part, {required int index}) {
    if (_openAIFileId(data: part.data) case final fileId?) {
      return {
        'type': 'input_file',
        'file_id': fileId,
      };
    }

    if (part.uri != null) {
      return {
        'type': 'input_file',
        'file_url': part.uri!.toString(),
      };
    }

    if (part.bytes == null) {
      throw missingOpenAIResponsesPdfFileData();
    }

    return {
      'type': 'input_file',
      'filename': part.filename ?? 'part-$index.pdf',
      'file_data': 'data:application/pdf;base64,${base64Encode(part.bytes!)}',
    };
  }

  String? _openAIFileId({
    required FileData data,
  }) {
    return resolveOpenAIFileId(
      data: data,
      providerNamespace: 'openai',
      context: 'OpenAI file prompt part',
    );
  }
}

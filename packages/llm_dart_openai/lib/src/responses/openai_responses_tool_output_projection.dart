import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../common/openai_request_encoding_util.dart';
import 'openai_responses_prompt_limitations.dart';
import '../tools/openai_tool_output_encoding.dart';

final class OpenAIResponsesToolOutputProjection {
  const OpenAIResponsesToolOutputProjection();

  Object? encode(ToolOutput output) {
    if (output is ContentToolOutput) {
      return _encodeContentToolOutput(output.parts);
    }

    return encodeOpenAIToolOutputAsText(output);
  }

  List<Object?> _encodeContentToolOutput(List<ToolOutputContentPart> parts) {
    return [
      for (final part in parts) _encodeContentToolOutputPart(part),
    ];
  }

  Object _encodeContentToolOutputPart(ToolOutputContentPart part) {
    return switch (part) {
      TextToolOutputContentPart(:final text) => {
          'type': 'input_text',
          'text': text,
        },
      JsonToolOutputContentPart(:final value) => {
          'type': 'input_text',
          'text': jsonEncode(normalizeJsonValue(value)),
        },
      FileToolOutputContentPart(
        :final mediaType,
        :final filename,
        :final data,
        :final providerOptions,
      ) =>
        _encodeContentToolOutputFilePart(
          mediaType: mediaType,
          filename: filename,
          data: data,
          providerOptions: providerOptions,
        ),
      CustomToolOutputContentPart(:final kind, :final data) => {
          'type': 'input_text',
          'text': jsonEncode(
            normalizeJsonValue({
              'type': 'custom',
              'kind': kind,
              if (data != null) 'data': data,
            }),
          ),
        },
    };
  }

  Map<String, Object?> _encodeContentToolOutputFilePart({
    required String mediaType,
    required String? filename,
    required FileData data,
    required ProviderPromptPartOptions? providerOptions,
  }) {
    final imageDetail = resolveOpenAIImageDetail(
      providerOptions,
      path: 'toolOutput.file.providerOptions',
    );
    final isImage = mediaType == 'image/*' || mediaType.startsWith('image/');
    final reference = data.providerReference;

    if (reference?.containsProvider('openai') == true) {
      final fileId = reference!.requireProvider(
        'openai',
        context: 'OpenAI Responses tool output file part',
      );
      return {
        'type': isImage ? 'input_image' : 'input_file',
        'file_id': fileId,
        if (isImage && imageDetail != null) 'detail': imageDetail,
      };
    }

    final uri = data.uri;
    if (uri != null) {
      return {
        'type': isImage ? 'input_image' : 'input_file',
        if (isImage)
          'image_url': uri.toString()
        else
          'file_url': uri.toString(),
        if (isImage && imageDetail != null) 'detail': imageDetail,
      };
    }

    final bytes = data.bytes;
    if (bytes != null) {
      final normalizedMediaType = isImage
          ? normalizeOpenAIImageMediaTypeForDataUrl(mediaType)
          : mediaType;
      return {
        'type': isImage ? 'input_image' : 'input_file',
        if (isImage)
          'image_url': 'data:$normalizedMediaType;base64,${base64Encode(bytes)}'
        else
          'filename': filename ?? 'data',
        if (!isImage)
          'file_data':
              'data:$normalizedMediaType;base64,${base64Encode(bytes)}',
        if (isImage && imageDetail != null) 'detail': imageDetail,
      };
    }

    final text = data.text;
    if (text != null) {
      if (isImage) {
        throw missingOpenAIResponsesToolOutputImageData();
      }

      final normalizedMediaType =
          normalizeOpenAIImageMediaTypeForDataUrl(mediaType);
      final encodedText = base64Encode(utf8.encode(text));
      return {
        'type': 'input_file',
        'filename': filename ?? 'data',
        'file_data': 'data:$normalizedMediaType;base64,$encodedText',
      };
    }

    throw missingOpenAIResponsesToolOutputFileData();
  }
}

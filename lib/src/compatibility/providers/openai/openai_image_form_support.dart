part of 'openai_image_support.dart';

final class _OpenAIImageFormSupport {
  const _OpenAIImageFormSupport();

  FormData buildEditFormData(ImageEditRequest request) {
    _validateImageData(
      request.image.data,
      errorMessage: 'Image data is required for image editing',
    );

    final formData = FormData();
    _appendCommonFields(
      formData,
      model: request.model,
      count: request.count,
      size: request.size,
      responseFormat: request.responseFormat,
      user: request.user,
      prompt: request.prompt,
    );

    _attachImageFile(
      formData,
      fieldName: 'image',
      data: request.image.data!,
      filename: 'image.png',
    );

    if (request.mask?.data != null) {
      _attachImageFile(
        formData,
        fieldName: 'mask',
        data: request.mask!.data!,
        filename: 'mask.png',
      );
    }

    return formData;
  }

  FormData buildVariationFormData(ImageVariationRequest request) {
    _validateImageData(
      request.image.data,
      errorMessage: 'Image data is required for image variation',
    );

    final formData = FormData();
    _appendCommonFields(
      formData,
      model: request.model,
      count: request.count,
      size: request.size,
      responseFormat: request.responseFormat,
      user: request.user,
    );

    _attachImageFile(
      formData,
      fieldName: 'image',
      data: request.image.data!,
      filename: 'image.png',
    );

    return formData;
  }

  void _appendCommonFields(
    FormData formData, {
    required String? model,
    required int? count,
    required String? size,
    required String? responseFormat,
    required String? user,
    String? prompt,
  }) {
    if (prompt != null) {
      formData.fields.add(MapEntry('prompt', prompt));
    }
    if (model != null) {
      formData.fields.add(MapEntry('model', model));
    }
    if (count != null) {
      formData.fields.add(MapEntry('n', count.toString()));
    }
    if (size != null) {
      formData.fields.add(MapEntry('size', size));
    }
    if (responseFormat != null) {
      formData.fields.add(MapEntry('response_format', responseFormat));
    }
    if (user != null) {
      formData.fields.add(MapEntry('user', user));
    }
  }

  void _attachImageFile(
    FormData formData, {
    required String fieldName,
    required List<int> data,
    required String filename,
  }) {
    formData.files.add(
      MapEntry(
        fieldName,
        MultipartFile.fromBytes(
          data,
          filename: filename,
          contentType: DioMediaType('image', 'png'),
        ),
      ),
    );
  }

  void _validateImageData(
    List<int>? data, {
    required String errorMessage,
  }) {
    if (data == null) {
      throw InvalidRequestError(errorMessage);
    }
  }
}

/// Image dimensions
class ImageDimensions {
  final int width;
  final int height;

  const ImageDimensions({required this.width, required this.height});

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
      };

  factory ImageDimensions.fromJson(Map<String, dynamic> json) =>
      ImageDimensions(
        width: json['width'] as int,
        height: json['height'] as int,
      );

  @override
  String toString() => '${width}x$height';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageDimensions &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => width.hashCode ^ height.hashCode;
}

/// Image style options for generation
enum ImageStyle {
  /// Natural, photographic style
  natural,

  /// Vivid, artistic style
  vivid,

  /// Anime/cartoon style
  anime,

  /// Digital art style
  digitalArt,

  /// Oil painting style
  oilPainting,

  /// Watercolor style
  watercolor,

  /// Sketch/pencil style
  sketch,

  /// 3D render style
  render3d,

  /// Pixel art style
  pixelArt,

  /// Abstract style
  abstract;

  /// Convert to string value for API requests
  String get value {
    switch (this) {
      case ImageStyle.natural:
        return 'natural';
      case ImageStyle.vivid:
        return 'vivid';
      case ImageStyle.anime:
        return 'anime';
      case ImageStyle.digitalArt:
        return 'digital-art';
      case ImageStyle.oilPainting:
        return 'oil-painting';
      case ImageStyle.watercolor:
        return 'watercolor';
      case ImageStyle.sketch:
        return 'sketch';
      case ImageStyle.render3d:
        return '3d-render';
      case ImageStyle.pixelArt:
        return 'pixel-art';
      case ImageStyle.abstract:
        return 'abstract';
    }
  }

  /// Create from string value
  static ImageStyle? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'natural':
        return ImageStyle.natural;
      case 'vivid':
        return ImageStyle.vivid;
      case 'anime':
        return ImageStyle.anime;
      case 'digital-art':
        return ImageStyle.digitalArt;
      case 'oil-painting':
        return ImageStyle.oilPainting;
      case 'watercolor':
        return ImageStyle.watercolor;
      case 'sketch':
        return ImageStyle.sketch;
      case '3d-render':
        return ImageStyle.render3d;
      case 'pixel-art':
        return ImageStyle.pixelArt;
      case 'abstract':
        return ImageStyle.abstract;
      default:
        return null;
    }
  }
}

/// Image quality options
enum ImageQuality {
  /// Standard quality
  standard,

  /// High definition quality
  hd,

  /// Ultra high definition quality
  uhd;

  /// Convert to string value for API requests
  String get value {
    switch (this) {
      case ImageQuality.standard:
        return 'standard';
      case ImageQuality.hd:
        return 'hd';
      case ImageQuality.uhd:
        return 'uhd';
    }
  }

  /// Create from string value
  static ImageQuality? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'standard':
        return ImageQuality.standard;
      case 'hd':
        return ImageQuality.hd;
      case 'uhd':
        return ImageQuality.uhd;
      default:
        return null;
    }
  }
}

/// Common image sizes for generation
class ImageSize {
  static const square256 = '256x256';
  static const square512 = '512x512';
  static const square1024 = '1024x1024';
  static const landscape1792x1024 = '1792x1024';
  static const portrait1024x1792 = '1024x1792';
  static const landscape1344x768 = '1344x768';
  static const portrait768x1344 = '768x1344';
  static const landscape1536x640 = '1536x640';
  static const portrait640x1536 = '640x1536';

  /// Get all available standard sizes
  static List<String> get allSizes => [
        square256,
        square512,
        square1024,
        landscape1792x1024,
        portrait1024x1792,
        landscape1344x768,
        portrait768x1344,
        landscape1536x640,
        portrait640x1536,
      ];

  /// Parse size string to dimensions
  static ImageDimensions? parseDimensions(String size) {
    final parts = size.split('x');
    if (parts.length != 2) return null;

    final width = int.tryParse(parts[0]);
    final height = int.tryParse(parts[1]);

    if (width == null || height == null) return null;

    return ImageDimensions(width: width, height: height);
  }

  /// Check if size is square
  static bool isSquare(String size) {
    final dimensions = parseDimensions(size);
    if (dimensions == null) return false;
    return dimensions.width == dimensions.height;
  }

  /// Check if size is landscape
  static bool isLandscape(String size) {
    final dimensions = parseDimensions(size);
    if (dimensions == null) return false;
    return dimensions.width > dimensions.height;
  }

  /// Check if size is portrait
  static bool isPortrait(String size) {
    final dimensions = parseDimensions(size);
    if (dimensions == null) return false;
    return dimensions.width < dimensions.height;
  }
}

/// Image input for editing and variation requests
class ImageInput {
  /// Image data as bytes
  final List<int>? data;

  /// Image URL (for URL-based inputs)
  final String? url;

  /// Image format (png, jpeg, webp, etc.)
  final String? format;

  const ImageInput({
    this.data,
    this.url,
    this.format,
  });

  /// Create from URL
  factory ImageInput.fromUrl(String url, {String? format}) =>
      ImageInput(url: url, format: format);

  /// Create from bytes
  factory ImageInput.fromBytes(List<int> data, {String? format}) =>
      ImageInput(data: data, format: format);

  Map<String, dynamic> toJson() => {
        if (data != null) 'data': data,
        if (url != null) 'url': url,
        if (format != null) 'format': format,
      };

  factory ImageInput.fromJson(Map<String, dynamic> json) => ImageInput(
        data:
            json['data'] != null ? List<int>.from(json['data'] as List) : null,
        url: json['url'] as String?,
        format: json['format'] as String?,
      );

  @override
  String toString() => 'ImageInput('
      'hasData: ${data != null}, '
      'url: $url, '
      'format: $format'
      ')';
}

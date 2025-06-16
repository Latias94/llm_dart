import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('ImageGenerationRequest', () {
    test('creates request with required fields', () {
      const request = ImageGenerationRequest(prompt: 'A beautiful sunset');

      expect(request.prompt, equals('A beautiful sunset'));
      expect(request.model, isNull);
      expect(request.negativePrompt, isNull);
    });

    test('creates request with all fields', () {
      const request = ImageGenerationRequest(
        prompt: 'A beautiful sunset',
        model: 'dall-e-3',
        negativePrompt: 'ugly, blurry',
        size: '1024x1024',
        count: 2,
        seed: 12345,
        steps: 50,
        guidanceScale: 7.5,
        enhancePrompt: true,
        style: 'vivid',
        quality: 'hd',
        responseFormat: 'url',
        user: 'user123',
      );

      expect(request.prompt, equals('A beautiful sunset'));
      expect(request.model, equals('dall-e-3'));
      expect(request.negativePrompt, equals('ugly, blurry'));
      expect(request.size, equals('1024x1024'));
      expect(request.count, equals(2));
      expect(request.seed, equals(12345));
      expect(request.steps, equals(50));
      expect(request.guidanceScale, equals(7.5));
      expect(request.enhancePrompt, isTrue);
      expect(request.style, equals('vivid'));
      expect(request.quality, equals('hd'));
      expect(request.responseFormat, equals('url'));
      expect(request.user, equals('user123'));
    });

    test('toJson() includes all non-null fields', () {
      const request = ImageGenerationRequest(
        prompt: 'A beautiful sunset',
        model: 'dall-e-3',
        size: '1024x1024',
        count: 2,
      );

      final json = request.toJson();
      expect(json['prompt'], equals('A beautiful sunset'));
      expect(json['model'], equals('dall-e-3'));
      expect(json['size'], equals('1024x1024'));
      expect(json['count'], equals(2));
      expect(json.containsKey('negative_prompt'), isFalse);
    });

    test('fromJson() creates correct instance', () {
      final json = {
        'prompt': 'A beautiful sunset',
        'model': 'dall-e-3',
        'size': '1024x1024',
        'count': 2,
        'seed': 12345,
      };

      final request = ImageGenerationRequest.fromJson(json);
      expect(request.prompt, equals('A beautiful sunset'));
      expect(request.model, equals('dall-e-3'));
      expect(request.size, equals('1024x1024'));
      expect(request.count, equals(2));
      expect(request.seed, equals(12345));
    });
  });

  group('ImageDimensions', () {
    test('creates dimensions with width and height', () {
      const dimensions = ImageDimensions(width: 1024, height: 768);

      expect(dimensions.width, equals(1024));
      expect(dimensions.height, equals(768));
    });

    test('toString() returns correct format', () {
      const dimensions = ImageDimensions(width: 1024, height: 768);
      expect(dimensions.toString(), equals('1024x768'));
    });

    test('equality works correctly', () {
      const dimensions1 = ImageDimensions(width: 1024, height: 768);
      const dimensions2 = ImageDimensions(width: 1024, height: 768);
      const dimensions3 = ImageDimensions(width: 512, height: 512);

      expect(dimensions1, equals(dimensions2));
      expect(dimensions1, isNot(equals(dimensions3)));
    });

    test('hashCode works correctly', () {
      const dimensions1 = ImageDimensions(width: 1024, height: 768);
      const dimensions2 = ImageDimensions(width: 1024, height: 768);

      expect(dimensions1.hashCode, equals(dimensions2.hashCode));
    });

    test('toJson() and fromJson() work correctly', () {
      const dimensions = ImageDimensions(width: 1024, height: 768);
      final json = dimensions.toJson();
      final restored = ImageDimensions.fromJson(json);

      expect(restored.width, equals(1024));
      expect(restored.height, equals(768));
    });
  });

  group('ImageStyle', () {
    test('value property returns correct strings', () {
      expect(ImageStyle.natural.value, equals('natural'));
      expect(ImageStyle.vivid.value, equals('vivid'));
      expect(ImageStyle.anime.value, equals('anime'));
      expect(ImageStyle.digitalArt.value, equals('digital-art'));
      expect(ImageStyle.oilPainting.value, equals('oil-painting'));
      expect(ImageStyle.watercolor.value, equals('watercolor'));
      expect(ImageStyle.sketch.value, equals('sketch'));
      expect(ImageStyle.render3d.value, equals('3d-render'));
      expect(ImageStyle.pixelArt.value, equals('pixel-art'));
      expect(ImageStyle.abstract.value, equals('abstract'));
    });

    test('fromString() creates correct enum values', () {
      expect(ImageStyle.fromString('natural'), equals(ImageStyle.natural));
      expect(ImageStyle.fromString('vivid'), equals(ImageStyle.vivid));
      expect(ImageStyle.fromString('anime'), equals(ImageStyle.anime));
      expect(
          ImageStyle.fromString('digital-art'), equals(ImageStyle.digitalArt));
      expect(ImageStyle.fromString('oil-painting'),
          equals(ImageStyle.oilPainting));
      expect(
          ImageStyle.fromString('watercolor'), equals(ImageStyle.watercolor));
      expect(ImageStyle.fromString('sketch'), equals(ImageStyle.sketch));
      expect(ImageStyle.fromString('3d-render'), equals(ImageStyle.render3d));
      expect(ImageStyle.fromString('pixel-art'), equals(ImageStyle.pixelArt));
      expect(ImageStyle.fromString('abstract'), equals(ImageStyle.abstract));
    });

    test('fromString() handles case insensitivity', () {
      expect(ImageStyle.fromString('NATURAL'), equals(ImageStyle.natural));
      expect(ImageStyle.fromString('Vivid'), equals(ImageStyle.vivid));
    });

    test('fromString() returns null for invalid values', () {
      expect(ImageStyle.fromString('invalid'), isNull);
      expect(ImageStyle.fromString(''), isNull);
      expect(ImageStyle.fromString(null), isNull);
    });
  });

  group('ImageQuality', () {
    test('value property returns correct strings', () {
      expect(ImageQuality.standard.value, equals('standard'));
      expect(ImageQuality.hd.value, equals('hd'));
      expect(ImageQuality.uhd.value, equals('uhd'));
    });

    test('fromString() creates correct enum values', () {
      expect(
          ImageQuality.fromString('standard'), equals(ImageQuality.standard));
      expect(ImageQuality.fromString('hd'), equals(ImageQuality.hd));
      expect(ImageQuality.fromString('uhd'), equals(ImageQuality.uhd));
    });

    test('fromString() handles case insensitivity', () {
      expect(
          ImageQuality.fromString('STANDARD'), equals(ImageQuality.standard));
      expect(ImageQuality.fromString('HD'), equals(ImageQuality.hd));
    });

    test('fromString() returns null for invalid values', () {
      expect(ImageQuality.fromString('invalid'), isNull);
      expect(ImageQuality.fromString(null), isNull);
    });
  });

  group('ImageSize', () {
    test('provides standard size constants', () {
      expect(ImageSize.square256, equals('256x256'));
      expect(ImageSize.square512, equals('512x512'));
      expect(ImageSize.square1024, equals('1024x1024'));
      expect(ImageSize.landscape1792x1024, equals('1792x1024'));
      expect(ImageSize.portrait1024x1792, equals('1024x1792'));
    });

    test('allSizes contains all standard sizes', () {
      final sizes = ImageSize.allSizes;
      expect(sizes, contains('256x256'));
      expect(sizes, contains('512x512'));
      expect(sizes, contains('1024x1024'));
      expect(sizes, contains('1792x1024'));
      expect(sizes, contains('1024x1792'));
      expect(sizes.length, equals(9));
    });

    test('parseDimensions() works correctly', () {
      final dimensions = ImageSize.parseDimensions('1024x768');
      expect(dimensions?.width, equals(1024));
      expect(dimensions?.height, equals(768));
    });

    test('parseDimensions() returns null for invalid input', () {
      expect(ImageSize.parseDimensions('invalid'), isNull);
      expect(ImageSize.parseDimensions('1024'), isNull);
      expect(ImageSize.parseDimensions('1024x'), isNull);
      expect(ImageSize.parseDimensions('x768'), isNull);
    });

    test('isSquare() works correctly', () {
      expect(ImageSize.isSquare('1024x1024'), isTrue);
      expect(ImageSize.isSquare('512x512'), isTrue);
      expect(ImageSize.isSquare('1024x768'), isFalse);
      expect(ImageSize.isSquare('invalid'), isFalse);
    });

    test('isLandscape() works correctly', () {
      expect(ImageSize.isLandscape('1792x1024'), isTrue);
      expect(ImageSize.isLandscape('1024x768'), isTrue);
      expect(ImageSize.isLandscape('1024x1024'), isFalse);
      expect(ImageSize.isLandscape('768x1024'), isFalse);
      expect(ImageSize.isLandscape('invalid'), isFalse);
    });

    test('isPortrait() works correctly', () {
      expect(ImageSize.isPortrait('1024x1792'), isTrue);
      expect(ImageSize.isPortrait('768x1024'), isTrue);
      expect(ImageSize.isPortrait('1024x1024'), isFalse);
      expect(ImageSize.isPortrait('1024x768'), isFalse);
      expect(ImageSize.isPortrait('invalid'), isFalse);
    });
  });

  group('ImageInput', () {
    test('creates from URL', () {
      final input =
          ImageInput.fromUrl('https://example.com/image.png', format: 'png');

      expect(input.url, equals('https://example.com/image.png'));
      expect(input.format, equals('png'));
      expect(input.data, isNull);
    });

    test('creates from bytes', () {
      final data = [1, 2, 3, 4, 5];
      final input = ImageInput.fromBytes(data, format: 'png');

      expect(input.data, equals(data));
      expect(input.format, equals('png'));
      expect(input.url, isNull);
    });

    test('toJson() and fromJson() work correctly', () {
      final input =
          ImageInput.fromUrl('https://example.com/image.png', format: 'png');
      final json = input.toJson();
      final restored = ImageInput.fromJson(json);

      expect(restored.url, equals('https://example.com/image.png'));
      expect(restored.format, equals('png'));
      expect(restored.data, isNull);
    });

    test('toString() provides useful information', () {
      final input =
          ImageInput.fromUrl('https://example.com/image.png', format: 'png');
      final string = input.toString();

      expect(string, contains('hasData: false'));
      expect(string, contains('url: https://example.com/image.png'));
      expect(string, contains('format: png'));
    });
  });
}

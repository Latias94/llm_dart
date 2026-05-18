import 'package:llm_dart_google/src/google_grounding_projection.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('Google grounding projection', () {
    test('projects grounding chunks into provider-native sources', () {
      final sources = projectGoogleGroundingSources({
        'groundingChunks': [
          {
            'web': {
              'uri': 'https://example.com/web',
              'title': 'Web Source',
            },
          },
          {
            'image': {
              'sourceUri': 'https://example.com/image-source',
              'imageUri': 'https://example.com/image.png',
              'title': 'Image Source',
              'domain': 'example.com',
            },
          },
          {
            'retrievedContext': {
              'uri': 'gs://bucket/report.pdf',
              'title': 'Report',
              'text': 'report excerpt',
            },
          },
          {
            'maps': {
              'uri': 'https://maps.example/place',
              'title': 'Place',
              'text': 'place excerpt',
              'placeId': 'place_123',
            },
          },
        ],
      });

      expect(sources, hasLength(4));

      expect(sources[0].kind, SourceReferenceKind.url);
      expect(sources[0].sourceId, 'https://example.com/web');
      expect(sources[0].uri, Uri.parse('https://example.com/web'));
      expect(sources[0].title, 'Web Source');
      expect(sources[0].providerMetadata?.values['google'], {
        'chunkType': 'web',
      });

      expect(sources[1].kind, SourceReferenceKind.url);
      expect(sources[1].sourceId, 'https://example.com/image-source');
      expect(sources[1].uri, Uri.parse('https://example.com/image-source'));
      expect(sources[1].providerMetadata?.values['google'], {
        'chunkType': 'image',
        'imageUri': 'https://example.com/image.png',
        'domain': 'example.com',
      });

      expect(sources[2].kind, SourceReferenceKind.document);
      expect(sources[2].sourceId, 'gs://bucket/report.pdf');
      expect(sources[2].filename, 'report.pdf');
      expect(sources[2].mediaType, 'application/pdf');
      expect(sources[2].providerMetadata?.values['google'], {
        'chunkType': 'retrievedContext',
        'uri': 'gs://bucket/report.pdf',
        'text': 'report excerpt',
      });

      expect(sources[3].kind, SourceReferenceKind.url);
      expect(sources[3].sourceId, 'https://maps.example/place');
      expect(sources[3].providerMetadata?.values['google'], {
        'chunkType': 'maps',
        'text': 'place excerpt',
        'placeId': 'place_123',
      });
    });

    test('emits source content parts and deduplicated stream events', () {
      final groundingMetadata = {
        'groundingChunks': [
          {
            'web': {
              'uri': 'https://example.com',
              'title': 'Example',
            },
          },
        ],
      };

      final contentPart =
          projectGoogleGroundingContentParts(groundingMetadata).single;
      expect(contentPart.source.sourceId, 'https://example.com');

      final emittedSourceKeys = <String>{};
      final firstEvents = emitGoogleGroundingSourceEvents(
        groundingMetadata,
        emittedSourceKeys: emittedSourceKeys,
      ).toList();
      final secondEvents = emitGoogleGroundingSourceEvents(
        groundingMetadata,
        emittedSourceKeys: emittedSourceKeys,
      ).toList();

      expect(firstEvents, hasLength(1));
      expect(firstEvents.single.source.sourceId, 'https://example.com');
      expect(secondEvents, isEmpty);
      expect(emittedSourceKeys, {
        'SourceReferenceKind.url:https://example.com',
      });
    });
  });
}

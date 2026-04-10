import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('Dio response stream helpers', () {
    test('extractDioResponseByteStream returns ResponseBody stream', () async {
      final body = ResponseBody(
        Stream<Uint8List>.fromIterable([
          Uint8List.fromList([1, 2]),
          Uint8List.fromList([3, 4]),
        ]),
        200,
      );

      final chunks = await extractDioResponseByteStream(body).toList();

      expect(chunks, hasLength(2));
      expect(chunks.first, [1, 2]);
      expect(chunks.last, [3, 4]);
    });

    test('decodeDioResponseTextStream decodes split UTF-8 chunks', () async {
      final source = Stream<List<int>>.fromIterable([
        utf8.encode('hello '),
        [0xE4, 0xB8],
        [0x96, 0xE7, 0x95, 0x8C],
      ]);

      final decoded = await decodeDioResponseTextStream(source).toList();

      expect(decoded.join(), 'hello 世界');
    });

    test('collectDioResponseTextBody joins decoded chunks', () async {
      final body = ResponseBody(
        Stream<Uint8List>.fromIterable([
          Uint8List.fromList(utf8.encode('hello ')),
          Uint8List.fromList([0xE4, 0xB8]),
          Uint8List.fromList([0x96, 0xE7, 0x95, 0x8C]),
        ]),
        200,
      );

      final content = await collectDioResponseTextBody(body);

      expect(content, 'hello 世界');
    });

    test('decodeDioResponseTextStream uses custom invalid body error', () {
      expect(
        () => decodeDioResponseTextStream(
          123,
          invalidBodyErrorFactory: StateError.new,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('collectDioResponseTextBody uses custom invalid body error', () {
      expect(
        () => collectDioResponseTextBody(
          123,
          invalidBodyErrorFactory: StateError.new,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

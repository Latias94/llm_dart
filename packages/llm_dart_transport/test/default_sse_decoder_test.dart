import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  test('DefaultSseDecoder rebuilds split SSE frames', () async {
    final frames = await const DefaultSseDecoder()
        .decode(
          Stream.fromIterable([
            'id: 1\nevent: message\ndata: hel',
            'lo\ndata: world\n\n',
          ]),
        )
        .toList();

    expect(frames, hasLength(1));
    expect(frames.single.id, '1');
    expect(frames.single.event, 'message');
    expect(frames.single.data, 'hello\nworld');
  });
}

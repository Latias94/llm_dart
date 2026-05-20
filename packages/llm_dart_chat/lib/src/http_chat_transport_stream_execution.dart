import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'http_chat_transport_chunk.dart';
import 'http_chat_transport_chunk_json_codec.dart';

const String httpChatTransportStreamSourceName = 'HTTP chat transport stream';

sealed class HttpChatTransportStreamFrame {
  const HttpChatTransportStreamFrame();
}

final class HttpChatTransportStreamStatusFailure
    extends HttpChatTransportStreamFrame {
  final int statusCode;

  const HttpChatTransportStreamStatusFailure(this.statusCode);
}

final class HttpChatTransportStreamReceivedChunk
    extends HttpChatTransportStreamFrame {
  final HttpChatTransportChunk chunk;

  const HttpChatTransportStreamReceivedChunk(this.chunk);
}

Stream<HttpChatTransportStreamFrame> executeHttpChatTransportStream({
  required TransportClient transport,
  required TransportRequest request,
  required SseDecoder sseDecoder,
  required HttpChatTransportChunkJsonCodec chunkCodec,
}) async* {
  final response = await transport.sendStream(request);

  if (response.statusCode >= 400) {
    yield HttpChatTransportStreamStatusFailure(response.statusCode);
    return;
  }

  final parser = SseJsonChunkParser(sseDecoder: sseDecoder);
  await for (final envelope in parser.parse(
    response.stream,
    sourceName: httpChatTransportStreamSourceName,
  )) {
    yield HttpChatTransportStreamReceivedChunk(
      chunkCodec.decodeChunk(envelope),
    );
  }
}

final class SseFrame {
  final String? event;
  final String data;
  final String? id;
  final int? retryMilliseconds;

  const SseFrame({
    this.event,
    required this.data,
    this.id,
    this.retryMilliseconds,
  });
}

abstract interface class SseDecoder {
  Stream<SseFrame> decode(Stream<String> chunks);
}

final class DefaultSseDecoder implements SseDecoder {
  const DefaultSseDecoder();

  @override
  Stream<SseFrame> decode(Stream<String> chunks) async* {
    final buffer = StringBuffer();
    final dataLines = <String>[];
    String? event;
    String? lastEventId;
    int? retryMilliseconds;

    SseFrame? flushFrame() {
      if (dataLines.isEmpty && event == null && retryMilliseconds == null) {
        event = null;
        retryMilliseconds = null;
        return null;
      }

      final frame = SseFrame(
        event: event,
        data: dataLines.join('\n'),
        id: lastEventId,
        retryMilliseconds: retryMilliseconds,
      );

      dataLines.clear();
      event = null;
      retryMilliseconds = null;
      return frame;
    }

    Iterable<SseFrame> processLines(List<String> lines) sync* {
      for (final line in lines) {
        if (line.isEmpty) {
          final frame = flushFrame();
          if (frame != null) {
            yield frame;
          }
          continue;
        }

        if (line.startsWith(':')) {
          continue;
        }

        final separatorIndex = line.indexOf(':');
        final field =
            separatorIndex == -1 ? line : line.substring(0, separatorIndex);
        var value =
            separatorIndex == -1 ? '' : line.substring(separatorIndex + 1);
        if (value.startsWith(' ')) {
          value = value.substring(1);
        }

        switch (field) {
          case 'event':
            event = value;
            break;
          case 'data':
            dataLines.add(value);
            break;
          case 'id':
            if (!value.contains('\u0000')) {
              lastEventId = value;
            }
            break;
          case 'retry':
            retryMilliseconds = int.tryParse(value);
            break;
        }
      }
    }

    await for (final chunk in chunks) {
      buffer.write(chunk);
      final normalized = buffer.toString().replaceAll('\r\n', '\n').replaceAll(
            '\r',
            '\n',
          );
      final lines = normalized.split('\n');
      final hasTrailingNewline = normalized.endsWith('\n');

      buffer.clear();
      if (!hasTrailingNewline) {
        buffer.write(lines.removeLast());
      }

      for (final frame in processLines(lines)) {
        yield frame;
      }
    }

    if (buffer.isNotEmpty) {
      for (final frame in processLines([buffer.toString()])) {
        yield frame;
      }
    }

    final trailingFrame = flushFrame();
    if (trailingFrame != null) {
      yield trailingFrame;
    }
  }
}

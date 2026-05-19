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
    final lineBuffer = StringBuffer();
    final dataLines = <String>[];
    String? event;
    String? lastEventId;
    int? retryMilliseconds;
    var atStreamStart = true;
    var pendingCarriageReturn = false;

    SseFrame? flushFrame() {
      if (dataLines.isEmpty) {
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

    Iterable<SseFrame> processLine(String line) sync* {
      if (line.isEmpty) {
        final frame = flushFrame();
        if (frame != null) {
          yield frame;
        }
        return;
      }

      if (line.startsWith(':')) {
        return;
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

    await for (final chunk in chunks) {
      for (var index = 0; index < chunk.length; index++) {
        final codeUnit = chunk.codeUnitAt(index);

        if (pendingCarriageReturn) {
          pendingCarriageReturn = false;
          if (codeUnit == 0x0A) {
            continue;
          }
        }

        if (atStreamStart) {
          atStreamStart = false;
          if (codeUnit == 0xFEFF) {
            continue;
          }
        }

        if (codeUnit == 0x0D) {
          for (final frame in processLine(lineBuffer.toString())) {
            yield frame;
          }
          lineBuffer.clear();
          pendingCarriageReturn = true;
          continue;
        }

        if (codeUnit == 0x0A) {
          for (final frame in processLine(lineBuffer.toString())) {
            yield frame;
          }
          lineBuffer.clear();
          continue;
        }

        lineBuffer.writeCharCode(codeUnit);
      }
    }

    if (lineBuffer.isNotEmpty) {
      for (final frame in processLine(lineBuffer.toString())) {
        yield frame;
      }
    }

    final trailingFrame = flushFrame();
    if (trailingFrame != null) {
      yield trailingFrame;
    }
  }
}

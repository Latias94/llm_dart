/// Incremental `<tag>...</tag>` splitter for streaming deltas.
///
/// Many providers stream reasoning as `<think>...</think>` tags inside the text
/// channel, and the tags can be split across network chunk boundaries (even
/// inside the tag itself). This utility performs best-effort incremental
/// splitting without assuming chunk boundaries align to tags.
library;

sealed class ThinkTagPiece {
  const ThinkTagPiece();
}

final class ThinkTagTextPiece extends ThinkTagPiece {
  final String text;
  const ThinkTagTextPiece(this.text);
}

final class ThinkTagThinkingPiece extends ThinkTagPiece {
  final String thinking;
  const ThinkTagThinkingPiece(this.thinking);
}

final class ThinkTagThinkingStartPiece extends ThinkTagPiece {
  const ThinkTagThinkingStartPiece();
}

final class ThinkTagThinkingEndPiece extends ThinkTagPiece {
  const ThinkTagThinkingEndPiece();
}

final class ThinkTagSplitter {
  final String tagName;

  bool _inTag = false;
  String _pendingTagFragment = '';

  ThinkTagSplitter({this.tagName = 'think'});

  bool get inTag => _inTag;
  String get pendingTagFragment => _pendingTagFragment;

  void reset() {
    _inTag = false;
    _pendingTagFragment = '';
  }

  /// Consume and clear the buffered trailing tag fragment, if any.
  ///
  /// This fragment is typically an incomplete prefix of `<think>` or
  /// `</think>` that we buffered because it might become a full tag after the
  /// next delta arrives.
  String consumePendingTagFragment() {
    final pending = _pendingTagFragment;
    _pendingTagFragment = '';
    return pending;
  }

  List<ThinkTagPiece> splitDelta(String delta) {
    if (delta.isEmpty) return const [];

    final openTag = '<$tagName>';
    final closeTag = '</$tagName>';

    final shouldScan =
        _pendingTagFragment.isNotEmpty || delta.contains('<');
    if (!shouldScan) {
      return [
        _inTag ? ThinkTagThinkingPiece(delta) : ThinkTagTextPiece(delta),
      ];
    }

    var buffer = '$_pendingTagFragment$delta';
    _pendingTagFragment = '';

    final pieces = <ThinkTagPiece>[];

    while (buffer.isNotEmpty) {
      final tag = _inTag ? closeTag : openTag;
      final index = buffer.indexOf(tag);

      if (index == -1) {
        final split = _splitForPotentialTagPrefix(buffer, tag);
        if (split.emit.isNotEmpty) {
          pieces.add(
            _inTag
                ? ThinkTagThinkingPiece(split.emit)
                : ThinkTagTextPiece(split.emit),
          );
        }
        _pendingTagFragment = split.pending;
        break;
      }

      final before = buffer.substring(0, index);
      if (before.isNotEmpty) {
        pieces.add(
          _inTag ? ThinkTagThinkingPiece(before) : ThinkTagTextPiece(before),
        );
      }

      pieces.add(
        _inTag
            ? const ThinkTagThinkingEndPiece()
            : const ThinkTagThinkingStartPiece(),
      );
      _inTag = !_inTag;

      buffer = buffer.substring(index + tag.length);
    }

    return pieces;
  }

  _PendingSplit _splitForPotentialTagPrefix(String buffer, String tag) {
    final maxPrefixLen =
        buffer.length < tag.length - 1 ? buffer.length : tag.length - 1;

    for (var len = maxPrefixLen; len >= 1; len--) {
      final prefix = tag.substring(0, len);
      if (!buffer.endsWith(prefix)) continue;

      final emit = buffer.substring(0, buffer.length - len);
      final pending = buffer.substring(buffer.length - len);
      return _PendingSplit(emit: emit, pending: pending);
    }

    return _PendingSplit(emit: buffer, pending: '');
  }
}

final class _PendingSplit {
  final String emit;
  final String pending;
  const _PendingSplit({required this.emit, required this.pending});
}


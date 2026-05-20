String fixJson(String input) {
  return _JsonRepairScanner(input).repair();
}

final class _JsonRepairScanner {
  final String input;
  final List<_JsonScannerState> _stack = [_JsonScannerState.root];
  var _lastValidIndex = -1;
  int? _literalStart;

  _JsonRepairScanner(this.input);

  String repair() {
    for (var index = 0; index < input.length; index++) {
      _processCharacter(input[index], index);
    }

    final buffer = StringBuffer(input.substring(0, _lastValidIndex + 1));
    _appendMissingClosures(buffer);
    return buffer.toString();
  }

  void _processCharacter(String char, int index) {
    switch (_stack.last) {
      case _JsonScannerState.root:
        _processValueStart(char, index, _JsonScannerState.finish);
        break;
      case _JsonScannerState.finish:
        break;
      case _JsonScannerState.insideObjectStart:
        _processObjectStart(char, index);
        break;
      case _JsonScannerState.insideObjectKey:
        if (char == '"') {
          _swapTop(_JsonScannerState.insideObjectAfterKey);
        }
        break;
      case _JsonScannerState.insideObjectAfterKey:
        if (char == ':') {
          _swapTop(_JsonScannerState.insideObjectBeforeValue);
        }
        break;
      case _JsonScannerState.insideObjectBeforeValue:
        _processValueStart(
          char,
          index,
          _JsonScannerState.insideObjectAfterValue,
        );
        break;
      case _JsonScannerState.insideObjectAfterValue:
        _processAfterObjectValue(char, index);
        break;
      case _JsonScannerState.insideObjectAfterComma:
        if (char == '"') {
          _swapTop(_JsonScannerState.insideObjectKey);
        }
        break;
      case _JsonScannerState.insideArrayStart:
        _processArrayStart(char, index);
        break;
      case _JsonScannerState.insideArrayAfterValue:
        _processArrayAfterValue(char, index);
        break;
      case _JsonScannerState.insideArrayAfterComma:
        _processValueStart(
            char, index, _JsonScannerState.insideArrayAfterValue);
        break;
      case _JsonScannerState.insideString:
        _processString(char, index);
        break;
      case _JsonScannerState.insideStringEscape:
        _stack.removeLast();
        _lastValidIndex = index;
        break;
      case _JsonScannerState.insideNumber:
        _processNumber(char, index);
        break;
      case _JsonScannerState.insideLiteral:
        _processLiteral(char, index);
        break;
    }
  }

  void _processValueStart(
    String char,
    int index,
    _JsonScannerState nextState,
  ) {
    switch (char) {
      case '"':
        _lastValidIndex = index;
        _stack
          ..removeLast()
          ..add(nextState)
          ..add(_JsonScannerState.insideString);
        break;
      case 'f':
      case 't':
      case 'n':
        _lastValidIndex = index;
        _literalStart = index;
        _stack
          ..removeLast()
          ..add(nextState)
          ..add(_JsonScannerState.insideLiteral);
        break;
      case '-':
        _stack
          ..removeLast()
          ..add(nextState)
          ..add(_JsonScannerState.insideNumber);
        break;
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
        _lastValidIndex = index;
        _stack
          ..removeLast()
          ..add(nextState)
          ..add(_JsonScannerState.insideNumber);
        break;
      case '{':
        _lastValidIndex = index;
        _stack
          ..removeLast()
          ..add(nextState)
          ..add(_JsonScannerState.insideObjectStart);
        break;
      case '[':
        _lastValidIndex = index;
        _stack
          ..removeLast()
          ..add(nextState)
          ..add(_JsonScannerState.insideArrayStart);
        break;
    }
  }

  void _processObjectStart(String char, int index) {
    switch (char) {
      case '"':
        _swapTop(_JsonScannerState.insideObjectKey);
        break;
      case '}':
        _lastValidIndex = index;
        _stack.removeLast();
        break;
    }
  }

  void _processAfterObjectValue(String char, int index) {
    switch (char) {
      case ',':
        _swapTop(_JsonScannerState.insideObjectAfterComma);
        break;
      case '}':
        _lastValidIndex = index;
        _stack.removeLast();
        break;
    }
  }

  void _processArrayStart(String char, int index) {
    switch (char) {
      case ']':
        _lastValidIndex = index;
        _stack.removeLast();
        break;
      default:
        _lastValidIndex = index;
        _processValueStart(
          char,
          index,
          _JsonScannerState.insideArrayAfterValue,
        );
        break;
    }
  }

  void _processArrayAfterValue(String char, int index) {
    switch (char) {
      case ',':
        _swapTop(_JsonScannerState.insideArrayAfterComma);
        break;
      case ']':
        _lastValidIndex = index;
        _stack.removeLast();
        break;
      default:
        _lastValidIndex = index;
        break;
    }
  }

  void _processAfterArrayValue(String char, int index) {
    switch (char) {
      case ',':
        _swapTop(_JsonScannerState.insideArrayAfterComma);
        break;
      case ']':
        _lastValidIndex = index;
        _stack.removeLast();
        break;
    }
  }

  void _processString(String char, int index) {
    switch (char) {
      case '"':
        _stack.removeLast();
        _lastValidIndex = index;
        break;
      case r'\':
        _stack.add(_JsonScannerState.insideStringEscape);
        break;
      default:
        _lastValidIndex = index;
        break;
    }
  }

  void _processNumber(String char, int index) {
    switch (char) {
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
        _lastValidIndex = index;
        break;
      case 'e':
      case 'E':
      case '-':
      case '.':
        break;
      case ',':
        _stack.removeLast();
        if (_stack.last == _JsonScannerState.insideArrayAfterValue) {
          _processAfterArrayValue(char, index);
        }
        if (_stack.last == _JsonScannerState.insideObjectAfterValue) {
          _processAfterObjectValue(char, index);
        }
        break;
      case '}':
        _stack.removeLast();
        if (_stack.last == _JsonScannerState.insideObjectAfterValue) {
          _processAfterObjectValue(char, index);
        }
        break;
      case ']':
        _stack.removeLast();
        if (_stack.last == _JsonScannerState.insideArrayAfterValue) {
          _processAfterArrayValue(char, index);
        }
        break;
      default:
        _stack.removeLast();
        break;
    }
  }

  void _processLiteral(String char, int index) {
    final partialLiteral = input.substring(_literalStart!, index + 1);
    if (_isLiteralPrefix(partialLiteral)) {
      _lastValidIndex = index;
      return;
    }

    _stack.removeLast();
    if (_stack.last == _JsonScannerState.insideObjectAfterValue) {
      _processAfterObjectValue(char, index);
    } else if (_stack.last == _JsonScannerState.insideArrayAfterValue) {
      _processAfterArrayValue(char, index);
    }
  }

  void _appendMissingClosures(StringBuffer buffer) {
    for (var index = _stack.length - 1; index >= 0; index--) {
      switch (_stack[index]) {
        case _JsonScannerState.insideString:
          buffer.write('"');
          break;
        case _JsonScannerState.insideObjectKey:
        case _JsonScannerState.insideObjectAfterKey:
        case _JsonScannerState.insideObjectStart:
        case _JsonScannerState.insideObjectBeforeValue:
        case _JsonScannerState.insideObjectAfterValue:
        case _JsonScannerState.insideObjectAfterComma:
          buffer.write('}');
          break;
        case _JsonScannerState.insideArrayStart:
        case _JsonScannerState.insideArrayAfterValue:
        case _JsonScannerState.insideArrayAfterComma:
          buffer.write(']');
          break;
        case _JsonScannerState.insideLiteral:
          _appendLiteralSuffix(buffer);
          break;
        case _JsonScannerState.root:
        case _JsonScannerState.finish:
        case _JsonScannerState.insideStringEscape:
        case _JsonScannerState.insideNumber:
          break;
      }
    }
  }

  void _appendLiteralSuffix(StringBuffer buffer) {
    final partialLiteral = input.substring(_literalStart!, input.length);
    if ('true'.startsWith(partialLiteral)) {
      buffer.write('true'.substring(partialLiteral.length));
    } else if ('false'.startsWith(partialLiteral)) {
      buffer.write('false'.substring(partialLiteral.length));
    } else if ('null'.startsWith(partialLiteral)) {
      buffer.write('null'.substring(partialLiteral.length));
    }
  }

  void _swapTop(_JsonScannerState state) {
    _stack
      ..removeLast()
      ..add(state);
  }
}

bool _isLiteralPrefix(String value) {
  return 'false'.startsWith(value) ||
      'true'.startsWith(value) ||
      'null'.startsWith(value);
}

enum _JsonScannerState {
  root,
  finish,
  insideString,
  insideStringEscape,
  insideLiteral,
  insideNumber,
  insideObjectStart,
  insideObjectKey,
  insideObjectAfterKey,
  insideObjectBeforeValue,
  insideObjectAfterValue,
  insideObjectAfterComma,
  insideArrayStart,
  insideArrayAfterValue,
  insideArrayAfterComma,
}

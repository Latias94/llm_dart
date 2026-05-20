String fixJson(String input) {
  final stack = <_JsonScannerState>[_JsonScannerState.root];
  var lastValidIndex = -1;
  int? literalStart;

  void processValueStart(
    String char,
    int index,
    _JsonScannerState nextState,
  ) {
    switch (char) {
      case '"':
        lastValidIndex = index;
        stack
          ..removeLast()
          ..add(nextState)
          ..add(_JsonScannerState.insideString);
        break;
      case 'f':
      case 't':
      case 'n':
        lastValidIndex = index;
        literalStart = index;
        stack
          ..removeLast()
          ..add(nextState)
          ..add(_JsonScannerState.insideLiteral);
        break;
      case '-':
        stack
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
        lastValidIndex = index;
        stack
          ..removeLast()
          ..add(nextState)
          ..add(_JsonScannerState.insideNumber);
        break;
      case '{':
        lastValidIndex = index;
        stack
          ..removeLast()
          ..add(nextState)
          ..add(_JsonScannerState.insideObjectStart);
        break;
      case '[':
        lastValidIndex = index;
        stack
          ..removeLast()
          ..add(nextState)
          ..add(_JsonScannerState.insideArrayStart);
        break;
    }
  }

  void processAfterObjectValue(String char, int index) {
    switch (char) {
      case ',':
        stack
          ..removeLast()
          ..add(_JsonScannerState.insideObjectAfterComma);
        break;
      case '}':
        lastValidIndex = index;
        stack.removeLast();
        break;
    }
  }

  void processAfterArrayValue(String char, int index) {
    switch (char) {
      case ',':
        stack
          ..removeLast()
          ..add(_JsonScannerState.insideArrayAfterComma);
        break;
      case ']':
        lastValidIndex = index;
        stack.removeLast();
        break;
    }
  }

  for (var index = 0; index < input.length; index++) {
    final char = input[index];
    final currentState = stack.last;

    switch (currentState) {
      case _JsonScannerState.root:
        processValueStart(char, index, _JsonScannerState.finish);
        break;
      case _JsonScannerState.finish:
        break;
      case _JsonScannerState.insideObjectStart:
        switch (char) {
          case '"':
            stack
              ..removeLast()
              ..add(_JsonScannerState.insideObjectKey);
            break;
          case '}':
            lastValidIndex = index;
            stack.removeLast();
            break;
        }
        break;
      case _JsonScannerState.insideObjectKey:
        if (char == '"') {
          stack
            ..removeLast()
            ..add(_JsonScannerState.insideObjectAfterKey);
        }
        break;
      case _JsonScannerState.insideObjectAfterKey:
        if (char == ':') {
          stack
            ..removeLast()
            ..add(_JsonScannerState.insideObjectBeforeValue);
        }
        break;
      case _JsonScannerState.insideObjectBeforeValue:
        processValueStart(
          char,
          index,
          _JsonScannerState.insideObjectAfterValue,
        );
        break;
      case _JsonScannerState.insideObjectAfterValue:
        processAfterObjectValue(char, index);
        break;
      case _JsonScannerState.insideObjectAfterComma:
        if (char == '"') {
          stack
            ..removeLast()
            ..add(_JsonScannerState.insideObjectKey);
        }
        break;
      case _JsonScannerState.insideArrayStart:
        switch (char) {
          case ']':
            lastValidIndex = index;
            stack.removeLast();
            break;
          default:
            lastValidIndex = index;
            processValueStart(
              char,
              index,
              _JsonScannerState.insideArrayAfterValue,
            );
            break;
        }
        break;
      case _JsonScannerState.insideArrayAfterValue:
        switch (char) {
          case ',':
            stack
              ..removeLast()
              ..add(_JsonScannerState.insideArrayAfterComma);
            break;
          case ']':
            lastValidIndex = index;
            stack.removeLast();
            break;
          default:
            lastValidIndex = index;
            break;
        }
        break;
      case _JsonScannerState.insideArrayAfterComma:
        processValueStart(char, index, _JsonScannerState.insideArrayAfterValue);
        break;
      case _JsonScannerState.insideString:
        switch (char) {
          case '"':
            stack.removeLast();
            lastValidIndex = index;
            break;
          case '\\':
            stack.add(_JsonScannerState.insideStringEscape);
            break;
          default:
            lastValidIndex = index;
            break;
        }
        break;
      case _JsonScannerState.insideStringEscape:
        stack.removeLast();
        lastValidIndex = index;
        break;
      case _JsonScannerState.insideNumber:
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
            lastValidIndex = index;
            break;
          case 'e':
          case 'E':
          case '-':
          case '.':
            break;
          case ',':
            stack.removeLast();
            if (stack.last == _JsonScannerState.insideArrayAfterValue) {
              processAfterArrayValue(char, index);
            }
            if (stack.last == _JsonScannerState.insideObjectAfterValue) {
              processAfterObjectValue(char, index);
            }
            break;
          case '}':
            stack.removeLast();
            if (stack.last == _JsonScannerState.insideObjectAfterValue) {
              processAfterObjectValue(char, index);
            }
            break;
          case ']':
            stack.removeLast();
            if (stack.last == _JsonScannerState.insideArrayAfterValue) {
              processAfterArrayValue(char, index);
            }
            break;
          default:
            stack.removeLast();
            break;
        }
        break;
      case _JsonScannerState.insideLiteral:
        final partialLiteral = input.substring(literalStart!, index + 1);
        if (!_isLiteralPrefix(partialLiteral)) {
          stack.removeLast();
          if (stack.last == _JsonScannerState.insideObjectAfterValue) {
            processAfterObjectValue(char, index);
          } else if (stack.last == _JsonScannerState.insideArrayAfterValue) {
            processAfterArrayValue(char, index);
          }
        } else {
          lastValidIndex = index;
        }
        break;
    }
  }

  var result = input.substring(0, lastValidIndex + 1);

  for (var index = stack.length - 1; index >= 0; index--) {
    switch (stack[index]) {
      case _JsonScannerState.insideString:
        result += '"';
        break;
      case _JsonScannerState.insideObjectKey:
      case _JsonScannerState.insideObjectAfterKey:
      case _JsonScannerState.insideObjectStart:
      case _JsonScannerState.insideObjectBeforeValue:
      case _JsonScannerState.insideObjectAfterValue:
      case _JsonScannerState.insideObjectAfterComma:
        result += '}';
        break;
      case _JsonScannerState.insideArrayStart:
      case _JsonScannerState.insideArrayAfterValue:
      case _JsonScannerState.insideArrayAfterComma:
        result += ']';
        break;
      case _JsonScannerState.insideLiteral:
        final partialLiteral = input.substring(literalStart!, input.length);
        if ('true'.startsWith(partialLiteral)) {
          result += 'true'.substring(partialLiteral.length);
        } else if ('false'.startsWith(partialLiteral)) {
          result += 'false'.substring(partialLiteral.length);
        } else if ('null'.startsWith(partialLiteral)) {
          result += 'null'.substring(partialLiteral.length);
        }
        break;
      case _JsonScannerState.root:
      case _JsonScannerState.finish:
      case _JsonScannerState.insideStringEscape:
      case _JsonScannerState.insideNumber:
        break;
    }
  }

  return result;
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

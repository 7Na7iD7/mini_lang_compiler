import '../models/ast_nodes.dart';
import '../models/token_types.dart';

class Lexer {
  final String source;
  int _current = 0;
  int _line = 1;
  int _column = 1;
  final List<CompilerError> errors = [];
  final List<CompilerError> warnings = [];

  Lexer(this.source);

  bool get _isAtEnd => _current >= source.length;
  String get _currentChar => _isAtEnd ? '\0' : source[_current];
  String get _peekNext => (_current + 1 >= source.length) ? '\0' : source[_current + 1];

  String _advance() {
    if (_isAtEnd) return '\0';
    final char = source[_current];
    _current++;
    if (char == '\n') {
      _line++;
      _column = 1;
    } else {
      _column++;
    }
    return char;
  }

  bool _match(String expected) {
    if (_isAtEnd || source[_current] != expected) return false;
    _advance();
    return true;
  }

  String _peek([int offset = 0]) {
    final pos = _current + offset;
    return pos >= source.length ? '\0' : source[pos];
  }

  void _skipWhitespace() {
    while (!_isAtEnd) {
      final char = _currentChar;
      if (char == ' ' || char == '\r' || char == '\t') {
        _advance();
      } else if (char == '\n') {
        _advance();
      } else if (char == '/' && _peekNext == '/') {
        while (!_isAtEnd && _currentChar != '\n') {
          _advance();
        }
      } else if (char == '/' && _peekNext == '*') {
        _advance();
        _advance();
        while (!_isAtEnd) {
          if (_currentChar == '*' && _peekNext == '/') {
            _advance();
            _advance();
            break;
          }
          _advance();
        }
      } else {
        break;
      }
    }
  }

  Token _makeToken(TokenType type, String value) {
    final safeColumn = (_column - value.length).clamp(1, _column);
    final safePosition = (_current - value.length).clamp(0, _current);

    return Token(
      type: type,
      value: value,
      line: _line,
      column: safeColumn,
      position: safePosition,
    );
  }

  void _error(String message) {
    errors.add(CompilerError.error(
      message: message,
      line: _line,
      column: _column,
      phase: 'Lexer',
    ));
  }

  bool _isDigit(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  bool _isAlpha(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        char == '_';
  }

  bool _isAlphaNumeric(String char) => _isAlpha(char) || _isDigit(char);

  List<Token> tokenize() {
    _current = 0;
    _line = 1;
    _column = 1;
    errors.clear();
    warnings.clear();

    final tokens = <Token>[];
    const int maxTokens = 10000;
    int tokenCount = 0;

    while (!_isAtEnd && tokenCount < maxTokens) {
      _skipWhitespace();
      if (_isAtEnd) break;

      final startPos = _current;
      final startLine = _line;
      final startColumn = _column;

      final char = _advance();

      Token? token;
      switch (char) {
        case '(':
          token = _makeToken(TokenType.LPAREN, char);
          break;
        case ')':
          token = _makeToken(TokenType.RPAREN, char);
          break;
        case '{':
          token = _makeToken(TokenType.LBRACE, char);
          break;
        case '}':
          token = _makeToken(TokenType.RBRACE, char);
          break;
        case '[':
          token = _makeToken(TokenType.LBRACKET, char);
          break;
        case ']':
          token = _makeToken(TokenType.RBRACKET, char);
          break;
        case ',':
          token = _makeToken(TokenType.COMMA, char);
          break;
        case ';':
          token = _makeToken(TokenType.SEMICOLON, char);
          break;
        case ':':
          token = _makeToken(TokenType.COLON, char);
          break;
        case '.':
          token = _makeToken(TokenType.DOT, char);
          break;
        case '?':
          token = _makeToken(TokenType.QUESTION, char);
          break;
        case '+':
          if (_match('+')) {
            token = _makeToken(TokenType.INCREMENT, '++');
          } else if (_match('=')) {
            token = _makeToken(TokenType.PLUS_ASSIGN, '+=');
          } else {
            token = _makeToken(TokenType.PLUS, '+');
          }
          break;
        case '-':
          if (_match('-')) {
            token = _makeToken(TokenType.DECREMENT, '--');
          } else if (_match('=')) {
            token = _makeToken(TokenType.MINUS_ASSIGN, '-=');
          } else {
            token = _makeToken(TokenType.MINUS, '-');
          }
          break;
        case '*':
          if (_match('*')) {
            token = _makeToken(TokenType.POWER, '**');
          } else if (_match('=')) {
            token = _makeToken(TokenType.MULTIPLY_ASSIGN, '*=');
          } else {
            token = _makeToken(TokenType.MULTIPLY, '*');
          }
          break;
        case '/':
          if (_match('=')) {
            token = _makeToken(TokenType.DIVIDE_ASSIGN, '/=');
          } else {
            token = _makeToken(TokenType.DIVIDE, '/');
          }
          break;
        case '%':
          token = _makeToken(TokenType.MODULO, '%');
          break;
        case '=':
          if (_match('=')) {
            token = _makeToken(TokenType.EQUAL, '==');
          } else if (_match('>')) {
            token = _makeToken(TokenType.ARROW, '=>');
          } else {
            token = _makeToken(TokenType.ASSIGN, '=');
          }
          break;
        case '!':
          if (_match('=')) {
            token = _makeToken(TokenType.NOT_EQUAL, '!=');
          } else {
            token = _makeToken(TokenType.NOT, '!');
          }
          break;
        case '>':
          if (_match('=')) {
            token = _makeToken(TokenType.GREATER_EQUAL, '>=');
          } else if (_match('>')) {
            token = _makeToken(TokenType.RIGHT_SHIFT, '>>');
          } else {
            token = _makeToken(TokenType.GREATER, '>');
          }
          break;
        case '<':
          if (_match('=')) {
            token = _makeToken(TokenType.LESS_EQUAL, '<=');
          } else if (_match('<')) {
            token = _makeToken(TokenType.LEFT_SHIFT, '<<');
          } else {
            token = _makeToken(TokenType.LESS, '<');
          }
          break;
        case '&':
          if (_match('&')) {
            token = _makeToken(TokenType.AND, '&&');
          } else {
            token = _makeToken(TokenType.BIT_AND, '&');
          }
          break;
        case '|':
          if (_match('|')) {
            token = _makeToken(TokenType.OR, '||');
          } else {
            token = _makeToken(TokenType.BIT_OR, '|');
          }
          break;
        case '^':
          token = _makeToken(TokenType.BIT_XOR, '^');
          break;
        case '~':
          token = _makeToken(TokenType.BIT_NOT, '~');
          break;
        case '"':
          token = _scanString(startPos, startLine, startColumn);
          break;
        case "'":
          token = _scanCharacter(startPos, startLine, startColumn);
          break;
        default:
          if (_isDigit(char)) {
            token = _scanNumber(startPos);
          } else if (_isAlpha(char)) {
            token = _scanIdentifierOrKeyword(startPos);
          } else {
            errors.add(CompilerError.error(
              message: 'Unexpected character: $char',
              line: startLine,
              column: startColumn,
              phase: 'Lexer',
            ));
            token = _makeToken(TokenType.ERROR, char);
          }
      }

      if (token != null && token.type != TokenType.ERROR) {
        tokens.add(token);
        tokenCount++;
      }

      if (token?.type == TokenType.ERROR) {
        break;
      }
    }

    if (tokenCount >= maxTokens) {
      errors.add(CompilerError.error(
        message: 'Maximum token limit exceeded',
        line: _line,
        column: _column,
        phase: 'Lexer',
      ));
    }

    if (tokens.isEmpty || tokens.last.type != TokenType.EOF) {
      tokens.add(_makeToken(TokenType.EOF, ''));
    }

    return tokens;
  }

  Token _scanString(int startPos, int startLine, int startColumn) {
    final buffer = StringBuffer();

    while (_currentChar != '"' && !_isAtEnd) {
      if (_currentChar == '\n') {
        errors.add(CompilerError.error(
          message: 'Unterminated string literal across lines',
          line: startLine,
          column: startColumn,
          phase: 'Lexer',
        ));
        break;
      }

      if (_currentChar == '\\') {
        _advance();
        if (_isAtEnd) break;

        final escaped = _currentChar;
        _advance();

        switch (escaped) {
          case 'n':
            buffer.write('\n');
            break;
          case 't':
            buffer.write('\t');
            break;
          case 'r':
            buffer.write('\r');
            break;
          case '\\':
            buffer.write('\\');
            break;
          case '"':
            buffer.write('"');
            break;
          case "'":
            buffer.write("'");
            break;
          case '0':
            buffer.write('\x00');
            break;
          default:
            buffer.write(escaped);
            warnings.add(CompilerError.warning(
              message: 'Unknown escape sequence: \\$escaped',
              line: _line,
              column: _column,
              phase: 'Lexer',
            ));
        }
      } else {
        buffer.write(_currentChar);
        _advance();
      }
    }

    if (_isAtEnd || _currentChar != '"') {
      errors.add(CompilerError.error(
        message: 'Unterminated string literal',
        line: startLine,
        column: startColumn,
        phase: 'Lexer',
      ));
      return _makeToken(TokenType.ERROR, buffer.toString());
    }

    _advance();

    final safePosition = (startPos).clamp(0, source.length);

    return Token(
      type: TokenType.STRING_LITERAL,
      value: buffer.toString(),
      line: startLine,
      column: startColumn,
      position: safePosition,
    );
  }

  Token _scanCharacter(int startPos, int startLine, int startColumn) {
    String charValue = '';

    if (_currentChar == '\\') {
      _advance();
      if (_isAtEnd) {
        errors.add(CompilerError.error(
          message: 'Unterminated character literal',
          line: startLine,
          column: startColumn,
          phase: 'Lexer',
        ));
        return _makeToken(TokenType.ERROR, "'\\'");
      }

      final escaped = _currentChar;
      _advance();

      switch (escaped) {
        case 'n':
          charValue = '\n';
          break;
        case 't':
          charValue = '\t';
          break;
        case 'r':
          charValue = '\r';
          break;
        case '\\':
          charValue = '\\';
          break;
        case "'":
          charValue = "'";
          break;
        case '"':
          charValue = '"';
          break;
        case '0':
          charValue = '\x00';
          break;
        default:
          charValue = escaped;
          warnings.add(CompilerError.warning(
            message: 'Unknown escape sequence: \\$escaped',
            line: _line,
            column: _column,
            phase: 'Lexer',
          ));
      }
    } else if (_currentChar != "'" && !_isAtEnd) {
      charValue = _currentChar;
      _advance();
    }

    if (_isAtEnd || _currentChar != "'") {
      errors.add(CompilerError.error(
        message: 'Unterminated character literal',
        line: startLine,
        column: startColumn,
        phase: 'Lexer',
      ));
      return _makeToken(TokenType.ERROR, "'$charValue");
    }

    _advance();

    if (charValue.isEmpty) {
      errors.add(CompilerError.error(
        message: 'Empty character literal',
        line: startLine,
        column: startColumn,
        phase: 'Lexer',
      ));
      return _makeToken(TokenType.ERROR, "''");
    }

    final safePosition = (startPos).clamp(0, source.length);

    return Token(
      type: TokenType.CHAR_LITERAL,
      value: charValue,
      line: startLine,
      column: startColumn,
      position: safePosition,
    );
  }

  Token _scanNumber(int startPos) {
    bool isFloat = false;

    while (_isDigit(_currentChar)) {
      _advance();
    }

    if (_currentChar == '.' && _isDigit(_peekNext)) {
      isFloat = true;
      _advance();
      while (_isDigit(_currentChar)) {
        _advance();
      }
    }

    if (_currentChar == 'e' || _currentChar == 'E') {
      isFloat = true;
      _advance();

      if (_currentChar == '+' || _currentChar == '-') {
        _advance();
      }

      if (!_isDigit(_currentChar)) {
        errors.add(CompilerError.error(
          message: 'Invalid scientific notation',
          line: _line,
          column: _column,
          phase: 'Lexer',
        ));
      }

      while (_isDigit(_currentChar)) {
        _advance();
      }
    }

    final safeStart = (startPos).clamp(0, source.length);
    final safeEnd = _current.clamp(0, source.length);
    final value = source.substring(safeStart, safeEnd);

    return _makeToken(
      isFloat ? TokenType.FLOAT_LITERAL : TokenType.NUMBER,
      value,
    );
  }

  Token _scanIdentifierOrKeyword(int startPos) {
    while (_isAlphaNumeric(_currentChar)) {
      _advance();
    }

    final safeStart = (startPos).clamp(0, source.length);
    final safeEnd = _current.clamp(0, source.length);
    final text = source.substring(safeStart, safeEnd);

    final type = Keywords.keywords[text] ?? TokenType.IDENTIFIER;
    return _makeToken(type, text);
  }

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  String getErrorsAsString() {
    final allMessages = <String>[];
    allMessages.addAll(errors.map((e) => e.toString()));
    allMessages.addAll(warnings.map((w) => w.toString()));
    return allMessages.join('\n');
  }

  List<CompilerError> getAllMessages() {
    return [...errors, ...warnings];
  }
}
enum TokenType {
  // Main Keywords - Dart-like
  INT, STRING, BOOLEAN, FLOAT, VOID, VAR,
  FOR, WHILE, DO, IF, ELSE, SWITCH, CASE, DEFAULT,
  PRINT, RETURN, BREAK, CONTINUE,
  CONST, TRUE, FALSE, NULL,

  // Advanced Keywords
  CLASS, STRUCT, ENUM, IMPORT, EXPORT,
  PUBLIC, PRIVATE, STATIC, ABSTRACT,

  // Identifiers and Literals
  IDENTIFIER, NUMBER, STRING_LITERAL, FLOAT_LITERAL, CHAR_LITERAL,

  // Arithmetic Operators
  ASSIGN, PLUS, MINUS, MULTIPLY, DIVIDE, MODULO, POWER,
  PLUS_ASSIGN, MINUS_ASSIGN, MULTIPLY_ASSIGN, DIVIDE_ASSIGN,
  INCREMENT, DECREMENT,

  // Logical Operators
  AND, OR, NOT, XOR,

  // Comparison Operators
  EQUAL, NOT_EQUAL, GREATER, LESS, GREATER_EQUAL, LESS_EQUAL,

  // Bitwise Operators
  BIT_AND, BIT_OR, BIT_XOR, BIT_NOT, LEFT_SHIFT, RIGHT_SHIFT,

  // Symbols
  SEMICOLON, DOT, COMMA, COLON, QUESTION,
  LPAREN, RPAREN, LBRACE, RBRACE, LBRACKET, RBRACKET,
  ARROW, DOUBLE_ARROW,

  // Special
  NEWLINE, COMMENT, MULTILINE_COMMENT,
  EOF, ERROR,
}

class Token {
  final TokenType type;
  final String value;
  final int line;
  final int column;
  final int position;

  Token({
    required this.type,
    required this.value,
    this.line = 1,
    this.column = 1,
    this.position = 0,
  });

  @override
  String toString() => 'Token(${type.name}, "$value", $line:$column)';

  @override
  bool operator ==(Object other) {
    return other is Token && other.type == type && other.value == value;
  }

  @override
  int get hashCode => type.hashCode ^ value.hashCode;
}

class Keywords {
  static const Map<String, TokenType> keywords = {
    'int': TokenType.INT,
    'string': TokenType.STRING,
    'boolean': TokenType.BOOLEAN,
    'float': TokenType.FLOAT,
    'void': TokenType.VOID,
    'var': TokenType.VAR,
    'for': TokenType.FOR,
    'while': TokenType.WHILE,
    'do': TokenType.DO,
    'if': TokenType.IF,
    'else': TokenType.ELSE,
    'switch': TokenType.SWITCH,
    'case': TokenType.CASE,
    'default': TokenType.DEFAULT,
    'print': TokenType.PRINT,
    'return': TokenType.RETURN,
    'break': TokenType.BREAK,
    'continue': TokenType.CONTINUE,
    'const': TokenType.CONST,
    'true': TokenType.TRUE,
    'false': TokenType.FALSE,
    'null': TokenType.NULL,
    'class': TokenType.CLASS,
    'struct': TokenType.STRUCT,
    'enum': TokenType.ENUM,
    'import': TokenType.IMPORT,
    'export': TokenType.EXPORT,
    'public': TokenType.PUBLIC,
    'private': TokenType.PRIVATE,
    'static': TokenType.STATIC,
    'abstract': TokenType.ABSTRACT,
  };
}
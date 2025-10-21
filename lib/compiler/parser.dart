import '../models/token_types.dart';
import '../models/ast_nodes.dart';

class Parser {
  final List<Token> tokens;
  int _current = 0;
  final List<CompilerError> errors = [];
  final List<CompilerError> warnings = [];
  int _loopDepth = 0;

  Parser(this.tokens);

  bool get _isAtEnd => _current >= tokens.length || _peek().type == TokenType.EOF;

  Token _peek() {
    if (_current >= tokens.length) {
      return Token(type: TokenType.EOF, value: '', line: 0, column: 0, position: 0);
    }
    return tokens[_current];
  }

  Token _previous() {
    if (_current - 1 < 0) {
      return Token(type: TokenType.EOF, value: '', line: 0, column: 0, position: 0);
    }
    return tokens[_current - 1];
  }

  Token _advance() {
    if (!_isAtEnd) _current++;
    return _previous();
  }

  bool _check(TokenType type) {
    if (_isAtEnd) return false;
    return _peek().type == type;
  }

  bool _match(List<TokenType> types) {
    for (final type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }
    return false;
  }

  Token _consume(TokenType type, String message) {
    if (_check(type)) return _advance();
    _error('Expected $message but found ${_peek().type.name}');
    return _peek();
  }

  void _error(String message) {
    final token = _peek();
    errors.add(CompilerError.error(
      message: message,
      line: token.line,
      column: token.column,
      phase: 'Parser',
    ));
  }

  void _warning(String message) {
    final token = _peek();
    warnings.add(CompilerError.warning(
      message: message,
      line: token.line,
      column: token.column,
      phase: 'Parser',
    ));
  }

  void _synchronize() {
    _advance();
    while (!_isAtEnd) {
      if (_previous().type == TokenType.SEMICOLON) return;

      switch (_peek().type) {
        case TokenType.CLASS:
        case TokenType.VAR:
        case TokenType.CONST:
        case TokenType.FOR:
        case TokenType.IF:
        case TokenType.WHILE:
        case TokenType.DO:
        case TokenType.SWITCH:
        case TokenType.PRINT:
        case TokenType.RETURN:
        case TokenType.BREAK:
        case TokenType.CONTINUE:
          return;
        default:
          _advance();
      }
    }
  }

  Program? parse() {
    final statements = <ASTNode>[];
    try {
      while (!_isAtEnd) {
        final stmt = _declaration();
        if (stmt != null) {
          statements.add(stmt);
        } else {
          if (errors.isNotEmpty) {
            _synchronize();
          }
        }
      }
    } catch (e) {
      if (errors.isEmpty) {
        errors.add(CompilerError.error(
          message: 'Critical parsing error: ${e.toString()}',
          phase: 'Parser',
        ));
      }
    }

    return errors.isEmpty ? Program(statements) : null;
  }

  ASTNode? _declaration() {
    try {
      if (_match([TokenType.INT, TokenType.STRING, TokenType.BOOLEAN, TokenType.FLOAT, TokenType.VOID])) {
        return _variableOrFunctionDeclaration(_previous().value);
      }

      if (_match([TokenType.VAR])) {
        return _varDeclaration();
      }

      return _statement();
    } catch (e) {
      _synchronize();
      return null;
    }
  }

  ASTNode? _varDeclaration() {
    final nameToken = _consume(TokenType.IDENTIFIER, 'variable name');
    if (nameToken.type == TokenType.EOF) return null;

    ASTNode? initializer;
    if (_match([TokenType.ASSIGN])) {
      initializer = _expression();
    }
    _consume(TokenType.SEMICOLON, '";" after variable declaration');

    return VariableDeclaration(type: 'var', name: nameToken.value, initialValue: initializer);
  }

  ASTNode? _variableOrFunctionDeclaration(String type) {
    final nameToken = _consume(TokenType.IDENTIFIER, 'variable or function name');
    if (nameToken.type == TokenType.EOF) return null;

    if (_match([TokenType.LPAREN])) {
      return _functionDeclaration(type, nameToken.value);
    } else if (_match([TokenType.LBRACKET])) {
      return _arrayDeclaration(type, nameToken.value);
    } else {
      return _variableDeclaration(type, nameToken.value);
    }
  }

  ASTNode? _functionDeclaration(String returnType, String name) {
    final parameters = <MapEntry<String, String>>[];

    if (!_check(TokenType.RPAREN)) {
      do {
        if (!_match([TokenType.INT, TokenType.STRING, TokenType.BOOLEAN, TokenType.FLOAT, TokenType.VOID])) {
          _error('Expected parameter type');
          break;
        }
        final paramType = _previous().value;

        if (!_check(TokenType.IDENTIFIER)) {
          _error('Expected parameter name');
          break;
        }
        final paramName = _advance().value;

        parameters.add(MapEntry(paramType, paramName));

      } while (_match([TokenType.COMMA]));
    }

    _consume(TokenType.RPAREN, '")" after function parameters');
    _consume(TokenType.LBRACE, '"{" before function body');

    final statements = <ASTNode>[];
    while (!_check(TokenType.RBRACE) && !_isAtEnd) {
      final stmt = _declaration();
      if (stmt != null) {
        statements.add(stmt);
      } else if (errors.isNotEmpty) {
        _synchronize();
      }
    }

    _consume(TokenType.RBRACE, '"}" after function body');

    return FunctionDeclaration(
      returnType: returnType,
      name: name,
      parameters: parameters,
      body: Block(statements),
    );
  }

  ASTNode? _arrayDeclaration(String type, String name) {
    final sizeExpr = _expression();
    _consume(TokenType.RBRACKET, '"]" after array size');
    _consume(TokenType.SEMICOLON, '";" after array declaration');

    if (sizeExpr == null) {
      _error('Array size expression is required');
      return null;
    }

    int size = 1;
    if (sizeExpr is NumberLiteral) {
      final value = sizeExpr.value;
      if (value is int) {
        size = value;
      } else {
        size = value.toInt();
      }
    } else {
      _error('Array size must be a number literal.');
    }

    return ArrayDeclaration(type: type, name: name, size: size);
  }

  ASTNode? _variableDeclaration(String type, String name) {
    ASTNode? initializer;
    if (_match([TokenType.ASSIGN])) {
      initializer = _expression();
    }
    _consume(TokenType.SEMICOLON, '";" after variable declaration');
    return VariableDeclaration(type: type, name: name, initialValue: initializer);
  }

  ASTNode? _statement() {
    if (_match([TokenType.PRINT])) return _printStatement();
    if (_match([TokenType.IF])) return _ifStatement();
    if (_match([TokenType.WHILE])) return _whileStatement();
    if (_match([TokenType.DO])) return _doWhileStatement();
    if (_match([TokenType.FOR])) return _forStatement();
    if (_match([TokenType.SWITCH])) return _switchStatement();
    if (_match([TokenType.RETURN])) return _returnStatement();
    if (_match([TokenType.BREAK])) return _breakStatement();
    if (_match([TokenType.CONTINUE])) return _continueStatement();
    if (_match([TokenType.LBRACE])) return Block(_block());

    return _expressionStatement();
  }

  ASTNode? _printStatement() {
    _consume(TokenType.LPAREN, '"(" after print');
    final value = _expression();
    _consume(TokenType.RPAREN, '")" after print value');
    _consume(TokenType.SEMICOLON, '";" after print statement');

    if (value == null) {
      _error('Print statement requires an expression');
      return null;
    }

    return PrintStatement(value);
  }

  ASTNode? _ifStatement() {
    _consume(TokenType.LPAREN, '"(" after "if"');
    final condition = _expression();
    _consume(TokenType.RPAREN, '")" after if condition');
    final thenBranch = _statement();

    if (condition == null || thenBranch == null) {
      _error('If statement requires condition and then branch');
      return null;
    }

    ASTNode? elseBranch;
    if (_match([TokenType.ELSE])) {
      elseBranch = _statement();
    }

    return IfStatement(
      condition: condition,
      thenBranch: thenBranch,
      elseBranch: elseBranch,
    );
  }

  ASTNode? _whileStatement() {
    _consume(TokenType.LPAREN, '"(" after "while"');
    final condition = _expression();
    _consume(TokenType.RPAREN, '")" after while condition');

    _loopDepth++;
    final body = _statement();
    _loopDepth--;

    if (condition == null || body == null) {
      _error('While statement requires condition and body');
      return null;
    }

    return WhileStatement(condition: condition, body: body);
  }

  ASTNode? _doWhileStatement() {
    _loopDepth++;
    final body = _statement();
    _loopDepth--;

    _consume(TokenType.WHILE, '"while" after do body');
    _consume(TokenType.LPAREN, '"(" after "while"');
    final condition = _expression();
    _consume(TokenType.RPAREN, '")" after condition');
    _consume(TokenType.SEMICOLON, '";" after do-while statement');

    if (condition == null || body == null) {
      _error('Do-while statement requires condition and body');
      return null;
    }

    return DoWhileStatement(body: body, condition: condition);
  }

  ASTNode? _forStatement() {
    _consume(TokenType.LPAREN, '"(" after "for"');

    ASTNode? initializer;

    if (_match([TokenType.INT, TokenType.STRING, TokenType.BOOLEAN, TokenType.FLOAT, TokenType.VOID])) {
      final varType = _previous().value;
      final nameToken = _consume(TokenType.IDENTIFIER, 'variable name');
      if (nameToken.type != TokenType.EOF) {
        ASTNode? initValue;
        if (_match([TokenType.ASSIGN])) {
          initValue = _expression();
        }
        initializer = VariableDeclaration(
          type: varType,
          name: nameToken.value,
          initialValue: initValue,
        );
      }
    } else if (_match([TokenType.VAR])) {
      final nameToken = _consume(TokenType.IDENTIFIER, 'variable name');
      if (nameToken.type != TokenType.EOF) {
        ASTNode? initValue;
        if (_match([TokenType.ASSIGN])) {
          initValue = _expression();
        }
        initializer = VariableDeclaration(
          type: 'var',
          name: nameToken.value,
          initialValue: initValue,
        );
      }
    } else if (!_check(TokenType.SEMICOLON)) {
      initializer = _assignmentOrExpression();
    }

    _consume(TokenType.SEMICOLON, '";" after loop initializer');

    ASTNode? condition;
    if (!_check(TokenType.SEMICOLON)) {
      condition = _expression();
    }
    _consume(TokenType.SEMICOLON, '";" after loop condition');

    ASTNode? increment;
    if (!_check(TokenType.RPAREN)) {
      increment = _assignmentOrExpression();
    }

    _consume(TokenType.RPAREN, '")" after for clauses');

    _loopDepth++;
    final body = _statement();
    _loopDepth--;

    if (body == null) {
      _error('For statement requires a body');
      return null;
    }

    return ForStatement(
      initializer: initializer,
      condition: condition,
      increment: increment,
      body: body,
    );
  }

  ASTNode? _switchStatement() {
    _consume(TokenType.LPAREN, '"(" after "switch"');
    final expression = _expression();
    _consume(TokenType.RPAREN, '")" after switch expression');
    _consume(TokenType.LBRACE, '"{" before switch body');

    if (expression == null) {
      _error('Switch statement requires an expression');
      return null;
    }

    final cases = <SwitchCase>[];
    ASTNode? defaultCase;

    _loopDepth++;

    while (!_check(TokenType.RBRACE) && !_isAtEnd) {
      if (_match([TokenType.CASE])) {
        final caseValue = _expression();
        _consume(TokenType.COLON, '":" after case value');

        final statements = <ASTNode>[];
        while (!_check(TokenType.CASE) && !_check(TokenType.DEFAULT) && !_check(TokenType.RBRACE) && !_isAtEnd) {
          final stmt = _statement();
          if (stmt != null) {
            statements.add(stmt);
          }
        }

        if (caseValue != null) {
          cases.add(SwitchCase(value: caseValue, body: Block(statements)));
        }
      } else if (_match([TokenType.DEFAULT])) {
        _consume(TokenType.COLON, '":" after default');

        final statements = <ASTNode>[];
        while (!_check(TokenType.RBRACE) && !_isAtEnd) {
          final stmt = _statement();
          if (stmt != null) {
            statements.add(stmt);
          }
        }

        defaultCase = Block(statements);
      } else {
        _error('Expected "case" or "default" in switch statement');
        _synchronize();
        break;
      }
    }

    _loopDepth--;
    _consume(TokenType.RBRACE, '"}" after switch body');

    return SwitchStatement(
      expression: expression,
      cases: cases,
      defaultCase: defaultCase,
    );
  }

  ASTNode? _breakStatement() {
    if (_loopDepth == 0) {
      _error('Break statement must be inside a loop or switch');
    }
    _consume(TokenType.SEMICOLON, '";" after break');
    return BreakStatement();
  }

  ASTNode? _continueStatement() {
    if (_loopDepth == 0) {
      _error('Continue statement must be inside a loop');
    }
    _consume(TokenType.SEMICOLON, '";" after continue');
    return ContinueStatement();
  }

  ASTNode? _returnStatement() {
    ASTNode? value;
    if (!_check(TokenType.SEMICOLON)) {
      value = _expression();
    }
    _consume(TokenType.SEMICOLON, '";" after return value');
    return ReturnStatement(value);
  }

  List<ASTNode> _block() {
    final statements = <ASTNode>[];
    while (!_check(TokenType.RBRACE) && !_isAtEnd) {
      final stmt = _declaration();
      if (stmt != null) {
        statements.add(stmt);
      } else if (errors.isNotEmpty) {
        _synchronize();
      }
    }
    _consume(TokenType.RBRACE, '"}" after block');
    return statements;
  }

  ASTNode? _expressionStatement() {
    final expr = _assignmentOrExpression();
    _consume(TokenType.SEMICOLON, '";" after expression');
    return expr;
  }

  ASTNode? _assignmentOrExpression() {
    final expr = _expression();

    if (expr == null) return null;

    if (expr is Identifier && _check(TokenType.ASSIGN)) {
      _advance();
      final value = _expression();
      if (value == null) {
        _error('Assignment requires a value');
        return null;
      }
      return Assignment(name: expr.name, value: value);
    }

    if (expr is ArrayAccess && _check(TokenType.ASSIGN)) {
      _advance();
      final value = _expression();
      if (value == null) {
        _error('Assignment requires a value');
        return null;
      }
      return ArrayAssignment(
        name: expr.name,
        index: expr.index,
        value: value,
      );
    }

    return expr;
  }

  ASTNode? _expression() {
    if (_check(TokenType.LPAREN)) {
      final lookahead = _quickLambdaCheck();
      if (lookahead) {
        return _parseLambdaExpression();
      }
    }

    return _logicalOr();
  }

  bool _quickLambdaCheck() {
    final start = _current;
    int depth = 0;
    int pos = _current;

    const maxLookAhead = 20;
    int searched = 0;

    try {
      if (pos >= tokens.length || tokens[pos].type != TokenType.LPAREN) {
        return false;
      }

      pos++;
      depth = 1;

      while (pos < tokens.length && searched < maxLookAhead) {
        searched++;
        final token = tokens[pos];

        if (token.type == TokenType.LPAREN) {
          depth++;
        } else if (token.type == TokenType.RPAREN) {
          depth--;
          if (depth == 0) {
            pos++;
            if (pos < tokens.length && tokens[pos].type == TokenType.ARROW) {
              return true;
            }
            return false;
          }
        } else if (token.type == TokenType.EOF) {
          return false;
        }

        pos++;
      }

      return false;
    } catch (e) {
      return false;
    } finally {
      _current = start;
    }
  }

  ASTNode? _parseLambdaExpression() {
    _advance();

    final params = <MapEntry<String, String>>[];

    if (!_check(TokenType.RPAREN)) {
      int paramCount = 0;
      const maxParams = 10;

      do {
        if (paramCount >= maxParams) {
          _error('Too many lambda parameters (max $maxParams)');
          break;
        }

        if (!_match([TokenType.INT, TokenType.STRING, TokenType.BOOLEAN, TokenType.FLOAT, TokenType.VOID, TokenType.VAR])) {
          _error('Expected parameter type in lambda');
          return null;
        }
        final paramType = _previous().value;

        if (!_check(TokenType.IDENTIFIER)) {
          _error('Expected parameter name in lambda');
          return null;
        }
        final paramName = _advance().value;

        params.add(MapEntry(paramType, paramName));
        paramCount++;

      } while (_match([TokenType.COMMA]) && !_isAtEnd);
    }

    _consume(TokenType.RPAREN, '")" after lambda parameters');
    _consume(TokenType.ARROW, '"=>" in lambda expression');

    final body = _logicalOr();
    if (body == null) {
      _error('Lambda body is required');
      return null;
    }

    return LambdaFunction(parameters: params, body: body);
  }

  ASTNode? _logicalOr() {
    ASTNode? expr = _logicalAnd();

    while (_match([TokenType.OR])) {
      final operator = _previous().value;
      final right = _logicalAnd();
      if (expr != null && right != null) {
        expr = BinaryExpression(left: expr, operator: operator, right: right);
      } else {
        _error('Invalid binary expression');
        return null;
      }
    }

    return expr;
  }

  ASTNode? _logicalAnd() {
    ASTNode? expr = _equality();

    while (_match([TokenType.AND])) {
      final operator = _previous().value;
      final right = _equality();
      if (expr != null && right != null) {
        expr = BinaryExpression(left: expr, operator: operator, right: right);
      } else {
        _error('Invalid binary expression');
        return null;
      }
    }

    return expr;
  }

  ASTNode? _equality() {
    ASTNode? expr = _comparison();

    while (_match([TokenType.EQUAL, TokenType.NOT_EQUAL])) {
      final operator = _previous().value;
      final right = _comparison();
      if (expr != null && right != null) {
        expr = BinaryExpression(left: expr, operator: operator, right: right);
      } else {
        _error('Invalid binary expression');
        return null;
      }
    }

    return expr;
  }

  ASTNode? _comparison() {
    ASTNode? expr = _addition();

    while (_match([TokenType.GREATER, TokenType.GREATER_EQUAL, TokenType.LESS, TokenType.LESS_EQUAL])) {
      final operator = _previous().value;
      final right = _addition();
      if (expr != null && right != null) {
        expr = BinaryExpression(left: expr, operator: operator, right: right);
      } else {
        _error('Invalid binary expression');
        return null;
      }
    }

    return expr;
  }

  ASTNode? _addition() {
    ASTNode? expr = _multiplication();

    while (_match([TokenType.PLUS, TokenType.MINUS])) {
      final operator = _previous().value;
      final right = _multiplication();
      if (expr != null && right != null) {
        expr = BinaryExpression(left: expr, operator: operator, right: right);
      } else {
        _error('Invalid binary expression');
        return null;
      }
    }

    return expr;
  }

  ASTNode? _multiplication() {
    ASTNode? expr = _unary();

    while (_match([TokenType.MULTIPLY, TokenType.DIVIDE, TokenType.MODULO])) {
      final operator = _previous().value;
      final right = _unary();
      if (expr != null && right != null) {
        expr = BinaryExpression(left: expr, operator: operator, right: right);
      } else {
        _error('Invalid binary expression');
        return null;
      }
    }

    return expr;
  }

  ASTNode? _unary() {
    if (_match([TokenType.NOT, TokenType.MINUS])) {
      final operator = _previous().value;
      final right = _unary();
      if (right != null) {
        return UnaryExpression(operator: operator, operand: right);
      } else {
        _error('Unary expression requires an operand');
        return null;
      }
    }

    ASTNode? expr = _call();

    if (expr != null && (expr is Identifier)) {
      if (_match([TokenType.INCREMENT])) {
        return Assignment(
          name: expr.name,
          value: BinaryExpression(
            left: Identifier(expr.name),
            operator: '+',
            right: NumberLiteral(1),
          ),
        );
      }
      if (_match([TokenType.DECREMENT])) {
        return Assignment(
          name: expr.name,
          value: BinaryExpression(
            left: Identifier(expr.name),
            operator: '-',
            right: NumberLiteral(1),
          ),
        );
      }
    }

    return expr;
  }

  ASTNode? _call() {
    ASTNode? expr = _primary();

    while (true) {
      if (_match([TokenType.LPAREN]) && expr is Identifier) {
        expr = _finishCall(expr);
      } else if (_match([TokenType.LPAREN]) && expr is LambdaFunction) {
        expr = _finishLambdaCall(expr);
      } else if (expr is Identifier && _match([TokenType.LBRACKET])) {
        expr = _finishArrayAccess(expr);
      } else {
        break;
      }
    }
    return expr;
  }

  ASTNode? _finishArrayAccess(Identifier arrayName) {
    final index = _expression();
    _consume(TokenType.RBRACKET, '"]" after array index');

    if (index == null) {
      _error('Array access requires an index');
      return null;
    }

    return ArrayAccess(name: arrayName.name, index: index);
  }

  ASTNode? _finishCall(Identifier callee) {
    final arguments = <ASTNode>[];

    if (!_check(TokenType.RPAREN)) {
      do {
        final arg = _expression();
        if (arg != null) {
          arguments.add(arg);
        }
      } while (_match([TokenType.COMMA]));
    }

    _consume(TokenType.RPAREN, '")" after arguments');

    return FunctionCall(name: callee.name, arguments: arguments);
  }

  ASTNode? _finishLambdaCall(LambdaFunction lambda) {
    final arguments = <ASTNode>[];

    if (!_check(TokenType.RPAREN)) {
      do {
        final arg = _expression();
        if (arg != null) {
          arguments.add(arg);
        }
      } while (_match([TokenType.COMMA]));
    }

    _consume(TokenType.RPAREN, '")" after arguments');

    return LambdaCall(lambda: lambda, arguments: arguments);
  }

  ASTNode? _primary() {
    if (_match([TokenType.TRUE])) {
      return BooleanLiteral(true);
    }
    if (_match([TokenType.FALSE])) {
      return BooleanLiteral(false);
    }

    if (_match([TokenType.NUMBER])) {
      try {
        final value = int.parse(_previous().value);
        return NumberLiteral(value);
      } catch (_) {
        _error('Invalid number format');
        return NumberLiteral(0);
      }
    }

    if (_match([TokenType.FLOAT_LITERAL])) {
      try {
        final value = double.parse(_previous().value);
        return NumberLiteral(value);
      } catch (_) {
        _error('Invalid float format');
        return NumberLiteral(0.0);
      }
    }

    if (_match([TokenType.STRING_LITERAL])) {
      return StringLiteral(_previous().value);
    }

    if (_match([TokenType.IDENTIFIER])) {
      return Identifier(_previous().value);
    }

    if (_match([TokenType.LPAREN])) {
      final expr = _expression();
      _consume(TokenType.RPAREN, '")" after expression');
      return expr;
    }

    _error('Expected expression or simple value');
    return null;
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
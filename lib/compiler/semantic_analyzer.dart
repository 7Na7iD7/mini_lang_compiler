import '../models/ast_nodes.dart';
import '../models/token_types.dart';

class Symbol {
  final String name;
  final String type;
  final bool isArray;
  final bool isFunction;
  final bool isLambda;
  final List<String>? parameters;
  final String scope;

  Symbol({
    required this.name,
    required this.type,
    this.isArray = false,
    this.isFunction = false,
    this.isLambda = false,
    this.parameters,
    this.scope = 'global',
  });

  @override
  String toString() {
    if (isFunction) {
      return 'Function $name($type) params: ${parameters?.join(', ') ?? 'none'}';
    } else if (isLambda) {
      return 'Lambda($type) params: ${parameters?.join(', ') ?? 'none'}';
    } else if (isArray) {
      return 'Array $name[$type]';
    } else {
      return 'Variable $name($type)';
    }
  }
}

class SemanticAnalyzer implements ASTVisitor<String?> {
  final List<CompilerError> errors = [];
  final List<CompilerError> warnings = [];

  final Map<String, Symbol> globalSymbolTable = {};
  final List<Map<String, Symbol>> scopeStack = [];

  String? currentFunctionReturnType;
  bool currentFunctionHasReturn = false;
  int loopDepth = 0;

  SemanticAnalyzer();

  void analyze(Program program) {
    globalSymbolTable.clear();
    errors.clear();
    warnings.clear();
    scopeStack.clear();
    currentFunctionReturnType = null;
    currentFunctionHasReturn = false;
    loopDepth = 0;

    try {
      program.accept(this);
    } catch (e, stackTrace) {
      errors.add(CompilerError.error(
        message: 'Critical Semantic Analysis Error: ${e.toString()}',
        phase: 'Semantic Analyzer',
      ));
      print('Semantic analyzer error stack trace: $stackTrace');
    }
  }

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  String getErrorsAsString() {
    return errors.map((e) => e.toString()).join('\n');
  }

  String getWarningsAsString() {
    return warnings.map((e) => e.toString()).join('\n');
  }

  List<CompilerError> getAllMessages() {
    return [...errors, ...warnings];
  }

  void _pushScope() {
    scopeStack.add({});
  }

  void _popScope() {
    if (scopeStack.isNotEmpty) {
      scopeStack.removeLast();
    }
  }

  void _addSymbol(String name, Symbol symbol) {
    if (scopeStack.isEmpty) {
      if (globalSymbolTable.containsKey(name)) {
        errors.add(CompilerError.error(
          message: 'Symbol \'$name\' is already defined in global scope.',
          phase: 'Semantic Analyzer',
        ));
      } else {
        globalSymbolTable[name] = symbol;
      }
    } else {
      final currentScope = scopeStack.last;
      if (currentScope.containsKey(name)) {
        errors.add(CompilerError.error(
          message: 'Symbol \'$name\' is already defined in current scope.',
          phase: 'Semantic Analyzer',
        ));
      } else {
        currentScope[name] = symbol;
      }
    }
  }

  Symbol? _lookupSymbol(String name) {
    for (int i = scopeStack.length - 1; i >= 0; i--) {
      final symbol = scopeStack[i][name];
      if (symbol != null) return symbol;
    }
    return globalSymbolTable[name];
  }

  bool _isNumericType(String type) {
    return type == 'int' || type == 'float' || type == 'double';
  }

  bool _isCompatibleType(String sourceType, String targetType) {
    if (sourceType == targetType) return true;

    if (targetType == 'var' || sourceType == 'var') return true;

    if (sourceType == 'int' && (targetType == 'float' || targetType == 'double')) {
      return true;
    }

    if (sourceType == 'float' && targetType == 'double') {
      return true;
    }

    if (sourceType == 'double' && targetType == 'float') {
      warnings.add(CompilerError.warning(
        message: 'Implicit conversion from \'double\' to \'float\' may lose precision.',
        phase: 'Semantic Analyzer',
      ));
      return true;
    }

    if (sourceType.startsWith('lambda<') || targetType.startsWith('lambda<')) {
      return true;
    }

    if (sourceType == 'lambda' || targetType == 'lambda') {
      return true;
    }

    return false;
  }

  String? _inferBinaryExpressionType(String leftType, String rightType, String operator) {
    if (['+', '-', '*', '/'].contains(operator)) {
      if (_isNumericType(leftType) && _isNumericType(rightType)) {
        if (leftType == 'double' || rightType == 'double') return 'double';
        if (leftType == 'float' || rightType == 'float') return 'float';
        return 'int';
      }
      if (operator == '+' && (leftType == 'string' || rightType == 'string')) {
        return 'string';
      }
      return null;
    }

    if (operator == '%') {
      if (leftType == 'int' && rightType == 'int') {
        return 'int';
      }
      if (_isNumericType(leftType) && _isNumericType(rightType)) {
        warnings.add(CompilerError.warning(
          message: 'Modulo operator (%) with floating-point numbers may produce unexpected results.',
          phase: 'Semantic Analyzer',
        ));
        if (leftType == 'double' || rightType == 'double') return 'double';
        if (leftType == 'float' || rightType == 'float') return 'float';
        return 'int';
      }
      return null;
    }

    if (['==', '!=', '<', '>', '<=', '>='].contains(operator)) {
      if (leftType == rightType || (_isNumericType(leftType) && _isNumericType(rightType))) {
        return 'boolean';
      }
      return null;
    }

    if (['&&', '||'].contains(operator)) {
      if (leftType == 'boolean' && rightType == 'boolean') {
        return 'boolean';
      }
      return null;
    }

    return null;
  }

  String? _inferUnaryExpressionType(String operandType, String operator) {
    if (operator == '-') {
      return _isNumericType(operandType) ? operandType : null;
    }
    if (operator == '!') {
      return operandType == 'boolean' ? 'boolean' : null;
    }
    return null;
  }

  @override
  String? visitProgram(Program node) {
    for (final statement in node.statements) {
      if (statement is FunctionDeclaration) {
        final parameters = statement.parameters.map((p) => '${p.key} ${p.value}').toList();

        final existing = globalSymbolTable[statement.name];
        if (existing != null) {
          if (!existing.isFunction) {
            errors.add(CompilerError.error(
              message: 'Function \'${statement.name}\' conflicts with existing variable.',
              phase: 'Semantic Analyzer',
            ));
          } else {
            errors.add(CompilerError.error(
              message: 'Function \'${statement.name}\' is already defined.',
              phase: 'Semantic Analyzer',
            ));
          }
        } else {
          globalSymbolTable[statement.name] = Symbol(
            name: statement.name,
            type: statement.returnType,
            isFunction: true,
            parameters: parameters,
            scope: 'global',
          );
        }
      }
    }

    for (final statement in node.statements) {
      statement.accept(this);
    }
    return null;
  }

  @override
  String? visitVariableDeclaration(VariableDeclaration node) {
    final existing = _lookupSymbol(node.name);
    if (existing != null && existing.isFunction) {
      errors.add(CompilerError.error(
        message: 'Variable \'${node.name}\' conflicts with existing function.',
        phase: 'Semantic Analyzer',
      ));
    }

    String actualType = node.type;
    bool isLambda = false;

    if (node.initialValue != null) {
      final inferredType = node.initialValue!.accept(this);

      if (inferredType != null && inferredType.startsWith('lambda<')) {
        isLambda = true;
        if (node.type == 'var') {
          actualType = inferredType;
        }
      } else if (node.type == 'var' && inferredType != null) {
        actualType = inferredType;
      }
    }

    final scopeName = scopeStack.isEmpty ? 'global' : 'local';

    _addSymbol(node.name, Symbol(
      name: node.name,
      type: actualType,
      isLambda: isLambda,
      scope: scopeName,
    ));

    if (node.initialValue != null) {
      final valueType = node.initialValue!.accept(this);
      if (valueType != null && node.type != 'var' && !_isCompatibleType(valueType, node.type)) {
        errors.add(CompilerError.error(
          message: 'Type mismatch: Cannot assign \'$valueType\' to variable \'${node.name}\' of type \'${node.type}\'.',
          phase: 'Semantic Analyzer',
        ));
      }
    }
    return null;
  }

  @override
  String? visitAssignment(Assignment node) {
    final symbol = _lookupSymbol(node.name);
    if (symbol == null) {
      errors.add(CompilerError.error(
        message: 'Variable \'${node.name}\' is not declared.',
        phase: 'Semantic Analyzer',
      ));
      return null;
    } else if (symbol.isFunction) {
      errors.add(CompilerError.error(
        message: 'Cannot assign to function \'${node.name}\'.',
        phase: 'Semantic Analyzer',
      ));
      return null;
    } else if (symbol.isArray) {
      errors.add(CompilerError.error(
        message: 'Cannot assign to entire array \'${node.name}\'. Use array indexing.',
        phase: 'Semantic Analyzer',
      ));
      return null;
    }

    final valueType = node.value.accept(this);
    if (valueType != null && symbol.type != 'var' && !_isCompatibleType(valueType, symbol.type)) {
      errors.add(CompilerError.error(
        message: 'Type mismatch: Cannot assign \'$valueType\' to variable \'${node.name}\' of type \'${symbol.type}\'.',
        phase: 'Semantic Analyzer',
      ));
    }

    return null;
  }

  @override
  String? visitPrintStatement(PrintStatement node) {
    node.expression.accept(this);
    return null;
  }

  @override
  String? visitIfStatement(IfStatement node) {
    final conditionType = node.condition.accept(this);
    if (conditionType != null && conditionType != 'boolean') {
      errors.add(CompilerError.error(
        message: 'Condition in if statement must be of type \'boolean\', got \'$conditionType\'.',
        phase: 'Semantic Analyzer',
      ));
    }
    node.thenBranch.accept(this);
    node.elseBranch?.accept(this);
    return null;
  }

  @override
  String? visitWhileStatement(WhileStatement node) {
    final conditionType = node.condition.accept(this);
    if (conditionType != null && conditionType != 'boolean') {
      errors.add(CompilerError.error(
        message: 'Condition in while statement must be of type \'boolean\', got \'$conditionType\'.',
        phase: 'Semantic Analyzer',
      ));
    }
    loopDepth++;
    node.body.accept(this);
    loopDepth--;
    return null;
  }

  @override
  String? visitDoWhileStatement(DoWhileStatement node) {
    loopDepth++;
    node.body.accept(this);
    loopDepth--;

    final conditionType = node.condition.accept(this);
    if (conditionType != null && conditionType != 'boolean') {
      errors.add(CompilerError.error(
        message: 'Condition in do-while statement must be of type \'boolean\', got \'$conditionType\'.',
        phase: 'Semantic Analyzer',
      ));
    }
    return null;
  }

  @override
  String? visitForStatement(ForStatement node) {
    _pushScope();
    node.initializer?.accept(this);
    final conditionType = node.condition?.accept(this);
    if (conditionType != null && conditionType != 'boolean') {
      errors.add(CompilerError.error(
        message: 'Condition in for statement must be of type \'boolean\', got \'$conditionType\'.',
        phase: 'Semantic Analyzer',
      ));
    }
    node.increment?.accept(this);
    loopDepth++;
    node.body.accept(this);
    loopDepth--;
    _popScope();
    return null;
  }

  @override
  String? visitSwitchStatement(SwitchStatement node) {
    node.expression.accept(this);

    loopDepth++;
    for (final caseNode in node.cases) {
      caseNode.accept(this);
    }
    node.defaultCase?.accept(this);
    loopDepth--;

    return null;
  }

  @override
  String? visitSwitchCase(SwitchCase node) {
    node.value.accept(this);
    node.body.accept(this);
    return null;
  }

  @override
  String? visitBreakStatement(BreakStatement node) {
    if (loopDepth == 0) {
      errors.add(CompilerError.error(
        message: 'Break statement must be inside a loop or switch.',
        phase: 'Semantic Analyzer',
      ));
    }
    return null;
  }

  @override
  String? visitContinueStatement(ContinueStatement node) {
    if (loopDepth == 0) {
      errors.add(CompilerError.error(
        message: 'Continue statement must be inside a loop.',
        phase: 'Semantic Analyzer',
      ));
    }
    return null;
  }

  @override
  String? visitFunctionDeclaration(FunctionDeclaration node) {
    _pushScope();
    final previousFunctionReturnType = currentFunctionReturnType;
    final previousHasReturn = currentFunctionHasReturn;
    currentFunctionReturnType = node.returnType;
    currentFunctionHasReturn = false;

    for (final param in node.parameters) {
      _addSymbol(param.value, Symbol(
        name: param.value,
        type: param.key,
        scope: 'local',
      ));
    }

    node.body.accept(this);

    if (currentFunctionReturnType != 'void' && !currentFunctionHasReturn) {
      warnings.add(CompilerError.warning(
        message: 'Function \'${node.name}\' may not return a value in all code paths.',
        phase: 'Semantic Analyzer',
      ));
    }

    currentFunctionReturnType = previousFunctionReturnType;
    currentFunctionHasReturn = previousHasReturn;
    _popScope();
    return null;
  }

  @override
  String? visitFunctionCall(FunctionCall node) {
    final symbol = _lookupSymbol(node.name);
    if (symbol != null && symbol.isLambda) {
      if (symbol.type.startsWith('lambda<')) {
        final returnType = symbol.type.substring(7, symbol.type.length - 1);
        return returnType == 'var' ? null : returnType;
      }
      return null;
    }

    if (symbol == null) {
      errors.add(CompilerError.error(
        message: 'Function \'${node.name}\' is not defined.',
        phase: 'Semantic Analyzer',
      ));
      return null;
    } else if (!symbol.isFunction) {
      errors.add(CompilerError.error(
        message: '\'${node.name}\' is not a function.',
        phase: 'Semantic Analyzer',
      ));
      return null;
    }

    final expectedParamCount = symbol.parameters?.length ?? 0;
    final actualArgCount = node.arguments.length;

    if (actualArgCount != expectedParamCount) {
      errors.add(CompilerError.error(
        message: 'Function \'${node.name}\' expects $expectedParamCount argument(s), but got $actualArgCount.',
        phase: 'Semantic Analyzer',
      ));
    }

    for (int i = 0; i < node.arguments.length && i < expectedParamCount; i++) {
      final argType = node.arguments[i].accept(this);
      if (argType != null && symbol.parameters != null && i < symbol.parameters!.length) {
        final paramInfo = symbol.parameters![i].split(' ');
        if (paramInfo.isNotEmpty) {
          final expectedType = paramInfo[0];
          if (!_isCompatibleType(argType, expectedType)) {
            errors.add(CompilerError.error(
              message: 'Argument ${i + 1} of function \'${node.name}\': expected \'$expectedType\', got \'$argType\'.',
              phase: 'Semantic Analyzer',
            ));
          }
        }
      }
    }
    return symbol.type;
  }

  @override
  String? visitLambdaFunction(LambdaFunction node) {
    _pushScope();

    for (final param in node.parameters) {
      _addSymbol(param.value, Symbol(
        name: param.value,
        type: param.key,
        scope: 'local',
      ));
    }

    final bodyType = node.body.accept(this);
    _popScope();

    return 'lambda<${bodyType ?? 'var'}>';
  }

  @override
  String? visitLambdaCall(LambdaCall node) {
    final lambdaType = node.lambda.accept(this);

    final expectedParamCount = node.lambda.parameters.length;
    final actualArgCount = node.arguments.length;

    if (actualArgCount != expectedParamCount) {
      errors.add(CompilerError.error(
        message: 'Lambda expects $expectedParamCount argument(s), but got $actualArgCount.',
        phase: 'Semantic Analyzer',
      ));
    }

    for (int i = 0; i < node.arguments.length && i < expectedParamCount; i++) {
      final argType = node.arguments[i].accept(this);
      final paramType = node.lambda.parameters[i].key;

      if (argType != null && !_isCompatibleType(argType, paramType)) {
        errors.add(CompilerError.error(
          message: 'Lambda argument ${i + 1}: expected \'$paramType\', got \'$argType\'.',
          phase: 'Semantic Analyzer',
        ));
      }
    }

    if (lambdaType != null && lambdaType.startsWith('lambda<')) {
      final returnType = lambdaType.substring(7, lambdaType.length - 1);
      return returnType;
    }

    return 'var';
  }

  @override
  String? visitArrayDeclaration(ArrayDeclaration node) {
    if (node.size <= 0) {
      errors.add(CompilerError.error(
        message: 'Array size must be a positive integer, got ${node.size}.',
        phase: 'Semantic Analyzer',
      ));
    }

    const maxArraySize = 10000;
    if (node.size > maxArraySize) {
      errors.add(CompilerError.error(
        message: 'Array size ${node.size} exceeds maximum allowed size of $maxArraySize.',
        phase: 'Semantic Analyzer',
      ));
    }

    final scopeName = scopeStack.isEmpty ? 'global' : 'local';
    _addSymbol(node.name, Symbol(
      name: node.name,
      type: node.type,
      isArray: true,
      scope: scopeName,
    ));
    return null;
  }

  @override
  String? visitArrayAccess(ArrayAccess node) {
    final symbol = _lookupSymbol(node.name);
    if (symbol == null) {
      errors.add(CompilerError.error(
        message: 'Array \'${node.name}\' is not declared.',
        phase: 'Semantic Analyzer',
      ));
      return null;
    } else if (!symbol.isArray) {
      errors.add(CompilerError.error(
        message: '\'${node.name}\' is not an array.',
        phase: 'Semantic Analyzer',
      ));
      return null;
    }
    final indexType = node.index.accept(this);
    if (indexType != null && indexType != 'int') {
      errors.add(CompilerError.error(
        message: 'Array index must be of type \'int\', got \'$indexType\'.',
        phase: 'Semantic Analyzer',
      ));
    }
    return symbol.type;
  }

  @override
  String? visitArrayAssignment(ArrayAssignment node) {
    final symbol = _lookupSymbol(node.name);
    if (symbol == null) {
      errors.add(CompilerError.error(
        message: 'Array \'${node.name}\' is not declared.',
        phase: 'Semantic Analyzer',
      ));
      return null;
    } else if (!symbol.isArray) {
      errors.add(CompilerError.error(
        message: '\'${node.name}\' is not an array.',
        phase: 'Semantic Analyzer',
      ));
      return null;
    }
    final indexType = node.index.accept(this);
    if (indexType != null && indexType != 'int') {
      errors.add(CompilerError.error(
        message: 'Array index must be of type \'int\', got \'$indexType\'.',
        phase: 'Semantic Analyzer',
      ));
    }
    final valueType = node.value.accept(this);
    if (valueType != null && !_isCompatibleType(valueType, symbol.type)) {
      errors.add(CompilerError.error(
        message: 'Type mismatch: Cannot assign \'$valueType\' to array \'${node.name}\' of type \'${symbol.type}\'.',
        phase: 'Semantic Analyzer',
      ));
    }
    return null;
  }

  @override
  String? visitReturnStatement(ReturnStatement node) {
    if (currentFunctionReturnType == null) {
      errors.add(CompilerError.error(
        message: 'Return statement outside of function.',
        phase: 'Semantic Analyzer',
      ));
      return null;
    }
    currentFunctionHasReturn = true;
    final returnValueType = node.value?.accept(this);
    if (node.value == null && currentFunctionReturnType != 'void') {
      errors.add(CompilerError.error(
        message: 'Non-void function must return a value of type \'$currentFunctionReturnType\'.',
        phase: 'Semantic Analyzer',
      ));
    } else if (node.value != null && currentFunctionReturnType == 'void') {
      warnings.add(CompilerError.warning(
        message: 'Void function should not return a value.',
        phase: 'Semantic Analyzer',
      ));
    } else if (returnValueType != null && currentFunctionReturnType != 'void') {
      if (!_isCompatibleType(returnValueType, currentFunctionReturnType!)) {
        errors.add(CompilerError.error(
          message: 'Return type mismatch: expected \'$currentFunctionReturnType\', got \'$returnValueType\'.',
          phase: 'Semantic Analyzer',
        ));
      }
    }
    return null;
  }

  @override
  String? visitBlock(Block node) {
    for (final statement in node.statements) {
      statement.accept(this);
    }
    return null;
  }

  @override
  String? visitBinaryExpression(BinaryExpression node) {
    final leftType = node.left.accept(this);
    final rightType = node.right.accept(this);
    if (leftType == null || rightType == null) {
      return null;
    }
    final resultType = _inferBinaryExpressionType(leftType, rightType, node.operator);
    if (resultType == null) {
      errors.add(CompilerError.error(
        message: 'Invalid binary operation: \'$leftType\' ${node.operator} \'$rightType\'.',
        phase: 'Semantic Analyzer',
      ));
      return null;
    }
    return resultType;
  }

  @override
  String? visitUnaryExpression(UnaryExpression node) {
    final operandType = node.operand.accept(this);
    if (operandType == null) {
      return null;
    }
    final resultType = _inferUnaryExpressionType(operandType, node.operator);
    if (resultType == null) {
      errors.add(CompilerError.error(
        message: 'Invalid unary operation: \'${node.operator}\' on type \'$operandType\'.',
        phase: 'Semantic Analyzer',
      ));
      return null;
    }
    return resultType;
  }

  @override
  String? visitIdentifier(Identifier node) {
    final symbol = _lookupSymbol(node.name);
    if (symbol == null) {
      errors.add(CompilerError.error(
        message: 'Undefined identifier: \'${node.name}\'',
        phase: 'Semantic Analyzer',
      ));
      return null;
    }
    return symbol.type;
  }

  @override
  String? visitNumberLiteral(NumberLiteral node) {
    if (node.value is int) {
      return 'int';
    } else if (node.value is double) {
      return 'double';
    } else {
      return 'int';
    }
  }

  @override
  String? visitStringLiteral(StringLiteral node) {
    return 'string';
  }

  @override
  String? visitBooleanLiteral(BooleanLiteral node) {
    return 'boolean';
  }

  Map<String, dynamic> getStatistics() {
    final allSymbols = getAllSymbols();
    return {
      'totalSymbols': allSymbols.length,
      'functions': allSymbols.where((s) => s.isFunction).length,
      'variables': allSymbols.where((s) => !s.isFunction && !s.isArray).length,
      'arrays': allSymbols.where((s) => s.isArray).length,
      'errors': errors.length,
      'warnings': warnings.length,
    };
  }

  Map<String, dynamic> getSymbolTableAsMap() {
    final result = <String, dynamic>{};

    for (final entry in globalSymbolTable.entries) {
      final symbol = entry.value;
      result[entry.key] = {
        'type': symbol.type,
        'isFunction': symbol.isFunction,
        'isArray': symbol.isArray,
        'isLambda': symbol.isLambda,
        'parameters': symbol.parameters ?? [],
        'scope': symbol.scope,
      };
    }

    for (int i = 0; i < scopeStack.length; i++) {
      for (final entry in scopeStack[i].entries) {
        final symbol = entry.value;
        // Use a unique key for local scopes
        final key = '${entry.key}_scope$i';
        result[key] = {
          'type': symbol.type,
          'isFunction': symbol.isFunction,
          'isArray': symbol.isArray,
          'isLambda': symbol.isLambda,
          'parameters': symbol.parameters ?? [],
          'scope': 'local',
        };
      }
    }

    return result;
  }

  List<Symbol> getAllSymbols() {
    final allSymbols = <Symbol>[];
    allSymbols.addAll(globalSymbolTable.values);
    for (final scope in scopeStack) {
      allSymbols.addAll(scope.values);
    }
    return allSymbols;
  }

  List<Symbol> getSymbolsByType(String type) {
    return getAllSymbols().where((s) => s.type == type).toList();
  }

  bool isFunction(String name) {
    final symbol = _lookupSymbol(name);
    return symbol?.isFunction ?? false;
  }

  bool isArray(String name) {
    final symbol = _lookupSymbol(name);
    return symbol?.isArray ?? false;
  }

  String? getSymbolType(String name) {
    final symbol = _lookupSymbol(name);
    return symbol?.type;
  }
}
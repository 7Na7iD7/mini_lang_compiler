import '../models/token_types.dart';
import '../models/ast_nodes.dart';

class InterpreterResult {
  final String output;
  final int executionTime;

  InterpreterResult({required this.output, required this.executionTime});
}

class InterpreterConfig {
  static const int maxRecursionDepth = 1000;
  static const int maxIterations = 100000;
  static const int maxOutputLength = 1000000;
}

class Interpreter implements ASTVisitor<dynamic> {
  final Program program;
  final Map<String, dynamic> globalSymbolTable = {};
  Map<String, dynamic> localSymbolTable = {};
  final Map<String, FunctionDeclaration> functionTable = {};
  final List<CompilerError> errors = [];
  final StringBuffer _output = StringBuffer();
  int _executionTime = 0;
  dynamic _returnValue;
  bool _shouldReturn = false;
  bool _shouldBreak = false;
  bool _shouldContinue = false;
  bool _isInFunction = false;
  int _recursionDepth = 0;

  Interpreter(this.program);

  InterpreterResult interpret() {
    final stopwatch = Stopwatch()..start();
    try {
      for (final statement in program.statements) {
        if (statement is FunctionDeclaration) {
          if (functionTable.containsKey(statement.name)) {
            errors.add(CompilerError.warning(
              message: 'Function ${statement.name} is already defined. Overwriting previous definition.',
              phase: 'Interpreter',
            ));
          }
          functionTable[statement.name] = statement;
        }
      }

      for (final statement in program.statements) {
        if (statement is! FunctionDeclaration) {
          statement.accept(this);
          if (_shouldReturn) break;
        }
      }

      if (functionTable.containsKey('main')) {
        final mainFunc = functionTable['main']!;
        if (mainFunc.parameters.isEmpty) {
          visitFunctionCall(FunctionCall(name: 'main', arguments: []));
        } else {
          errors.add(CompilerError.warning(
            message: 'Function main found but requires parameters. main() should be parameterless.',
            phase: 'Interpreter',
          ));
        }
      }
    } catch (e, stack) {
      errors.add(CompilerError.error(
        message: 'Runtime Execution Error: ${e.toString()}',
        phase: 'Interpreter',
      ));
      print('Interpreter error stack trace: $stack');
    }
    stopwatch.stop();
    _executionTime = stopwatch.elapsedMilliseconds;

    var outputStr = _output.toString();
    if (outputStr.length > InterpreterConfig.maxOutputLength) {
      outputStr = outputStr.substring(0, InterpreterConfig.maxOutputLength) +
          '\n... (output truncated)';
    }

    return InterpreterResult(
        output: outputStr,
        executionTime: _executionTime
    );
  }

  dynamic _getDefaultValue(String type) {
    switch (type.toLowerCase()) {
      case 'int':
        return 0;
      case 'float':
      case 'double':
        return 0.0;
      case 'bool':
      case 'boolean':
        return false;
      case 'string':
        return '';
      case 'var':
        return null;
      default:
        return null;
    }
  }

  dynamic _getVariable(String name) {
    if (_isInFunction && localSymbolTable.containsKey(name)) {
      return localSymbolTable[name];
    }
    if (globalSymbolTable.containsKey(name)) {
      return globalSymbolTable[name];
    }
    return null;
  }

  void _setVariable(String name, dynamic value) {
    if (_isInFunction && localSymbolTable.containsKey(name)) {
      localSymbolTable[name] = value;
    } else {
      globalSymbolTable[name] = value;
    }
  }

  bool _hasVariable(String name) {
    if (_isInFunction && localSymbolTable.containsKey(name)) {
      return true;
    }
    return globalSymbolTable.containsKey(name);
  }

  @override
  dynamic visitProgram(Program node) {
    for (final statement in node.statements) {
      statement.accept(this);
      if (_shouldReturn) break;
    }
    return null;
  }

  @override
  dynamic visitVariableDeclaration(VariableDeclaration node) {
    final value = node.initialValue?.accept(this) ?? _getDefaultValue(node.type);
    if (_isInFunction) {
      localSymbolTable[node.name] = value;
    } else {
      globalSymbolTable[node.name] = value;
    }
    return null;
  }

  @override
  dynamic visitAssignment(Assignment node) {
    if (!_hasVariable(node.name)) {
      errors.add(CompilerError.error(
        message: 'Variable ${node.name} not declared.',
        phase: 'Interpreter',
      ));
      return null;
    }
    final value = node.value.accept(this);
    _setVariable(node.name, value);
    return value;
  }

  @override
  dynamic visitPrintStatement(PrintStatement node) {
    final value = node.expression.accept(this);

    if (_output.length > InterpreterConfig.maxOutputLength) {
      errors.add(CompilerError.error(
        message: 'Output buffer limit exceeded',
        phase: 'Interpreter',
      ));
      return null;
    }

    if (value == null) {
      _output.writeln('null');
    } else {
      _output.writeln(value.toString().replaceAll(r'\n', '\n'));
    }
    return null;
  }

  @override
  dynamic visitIfStatement(IfStatement node) {
    final condition = node.condition.accept(this);
    if (condition == true) {
      node.thenBranch.accept(this);
    } else if (node.elseBranch != null) {
      node.elseBranch!.accept(this);
    }
    return null;
  }

  @override
  dynamic visitWhileStatement(WhileStatement node) {
    int iterations = 0;

    while (iterations < InterpreterConfig.maxIterations && errors.isEmpty) {
      final condition = node.condition.accept(this);
      if (condition != true) break;

      node.body.accept(this);
      iterations++;

      if (_shouldBreak) {
        _shouldBreak = false;
        break;
      }
      if (_shouldContinue) {
        _shouldContinue = false;
        continue;
      }
      if (_shouldReturn) break;
    }

    if (iterations >= InterpreterConfig.maxIterations) {
      errors.add(CompilerError.error(
        message: 'Possible infinite loop detected in While statement (exceeded ${InterpreterConfig.maxIterations} iterations).',
        phase: 'Interpreter',
      ));
    }
    return null;
  }

  @override
  dynamic visitDoWhileStatement(DoWhileStatement node) {
    int iterations = 0;

    // FIXED: Simplified and more reliable do-while loop
    do {
      if (iterations >= InterpreterConfig.maxIterations) {
        errors.add(CompilerError.error(
          message: 'Possible infinite loop detected in Do-While statement (exceeded ${InterpreterConfig.maxIterations} iterations).',
          phase: 'Interpreter',
        ));
        break;
      }

      node.body.accept(this);
      iterations++;

      if (_shouldBreak) {
        _shouldBreak = false;
        break;
      }

      if (_shouldReturn) break;

      if (_shouldContinue) {
        _shouldContinue = false;
      }

      // Check condition after each iteration
      final condition = node.condition.accept(this);
      if (condition != true) break;

      // Safety check for errors
      if (errors.isNotEmpty) break;

    } while (true);

    return null;
  }

  @override
  dynamic visitForStatement(ForStatement node) {
    final savedLocalSymbols = Map<String, dynamic>.from(localSymbolTable);

    node.initializer?.accept(this);
    int currentIteration = 0;

    while (currentIteration < InterpreterConfig.maxIterations && errors.isEmpty) {
      final condition = node.condition?.accept(this) ?? true;
      if (condition != true) break;

      node.body.accept(this);

      if (_shouldBreak) {
        _shouldBreak = false;
        break;
      }
      if (_shouldContinue) {
        _shouldContinue = false;
        node.increment?.accept(this);
        currentIteration++;
        continue;
      }
      if (_shouldReturn) break;

      node.increment?.accept(this);
      currentIteration++;
    }

    if (_isInFunction) {
      final keysToRemove = localSymbolTable.keys
          .where((k) => !savedLocalSymbols.containsKey(k))
          .toList();
      for (final key in keysToRemove) {
        localSymbolTable.remove(key);
      }
    }

    if (currentIteration >= InterpreterConfig.maxIterations) {
      errors.add(CompilerError.error(
        message: 'Possible infinite loop detected in For statement (exceeded ${InterpreterConfig.maxIterations} iterations).',
        phase: 'Interpreter',
      ));
    }
    return null;
  }

  @override
  dynamic visitSwitchStatement(SwitchStatement node) {
    final switchValue = node.expression.accept(this);
    bool matched = false;

    for (final caseNode in node.cases) {
      final caseValue = caseNode.value.accept(this);
      if (switchValue == caseValue) {
        matched = true;
        caseNode.body.accept(this);

        if (_shouldBreak) {
          _shouldBreak = false;
          break;
        }
        if (_shouldReturn) break;
      }
    }

    if (!matched && node.defaultCase != null) {
      node.defaultCase!.accept(this);
      if (_shouldBreak) {
        _shouldBreak = false;
      }
    }

    return null;
  }

  @override
  dynamic visitSwitchCase(SwitchCase node) {
    return node.body.accept(this);
  }

  @override
  dynamic visitBreakStatement(BreakStatement node) {
    _shouldBreak = true;
    return null;
  }

  @override
  dynamic visitContinueStatement(ContinueStatement node) {
    _shouldContinue = true;
    return null;
  }

  @override
  dynamic visitFunctionDeclaration(FunctionDeclaration node) {
    return null;
  }

  @override
  dynamic visitFunctionCall(FunctionCall node) {
    final variable = _getVariable(node.name);
    if (variable is LambdaFunction) {
      return _executeLambda(variable, node.arguments);
    }

    if (!functionTable.containsKey(node.name)) {
      errors.add(CompilerError.error(
        message: 'Function ${node.name} not defined.',
        phase: 'Interpreter',
      ));
      return null;
    }

    final funcDecl = functionTable[node.name]!;
    if (node.arguments.length != funcDecl.parameters.length) {
      errors.add(CompilerError.error(
        message: 'Function ${node.name} expects ${funcDecl.parameters.length} arguments but received ${node.arguments.length}.',
        phase: 'Interpreter',
      ));
      return null;
    }

    _recursionDepth++;
    if (_recursionDepth > InterpreterConfig.maxRecursionDepth) {
      _recursionDepth--;
      errors.add(CompilerError.error(
        message: 'Maximum recursion depth exceeded (${InterpreterConfig.maxRecursionDepth}). Possible infinite recursion in function ${node.name}.',
        phase: 'Interpreter',
      ));
      return null;
    }

    final savedLocalSymbols = Map<String, dynamic>.from(localSymbolTable);
    final wasInFunction = _isInFunction;
    final savedReturnFlag = _shouldReturn;

    _isInFunction = true;
    _shouldReturn = false;
    localSymbolTable = {};

    dynamic result;
    try {
      final evaluatedArgs = <dynamic>[];
      final tempInFunction = _isInFunction;
      _isInFunction = wasInFunction;
      final tempLocalSymbols = localSymbolTable;
      localSymbolTable = savedLocalSymbols;

      for (final arg in node.arguments) {
        final argValue = arg.accept(this);
        evaluatedArgs.add(argValue);
      }

      _isInFunction = tempInFunction;
      localSymbolTable = tempLocalSymbols;

      for (int i = 0; i < funcDecl.parameters.length; i++) {
        localSymbolTable[funcDecl.parameters[i].value] = evaluatedArgs[i];
      }

      funcDecl.body.accept(this);

      if (_shouldReturn) {
        result = _returnValue;
        _shouldReturn = false;
        _returnValue = null;
      }

      if (funcDecl.returnType != 'void' && result == null && !_shouldReturn) {
        if (_recursionDepth == 1) {
          errors.add(CompilerError.warning(
            message: 'Function ${node.name} is not declared as void but reached end without a return statement.',
            phase: 'Interpreter',
          ));
        }
      }

    } finally {
      localSymbolTable = savedLocalSymbols;
      _isInFunction = wasInFunction;
      _shouldReturn = savedReturnFlag;
      _recursionDepth--;
    }

    return result;
  }

  dynamic _executeLambda(LambdaFunction lambda, List<ASTNode> arguments) {
    if (arguments.length != lambda.parameters.length) {
      errors.add(CompilerError.error(
        message: 'Lambda expects ${lambda.parameters.length} arguments but received ${arguments.length}.',
        phase: 'Interpreter',
      ));
      return null;
    }

    final savedLocalSymbols = Map<String, dynamic>.from(localSymbolTable);
    final wasInFunction = _isInFunction;

    dynamic result;
    try {
      final evaluatedArgs = <dynamic>[];
      for (final arg in arguments) {
        final argValue = arg.accept(this);
        evaluatedArgs.add(argValue);
      }

      _isInFunction = true;
      localSymbolTable = {};

      for (int i = 0; i < lambda.parameters.length; i++) {
        localSymbolTable[lambda.parameters[i].value] = evaluatedArgs[i];
      }

      result = lambda.body.accept(this);

    } finally {
      localSymbolTable = savedLocalSymbols;
      _isInFunction = wasInFunction;
    }

    return result;
  }

  @override
  dynamic visitLambdaFunction(LambdaFunction node) {
    return node;
  }

  @override
  dynamic visitLambdaCall(LambdaCall node) {
    final lambda = node.lambda;
    return _executeLambda(lambda, node.arguments);
  }

  @override
  dynamic visitArrayDeclaration(ArrayDeclaration node) {
    if (node.size <= 0) {
      errors.add(CompilerError.error(
        message: 'Array size must be positive, got ${node.size}.',
        phase: 'Interpreter',
      ));
      return null;
    }

    const maxArraySize = 10000;
    if (node.size > maxArraySize) {
      errors.add(CompilerError.error(
        message: 'Array size exceeds maximum allowed size of $maxArraySize.',
        phase: 'Interpreter',
      ));
      return null;
    }

    final defaultValue = _getDefaultValue(node.type);
    final array = List<dynamic>.filled(node.size, defaultValue, growable: false);

    if (_isInFunction) {
      localSymbolTable[node.name] = array;
    } else {
      globalSymbolTable[node.name] = array;
    }
    return null;
  }

  @override
  dynamic visitArrayAccess(ArrayAccess node) {
    final array = _getVariable(node.name);

    if (array == null) {
      errors.add(CompilerError.error(
          message: 'Array ${node.name} not declared.',
          phase: 'Interpreter'
      ));
      return null;
    }

    if (array is! List) {
      errors.add(CompilerError.error(
          message: '${node.name} is not an array.',
          phase: 'Interpreter'
      ));
      return null;
    }

    final index = node.index.accept(this);
    if (index == null) {
      errors.add(CompilerError.error(
          message: 'Array index cannot be null.',
          phase: 'Interpreter'
      ));
      return null;
    }

    if (index is! num) {
      errors.add(CompilerError.error(
          message: 'Array index must be a number, got ${index.runtimeType}.',
          phase: 'Interpreter'
      ));
      return null;
    }

    final idx = index.toInt();
    if (idx < 0 || idx >= array.length) {
      errors.add(CompilerError.error(
          message: 'Array index $idx is out of bounds for array ${node.name} with size ${array.length}.',
          phase: 'Interpreter'
      ));
      return null;
    }

    return array[idx];
  }

  @override
  dynamic visitArrayAssignment(ArrayAssignment node) {
    final array = _getVariable(node.name);

    if (array == null) {
      errors.add(CompilerError.error(
          message: 'Array ${node.name} not declared.',
          phase: 'Interpreter'
      ));
      return null;
    }

    if (array is! List) {
      errors.add(CompilerError.error(
          message: '${node.name} is not an array.',
          phase: 'Interpreter'
      ));
      return null;
    }

    final index = node.index.accept(this);
    if (index == null) {
      errors.add(CompilerError.error(
          message: 'Array index cannot be null.',
          phase: 'Interpreter'
      ));
      return null;
    }

    if (index is! num) {
      errors.add(CompilerError.error(
          message: 'Array index must be a number, got ${index.runtimeType}.',
          phase: 'Interpreter'
      ));
      return null;
    }

    final idx = index.toInt();
    if (idx < 0 || idx >= array.length) {
      errors.add(CompilerError.error(
          message: 'Array index $idx is out of bounds for array ${node.name} with size ${array.length}.',
          phase: 'Interpreter'
      ));
      return null;
    }

    final value = node.value.accept(this);
    array[idx] = value;
    return value;
  }

  @override
  dynamic visitReturnStatement(ReturnStatement node) {
    _returnValue = node.value?.accept(this);
    _shouldReturn = true;
    return null;
  }

  @override
  dynamic visitBlock(Block node) {
    for (final statement in node.statements) {
      statement.accept(this);
      if (_shouldReturn || _shouldBreak || _shouldContinue) return null;
    }
    return null;
  }

  @override
  dynamic visitBinaryExpression(BinaryExpression node) {
    final left = node.left.accept(this);
    final right = node.right.accept(this);

    if (left == null || right == null) {
      errors.add(CompilerError.error(
        message: 'Cannot perform binary operation on null values.',
        phase: 'Interpreter',
      ));
      return null;
    }

    if (node.operator == '+' && (left is String || right is String)) {
      return left.toString() + right.toString();
    }

    if (node.operator == '&&' || node.operator == '||') {
      if (left is! bool || right is! bool) {
        errors.add(CompilerError.error(
          message: 'Logical operators (${node.operator}) require boolean operands, got ${left.runtimeType} and ${right.runtimeType}.',
          phase: 'Interpreter',
        ));
        return null;
      }
      return node.operator == '&&' ? (left && right) : (left || right);
    }

    if (node.operator == '==' || node.operator == '!=') {
      return node.operator == '==' ? (left == right) : (left != right);
    }

    if (left is! num || right is! num) {
      errors.add(CompilerError.error(
        message: 'Cannot apply operator ${node.operator} to non-numeric types (${left.runtimeType}, ${right.runtimeType}).',
        phase: 'Interpreter',
      ));
      return null;
    }

    if (node.operator == '%') {
      if (right == 0) {
        errors.add(CompilerError.error(
            message: 'Modulo by zero.',
            phase: 'Interpreter'
        ));
        return null;
      }
      return left % right;
    }

    switch (node.operator) {
      case '+': return left + right;
      case '-': return left - right;
      case '*': return left * right;
      case '/':
        if (right == 0) {
          errors.add(CompilerError.error(
              message: 'Division by zero.',
              phase: 'Interpreter'
          ));
          return null;
        }
        return left / right;
      case '>': return left > right;
      case '<': return left < right;
      case '>=': return left >= right;
      case '<=': return left <= right;
      default:
        errors.add(CompilerError.error(
            message: 'Unsupported operator: ${node.operator}',
            phase: 'Interpreter'
        ));
        return null;
    }
  }

  @override
  dynamic visitUnaryExpression(UnaryExpression node) {
    final operand = node.operand.accept(this);

    if (operand == null) {
      errors.add(CompilerError.error(
          message: 'Cannot apply unary operator to null.',
          phase: 'Interpreter'
      ));
      return null;
    }

    switch (node.operator) {
      case '-':
        if (operand is! num) {
          errors.add(CompilerError.error(
              message: 'Unary minus requires a numeric operand, got ${operand.runtimeType}.',
              phase: 'Interpreter'
          ));
          return null;
        }
        return -operand;
      case '!':
        if (operand is! bool) {
          errors.add(CompilerError.error(
              message: 'Unary NOT requires a boolean operand, got ${operand.runtimeType}.',
              phase: 'Interpreter'
          ));
          return null;
        }
        return !operand;
      default:
        errors.add(CompilerError.error(
            message: 'Unsupported unary operator: ${node.operator}',
            phase: 'Interpreter'
        ));
        return null;
    }
  }

  @override
  dynamic visitIdentifier(Identifier node) {
    if (!_hasVariable(node.name)) {
      errors.add(CompilerError.error(
        message: 'Undefined variable: ${node.name}',
        phase: 'Interpreter',
      ));
      return null;
    }
    return _getVariable(node.name);
  }

  @override
  dynamic visitNumberLiteral(NumberLiteral node) {
    return node.value;
  }

  @override
  dynamic visitStringLiteral(StringLiteral node) {
    return node.value;
  }

  @override
  dynamic visitBooleanLiteral(BooleanLiteral node) {
    return node.value;
  }
}
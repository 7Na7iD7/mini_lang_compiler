import '../models/token_types.dart';
import '../models/ast_nodes.dart';

class InterpreterResult {
  final String output;
  final int executionTime;
  final List<String> executionLog;

  InterpreterResult({
    required this.output,
    required this.executionTime,
    required this.executionLog,
  });
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
  final List<String> _executionLog = []; // Changed to private
  int _executionTime = 0;
  dynamic _returnValue;
  bool _shouldReturn = false;
  bool _shouldBreak = false;
  bool _shouldContinue = false;
  bool _isInFunction = false;
  int _recursionDepth = 0;

  Interpreter(this.program);

  List<String> getExecutionLog() {
    return List.unmodifiable(_executionLog);
  }

  void _log(String message) {
    _executionLog.add(message);
  }

  InterpreterResult interpret() {
    final stopwatch = Stopwatch()..start();
    _log('=== Interpreter Started ===');

    try {
      _log('Phase 1: Registering functions');
      for (final statement in program.statements) {
        if (statement is FunctionDeclaration) {
          if (functionTable.containsKey(statement.name)) {
            _log('Warning: Function "${statement.name}" redefined');
            errors.add(CompilerError.warning(
              message: 'Function ${statement.name} is already defined. Overwriting previous definition.',
              phase: 'Interpreter',
            ));
          }
          functionTable[statement.name] = statement;
          _log('Registered function "${statement.name}" with ${statement.parameters.length} parameter(s)');
        }
      }

      _log('Phase 2: Executing global statements');
      for (final statement in program.statements) {
        if (statement is! FunctionDeclaration) {
          statement.accept(this);
          if (_shouldReturn) break;
        }
      }

      if (functionTable.containsKey('main')) {
        _log('Phase 3: Calling main() function');
        final mainFunc = functionTable['main']!;
        if (mainFunc.parameters.isEmpty) {
          visitFunctionCall(FunctionCall(name: 'main', arguments: []));
        } else {
          _log('Warning: main() requires parameters, skipping execution');
          errors.add(CompilerError.warning(
            message: 'Function main found but requires parameters. main() should be parameterless.',
            phase: 'Interpreter',
          ));
        }
      }
    } catch (e, stack) {
      _log('FATAL ERROR: ${e.toString()}');
      errors.add(CompilerError.error(
        message: 'Runtime Execution Error: ${e.toString()}',
        phase: 'Interpreter',
      ));
      print('Interpreter error stack trace: $stack');
    }

    stopwatch.stop();
    _executionTime = stopwatch.elapsedMilliseconds;
    _log('=== Interpreter Finished (${_executionTime}ms) ===');

    var outputStr = _output.toString();
    if (outputStr.length > InterpreterConfig.maxOutputLength) {
      outputStr = outputStr.substring(0, InterpreterConfig.maxOutputLength) +
          '\n... (output truncated)';
    }

    return InterpreterResult(
      output: outputStr,
      executionTime: _executionTime,
      executionLog: _executionLog,
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

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    if (value is List) return '[${value.join(', ')}]';
    return value.toString();
  }

  @override
  dynamic visitProgram(Program node) {
    _log('Visiting Program with ${node.statements.length} statement(s)');
    for (final statement in node.statements) {
      statement.accept(this);
      if (_shouldReturn) break;
    }
    return null;
  }

  @override
  dynamic visitVariableDeclaration(VariableDeclaration node) {
    final value = node.initialValue?.accept(this) ?? _getDefaultValue(node.type);
    final scope = _isInFunction ? 'local' : 'global';

    if (_isInFunction) {
      localSymbolTable[node.name] = value;
    } else {
      globalSymbolTable[node.name] = value;
    }

    _log('Declare variable "$node.name" of type ${node.type} = ${_formatValue(value)} [$scope]');
    return null;
  }

  @override
  dynamic visitAssignment(Assignment node) {
    if (!_hasVariable(node.name)) {
      _log('ERROR: Variable "${node.name}" not declared');
      errors.add(CompilerError.error(
        message: 'Variable ${node.name} not declared.',
        phase: 'Interpreter',
      ));
      return null;
    }

    final oldValue = _getVariable(node.name);
    final value = node.value.accept(this);
    _setVariable(node.name, value);

    _log('Assign "${node.name}" = ${_formatValue(value)} (was: ${_formatValue(oldValue)})');
    return value;
  }

  @override
  dynamic visitPrintStatement(PrintStatement node) {
    final value = node.expression.accept(this);

    if (_output.length > InterpreterConfig.maxOutputLength) {
      _log('ERROR: Output buffer limit exceeded');
      errors.add(CompilerError.error(
        message: 'Output buffer limit exceeded',
        phase: 'Interpreter',
      ));
      return null;
    }

    if (value == null) {
      _output.writeln('null');
      _log('Print: null');
    } else {
      final displayValue = value.toString().replaceAll(r'\n', '\n');
      _output.writeln(displayValue);
      _log('Print: ${_formatValue(value)}');
    }
    return null;
  }

  @override
  dynamic visitIfStatement(IfStatement node) {
    final condition = node.condition.accept(this);
    _log('If condition evaluated to: $condition');

    if (condition == true) {
      _log('Executing THEN branch');
      node.thenBranch.accept(this);
    } else if (node.elseBranch != null) {
      _log('Executing ELSE branch');
      node.elseBranch!.accept(this);
    } else {
      _log('Condition false, no ELSE branch');
    }
    return null;
  }

  @override
  dynamic visitWhileStatement(WhileStatement node) {
    int iterations = 0;
    _log('While loop started');

    while (iterations < InterpreterConfig.maxIterations && errors.isEmpty) {
      final condition = node.condition.accept(this);
      if (condition != true) {
        _log('While loop ended after $iterations iteration(s)');
        break;
      }

      _log('While iteration ${iterations + 1}');
      node.body.accept(this);
      iterations++;

      if (_shouldBreak) {
        _log('Break statement executed in while loop');
        _shouldBreak = false;
        break;
      }
      if (_shouldContinue) {
        _log('Continue statement executed in while loop');
        _shouldContinue = false;
        continue;
      }
      if (_shouldReturn) break;
    }

    if (iterations >= InterpreterConfig.maxIterations) {
      _log('ERROR: Infinite loop detected in While statement');
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
    _log('Do-While loop started');

    do {
      if (iterations >= InterpreterConfig.maxIterations) {
        _log('ERROR: Infinite loop detected in Do-While statement');
        errors.add(CompilerError.error(
          message: 'Possible infinite loop detected in Do-While statement (exceeded ${InterpreterConfig.maxIterations} iterations).',
          phase: 'Interpreter',
        ));
        break;
      }

      _log('Do-While iteration ${iterations + 1}');
      node.body.accept(this);
      iterations++;

      if (_shouldBreak) {
        _log('Break statement executed in do-while loop');
        _shouldBreak = false;
        break;
      }

      if (_shouldReturn) break;

      if (_shouldContinue) {
        _log('Continue statement executed in do-while loop');
        _shouldContinue = false;
      }

      final condition = node.condition.accept(this);
      if (condition != true) {
        _log('Do-While loop ended after $iterations iteration(s)');
        break;
      }

      if (errors.isNotEmpty) break;

    } while (true);

    return null;
  }

  @override
  dynamic visitForStatement(ForStatement node) {
    final savedLocalSymbols = Map<String, dynamic>.from(localSymbolTable);
    _log('For loop started');

    node.initializer?.accept(this);
    int currentIteration = 0;

    while (currentIteration < InterpreterConfig.maxIterations && errors.isEmpty) {
      final condition = node.condition?.accept(this) ?? true;
      if (condition != true) {
        _log('For loop ended after $currentIteration iteration(s)');
        break;
      }

      _log('For iteration ${currentIteration + 1}');
      node.body.accept(this);

      if (_shouldBreak) {
        _log('Break statement executed in for loop');
        _shouldBreak = false;
        break;
      }
      if (_shouldContinue) {
        _log('Continue statement executed in for loop');
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
      _log('ERROR: Infinite loop detected in For statement');
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
    _log('Switch on value: ${_formatValue(switchValue)}');
    bool matched = false;

    for (final caseNode in node.cases) {
      final caseValue = caseNode.value.accept(this);
      if (switchValue == caseValue) {
        _log('Switch case matched: ${_formatValue(caseValue)}');
        matched = true;
        caseNode.body.accept(this);

        if (_shouldBreak) {
          _log('Break from switch');
          _shouldBreak = false;
          break;
        }
        if (_shouldReturn) break;
      }
    }

    if (!matched && node.defaultCase != null) {
      _log('Switch default case executed');
      node.defaultCase!.accept(this);
      if (_shouldBreak) {
        _shouldBreak = false;
      }
    } else if (!matched) {
      _log('No switch case matched');
    }

    return null;
  }

  @override
  dynamic visitSwitchCase(SwitchCase node) {
    return node.body.accept(this);
  }

  @override
  dynamic visitBreakStatement(BreakStatement node) {
    _log('Break statement');
    _shouldBreak = true;
    return null;
  }

  @override
  dynamic visitContinueStatement(ContinueStatement node) {
    _log('Continue statement');
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
      _log('Calling lambda function with ${node.arguments.length} argument(s)');
      return _executeLambda(variable, node.arguments);
    }

    if (!functionTable.containsKey(node.name)) {
      _log('ERROR: Function "${node.name}" not defined');
      errors.add(CompilerError.error(
        message: 'Function ${node.name} not defined.',
        phase: 'Interpreter',
      ));
      return null;
    }

    final funcDecl = functionTable[node.name]!;
    if (node.arguments.length != funcDecl.parameters.length) {
      _log('ERROR: Function "${node.name}" argument count mismatch');
      errors.add(CompilerError.error(
        message: 'Function ${node.name} expects ${funcDecl.parameters.length} arguments but received ${node.arguments.length}.',
        phase: 'Interpreter',
      ));
      return null;
    }

    _recursionDepth++;
    _log('Call function "${node.name}" (depth: $_recursionDepth)');

    if (_recursionDepth > InterpreterConfig.maxRecursionDepth) {
      _recursionDepth--;
      _log('ERROR: Maximum recursion depth exceeded');
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
        _log('  Parameter "${funcDecl.parameters[i].value}" = ${_formatValue(evaluatedArgs[i])}');
      }

      funcDecl.body.accept(this);

      if (_shouldReturn) {
        result = _returnValue;
        _log('Function "${node.name}" returned: ${_formatValue(result)}');
        _shouldReturn = false;
        _returnValue = null;
      } else {
        _log('Function "${node.name}" finished without explicit return');
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
      _log('ERROR: Lambda argument count mismatch');
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
        _log('  Lambda parameter "${lambda.parameters[i].value}" = ${_formatValue(evaluatedArgs[i])}');
      }

      result = lambda.body.accept(this);
      _log('Lambda returned: ${_formatValue(result)}');

    } finally {
      localSymbolTable = savedLocalSymbols;
      _isInFunction = wasInFunction;
    }

    return result;
  }

  @override
  dynamic visitLambdaFunction(LambdaFunction node) {
    _log('Lambda function created with ${node.parameters.length} parameter(s)');
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
      _log('ERROR: Array size must be positive');
      errors.add(CompilerError.error(
        message: 'Array size must be positive, got ${node.size}.',
        phase: 'Interpreter',
      ));
      return null;
    }

    const maxArraySize = 10000;
    if (node.size > maxArraySize) {
      _log('ERROR: Array size exceeds maximum');
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

    _log('Declare array "${node.name}" of type ${node.type}[${node.size}]');
    return null;
  }

  @override
  dynamic visitArrayAccess(ArrayAccess node) {
    final array = _getVariable(node.name);

    if (array == null) {
      _log('ERROR: Array "${node.name}" not declared');
      errors.add(CompilerError.error(
          message: 'Array ${node.name} not declared.',
          phase: 'Interpreter'
      ));
      return null;
    }

    if (array is! List) {
      _log('ERROR: "${node.name}" is not an array');
      errors.add(CompilerError.error(
          message: '${node.name} is not an array.',
          phase: 'Interpreter'
      ));
      return null;
    }

    final index = node.index.accept(this);
    if (index == null) {
      _log('ERROR: Array index cannot be null');
      errors.add(CompilerError.error(
          message: 'Array index cannot be null.',
          phase: 'Interpreter'
      ));
      return null;
    }

    if (index is! num) {
      _log('ERROR: Array index must be numeric');
      errors.add(CompilerError.error(
          message: 'Array index must be a number, got ${index.runtimeType}.',
          phase: 'Interpreter'
      ));
      return null;
    }

    final idx = index.toInt();
    if (idx < 0 || idx >= array.length) {
      _log('ERROR: Array index $idx out of bounds');
      errors.add(CompilerError.error(
          message: 'Array index $idx is out of bounds for array ${node.name} with size ${array.length}.',
          phase: 'Interpreter'
      ));
      return null;
    }

    final value = array[idx];
    _log('Array access "${node.name}[$idx]" = ${_formatValue(value)}');
    return value;
  }

  @override
  dynamic visitArrayAssignment(ArrayAssignment node) {
    final array = _getVariable(node.name);

    if (array == null) {
      _log('ERROR: Array "${node.name}" not declared');
      errors.add(CompilerError.error(
          message: 'Array ${node.name} not declared.',
          phase: 'Interpreter'
      ));
      return null;
    }

    if (array is! List) {
      _log('ERROR: "${node.name}" is not an array');
      errors.add(CompilerError.error(
          message: '${node.name} is not an array.',
          phase: 'Interpreter'
      ));
      return null;
    }

    final index = node.index.accept(this);
    if (index == null) {
      _log('ERROR: Array index cannot be null');
      errors.add(CompilerError.error(
          message: 'Array index cannot be null.',
          phase: 'Interpreter'
      ));
      return null;
    }

    if (index is! num) {
      _log('ERROR: Array index must be numeric');
      errors.add(CompilerError.error(
          message: 'Array index must be a number, got ${index.runtimeType}.',
          phase: 'Interpreter'
      ));
      return null;
    }

    final idx = index.toInt();
    if (idx < 0 || idx >= array.length) {
      _log('ERROR: Array index $idx out of bounds');
      errors.add(CompilerError.error(
          message: 'Array index $idx is out of bounds for array ${node.name} with size ${array.length}.',
          phase: 'Interpreter'
      ));
      return null;
    }

    final value = node.value.accept(this);
    array[idx] = value;
    _log('Array assign "${node.name}[$idx]" = ${_formatValue(value)}');
    return value;
  }

  @override
  dynamic visitReturnStatement(ReturnStatement node) {
    _returnValue = node.value?.accept(this);
    _log('Return statement: ${_formatValue(_returnValue)}');
    _shouldReturn = true;
    return null;
  }

  @override
  dynamic visitBlock(Block node) {
    _log('Block with ${node.statements.length} statement(s)');
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
      _log('ERROR: Binary operation on null values');
      errors.add(CompilerError.error(
        message: 'Cannot perform binary operation on null values.',
        phase: 'Interpreter',
      ));
      return null;
    }

    if (node.operator == '+' && (left is String || right is String)) {
      final result = left.toString() + right.toString();
      _log('Binary: ${_formatValue(left)} + ${_formatValue(right)} = ${_formatValue(result)}');
      return result;
    }

    if (node.operator == '&&' || node.operator == '||') {
      if (left is! bool || right is! bool) {
        _log('ERROR: Logical operator requires boolean operands');
        errors.add(CompilerError.error(
          message: 'Logical operators (${node.operator}) require boolean operands, got ${left.runtimeType} and ${right.runtimeType}.',
          phase: 'Interpreter',
        ));
        return null;
      }
      final result = node.operator == '&&' ? (left && right) : (left || right);
      _log('Binary: $left ${node.operator} $right = $result');
      return result;
    }

    if (node.operator == '==' || node.operator == '!=') {
      final result = node.operator == '==' ? (left == right) : (left != right);
      _log('Binary: ${_formatValue(left)} ${node.operator} ${_formatValue(right)} = $result');
      return result;
    }

    if (left is! num || right is! num) {
      _log('ERROR: Operator ${node.operator} requires numeric operands');
      errors.add(CompilerError.error(
        message: 'Cannot apply operator ${node.operator} to non-numeric types (${left.runtimeType}, ${right.runtimeType}).',
        phase: 'Interpreter',
      ));
      return null;
    }

    if (node.operator == '%') {
      if (right == 0) {
        _log('ERROR: Modulo by zero');
        errors.add(CompilerError.error(
            message: 'Modulo by zero.',
            phase: 'Interpreter'
        ));
        return null;
      }
      final result = left % right;
      _log('Binary: $left % $right = $result');
      return result;
    }

    dynamic result;
    switch (node.operator) {
      case '+': result = left + right; break;
      case '-': result = left - right; break;
      case '*': result = left * right; break;
      case '/':
        if (right == 0) {
          _log('ERROR: Division by zero');
          errors.add(CompilerError.error(
              message: 'Division by zero.',
              phase: 'Interpreter'
          ));
          return null;
        }
        result = left / right;
        break;
      case '>': result = left > right; break;
      case '<': result = left < right; break;
      case '>=': result = left >= right; break;
      case '<=': result = left <= right; break;
      default:
        _log('ERROR: Unsupported operator ${node.operator}');
        errors.add(CompilerError.error(
            message: 'Unsupported operator: ${node.operator}',
            phase: 'Interpreter'
        ));
        return null;
    }

    _log('Binary: $left ${node.operator} $right = ${_formatValue(result)}');
    return result;
  }

  @override
  dynamic visitUnaryExpression(UnaryExpression node) {
    final operand = node.operand.accept(this);

    if (operand == null) {
      _log('ERROR: Unary operator on null value');
      errors.add(CompilerError.error(
          message: 'Cannot apply unary operator to null.',
          phase: 'Interpreter'
      ));
      return null;
    }

    switch (node.operator) {
      case '-':
        if (operand is! num) {
          _log('ERROR: Unary minus requires numeric operand');
          errors.add(CompilerError.error(
              message: 'Unary minus requires a numeric operand, got ${operand.runtimeType}.',
              phase: 'Interpreter'
          ));
          return null;
        }
        final result = -operand;
        _log('Unary: -$operand = $result');
        return result;
      case '!':
        if (operand is! bool) {
          _log('ERROR: Unary NOT requires boolean operand');
          errors.add(CompilerError.error(
              message: 'Unary NOT requires a boolean operand, got ${operand.runtimeType}.',
              phase: 'Interpreter'
          ));
          return null;
        }
        final result = !operand;
        _log('Unary: !$operand = $result');
        return result;
      default:
        _log('ERROR: Unsupported unary operator ${node.operator}');
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
      _log('ERROR: Undefined variable "${node.name}"');
      errors.add(CompilerError.error(
        message: 'Undefined variable: ${node.name}',
        phase: 'Interpreter',
      ));
      return null;
    }
    final value = _getVariable(node.name);
    _log('Access variable "${node.name}" = ${_formatValue(value)}');
    return value;
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
import '../models/ast_nodes.dart';
import '../models/token_types.dart';

/// Optimization result
class OptimizationResult {
  final Program optimizedProgram;
  final List<String> optimizations;
  final Map<String, int> statistics;
  final List<CompilerError> warnings;

  OptimizationResult({
    required this.optimizedProgram,
    required this.optimizations,
    required this.statistics,
    required this.warnings,
  });
}

/// Optimization settings
class OptimizerConfig {
  final bool constantFolding;
  final bool constantPropagation;
  final bool deadCodeElimination;
  final bool algebraicSimplification;
  final bool loopInvariantCodeMotion;
  final bool strengthReduction;
  final bool inlineSimpleFunctions;

  const OptimizerConfig({
    this.constantFolding = true,
    this.constantPropagation = true,
    this.deadCodeElimination = true,
    this.algebraicSimplification = true,
    this.loopInvariantCodeMotion = false,
    this.strengthReduction = true,
    this.inlineSimpleFunctions = false,
  });

  static const OptimizerConfig conservative = OptimizerConfig(
    constantFolding: true,
    constantPropagation: false,
    deadCodeElimination: false,
    algebraicSimplification: true,
    loopInvariantCodeMotion: false,
    strengthReduction: false,
    inlineSimpleFunctions: false,
  );

  static const OptimizerConfig aggressive = OptimizerConfig(
    constantFolding: true,
    constantPropagation: true,
    deadCodeElimination: true,
    algebraicSimplification: true,
    loopInvariantCodeMotion: true,
    strengthReduction: true,
    inlineSimpleFunctions: true,
  );
}

/// Main optimizer class
class Optimizer {
  final OptimizerConfig config;
  final List<String> _optimizations = [];
  final List<CompilerError> _warnings = [];
  final Map<String, dynamic> _constants = {};
  int _passCount = 0;

  // Optimization statistics
  int _constantsFolded = 0;
  int _deadCodeRemoved = 0;
  int _expressionsSimplified = 0;
  int _propagations = 0;

  Optimizer({this.config = const OptimizerConfig()});

  /// Optimize program with multiple passes
  OptimizationResult optimize(Program program) {
    _optimizations.clear();
    _warnings.clear();
    _constants.clear();
    _constantsFolded = 0;
    _deadCodeRemoved = 0;
    _expressionsSimplified = 0;
    _propagations = 0;
    _passCount = 0;

    _log('=== Starting optimization phase ===');

    Program currentProgram = program;

    for (int i = 0; i < 3; i++) {
      _passCount = i + 1;
      _log('Pass $_passCount started');

      final optimizer = _ProgramOptimizer(this);
      final optimized = optimizer.visitProgram(currentProgram) as Program;

      if (_areEqual(currentProgram, optimized)) {
        _log('Pass $_passCount: No changes made, stopping');
        break;
      }

      currentProgram = optimized;
    }

    _log('=== Optimization phase completed ===');
    _log('Number of constants folded: $_constantsFolded');
    _log('Number of dead code removed: $_deadCodeRemoved');
    _log('Number of expressions simplified: $_expressionsSimplified');
    _log('Number of propagations: $_propagations');

    return OptimizationResult(
      optimizedProgram: currentProgram,
      optimizations: List.unmodifiable(_optimizations),
      statistics: {
        'passes': _passCount,
        'constantsFolded': _constantsFolded,
        'deadCodeRemoved': _deadCodeRemoved,
        'expressionsSimplified': _expressionsSimplified,
        'propagations': _propagations,
      },
      warnings: List.unmodifiable(_warnings),
    );
  }

  void _log(String message) {
    _optimizations.add(message);
  }

  void _warning(String message) {
    _warnings.add(CompilerError.warning(
      message: message,
      phase: 'Optimizer',
    ));
  }

  bool _areEqual(Program p1, Program p2) {
    // Simple comparison to detect changes
    return p1.toString() == p2.toString();
  }
}

/// Visitor for AST optimization
class _ProgramOptimizer implements ASTVisitor<ASTNode> {
  final Optimizer optimizer;
  final Map<String, dynamic> _localConstants = {};
  bool _inFunction = false;

  _ProgramOptimizer(this.optimizer);

  OptimizerConfig get config => optimizer.config;

  @override
  ASTNode visitProgram(Program node) {
    final optimizedStatements = <ASTNode>[];

    for (final stmt in node.statements) {
      final optimized = stmt.accept(this);

      // Dead Code Elimination
      if (config.deadCodeElimination && _isDeadCode(optimized)) {
        optimizer._deadCodeRemoved++;
        optimizer._log('Dead code removed: ${stmt.runtimeType}');
        continue;
      }

      optimizedStatements.add(optimized);
    }

    return Program(optimizedStatements);
  }

  @override
  ASTNode visitVariableDeclaration(VariableDeclaration node) {
    ASTNode? optimizedInitialValue;

    if (node.initialValue != null) {
      optimizedInitialValue = node.initialValue!.accept(this);

      // Constant Propagation
      if (config.constantPropagation && optimizedInitialValue is NumberLiteral) {
        optimizer._constants[node.name] = optimizedInitialValue.value;
        _localConstants[node.name] = optimizedInitialValue.value;
        optimizer._propagations++;
        optimizer._log('Constant "${node.name}" = ${optimizedInitialValue.value} recorded');
      } else if (config.constantPropagation && optimizedInitialValue is StringLiteral) {
        optimizer._constants[node.name] = optimizedInitialValue.value;
        _localConstants[node.name] = optimizedInitialValue.value;
        optimizer._propagations++;
      } else if (config.constantPropagation && optimizedInitialValue is BooleanLiteral) {
        optimizer._constants[node.name] = optimizedInitialValue.value;
        _localConstants[node.name] = optimizedInitialValue.value;
        optimizer._propagations++;
      }
    }

    return VariableDeclaration(
      type: node.type,
      name: node.name,
      initialValue: optimizedInitialValue,
    );
  }

  @override
  ASTNode visitAssignment(Assignment node) {
    final optimizedValue = node.value.accept(this);

    // Constant Propagation
    if (config.constantPropagation) {
      if (optimizedValue is NumberLiteral) {
        optimizer._constants[node.name] = optimizedValue.value;
        _localConstants[node.name] = optimizedValue.value;
      } else if (optimizedValue is StringLiteral) {
        optimizer._constants[node.name] = optimizedValue.value;
        _localConstants[node.name] = optimizedValue.value;
      } else if (optimizedValue is BooleanLiteral) {
        optimizer._constants[node.name] = optimizedValue.value;
        _localConstants[node.name] = optimizedValue.value;
      } else {
        // Variable is no longer constant
        optimizer._constants.remove(node.name);
        _localConstants.remove(node.name);
      }
    }

    return Assignment(name: node.name, value: optimizedValue);
  }

  @override
  ASTNode visitPrintStatement(PrintStatement node) {
    return PrintStatement(node.expression.accept(this));
  }

  @override
  ASTNode visitIfStatement(IfStatement node) {
    final optimizedCondition = node.condition.accept(this);

    // Constant Folding in if condition
    if (config.constantFolding && optimizedCondition is BooleanLiteral) {
      optimizer._constantsFolded++;
      if (optimizedCondition.value == true) {
        optimizer._log('If condition is always true, keeping only then branch');
        return node.thenBranch.accept(this);
      } else {
        optimizer._log('If condition is always false');
        if (node.elseBranch != null) {
          optimizer._log('Keeping only else branch');
          return node.elseBranch!.accept(this);
        } else {
          optimizer._log('Entire if removed (dead code)');
          return Block([]); // Dead code
        }
      }
    }

    final optimizedThen = node.thenBranch.accept(this);
    final optimizedElse = node.elseBranch?.accept(this);

    return IfStatement(
      condition: optimizedCondition,
      thenBranch: optimizedThen,
      elseBranch: optimizedElse,
    );
  }

  @override
  ASTNode visitWhileStatement(WhileStatement node) {
    final optimizedCondition = node.condition.accept(this);

    // Check for infinite loop or dead code
    if (config.constantFolding && optimizedCondition is BooleanLiteral) {
      if (optimizedCondition.value == false) {
        optimizer._log('While loop never executes (dead code)');
        optimizer._constantsFolded++;
        return Block([]); // Remove loop
      } else {
        optimizer._warning('Potential infinite loop in while (condition is always true)');
      }
    }

    final optimizedBody = node.body.accept(this);

    return WhileStatement(
      condition: optimizedCondition,
      body: optimizedBody,
    );
  }

  @override
  ASTNode visitDoWhileStatement(DoWhileStatement node) {
    final optimizedBody = node.body.accept(this);
    final optimizedCondition = node.condition.accept(this);

    if (config.constantFolding && optimizedCondition is BooleanLiteral) {
      if (optimizedCondition.value == false) {
        optimizer._log('do-while executes only once, converted to simple block');
        optimizer._constantsFolded++;
        return optimizedBody;
      } else {
        optimizer._warning('Potential infinite loop in do-while (condition is always true)');
      }
    }

    return DoWhileStatement(
      body: optimizedBody,
      condition: optimizedCondition,
    );
  }

  @override
  ASTNode visitForStatement(ForStatement node) {
    final optimizedInit = node.initializer?.accept(this);
    final optimizedCondition = node.condition?.accept(this);
    final optimizedIncrement = node.increment?.accept(this);
    final optimizedBody = node.body.accept(this);

    if (config.constantFolding && optimizedCondition is BooleanLiteral) {
      if (optimizedCondition.value == false) {
        optimizer._log('For loop never executes');
        optimizer._constantsFolded++;
        // Keep only initializer (if it exists)
        if (optimizedInit != null) {
          return Block([optimizedInit]);
        }
        return Block([]);
      }
    }

    return ForStatement(
      initializer: optimizedInit,
      condition: optimizedCondition,
      increment: optimizedIncrement,
      body: optimizedBody,
    );
  }

  @override
  ASTNode visitSwitchStatement(SwitchStatement node) {
    final optimizedExpr = node.expression.accept(this);

    // If expression is constant, keep only matching case
    if (config.constantFolding) {
      dynamic constValue;
      if (optimizedExpr is NumberLiteral) {
        constValue = optimizedExpr.value;
      } else if (optimizedExpr is StringLiteral) {
        constValue = optimizedExpr.value;
      } else if (optimizedExpr is BooleanLiteral) {
        constValue = optimizedExpr.value;
      }

      if (constValue != null) {
        optimizer._log('Switch with constant value $constValue');
        optimizer._constantsFolded++;

        for (final caseNode in node.cases) {
          final caseValue = caseNode.value;
          dynamic caseLiteral;

          if (caseValue is NumberLiteral) {
            caseLiteral = caseValue.value;
          } else if (caseValue is StringLiteral) {
            caseLiteral = caseValue.value;
          } else if (caseValue is BooleanLiteral) {
            caseLiteral = caseValue.value;
          }

          if (caseLiteral == constValue) {
            optimizer._log('Keeping only case ${caseLiteral}');
            return caseNode.body.accept(this);
          }
        }

        // No case matched
        if (node.defaultCase != null) {
          optimizer._log('Keeping only default case');
          return node.defaultCase!.accept(this);
        } else {
          optimizer._log('Switch converted to dead code');
          return Block([]);
        }
      }
    }

    final optimizedCases = node.cases
        .map((c) => SwitchCase(
      value: c.value.accept(this),
      body: c.body.accept(this),
    ))
        .toList();

    final optimizedDefault = node.defaultCase?.accept(this);

    return SwitchStatement(
      expression: optimizedExpr,
      cases: optimizedCases,
      defaultCase: optimizedDefault,
    );
  }

  @override
  ASTNode visitSwitchCase(SwitchCase node) {
    return SwitchCase(
      value: node.value.accept(this),
      body: node.body.accept(this),
    );
  }

  @override
  ASTNode visitBreakStatement(BreakStatement node) => node;

  @override
  ASTNode visitContinueStatement(ContinueStatement node) => node;

  @override
  ASTNode visitFunctionDeclaration(FunctionDeclaration node) {
    final wasInFunction = _inFunction;
    _inFunction = true;

    final savedConstants = Map<String, dynamic>.from(_localConstants);
    _localConstants.clear();

    final optimizedBody = node.body.accept(this) as Block;

    _localConstants.clear();
    _localConstants.addAll(savedConstants);
    _inFunction = wasInFunction;

    return FunctionDeclaration(
      returnType: node.returnType,
      name: node.name,
      parameters: node.parameters,
      body: optimizedBody,
    );
  }

  @override
  ASTNode visitFunctionCall(FunctionCall node) {
    final optimizedArgs = node.arguments.map((arg) => arg.accept(this)).toList();

    return FunctionCall(
      name: node.name,
      arguments: optimizedArgs,
    );
  }

  @override
  ASTNode visitLambdaFunction(LambdaFunction node) {
    return LambdaFunction(
      parameters: node.parameters,
      body: node.body.accept(this),
    );
  }

  @override
  ASTNode visitLambdaCall(LambdaCall node) {
    final optimizedLambda = node.lambda.accept(this) as LambdaFunction;
    final optimizedArgs = node.arguments.map((arg) => arg.accept(this)).toList();

    return LambdaCall(
      lambda: optimizedLambda,
      arguments: optimizedArgs,
    );
  }

  @override
  ASTNode visitArrayDeclaration(ArrayDeclaration node) => node;

  @override
  ASTNode visitArrayAccess(ArrayAccess node) {
    return ArrayAccess(
      name: node.name,
      index: node.index.accept(this),
    );
  }

  @override
  ASTNode visitArrayAssignment(ArrayAssignment node) {
    return ArrayAssignment(
      name: node.name,
      index: node.index.accept(this),
      value: node.value.accept(this),
    );
  }

  @override
  ASTNode visitReturnStatement(ReturnStatement node) {
    return ReturnStatement(node.value?.accept(this));
  }

  @override
  ASTNode visitBlock(Block node) {
    final optimizedStatements = <ASTNode>[];

    for (final stmt in node.statements) {
      final optimized = stmt.accept(this);

      // Remove dead code in block
      if (config.deadCodeElimination && _isDeadCode(optimized)) {
        optimizer._deadCodeRemoved++;
        continue;
      }

      optimizedStatements.add(optimized);
    }

    return Block(optimizedStatements);
  }

  @override
  ASTNode visitBinaryExpression(BinaryExpression node) {
    final left = node.left.accept(this);
    final right = node.right.accept(this);

    // Constant Folding
    if (config.constantFolding && left is NumberLiteral && right is NumberLiteral) {
      final result = _foldConstantBinary(left.value, right.value, node.operator);
      if (result != null) {
        optimizer._constantsFolded++;
        optimizer._log('Fold: ${left.value} ${node.operator} ${right.value} = $result');
        if (result is bool) {
          return BooleanLiteral(result);
        } else {
          return NumberLiteral(result);
        }
      }
    }

    // String concatenation
    if (config.constantFolding && node.operator == '+') {
      if (left is StringLiteral && right is StringLiteral) {
        optimizer._constantsFolded++;
        optimizer._log('Fold string: "${left.value}" + "${right.value}"');
        return StringLiteral(left.value + right.value);
      }
    }

    // Boolean operations
    if (config.constantFolding && left is BooleanLiteral && right is BooleanLiteral) {
      if (node.operator == '&&') {
        optimizer._constantsFolded++;
        return BooleanLiteral(left.value && right.value);
      } else if (node.operator == '||') {
        optimizer._constantsFolded++;
        return BooleanLiteral(left.value || right.value);
      }
    }

    // Algebraic Simplification
    if (config.algebraicSimplification) {
      final simplified = _algebraicSimplify(left, right, node.operator);
      if (simplified != null) {
        optimizer._expressionsSimplified++;
        optimizer._log('Algebraic simplification: ${node.operator}');
        return simplified;
      }
    }

    // Strength Reduction
    if (config.strengthReduction) {
      final reduced = _strengthReduce(left, right, node.operator);
      if (reduced != null) {
        optimizer._expressionsSimplified++;
        optimizer._log('Strength reduction: ${node.operator}');
        return reduced;
      }
    }

    return BinaryExpression(left: left, operator: node.operator, right: right);
  }

  @override
  ASTNode visitUnaryExpression(UnaryExpression node) {
    final operand = node.operand.accept(this);

    // Constant Folding
    if (config.constantFolding) {
      if (node.operator == '-' && operand is NumberLiteral) {
        optimizer._constantsFolded++;
        optimizer._log('Fold unary: -${operand.value}');
        return NumberLiteral(-operand.value);
      } else if (node.operator == '!' && operand is BooleanLiteral) {
        optimizer._constantsFolded++;
        optimizer._log('Fold unary: !${operand.value}');
        return BooleanLiteral(!operand.value);
      }
    }

    // Double negation elimination: !!x => x
    if (config.algebraicSimplification &&
        node.operator == '!' &&
        operand is UnaryExpression &&
        operand.operator == '!') {
      optimizer._expressionsSimplified++;
      optimizer._log('Double negation removal: !!x => x');
      return operand.operand;
    }

    return UnaryExpression(operator: node.operator, operand: operand);
  }

  @override
  ASTNode visitIdentifier(Identifier node) {
    // Constant Propagation
    if (config.constantPropagation && _localConstants.containsKey(node.name)) {
      final value = _localConstants[node.name];
      optimizer._log('Propagate: ${node.name} => $value');

      if (value is num) {
        return NumberLiteral(value);
      } else if (value is String) {
        return StringLiteral(value);
      } else if (value is bool) {
        return BooleanLiteral(value);
      }
    }

    return node;
  }

  @override
  ASTNode visitNumberLiteral(NumberLiteral node) => node;

  @override
  ASTNode visitStringLiteral(StringLiteral node) => node;

  @override
  ASTNode visitBooleanLiteral(BooleanLiteral node) => node;

  // Helper functions

  bool _isDeadCode(ASTNode node) {
    // Empty block is dead code
    if (node is Block && node.statements.isEmpty) {
      return true;
    }
    return false;
  }

  dynamic _foldConstantBinary(num left, num right, String operator) {
    try {
      switch (operator) {
        case '+': return left + right;
        case '-': return left - right;
        case '*': return left * right;
        case '/': return right != 0 ? left / right : null;
        case '%': return right != 0 ? left % right : null;
        case '>': return left > right;
        case '<': return left < right;
        case '>=': return left >= right;
        case '<=': return left <= right;
        case '==': return left == right;
        case '!=': return left != right;
        default: return null;
      }
    } catch (e) {
      return null;
    }
  }

  ASTNode? _algebraicSimplify(ASTNode left, ASTNode right, String operator) {
    // x + 0 => x
    if (operator == '+' && right is NumberLiteral && right.value == 0) {
      return left;
    }
    // 0 + x => x
    if (operator == '+' && left is NumberLiteral && left.value == 0) {
      return right;
    }

    // x - 0 => x
    if (operator == '-' && right is NumberLiteral && right.value == 0) {
      return left;
    }

    // x * 1 => x
    if (operator == '*' && right is NumberLiteral && right.value == 1) {
      return left;
    }
    // 1 * x => x
    if (operator == '*' && left is NumberLiteral && left.value == 1) {
      return right;
    }

    // x * 0 => 0
    if (operator == '*' && right is NumberLiteral && right.value == 0) {
      return NumberLiteral(0);
    }
    // 0 * x => 0
    if (operator == '*' && left is NumberLiteral && left.value == 0) {
      return NumberLiteral(0);
    }

    // x / 1 => x
    if (operator == '/' && right is NumberLiteral && right.value == 1) {
      return left;
    }

    // x && true => x
    if (operator == '&&' && right is BooleanLiteral && right.value == true) {
      return left;
    }
    // true && x => x
    if (operator == '&&' && left is BooleanLiteral && left.value == true) {
      return right;
    }

    // x && false => false
    if (operator == '&&' && right is BooleanLiteral && right.value == false) {
      return BooleanLiteral(false);
    }
    // false && x => false
    if (operator == '&&' && left is BooleanLiteral && left.value == false) {
      return BooleanLiteral(false);
    }

    // x || false => x
    if (operator == '||' && right is BooleanLiteral && right.value == false) {
      return left;
    }
    // false || x => x
    if (operator == '||' && left is BooleanLiteral && left.value == false) {
      return right;
    }

    // x || true => true
    if (operator == '||' && right is BooleanLiteral && right.value == true) {
      return BooleanLiteral(true);
    }
    // true || x => true
    if (operator == '||' && left is BooleanLiteral && left.value == true) {
      return BooleanLiteral(true);
    }

    return null;
  }

  ASTNode? _strengthReduce(ASTNode left, ASTNode right, String operator) {
    // x * 2 => x + x
    if (operator == '*' && right is NumberLiteral) {
      if (right.value == 2) {
        return BinaryExpression(left: left, operator: '+', right: left);
      }
    }

    return null;
  }
}
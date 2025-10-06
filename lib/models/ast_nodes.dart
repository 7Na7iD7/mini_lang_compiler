enum MessageType { error, warning, info }

class CompilerError {
  final String message;
  final int? line;
  final int? column;
  final String phase;
  final MessageType type;

  CompilerError({
    required this.message,
    this.line,
    this.column,
    required this.phase,
    this.type = MessageType.error,
  });

  factory CompilerError.error({
    required String message,
    int? line,
    int? column,
    required String phase,
  }) => CompilerError(
    message: message,
    line: line,
    column: column,
    phase: phase,
    type: MessageType.error,
  );

  factory CompilerError.warning({
    required String message,
    int? line,
    int? column,
    required String phase,
  }) => CompilerError(
    message: message,
    line: line,
    column: column,
    phase: phase,
    type: MessageType.warning,
  );

  @override
  String toString() {
    final typeStr = type.name.toUpperCase();
    if (line != null && column != null) {
      return '[$typeStr] $phase at line $line, column $column: $message';
    }
    return '[$typeStr] $phase: $message';
  }
}

abstract class ASTNode {
  T accept<T>(ASTVisitor<T> visitor);
  Map<String, dynamic> toJson();

  static ASTNode fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) {
      throw ArgumentError('AST node type is missing in JSON');
    }

    switch (type) {
      case 'Program':
        return Program.fromJson(json);
      case 'VariableDeclaration':
        return VariableDeclaration.fromJson(json);
      case 'Assignment':
        return Assignment.fromJson(json);
      case 'PrintStatement':
        return PrintStatement.fromJson(json);
      case 'IfStatement':
        return IfStatement.fromJson(json);
      case 'WhileStatement':
        return WhileStatement.fromJson(json);
      case 'DoWhileStatement':
        return DoWhileStatement.fromJson(json);
      case 'ForStatement':
        return ForStatement.fromJson(json);
      case 'SwitchStatement':
        return SwitchStatement.fromJson(json);
      case 'SwitchCase':
        return SwitchCase.fromJson(json);
      case 'BreakStatement':
        return BreakStatement.fromJson(json);
      case 'ContinueStatement':
        return ContinueStatement.fromJson(json);
      case 'FunctionDeclaration':
        return FunctionDeclaration.fromJson(json);
      case 'FunctionCall':
        return FunctionCall.fromJson(json);
      case 'LambdaFunction':
        return LambdaFunction.fromJson(json);
      case 'LambdaCall':
        return LambdaCall.fromJson(json);
      case 'ArrayDeclaration':
        return ArrayDeclaration.fromJson(json);
      case 'ArrayAccess':
        return ArrayAccess.fromJson(json);
      case 'ArrayAssignment':
        return ArrayAssignment.fromJson(json);
      case 'ReturnStatement':
        return ReturnStatement.fromJson(json);
      case 'Block':
        return Block.fromJson(json);
      case 'BinaryExpression':
        return BinaryExpression.fromJson(json);
      case 'UnaryExpression':
        return UnaryExpression.fromJson(json);
      case 'Identifier':
        return Identifier.fromJson(json);
      case 'NumberLiteral':
        return NumberLiteral.fromJson(json);
      case 'StringLiteral':
        return StringLiteral.fromJson(json);
      case 'BooleanLiteral':
        return BooleanLiteral.fromJson(json);
      default:
        throw ArgumentError('Unknown AST node type: $type');
    }
  }
}

// Visitor interface for tree traversal
abstract class ASTVisitor<T> {
  T visitProgram(Program node);
  T visitVariableDeclaration(VariableDeclaration node);
  T visitAssignment(Assignment node);
  T visitPrintStatement(PrintStatement node);
  T visitIfStatement(IfStatement node);
  T visitWhileStatement(WhileStatement node);
  T visitDoWhileStatement(DoWhileStatement node);
  T visitForStatement(ForStatement node);
  T visitSwitchStatement(SwitchStatement node);
  T visitSwitchCase(SwitchCase node);
  T visitBreakStatement(BreakStatement node);
  T visitContinueStatement(ContinueStatement node);
  T visitFunctionDeclaration(FunctionDeclaration node);
  T visitFunctionCall(FunctionCall node);
  T visitLambdaFunction(LambdaFunction node);
  T visitLambdaCall(LambdaCall node);
  T visitArrayDeclaration(ArrayDeclaration node);
  T visitArrayAccess(ArrayAccess node);
  T visitArrayAssignment(ArrayAssignment node);
  T visitReturnStatement(ReturnStatement node);
  T visitBlock(Block node);
  T visitBinaryExpression(BinaryExpression node);
  T visitUnaryExpression(UnaryExpression node);
  T visitIdentifier(Identifier node);
  T visitNumberLiteral(NumberLiteral node);
  T visitStringLiteral(StringLiteral node);
  T visitBooleanLiteral(BooleanLiteral node);
}

class Program extends ASTNode {
  final List<ASTNode> statements;

  Program(this.statements);

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitProgram(this);

  @override
  String toString() => 'Program(${statements.join(', ')})';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Program',
      'statements': statements.map((s) => s.toJson()).toList(),
    };
  }

  static Program fromJson(Map<String, dynamic> json) {
    final statementsList = json['statements'];
    if (statementsList == null || statementsList is! List) {
      throw ArgumentError('Program statements must be a list');
    }

    final statements = statementsList
        .map((s) {
      if (s is! Map<String, dynamic>) {
        throw ArgumentError('Statement must be a JSON object');
      }
      return ASTNode.fromJson(s);
    })
        .toList();
    return Program(statements);
  }
}

class VariableDeclaration extends ASTNode {
  final String type;
  final String name;
  final ASTNode? initialValue;

  VariableDeclaration({
    required this.type,
    required this.name,
    this.initialValue,
  });

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitVariableDeclaration(this);

  @override
  String toString() => 'VarDecl($type $name = $initialValue)';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'VariableDeclaration',
      'dataType': type,
      'name': name,
      'initialValue': initialValue?.toJson(),
    };
  }

  static VariableDeclaration fromJson(Map<String, dynamic> json) {
    final dataType = json['dataType'];
    final name = json['name'];

    if (dataType == null || dataType is! String) {
      throw ArgumentError('Variable dataType must be a string');
    }
    if (name == null || name is! String) {
      throw ArgumentError('Variable name must be a string');
    }

    return VariableDeclaration(
      type: dataType,
      name: name,
      initialValue: json['initialValue'] != null
          ? ASTNode.fromJson(json['initialValue'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Assignment extends ASTNode {
  final String name;
  final ASTNode value;

  Assignment({required this.name, required this.value});

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitAssignment(this);

  @override
  String toString() => 'Assign($name = $value)';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Assignment',
      'name': name,
      'value': value.toJson(),
    };
  }

  static Assignment fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    if (name == null || name is! String) {
      throw ArgumentError('Assignment name must be a string');
    }

    return Assignment(
      name: name,
      value: ASTNode.fromJson(json['value'] as Map<String, dynamic>),
    );
  }
}

class PrintStatement extends ASTNode {
  final ASTNode expression;

  PrintStatement(this.expression);

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitPrintStatement(this);

  @override
  String toString() => 'Print($expression)';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'PrintStatement',
      'expression': expression.toJson(),
    };
  }

  static PrintStatement fromJson(Map<String, dynamic> json) {
    return PrintStatement(
        ASTNode.fromJson(json['expression'] as Map<String, dynamic>)
    );
  }
}

class IfStatement extends ASTNode {
  final ASTNode condition;
  final ASTNode thenBranch;
  final ASTNode? elseBranch;

  IfStatement({
    required this.condition,
    required this.thenBranch,
    this.elseBranch,
  });

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitIfStatement(this);

  @override
  String toString() => 'If($condition) Then($thenBranch) Else($elseBranch)';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'IfStatement',
      'condition': condition.toJson(),
      'thenBranch': thenBranch.toJson(),
      'elseBranch': elseBranch?.toJson(),
    };
  }

  static IfStatement fromJson(Map<String, dynamic> json) {
    return IfStatement(
      condition: ASTNode.fromJson(json['condition'] as Map<String, dynamic>),
      thenBranch: ASTNode.fromJson(json['thenBranch'] as Map<String, dynamic>),
      elseBranch: json['elseBranch'] != null
          ? ASTNode.fromJson(json['elseBranch'] as Map<String, dynamic>)
          : null,
    );
  }
}

class WhileStatement extends ASTNode {
  final ASTNode condition;
  final ASTNode body;

  WhileStatement({required this.condition, required this.body});

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitWhileStatement(this);

  @override
  String toString() => 'While($condition) Body($body)';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'WhileStatement',
      'condition': condition.toJson(),
      'body': body.toJson(),
    };
  }

  static WhileStatement fromJson(Map<String, dynamic> json) {
    return WhileStatement(
      condition: ASTNode.fromJson(json['condition'] as Map<String, dynamic>),
      body: ASTNode.fromJson(json['body'] as Map<String, dynamic>),
    );
  }
}

// Do-While
class DoWhileStatement extends ASTNode {
  final ASTNode body;
  final ASTNode condition;

  DoWhileStatement({required this.body, required this.condition});

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitDoWhileStatement(this);

  @override
  String toString() => 'DoWhile($body) While($condition)';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'DoWhileStatement',
      'body': body.toJson(),
      'condition': condition.toJson(),
    };
  }

  static DoWhileStatement fromJson(Map<String, dynamic> json) {
    return DoWhileStatement(
      body: ASTNode.fromJson(json['body'] as Map<String, dynamic>),
      condition: ASTNode.fromJson(json['condition'] as Map<String, dynamic>),
    );
  }
}

class ForStatement extends ASTNode {
  final ASTNode? initializer;
  final ASTNode? condition;
  final ASTNode? increment;
  final ASTNode body;

  ForStatement({
    this.initializer,
    this.condition,
    this.increment,
    required this.body,
  });

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitForStatement(this);

  @override
  String toString() =>
      'For(Init: $initializer; Cond: $condition; Incr: $increment) Body($body)';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'ForStatement',
      'initializer': initializer?.toJson(),
      'condition': condition?.toJson(),
      'increment': increment?.toJson(),
      'body': body.toJson(),
    };
  }

  static ForStatement fromJson(Map<String, dynamic> json) {
    return ForStatement(
      initializer: json['initializer'] != null
          ? ASTNode.fromJson(json['initializer'] as Map<String, dynamic>)
          : null,
      condition: json['condition'] != null
          ? ASTNode.fromJson(json['condition'] as Map<String, dynamic>)
          : null,
      increment: json['increment'] != null
          ? ASTNode.fromJson(json['increment'] as Map<String, dynamic>)
          : null,
      body: ASTNode.fromJson(json['body'] as Map<String, dynamic>),
    );
  }
}

// Switch
class SwitchStatement extends ASTNode {
  final ASTNode expression;
  final List<SwitchCase> cases;
  final ASTNode? defaultCase;

  SwitchStatement({
    required this.expression,
    required this.cases,
    this.defaultCase,
  });

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitSwitchStatement(this);

  @override
  String toString() => 'Switch($expression) Cases(${cases.length}) Default($defaultCase)';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'SwitchStatement',
      'expression': expression.toJson(),
      'cases': cases.map((c) => c.toJson()).toList(),
      'defaultCase': defaultCase?.toJson(),
    };
  }

  static SwitchStatement fromJson(Map<String, dynamic> json) {
    final casesList = json['cases'] as List;
    return SwitchStatement(
      expression: ASTNode.fromJson(json['expression'] as Map<String, dynamic>),
      cases: casesList.map((c) => SwitchCase.fromJson(c as Map<String, dynamic>)).toList(),
      defaultCase: json['defaultCase'] != null
          ? ASTNode.fromJson(json['defaultCase'] as Map<String, dynamic>)
          : null,
    );
  }
}

// Switch Case
class SwitchCase extends ASTNode {
  final ASTNode value;
  final ASTNode body;

  SwitchCase({required this.value, required this.body});

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitSwitchCase(this);

  @override
  String toString() => 'Case($value): $body';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'SwitchCase',
      'value': value.toJson(),
      'body': body.toJson(),
    };
  }

  static SwitchCase fromJson(Map<String, dynamic> json) {
    return SwitchCase(
      value: ASTNode.fromJson(json['value'] as Map<String, dynamic>),
      body: ASTNode.fromJson(json['body'] as Map<String, dynamic>),
    );
  }
}

// Break
class BreakStatement extends ASTNode {
  BreakStatement();

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitBreakStatement(this);

  @override
  String toString() => 'Break';

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'BreakStatement'};
  }

  static BreakStatement fromJson(Map<String, dynamic> json) {
    return BreakStatement();
  }
}

// Continue
class ContinueStatement extends ASTNode {
  ContinueStatement();

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitContinueStatement(this);

  @override
  String toString() => 'Continue';

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'ContinueStatement'};
  }

  static ContinueStatement fromJson(Map<String, dynamic> json) {
    return ContinueStatement();
  }
}

class FunctionDeclaration extends ASTNode {
  final String returnType;
  final String name;
  final List<MapEntry<String, String>> parameters;
  final Block body;

  FunctionDeclaration({
    required this.returnType,
    required this.name,
    required this.parameters,
    required this.body,
  });

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitFunctionDeclaration(this);

  @override
  String toString() => 'FunctionDecl($returnType $name(${parameters.map((p) => '${p.key} ${p.value}').join(', ')})) Body($body)';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'FunctionDeclaration',
      'returnType': returnType,
      'name': name,
      'parameters': parameters.map((p) => {'type': p.key, 'name': p.value}).toList(),
      'body': body.toJson(),
    };
  }

  static FunctionDeclaration fromJson(Map<String, dynamic> json) {
    final paramsList = json['parameters'];
    if (paramsList == null || paramsList is! List) {
      throw ArgumentError('Function parameters must be a list');
    }

    final parameters = paramsList
        .map((p) {
      if (p is! Map) {
        throw ArgumentError('Parameter must be a JSON object');
      }
      final pType = p['type'];
      final pName = p['name'];
      if (pType == null || pType is! String || pName == null || pName is! String) {
        throw ArgumentError('Parameter type and name must be strings');
      }
      return MapEntry<String, String>(pType, pName);
    })
        .toList();

    return FunctionDeclaration(
      returnType: json['returnType'] as String,
      name: json['name'] as String,
      parameters: parameters,
      body: Block.fromJson(json['body'] as Map<String, dynamic>),
    );
  }
}

class FunctionCall extends ASTNode {
  final String name;
  final List<ASTNode> arguments;

  FunctionCall({required this.name, required this.arguments});

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitFunctionCall(this);

  @override
  String toString() => 'Call($name(${arguments.join(', ')}))';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'FunctionCall',
      'name': name,
      'arguments': arguments.map((a) => a.toJson()).toList(),
    };
  }

  static FunctionCall fromJson(Map<String, dynamic> json) {
    final argsList = json['arguments'];
    if (argsList == null || argsList is! List) {
      throw ArgumentError('Function arguments must be a list');
    }

    final arguments = argsList
        .map((a) {
      if (a is! Map<String, dynamic>) {
        throw ArgumentError('Argument must be a JSON object');
      }
      return ASTNode.fromJson(a);
    })
        .toList();

    return FunctionCall(
      name: json['name'] as String,
      arguments: arguments,
    );
  }
}

// Lambda Function
class LambdaFunction extends ASTNode {
  final List<MapEntry<String, String>> parameters;
  final ASTNode body;

  LambdaFunction({required this.parameters, required this.body});

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitLambdaFunction(this);

  @override
  String toString() => 'Lambda(${parameters.map((p) => '${p.key} ${p.value}').join(', ')}) => $body';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'LambdaFunction',
      'parameters': parameters.map((p) => {'type': p.key, 'name': p.value}).toList(),
      'body': body.toJson(),
    };
  }

  static LambdaFunction fromJson(Map<String, dynamic> json) {
    final paramsList = json['parameters'] as List;
    final parameters = paramsList
        .map((p) => MapEntry<String, String>(p['type'] as String, p['name'] as String))
        .toList();

    return LambdaFunction(
      parameters: parameters,
      body: ASTNode.fromJson(json['body'] as Map<String, dynamic>),
    );
  }
}

// Lambda Call
class LambdaCall extends ASTNode {
  final LambdaFunction lambda;
  final List<ASTNode> arguments;

  LambdaCall({required this.lambda, required this.arguments});

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitLambdaCall(this);

  @override
  String toString() => 'LambdaCall($lambda(${arguments.join(', ')}))';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'LambdaCall',
      'lambda': lambda.toJson(),
      'arguments': arguments.map((a) => a.toJson()).toList(),
    };
  }

  static LambdaCall fromJson(Map<String, dynamic> json) {
    final argsList = json['arguments'] as List;
    final arguments = argsList.map((a) => ASTNode.fromJson(a as Map<String, dynamic>)).toList();

    return LambdaCall(
      lambda: LambdaFunction.fromJson(json['lambda'] as Map<String, dynamic>),
      arguments: arguments,
    );
  }
}

class ArrayDeclaration extends ASTNode {
  final String type;
  final String name;
  final int size;

  ArrayDeclaration({
    required this.type,
    required this.name,
    required this.size,
  });

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitArrayDeclaration(this);

  @override
  String toString() => 'ArrayDecl($type $name[$size])';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'ArrayDeclaration',
      'dataType': type,
      'name': name,
      'size': size,
    };
  }

  static ArrayDeclaration fromJson(Map<String, dynamic> json) {
    final size = json['size'];
    if (size is! int) {
      throw ArgumentError('Array size must be an integer');
    }

    return ArrayDeclaration(
      type: json['dataType'] as String,
      name: json['name'] as String,
      size: size,
    );
  }
}

class ArrayAccess extends ASTNode {
  final String name;
  final ASTNode index;

  ArrayAccess({required this.name, required this.index});

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitArrayAccess(this);

  @override
  String toString() => 'ArrayAccess($name[$index])';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'ArrayAccess',
      'name': name,
      'index': index.toJson(),
    };
  }

  static ArrayAccess fromJson(Map<String, dynamic> json) {
    return ArrayAccess(
      name: json['name'] as String,
      index: ASTNode.fromJson(json['index'] as Map<String, dynamic>),
    );
  }
}

class ArrayAssignment extends ASTNode {
  final String name;
  final ASTNode index;
  final ASTNode value;

  ArrayAssignment({
    required this.name,
    required this.index,
    required this.value,
  });

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitArrayAssignment(this);

  @override
  String toString() => 'ArrayAssign($name[$index] = $value)';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'ArrayAssignment',
      'name': name,
      'index': index.toJson(),
      'value': value.toJson(),
    };
  }

  static ArrayAssignment fromJson(Map<String, dynamic> json) {
    return ArrayAssignment(
      name: json['name'] as String,
      index: ASTNode.fromJson(json['index'] as Map<String, dynamic>),
      value: ASTNode.fromJson(json['value'] as Map<String, dynamic>),
    );
  }
}

class ReturnStatement extends ASTNode {
  final ASTNode? value;

  ReturnStatement(this.value);

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitReturnStatement(this);

  @override
  String toString() => 'Return($value)';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'ReturnStatement',
      'value': value?.toJson(),
    };
  }

  static ReturnStatement fromJson(Map<String, dynamic> json) {
    return ReturnStatement(
      json['value'] != null
          ? ASTNode.fromJson(json['value'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Block extends ASTNode {
  final List<ASTNode> statements;

  Block(this.statements);

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitBlock(this);

  @override
  String toString() => 'Block(${statements.length} statements)';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Block',
      'statements': statements.map((s) => s.toJson()).toList(),
    };
  }

  static Block fromJson(Map<String, dynamic> json) {
    final statementsList = json['statements'];
    if (statementsList == null || statementsList is! List) {
      throw ArgumentError('Block statements must be a list');
    }

    final statements = statementsList
        .map((s) {
      if (s is! Map<String, dynamic>) {
        throw ArgumentError('Statement must be a JSON object');
      }
      return ASTNode.fromJson(s);
    })
        .toList();
    return Block(statements);
  }
}

class BinaryExpression extends ASTNode {
  final ASTNode left;
  final String operator;
  final ASTNode right;

  BinaryExpression({
    required this.left,
    required this.operator,
    required this.right,
  });

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitBinaryExpression(this);

  @override
  String toString() => 'Binary($left $operator $right)';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'BinaryExpression',
      'left': left.toJson(),
      'operator': operator,
      'right': right.toJson(),
    };
  }

  static BinaryExpression fromJson(Map<String, dynamic> json) {
    return BinaryExpression(
      left: ASTNode.fromJson(json['left'] as Map<String, dynamic>),
      operator: json['operator'] as String,
      right: ASTNode.fromJson(json['right'] as Map<String, dynamic>),
    );
  }
}

class UnaryExpression extends ASTNode {
  final String operator;
  final ASTNode operand;

  UnaryExpression({required this.operator, required this.operand});

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitUnaryExpression(this);

  @override
  String toString() => 'Unary($operator$operand)';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'UnaryExpression',
      'operator': operator,
      'operand': operand.toJson(),
    };
  }

  static UnaryExpression fromJson(Map<String, dynamic> json) {
    return UnaryExpression(
      operator: json['operator'] as String,
      operand: ASTNode.fromJson(json['operand'] as Map<String, dynamic>),
    );
  }
}

class Identifier extends ASTNode {
  final String name;

  Identifier(this.name);

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitIdentifier(this);

  @override
  String toString() => 'Identifier($name)';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Identifier',
      'name': name,
    };
  }

  static Identifier fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    if (name == null || name is! String) {
      throw ArgumentError('Identifier name must be a string');
    }
    return Identifier(name);
  }
}

class NumberLiteral extends ASTNode {
  final num value;

  NumberLiteral(this.value);

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitNumberLiteral(this);

  @override
  String toString() => 'Number($value)';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'NumberLiteral',
      'value': value,
    };
  }

  static NumberLiteral fromJson(Map<String, dynamic> json) {
    final value = json['value'];

    if (value is int) {
      return NumberLiteral(value);
    } else if (value is double) {
      return NumberLiteral(value);
    } else if (value is num) {
      return NumberLiteral(value);
    } else if (value is String) {
      final parsedInt = int.tryParse(value);
      if (parsedInt != null) {
        return NumberLiteral(parsedInt);
      }
      final parsedDouble = double.tryParse(value);
      if (parsedDouble != null) {
        return NumberLiteral(parsedDouble);
      }
      throw ArgumentError('Invalid number string: $value');
    } else {
      throw ArgumentError('Invalid number value type: ${value.runtimeType}');
    }
  }
}

class StringLiteral extends ASTNode {
  final String value;

  StringLiteral(this.value);

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitStringLiteral(this);

  @override
  String toString() => 'String("$value")';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'StringLiteral',
      'value': value,
    };
  }

  static StringLiteral fromJson(Map<String, dynamic> json) {
    final value = json['value'];
    if (value == null) {
      return StringLiteral('');
    }
    return StringLiteral(value.toString());
  }
}

class BooleanLiteral extends ASTNode {
  final bool value;

  BooleanLiteral(this.value);

  @override
  T accept<T>(ASTVisitor<T> visitor) => visitor.visitBooleanLiteral(this);

  @override
  String toString() => 'Boolean($value)';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'BooleanLiteral',
      'value': value,
    };
  }

  static BooleanLiteral fromJson(Map<String, dynamic> json) {
    final value = json['value'];
    if (value is bool) {
      return BooleanLiteral(value);
    } else if (value is String) {
      if (value.toLowerCase() == 'true') {
        return BooleanLiteral(true);
      } else if (value.toLowerCase() == 'false') {
        return BooleanLiteral(false);
      }
    }
    throw ArgumentError('Invalid boolean value: $value');
  }
}
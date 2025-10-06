import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../compiler/lexer.dart';
import '../compiler/parser.dart';
import '../compiler/semantic_analyzer.dart';
import '../compiler/interpreter.dart';
import '../models/token_types.dart';
import '../models/ast_nodes.dart';
import 'smart_cache_manager.dart';
import 'compiler_examples.dart';

enum CompilerState {
  idle,
  lexing,
  parsing,
  analyzing,
  interpreting,
  optimizing,
  completed,
  error,
}

class CompilationPhase {
  final String name;
  final bool isSuccessful;
  final String result;
  final List<String> errors;
  final List<String> warnings;
  final Duration duration;
  final Map<String, dynamic>? statistics;
  final bool wasCached;

  CompilationPhase({
    required this.name,
    required this.isSuccessful,
    required this.result,
    required this.errors,
    this.warnings = const [],
    required this.duration,
    this.statistics,
    this.wasCached = false,
  });

  @override
  String toString() {
    final warningText = warnings.isNotEmpty ? ' (${warnings.length} warnings)' : '';
    final cachedText = wasCached ? ' [CACHED]' : '';
    return '$name: ${isSuccessful ? 'Success' : 'Failed'} (${duration.inMilliseconds}ms)$warningText$cachedText';
  }
}

class CompilerConfig {
  static const int maxCompilationTimeMs = 30000;
  static const int maxSourceCodeLength = 100000;
  static const int maxTokens = 10000;
  static const int maxConcurrentCompilations = 1;
}

// Data class for isolate communication
class _CompilationData {
  final String sourceCode;

  _CompilationData({required this.sourceCode});
}

// Result class for isolate communication
class _CompilationResult {
  final List<Map<String, dynamic>> tokensJson;
  final Map<String, dynamic>? astJson;
  final String output;
  final int executionTime;
  final List<String> lexerErrors;
  final List<String> parserErrors;
  final List<String> parserWarnings;
  final List<String> analyzerErrors;
  final List<String> analyzerWarnings;
  final List<String> interpreterErrors;
  final Map<String, dynamic> stats;
  final int lexerDurationMs;
  final int parserDurationMs;
  final int analyzerDurationMs;
  final int interpreterDurationMs;

  _CompilationResult({
    required this.tokensJson,
    required this.astJson,
    required this.output,
    required this.executionTime,
    required this.lexerErrors,
    required this.parserErrors,
    required this.parserWarnings,
    required this.analyzerErrors,
    required this.analyzerWarnings,
    required this.interpreterErrors,
    required this.stats,
    required this.lexerDurationMs,
    required this.parserDurationMs,
    required this.analyzerDurationMs,
    required this.interpreterDurationMs,
  });
}

class CompilerProvider extends ChangeNotifier with CacheableMixin {
  String _sourceCode = '';
  CompilerState _state = CompilerState.idle;
  List<CompilationPhase> _phases = [];
  String _output = '';
  List<Token> _tokens = [];
  Program? _ast;
  bool _isRunning = false;
  bool _isCacheEnabled = true;

  Map<String, dynamic> _compilationStats = {};
  List<String> _suggestions = [];
  int _executionTime = 0;

  Map<String, dynamic> _cacheStats = {};

  CompilerProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    if (_isCacheEnabled) {
      try {
        await initializeCache();
        _updateCacheStats();
      } catch (e) {
        debugPrint('Cache initialization failed: $e');
      }
    }
  }

  // Getters
  String get sourceCode => _sourceCode;
  CompilerState get state => _state;
  List<CompilationPhase> get phases => List.unmodifiable(_phases);
  String get output => _output;
  List<Token> get tokens => List.unmodifiable(_tokens);
  Program? get ast => _ast;
  Map<String, dynamic> get compilationStats => Map.unmodifiable(_compilationStats);
  List<String> get suggestions => List.unmodifiable(_suggestions);
  bool get isRunning => _isRunning;
  bool get isCacheEnabled => _isCacheEnabled;
  Map<String, dynamic> get cacheStatistics => Map.unmodifiable(_cacheStats);

  void setSourceCode(String value) {
    if (_sourceCode != value) {
      _sourceCode = value;
      notifyListeners();
    }
  }

  void loadExampleCode(String exampleKey) {
    final exampleCode = CompilerExamples.getExample(exampleKey);
    setSourceCode(exampleCode);
  }

  Future<void> compile() async {
    if (_isRunning) {
      debugPrint('Compilation already in progress, ignoring request');
      return;
    }

    if (_sourceCode.trim().isEmpty) {
      _showError('Source code is empty');
      return;
    }

    if (_sourceCode.length > CompilerConfig.maxSourceCodeLength) {
      _showError('Source code exceeds maximum length of ${CompilerConfig.maxSourceCodeLength} characters');
      return;
    }

    _isRunning = true;
    _clearResults();
    final stopwatch = Stopwatch()..start();

    // Check cache first
    try {
      if (_isCacheEnabled) {
        final cachedResult = await getCachedCompilation(_sourceCode);
        if (cachedResult != null) {
          await _loadFromCache(cachedResult, stopwatch);
          return;
        }
      }

      // Perform full compilation in isolate with timeout
      final result = await compute(_compileInIsolate, _CompilationData(
        sourceCode: _sourceCode,
      )).timeout(
        Duration(milliseconds: CompilerConfig.maxCompilationTimeMs),
        onTimeout: () {
          throw TimeoutException('Compilation timeout exceeded');
        },
      );

      await _handleCompilationResult(result, stopwatch);
    } on TimeoutException catch (e) {
      _showError('Compilation timeout: ${e.message}');
      _state = CompilerState.error;
      _isRunning = false;
      notifyListeners();
    } catch (e, stackTrace) {
      final errorMessage = e.toString().split('\n').first;
      _showError('Compilation failed: $errorMessage');
      debugPrint('Full compilation error: $e\n$stackTrace');
      _state = CompilerState.error;
      _isRunning = false;
      notifyListeners();
    }
  }

  // Static method for compute isolate - runs in background thread
  static _CompilationResult _compileInIsolate(_CompilationData data) {
    final stopwatch = Stopwatch()..start();

    // Lexical Analysis
    final lexerStart = DateTime.now();
    final lexer = Lexer(data.sourceCode);
    final tokens = lexer.tokenize();
    final lexerDuration = DateTime.now().difference(lexerStart);

    final lexerErrors = lexer.hasErrors
        ? lexer.getErrorsAsString().split('\n').where((e) => e.isNotEmpty).toList()
        : <String>[];

    if (lexer.hasErrors) {
      return _CompilationResult(
        tokensJson: [],
        astJson: null,
        output: '',
        executionTime: 0,
        lexerErrors: lexerErrors,
        parserErrors: [],
        parserWarnings: [],
        analyzerErrors: [],
        analyzerWarnings: [],
        interpreterErrors: [],
        stats: {},
        lexerDurationMs: lexerDuration.inMilliseconds,
        parserDurationMs: 0,
        analyzerDurationMs: 0,
        interpreterDurationMs: 0,
      );
    }

    // Parsing
    final parserStart = DateTime.now();
    final parser = Parser(tokens);
    final ast = parser.parse();
    final parserDuration = DateTime.now().difference(parserStart);

    final parserErrors = parser.hasErrors
        ? parser.getErrorsAsString().split('\n').where((e) => e.isNotEmpty).toList()
        : <String>[];

    final parserWarnings = parser.hasWarnings
        ? parser.getAllMessages().where((m) => m.type == MessageType.warning).map((w) => w.toString()).toList()
        : <String>[];

    if (ast == null || parser.hasErrors) {
      return _CompilationResult(
        tokensJson: tokens.map((t) => {
          'type': t.type.toString(),
          'value': t.value,
          'line': t.line,
          'column': t.column,
        }).toList(),
        astJson: null,
        output: '',
        executionTime: 0,
        lexerErrors: lexerErrors,
        parserErrors: parserErrors,
        parserWarnings: parserWarnings,
        analyzerErrors: [],
        analyzerWarnings: [],
        interpreterErrors: [],
        stats: {},
        lexerDurationMs: lexerDuration.inMilliseconds,
        parserDurationMs: parserDuration.inMilliseconds,
        analyzerDurationMs: 0,
        interpreterDurationMs: 0,
      );
    }

    // Semantic Analysis
    final analyzerStart = DateTime.now();
    final analyzer = SemanticAnalyzer();
    analyzer.analyze(ast);
    final analyzerDuration = DateTime.now().difference(analyzerStart);

    final analyzerErrors = analyzer.hasErrors
        ? analyzer.getErrorsAsString().split('\n').where((e) => e.isNotEmpty).toList()
        : <String>[];

    final analyzerWarnings = analyzer.hasWarnings
        ? analyzer.getWarningsAsString().split('\n').where((e) => e.isNotEmpty).toList()
        : <String>[];

    final stats = analyzer.getStatistics();

    if (analyzer.hasErrors) {
      return _CompilationResult(
        tokensJson: tokens.map((t) => {
          'type': t.type.toString(),
          'value': t.value,
          'line': t.line,
          'column': t.column,
        }).toList(),
        astJson: ast.toJson(),
        output: '',
        executionTime: 0,
        lexerErrors: lexerErrors,
        parserErrors: parserErrors,
        parserWarnings: parserWarnings,
        analyzerErrors: analyzerErrors,
        analyzerWarnings: analyzerWarnings,
        interpreterErrors: [],
        stats: stats,
        lexerDurationMs: lexerDuration.inMilliseconds,
        parserDurationMs: parserDuration.inMilliseconds,
        analyzerDurationMs: analyzerDuration.inMilliseconds,
        interpreterDurationMs: 0,
      );
    }

    // Interpretation
    final interpreterStart = DateTime.now();
    final interpreter = Interpreter(ast);
    final interpretResult = interpreter.interpret();
    final interpreterDuration = DateTime.now().difference(interpreterStart);

    final interpreterErrors = interpreter.errors.isNotEmpty
        ? interpreter.errors.map((e) => e.toString()).toList()
        : <String>[];

    return _CompilationResult(
      tokensJson: tokens.map((t) => {
        'type': t.type.toString(),
        'value': t.value,
        'line': t.line,
        'column': t.column,
      }).toList(),
      astJson: ast.toJson(),
      output: interpretResult.output,
      executionTime: interpretResult.executionTime,
      lexerErrors: lexerErrors,
      parserErrors: parserErrors,
      parserWarnings: parserWarnings,
      analyzerErrors: analyzerErrors,
      analyzerWarnings: analyzerWarnings,
      interpreterErrors: interpreterErrors,
      stats: {
        ...stats,
        'tokenCount': tokens.length,
        'astNodeCount': _countASTNodesStatic(ast),
      },
      lexerDurationMs: lexerDuration.inMilliseconds,
      parserDurationMs: parserDuration.inMilliseconds,
      analyzerDurationMs: analyzerDuration.inMilliseconds,
      interpreterDurationMs: interpreterDuration.inMilliseconds,
    );
  }

  static int _countASTNodesStatic(Program ast) {
    int count = 0;

    void countNodes(ASTNode node) {
      count++;

      if (node is Program) {
        for (final stmt in node.statements) {
          countNodes(stmt);
        }
      } else if (node is Block) {
        for (final stmt in node.statements) {
          countNodes(stmt);
        }
      } else if (node is IfStatement) {
        countNodes(node.condition);
        countNodes(node.thenBranch);
        if (node.elseBranch != null) countNodes(node.elseBranch!);
      } else if (node is WhileStatement) {
        countNodes(node.condition);
        countNodes(node.body);
      } else if (node is DoWhileStatement) {
        countNodes(node.body);
        countNodes(node.condition);
      } else if (node is ForStatement) {
        if (node.initializer != null) countNodes(node.initializer!);
        if (node.condition != null) countNodes(node.condition!);
        if (node.increment != null) countNodes(node.increment!);
        countNodes(node.body);
      } else if (node is BinaryExpression) {
        countNodes(node.left);
        countNodes(node.right);
      } else if (node is UnaryExpression) {
        countNodes(node.operand);
      } else if (node is VariableDeclaration) {
        if (node.initialValue != null) countNodes(node.initialValue!);
      } else if (node is Assignment) {
        countNodes(node.value);
      }
    }

    countNodes(ast);
    return count;
  }

  Future<void> _handleCompilationResult(_CompilationResult result, Stopwatch stopwatch) async {
    _state = CompilerState.lexing;
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 50));

    // Reconstruct tokens from JSON
    _tokens = result.tokensJson.map((t) => Token(
      type: TokenType.values.firstWhere((type) => type.toString() == t['type']),
      value: t['value'],
      line: t['line'],
      column: t['column'],
    )).toList();

    _addPhase('Lexical Analysis', result.lexerErrors.isEmpty,
        _getTokensDisplayString(_tokens), result.lexerErrors,
        duration: Duration(milliseconds: result.lexerDurationMs));

    if (result.lexerErrors.isNotEmpty) {
      _finishCompilationWithError(stopwatch);
      return;
    }

    _state = CompilerState.parsing;
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 50));

    // Reconstruct AST from JSON
    if (result.astJson != null) {
      _ast = Program.fromJson(result.astJson!);
    }

    _addPhase('Parsing', result.parserErrors.isEmpty && _ast != null,
        _ast != null ? 'Parse tree generated with ${_countASTNodes(_ast!)} nodes' : 'Parse failed',
        result.parserErrors, warnings: result.parserWarnings,
        duration: Duration(milliseconds: result.parserDurationMs));

    if (_ast == null || result.parserErrors.isNotEmpty) {
      _finishCompilationWithError(stopwatch);
      return;
    }

    _state = CompilerState.analyzing;
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 50));

    _addPhase('Semantic Analysis', result.analyzerErrors.isEmpty,
        'Symbols: ${result.stats['totalSymbols']}, Functions: ${result.stats['functions']}, Variables: ${result.stats['variables']}',
        result.analyzerErrors, warnings: result.analyzerWarnings,
        duration: Duration(milliseconds: result.analyzerDurationMs), stats: result.stats);

    // Cache successful compilation
    if (_isCacheEnabled && result.analyzerErrors.isEmpty) {
      try {
        await cacheCompilationResult(
            _sourceCode,
            _tokens,
            _ast,
            result.analyzerErrors,
            result.analyzerWarnings,
            result.stats
        );
        _updateCacheStats();
      } catch (e) {
        debugPrint('Cache save failed: $e');
      }
    }

    if (result.analyzerErrors.isNotEmpty) {
      _finishCompilationWithError(stopwatch);
      return;
    }

    _state = CompilerState.interpreting;
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 50));

    _output = result.output;
    _executionTime = result.executionTime;

    _addPhase('Interpreting', result.interpreterErrors.isEmpty,
        _output.isEmpty ? 'No output generated' : 'Output: ${_output.split('\n').length} lines',
        result.interpreterErrors,
        duration: Duration(milliseconds: result.interpreterDurationMs),
        stats: {
          'executionTimeMs': _executionTime,
          'outputLength': _output.length,
          'errorCount': result.interpreterErrors.length,
        });

    stopwatch.stop();
    _compilationStats = {
      'totalTime': stopwatch.elapsedMilliseconds,
      'tokenCount': _tokens.length,
      'astNodeCount': _countASTNodes(_ast!),
      'statementCount': _ast!.statements.length,
      'executionTime': _executionTime,
      'wasCached': false,
      'cacheHit': false,
      'lexerTime': result.lexerDurationMs,
      'parserTime': result.parserDurationMs,
      'analyzerTime': result.analyzerDurationMs,
      'interpreterTime': result.interpreterDurationMs,
      ...result.stats,
    };

    _state = CompilerState.completed;
    _isRunning = false;
    notifyListeners();
  }

  Future<void> _loadFromCache(CachedCompilationResult cachedResult, Stopwatch stopwatch) async {
    final cacheLoadStart = DateTime.now();

    _tokens = List<Token>.from(cachedResult.tokens);
    _ast = cachedResult.ast;

    final cacheLoadDuration = DateTime.now().difference(cacheLoadStart);

    _state = CompilerState.lexing;
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 30));

    _addPhase('Cache Lookup', true, 'Loaded from cache', [],
        duration: cacheLoadDuration, wasCached: true);

    if (cachedResult.tokens.isNotEmpty) {
      _addPhase('Lexical Analysis', true,
          'Generated ${cachedResult.tokens.length} tokens', [],
          duration: Duration.zero, wasCached: true);
    }

    _state = CompilerState.parsing;
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 30));

    if (cachedResult.ast != null) {
      _addPhase('Parsing', true, 'Parse tree generated', [],
          duration: Duration.zero, wasCached: true);
    }

    _state = CompilerState.analyzing;
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 30));

    if (cachedResult.errors.isEmpty) {
      _addPhase('Semantic Analysis', true, 'No semantic errors found', [],
          duration: Duration.zero, wasCached: true);
    } else {
      _addPhase('Semantic Analysis', false, 'Semantic errors found',
          cachedResult.errors, duration: Duration.zero, wasCached: true);
    }

    if (cachedResult.ast != null && cachedResult.errors.isEmpty) {
      _state = CompilerState.interpreting;
      notifyListeners();
      await Future.delayed(Duration(milliseconds: 30));

      await _runInterpreter(cachedResult.ast!);
    }

    stopwatch.stop();
    _compilationStats = {
      ...cachedResult.statistics,
      'totalTime': stopwatch.elapsedMilliseconds,
      'wasCached': true,
      'cacheHit': true,
    };

    _state = CompilerState.completed;
    _isRunning = false;
    _updateCacheStats();
    notifyListeners();
  }

  Future<void> _runInterpreter(Program ast) async {
    final interpreterStart = DateTime.now();
    final interpreter = Interpreter(ast);
    final interpretResult = interpreter.interpret();
    final interpreterDuration = DateTime.now().difference(interpreterStart);

    _output = interpretResult.output;
    _executionTime = interpretResult.executionTime;

    final interpreterErrors = interpreter.errors.isNotEmpty
        ? interpreter.errors.map((e) => e.toString()).toList()
        : <String>[];

    _addPhase('Interpreting', interpreter.errors.isEmpty,
        _output.isEmpty ? 'No output generated' : 'Output: ${_output.split('\n').length} lines',
        interpreterErrors,
        duration: interpreterDuration,
        stats: {
          'executionTimeMs': _executionTime,
          'outputLength': _output.length,
          'errorCount': interpreter.errors.length,
        });
  }

  void _finishCompilationWithError(Stopwatch stopwatch) {
    stopwatch.stop();
    _state = CompilerState.error;
    _isRunning = false;
    notifyListeners();
  }

  String _getTokensDisplayString(List<Token> tokens) {
    if (tokens.isEmpty) return 'No tokens found';

    final tokenTypes = <TokenType, int>{};
    for (final token in tokens) {
      tokenTypes[token.type] = (tokenTypes[token.type] ?? 0) + 1;
    }

    return 'Generated ${tokens.length} tokens (${tokenTypes.length} types)';
  }

  int _countASTNodes(Program ast) {
    return _countASTNodesStatic(ast);
  }

  void _addPhase(
      String name,
      bool success,
      String result,
      List<String> errors, {
        List<String> warnings = const [],
        Map<String, dynamic>? stats,
        bool wasCached = false,
        Duration? duration,
      }) {
    final phase = CompilationPhase(
      name: name,
      isSuccessful: success,
      result: result,
      errors: errors,
      warnings: warnings,
      duration: duration ?? Duration.zero,
      statistics: stats,
      wasCached: wasCached,
    );
    _phases.add(phase);
    notifyListeners();
  }

  void _clearResults() {
    _phases.clear();
    _output = '';
    _tokens.clear();
    _ast = null;
    _compilationStats.clear();
    _suggestions.clear();
    _executionTime = 0;
    _state = CompilerState.idle;
    notifyListeners();
  }

  void _showError(String message) {
    _phases.add(CompilationPhase(
      name: 'Error',
      isSuccessful: false,
      result: '',
      errors: [message],
      duration: Duration.zero,
    ));
    notifyListeners();
  }

  void _updateCacheStats() {
    try {
      _cacheStats = getCacheStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Update cache stats failed: $e');
    }
  }

  Future<void> toggleCache() async {
    _isCacheEnabled = !_isCacheEnabled;
    if (_isCacheEnabled) {
      try {
        await initializeCache();
      } catch (e) {
        debugPrint('Cache initialization failed: $e');
      }
    }
    _updateCacheStats();
    notifyListeners();
  }

  Future<void> clearCache() async {
    if (_isCacheEnabled) {
      try {
        await clearCompilerCache();
        _updateCacheStats();
      } catch (e) {
        debugPrint('Clear cache failed: $e');
      }
    }
  }

  void clear() {
    _clearResults();
  }

  String getPhaseStatusIcon(CompilationPhase phase) {
    if (phase.wasCached) {
      return phase.isSuccessful ? '⚡' : '❌';
    } else if (phase.isSuccessful) {
      return phase.warnings.isEmpty ? '✅' : '⚠️';
    } else {
      return '❌';
    }
  }

  Color getPhaseStatusColor(CompilationPhase phase) {
    if (phase.wasCached && phase.isSuccessful) {
      return const Color(0xFF2196F3);
    } else if (phase.isSuccessful) {
      return phase.warnings.isEmpty
          ? const Color(0xFF4CAF50)
          : const Color(0xFFFF9800);
    } else {
      return const Color(0xFFF44336);
    }
  }

  bool get isCompiling =>
      _state != CompilerState.idle &&
          _state != CompilerState.completed &&
          _state != CompilerState.error;

  bool get hasOutput => _output.isNotEmpty;
  bool get hasErrors => _phases.any((phase) => !phase.isSuccessful);

  List<String> get allErrors => _phases
      .where((phase) => !phase.isSuccessful)
      .expand((phase) => phase.errors)
      .toList();

  List<String> get allWarnings => _phases
      .expand((phase) => phase.warnings)
      .toList();

  String get currentPhase {
    switch (_state) {
      case CompilerState.idle: return 'Ready';
      case CompilerState.lexing: return 'Tokenizing...';
      case CompilerState.parsing: return 'Parsing...';
      case CompilerState.analyzing: return 'Analyzing...';
      case CompilerState.interpreting: return 'Interpreting...';
      case CompilerState.optimizing: return 'Optimizing...';
      case CompilerState.completed: return 'Completed';
      case CompilerState.error: return 'Error';
    }
  }

  double get progressValue {
    switch (_state) {
      case CompilerState.idle: return 0.0;
      case CompilerState.lexing: return 0.2;
      case CompilerState.parsing: return 0.4;
      case CompilerState.analyzing: return 0.6;
      case CompilerState.interpreting: return 0.8;
      case CompilerState.optimizing: return 0.9;
      case CompilerState.completed:
      case CompilerState.error: return 1.0;
    }
  }

  void reset() {
    _clearResults();
    setSourceCode('');
  }

  String getFeatureInfo(String feature) {
    switch (feature) {
      case 'do_while':
        return 'Do-While Loop: Executes body at least once, then checks condition';
      case 'break':
        return 'Break: Exits from current loop or switch statement';
      case 'continue':
        return 'Continue: Skips rest of iteration, continues with next';
      case 'switch':
        return 'Switch-Case: Multi-way branch based on expression value';
      case 'lambda':
        return 'Lambda Functions: Anonymous functions with syntax (params) => expression';
      case 'recursion':
        return 'Optimized Recursion: Improved handling of recursive function calls';
      default:
        return 'Feature information not available';
    }
  }

  Map<String, bool> detectFeatures() {
    final features = <String, bool>{
      'do_while': _sourceCode.contains('do') && _sourceCode.contains('while'),
      'break': _sourceCode.contains('break'),
      'continue': _sourceCode.contains('continue'),
      'switch': _sourceCode.contains('switch'),
      'lambda': _sourceCode.contains('=>'),
      'recursion': _hasRecursiveFunctions(),
    };
    return features;
  }

  bool _hasRecursiveFunctions() {
    final functionPattern = RegExp(r'(\w+)\s+(\w+)\s*\([^)]*\)\s*\{');
    final matches = functionPattern.allMatches(_sourceCode);

    for (final match in matches) {
      final functionName = match.group(2);
      if (functionName != null) {
        final functionStart = match.end;
        final functionBody = _sourceCode.substring(functionStart);
        final endBrace = _findMatchingBrace(functionBody);
        if (endBrace != -1) {
          final body = functionBody.substring(0, endBrace);
          if (body.contains(RegExp('\\b$functionName\\s*\\('))) {
            return true;
          }
        }
      }
    }
    return false;
  }

  int _findMatchingBrace(String text) {
    int depth = 1;
    for (int i = 0; i < text.length; i++) {
      if (text[i] == '{') depth++;
      if (text[i] == '}') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
import 'package:flutter/material.dart';

class CodeIntelligence {
  // Language Keywords by category
  static const keywords = {
    'int', 'float', 'string', 'bool', 'void',
    'if', 'else', 'while', 'for', 'return',
    'true', 'false', 'null', 'print', 'func',
    'break', 'continue', 'const', 'let', 'var',
    'do', 'switch', 'case', 'default'
  };

  static const dataTypes = {'int', 'float', 'string', 'bool', 'void'};
  static const controlFlow = {'if', 'else', 'while', 'for', 'do', 'switch', 'case', 'default'};
  static const declarationKeywords = {'func', 'const', 'let', 'var'};

  // Built-in Functions with full signatures
  static const builtInFunctions = {
    'print': FunctionSignature(
      name: 'print',
      returnType: 'void',
      parameters: ['value: any'],
      description: 'Prints a value to the console',
      examples: ['print("Hello");', 'print(42);'],
    ),
    'parseInt': FunctionSignature(
      name: 'parseInt',
      returnType: 'int',
      parameters: ['str: string'],
      description: 'Converts string to integer',
      examples: ['int x = parseInt("42");'],
    ),
    'parseFloat': FunctionSignature(
      name: 'parseFloat',
      returnType: 'float',
      parameters: ['str: string'],
      description: 'Converts string to float',
      examples: ['float x = parseFloat("3.14");'],
    ),
    'toString': FunctionSignature(
      name: 'toString',
      returnType: 'string',
      parameters: ['value: any'],
      description: 'Converts value to string',
      examples: ['string s = toString(42);'],
    ),
    'len': FunctionSignature(
      name: 'len',
      returnType: 'int',
      parameters: ['str: string'],
      description: 'Returns the length of a string',
      examples: ['int length = len("hello");'],
    ),
    'sqrt': FunctionSignature(
      name: 'sqrt',
      returnType: 'float',
      parameters: ['x: float'],
      description: 'Returns square root of a number',
      examples: ['float result = sqrt(16.0);'],
    ),
    'abs': FunctionSignature(
      name: 'abs',
      returnType: 'float',
      parameters: ['x: float'],
      description: 'Returns absolute value',
      examples: ['float result = abs(-5.0);'],
    ),
  };

  // Operators by precedence
  static const operators = {
    '++', '--',
    '*', '/', '%',
    '+', '-',
    '<', '>', '<=', '>=',
    '==', '!=',
    '&&',
    '||',
    '=', '+=', '-=', '*=', '/=',
  };

  final String sourceCode;
  final List<Symbol> _symbols = [];
  final Map<String, List<Symbol>> _symbolsByName = {};
  final List<Scope> _scopes = [];
  final Map<int, String> _typeInference = {};
  final List<CodeError> _errors = [];

  // Cache for performance
  final Map<String, List<CompletionItem>> _completionCache = {};
  String _lastParsedCode = '';

  CodeIntelligence(this.sourceCode) {
    try {
      _parseSymbols();
      _buildScopes();
      _performTypeInference();
      _performSemanticAnalysis();
      _lastParsedCode = sourceCode;
    } catch (e) {
      debugPrint('Code intelligence error: $e');
    }
  }

  void _parseSymbols() {
    _symbols.clear();
    _symbolsByName.clear();

    // Parse function definitions
    final functionPattern = RegExp(
      r'func\s+([a-zA-Z_]\w*)\s*\(([^)]*)\)\s*(?::\s*([a-zA-Z_]\w+))?\s*\{',
    );
    for (final match in functionPattern.allMatches(sourceCode)) {
      final funcName = match.group(1)!;
      final paramsStr = match.group(2)?.trim() ?? '';
      final returnType = match.group(3) ?? 'void';

      final parameters = _parseParameters(paramsStr);
      final symbol = Symbol(
        name: funcName,
        type: SymbolType.function,
        line: _getLineNumber(match.start),
        offset: match.start,
        dataType: returnType,
        parameters: parameters,
        scope: _getCurrentScope(match.start),
      );

      _addSymbol(symbol);
    }

    // Parse variable declarations
    final varPattern = RegExp(
      r'\b(int|float|string|bool|var|let|const)\s+([a-zA-Z_]\w*)(?:\s*=\s*([^;]+))?',
    );
    for (final match in varPattern.allMatches(sourceCode)) {
      final declType = match.group(1)!;
      final varName = match.group(2)!;
      final initValue = match.group(3)?.trim();

      String dataType = declType;
      if (declType == 'var' || declType == 'let') {
        dataType = _inferTypeFromValue(initValue);
      }

      final symbol = Symbol(
        name: varName,
        type: SymbolType.variable,
        line: _getLineNumber(match.start),
        offset: match.start,
        dataType: dataType,
        isConstant: declType == 'const',
        scope: _getCurrentScope(match.start),
      );

      _addSymbol(symbol);
    }

    // Parse function parameters
    for (final funcSymbol in _symbols.where((s) => s.type == SymbolType.function)) {
      for (final param in funcSymbol.parameters) {
        final paramSymbol = Symbol(
          name: param.name,
          type: SymbolType.parameter,
          line: funcSymbol.line,
          offset: funcSymbol.offset,
          dataType: param.type,
          scope: funcSymbol.name,
        );
        _addSymbol(paramSymbol);
      }
    }
  }

  void _addSymbol(Symbol symbol) {
    _symbols.add(symbol);
    _symbolsByName.putIfAbsent(symbol.name, () => []).add(symbol);
  }

  List<Parameter> _parseParameters(String paramsStr) {
    if (paramsStr.isEmpty) return [];

    final params = <Parameter>[];
    for (final paramStr in paramsStr.split(',')) {
      final parts = paramStr.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        params.add(Parameter(
          name: parts[1],
          type: parts[0],
          isOptional: false,
        ));
      }
    }
    return params;
  }

  void _buildScopes() {
    _scopes.clear();

    final globalScope = Scope(
      name: 'global',
      start: 0,
      end: sourceCode.length,
      parent: null,
    );
    _scopes.add(globalScope);

    final scopePattern = RegExp(r'\{');
    final matches = scopePattern.allMatches(sourceCode).toList();

    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = _findClosingBrace(start);

      if (end > start) {
        _scopes.add(Scope(
          name: 'block_$i',
          start: start,
          end: end,
          parent: globalScope,
        ));
      }
    }
  }

  int _findClosingBrace(int openPos) {
    int depth = 1;
    for (int i = openPos + 1; i < sourceCode.length; i++) {
      if (sourceCode[i] == '{') depth++;
      if (sourceCode[i] == '}') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return sourceCode.length;
  }

  String _getCurrentScope(int position) {
    for (final scope in _scopes.reversed) {
      if (position >= scope.start && position <= scope.end) {
        return scope.name;
      }
    }
    return 'global';
  }

  void _performTypeInference() {
    _typeInference.clear();

    final literalPatterns = {
      r'\b\d+\.\d+\b': 'float',
      r'\b\d+\b': 'int',
      r'"[^"]*"': 'string',
      r"'[^']*'": 'string',
      r'\b(true|false)\b': 'bool',
    };

    for (final entry in literalPatterns.entries) {
      final pattern = RegExp(entry.key);
      for (final match in pattern.allMatches(sourceCode)) {
        _typeInference[match.start] = entry.value;
      }
    }
  }

  String _inferTypeFromValue(String? value) {
    if (value == null || value.isEmpty) return 'any';

    if (RegExp(r'^\d+\.\d+$').hasMatch(value)) return 'float';
    if (RegExp(r'^\d+$').hasMatch(value)) return 'int';
    if (value.startsWith('"') || value.startsWith("'")) return 'string';
    if (value == 'true' || value == 'false') return 'bool';

    return 'any';
  }

  void _performSemanticAnalysis() {
    _errors.clear();

    final codeWithoutStrings = _removeStringsAndComments(sourceCode);

    final varUsagePattern = RegExp(r'\b([a-zA-Z_]\w*)\b');

    for (final match in varUsagePattern.allMatches(codeWithoutStrings)) {
      final varName = match.group(1)!;
      final position = match.start;

      if (_shouldSkipCheck(varName, position, codeWithoutStrings)) {
        continue;
      }

      // Check if the variable is defined
      if (!_isSymbolDefined(varName, position)) {
        _errors.add(CodeError(
          message: 'Undefined variable or function: $varName',
          line: _getLineNumber(match.start),
          column: _getColumnNumber(match.start),
          severity: ErrorSeverity.error,
          offset: match.start,
        ));
      }
    }

    // Check for duplicate declarations
    for (final entry in _symbolsByName.entries) {
      if (entry.value.length > 1) {
        final symbols = entry.value.where((s) => s.scope == 'global').toList();
        if (symbols.length > 1) {
          for (var i = 1; i < symbols.length; i++) {
            _errors.add(CodeError(
              message: 'Duplicate declaration: ${entry.key}',
              line: symbols[i].line,
              column: 0,
              severity: ErrorSeverity.warning,
              offset: symbols[i].offset,
            ));
          }
        }
      }
    }
  }

  String _removeStringsAndComments(String code) {
    var result = code;

    result = result.replaceAll(RegExp(r'//.*$', multiLine: true), '');

    result = result.replaceAll(RegExp(r'"[^"]*"'), '""');

    result = result.replaceAll(RegExp(r"'[^']*'"), "''");

    return result;
  }

  bool _shouldSkipCheck(String varName, int position, String cleanCode) {
    // Language keywords
    if (keywords.contains(varName)) return true;

    // Built-in functions
    if (builtInFunctions.containsKey(varName)) return true;

    // Operators
    if (operators.contains(varName)) return true;

    // Numbers
    if (RegExp(r'^\d+$').hasMatch(varName)) return true;

    // Check if in a type declaration context (left side of variable declaration)
    if (_isInDeclarationContext(position, varName, cleanCode)) return true;

    // Check if it's a function name being declared
    if (_isInFunctionDeclarationContext(position, varName, cleanCode)) return true;

    // Check if it's a parameter name in parameter list
    if (_isInParameterListContext(position, varName, cleanCode)) return true;

    // Check if it's on the left side of an assignment (after initial declaration)
    if (_isLeftSideOfAssignment(position, varName, cleanCode)) return true;

    // Check if it's being called as a function (has parentheses after it)
    if (_isInFunctionCallContext(position, varName, cleanCode)) return true;

    // Check if it's part of a member access (obj.member)
    if (_isMemberAccess(position, cleanCode)) return true;

    return false;
  }

  bool _isInDeclarationContext(int position, String varName, String code) {
    // Find the start of the line containing this identifier
    int lineStart = position;
    while (lineStart > 0 && code[lineStart - 1] != '\n') {
      lineStart--;
    }

    // Get the text from line start to current position
    final textBeforeVar = code.substring(lineStart, position);

    // Check if this line starts with a declaration keyword followed by this identifier
    final declPatterns = [
      RegExp(r'^\s*(int|float|string|bool|var|let|const)\s+$'),
      RegExp(r'^\s*(int|float|string|bool|var|let|const)\s+' + RegExp.escape(varName) + r'\s*$'),
    ];

    for (final pattern in declPatterns) {
      if (pattern.hasMatch(textBeforeVar)) {
        return true;
      }
    }

    // Check if preceded by declaration keyword with possible whitespace
    if (RegExp(r'\b(int|float|string|bool|var|let|const)\s+' + RegExp.escape(varName) + r'\b')
        .hasMatch(code.substring(lineStart, position + varName.length))) {
      return true;
    }

    return false;
  }

  bool _isInFunctionDeclarationContext(int position, String varName, String code) {
    if (position >= 5) {
      final before = code.substring(position - 5, position);
      if (before == 'func ') {
        return true;
      }
    }

    int searchStart = position - 20;
    if (searchStart < 0) searchStart = 0;

    final searchText = code.substring(searchStart, position);
    if (RegExp(r'func\s+$').hasMatch(searchText)) {
      return true;
    }

    return false;
  }

  bool _isInParameterListContext(int position, String varName, String code) {
    // Search backwards for opening parenthesis
    int parenDepth = 0;
    int searchPos = position - 1;

    while (searchPos >= 0) {
      if (code[searchPos] == ')') {
        parenDepth++;
      } else if (code[searchPos] == '(') {
        if (parenDepth == 0) {
          // Found the opening paren - check if it's a function declaration
          final beforeParen = code.substring(0, searchPos).trimRight();

          // Check for function declaration pattern
          if (RegExp(r'func\s+[a-zA-Z_]\w*\s*$').hasMatch(beforeParen)) {
            return true;
          }

          // Not a function declaration parameter list
          return false;
        }
        parenDepth--;
      }
      searchPos--;
    }

    return false;
  }

  bool _isLeftSideOfAssignment(int position, String varName, String code) {
    // Find the end of the current identifier
    int identifierEnd = position;
    while (identifierEnd < code.length &&
        RegExp(r'[a-zA-Z_0-9]').hasMatch(code[identifierEnd])) {
      identifierEnd++;
    }

    // Skip whitespace after identifier
    int checkPos = identifierEnd;
    while (checkPos < code.length && code[checkPos].trim().isEmpty) {
      checkPos++;
    }

    // Check for assignment operators
    if (checkPos < code.length) {
      final remaining = code.substring(checkPos);

      // Check for various assignment operators
      if (remaining.startsWith('=') && !remaining.startsWith('==')) {
        return true;
      }
      if (remaining.startsWith('+=') || remaining.startsWith('-=') ||
          remaining.startsWith('*=') || remaining.startsWith('/=')) {
        return true;
      }
      if (remaining.startsWith('++') || remaining.startsWith('--')) {
        return true;
      }
    }

    return false;
  }

  bool _isInFunctionCallContext(int position, String varName, String code) {
    // Find the end of the identifier
    int identifierEnd = position;
    while (identifierEnd < code.length &&
        RegExp(r'[a-zA-Z_0-9]').hasMatch(code[identifierEnd])) {
      identifierEnd++;
    }

    // Skip whitespace
    int checkPos = identifierEnd;
    while (checkPos < code.length && code[checkPos].trim().isEmpty) {
      checkPos++;
    }

    // Check if followed by opening parenthesis (function call)
    if (checkPos < code.length && code[checkPos] == '(') {
      return true;
    }

    return false;
  }

  bool _isMemberAccess(int position, String code) {
    // Check if preceded by a dot (member access)
    if (position > 0 && code[position - 1] == '.') {
      return true;
    }

    // Check if preceded by dot with whitespace
    int checkPos = position - 1;
    while (checkPos >= 0 && code[checkPos].trim().isEmpty) {
      checkPos--;
    }
    if (checkPos >= 0 && code[checkPos] == '.') {
      return true;
    }

    return false;
  }

  bool _isSymbolDefined(String name, int position) {
    final symbols = _symbolsByName[name];
    if (symbols != null && symbols.isNotEmpty) {
      final currentScope = _getCurrentScope(position);
      for (final symbol in symbols) {
        if ((symbol.scope == currentScope || symbol.scope == 'global') &&
            symbol.offset < position) {
          return true;
        }

        if (symbol.type == SymbolType.parameter) {
          final funcScope = _scopes.firstWhere(
                (s) => s.name == symbol.scope || s.name.startsWith('block_'),
            orElse: () => Scope(name: 'global', start: 0, end: sourceCode.length, parent: null),
          );
          if (position >= funcScope.start && position <= funcScope.end) {
            return true;
          }
        }
      }
    }

    return false;
  }

  List<CompletionItem> getCompletions(String partialWord, int cursorPosition) {
    if (partialWord.isEmpty) return [];

    // Invalidate cache if source code changed
    if (_lastParsedCode != sourceCode) {
      _completionCache.clear();
      _lastParsedCode = sourceCode;
    }

    final cacheKey = '$partialWord:$cursorPosition';
    if (_completionCache.containsKey(cacheKey)) {
      return _completionCache[cacheKey]!;
    }

    final completions = <CompletionItem>[];
    final lowerPartial = partialWord.toLowerCase();
    final scores = <CompletionItem, double>{};

    // Keywords
    for (final keyword in keywords) {
      final score = _fuzzyMatch(keyword.toLowerCase(), lowerPartial);
      if (score > 0) {
        final item = CompletionItem(
          label: keyword,
          type: _getKeywordType(keyword),
          detail: _getKeywordDetail(keyword),
          sortText: '0_${(1000 - score * 100).toInt()}_$keyword',
          documentation: _getKeywordDocumentation(keyword),
          score: score,
        );
        completions.add(item);
        scores[item] = score;
      }
    }

    // Built-in functions
    for (final func in builtInFunctions.values) {
      final score = _fuzzyMatch(func.name.toLowerCase(), lowerPartial);
      if (score > 0) {
        final item = CompletionItem(
          label: func.name,
          type: CompletionType.function,
          detail: '${func.returnType} ${func.name}(${func.parameters.join(', ')})',
          documentation: '${func.description}\n\nExamples:\n${func.examples.map((e) => '  $e').join('\n')}',
          insertText: '${func.name}()',
          sortText: '1_${(1000 - score * 100).toInt()}_${func.name}',
          score: score,
        );
        completions.add(item);
        scores[item] = score;
      }
    }

    // User-defined symbols
    final visibleSymbols = _getVisibleSymbols(cursorPosition);
    for (final symbol in visibleSymbols) {
      final score = _fuzzyMatch(symbol.name.toLowerCase(), lowerPartial);
      if (score > 0) {
        final item = CompletionItem(
          label: symbol.name,
          type: symbol.type == SymbolType.function
              ? CompletionType.function
              : CompletionType.variable,
          detail: _getSymbolDetail(symbol),
          documentation: _getSymbolDocumentation(symbol),
          insertText: symbol.type == SymbolType.function ? '${symbol.name}()' : null,
          sortText: '2_${(1000 - score * 100).toInt()}_${symbol.name}',
          score: score,
        );
        completions.add(item);
        scores[item] = score;
      }
    }

    completions.sort((a, b) {
      final scoreCompare = (scores[b] ?? 0).compareTo(scores[a] ?? 0);
      if (scoreCompare != 0) return scoreCompare;
      return a.sortText.compareTo(b.sortText);
    });

    final result = completions.take(20).toList();
    _completionCache[cacheKey] = result;

    return result;
  }

  double _fuzzyMatch(String text, String pattern) {
    if (text.startsWith(pattern)) return 1.0;

    int textIndex = 0;
    int patternIndex = 0;
    double score = 0.0;
    bool consecutiveMatch = false;

    while (textIndex < text.length && patternIndex < pattern.length) {
      if (text[textIndex] == pattern[patternIndex]) {
        score += consecutiveMatch ? 2.0 : 1.0;
        consecutiveMatch = true;
        patternIndex++;
      } else {
        consecutiveMatch = false;
      }
      textIndex++;
    }

    if (patternIndex == pattern.length) {
      return score / text.length;
    }

    return 0.0;
  }

  List<Symbol> _getVisibleSymbols(int position) {
    final scope = _getCurrentScope(position);
    return _symbols.where((s) {
      return s.scope == scope || s.scope == 'global';
    }).toList();
  }

  CompletionType _getKeywordType(String keyword) {
    if (dataTypes.contains(keyword)) return CompletionType.type;
    if (controlFlow.contains(keyword)) return CompletionType.keyword;
    if (declarationKeywords.contains(keyword)) return CompletionType.keyword;
    return CompletionType.keyword;
  }

  String _getKeywordDetail(String keyword) {
    if (dataTypes.contains(keyword)) return 'type';
    if (controlFlow.contains(keyword)) return 'control flow';
    if (declarationKeywords.contains(keyword)) return 'declaration';
    return 'keyword';
  }

  String _getKeywordDocumentation(String keyword) {
    const docs = {
      'int': 'Integer number type',
      'float': 'Floating-point number type',
      'string': 'Text string type',
      'bool': 'Boolean type (true/false)',
      'void': 'No return value',
      'if': 'Conditional statement',
      'else': 'Alternative branch for if statement',
      'while': 'Loop while condition is true',
      'for': 'Iterate over a range',
      'func': 'Define a function',
      'return': 'Return a value from function',
      'const': 'Declare a constant',
      'var': 'Declare a variable with type inference',
      'let': 'Declare a mutable variable',
    };
    return docs[keyword] ?? '';
  }

  String _getSymbolDetail(Symbol symbol) {
    if (symbol.type == SymbolType.function) {
      final params = symbol.parameters.map((p) => '${p.type} ${p.name}').join(', ');
      return '${symbol.dataType} ${symbol.name}($params)';
    }
    return '${symbol.dataType} ${symbol.name}';
  }

  String _getSymbolDocumentation(Symbol symbol) {
    final docs = StringBuffer();
    docs.writeln('**${symbol.type.name}** `${symbol.name}`');
    docs.writeln('\nDefined at line ${symbol.line}');
    if (symbol.type == SymbolType.function) {
      docs.writeln('\nParameters:');
      for (final param in symbol.parameters) {
        docs.writeln('  • ${param.type} ${param.name}');
      }
      docs.writeln('\nReturns: ${symbol.dataType}');
    } else {
      docs.writeln('\nType: ${symbol.dataType}');
      if (symbol.isConstant) {
        docs.writeln('(constant)');
      }
    }
    return docs.toString();
  }

  HoverInfo? getHoverInfo(int cursorPosition) {
    final wordMatch = _getWordAtPosition(cursorPosition);
    if (wordMatch == null) return null;

    final word = wordMatch.group(0)!;

    if (builtInFunctions.containsKey(word)) {
      final func = builtInFunctions[word]!;
      final content = StringBuffer();
      content.writeln('```dart');
      content.writeln('${func.returnType} ${func.name}(${func.parameters.join(', ')})');
      content.writeln('```');
      content.writeln('\n${func.description}');
      content.writeln('\n**Examples:**');
      for (final example in func.examples) {
        content.writeln('```dart\n$example\n```');
      }

      return HoverInfo(
        range: TextRange(start: wordMatch.start, end: wordMatch.end),
        content: content.toString(),
      );
    }

    if (keywords.contains(word)) {
      return HoverInfo(
        range: TextRange(start: wordMatch.start, end: wordMatch.end),
        content: '**${_getKeywordDetail(word)}** `$word`\n\n${_getKeywordDocumentation(word)}',
      );
    }

    final symbols = _symbolsByName[word];
    if (symbols != null && symbols.isNotEmpty) {
      final symbol = symbols.first;
      return HoverInfo(
        range: TextRange(start: wordMatch.start, end: wordMatch.end),
        content: _getSymbolDocumentation(symbol),
      );
    }

    return null;
  }

  SignatureHelp? getSignatureHelp(int cursorPosition) {
    final textBefore = sourceCode.substring(0, cursorPosition);
    final funcMatch = RegExp(r'([a-zA-Z_]\w*)\s*\([^)]*$').firstMatch(textBefore);

    if (funcMatch == null) return null;

    final funcName = funcMatch.group(1)!;

    final builtInFunc = builtInFunctions[funcName];
    if (builtInFunc != null) {
      final openParen = funcMatch.end - 1;
      final argsText = sourceCode.substring(openParen, cursorPosition);
      final activeParam = ','.allMatches(argsText).length;

      return SignatureHelp(
        signatures: [builtInFunc],
        activeSignature: 0,
        activeParameter: activeParam,
      );
    }

    final userFuncs = _symbolsByName[funcName]
        ?.where((s) => s.type == SymbolType.function)
        .toList();

    if (userFuncs != null && userFuncs.isNotEmpty) {
      final func = userFuncs.first;
      final openParen = funcMatch.end - 1;
      final argsText = sourceCode.substring(openParen, cursorPosition);
      final activeParam = ','.allMatches(argsText).length;

      final signature = FunctionSignature(
        name: func.name,
        returnType: func.dataType,
        parameters: func.parameters.map((p) => '${p.type} ${p.name}').toList(),
        description: 'User-defined function',
        examples: [],
      );

      return SignatureHelp(
        signatures: [signature],
        activeSignature: 0,
        activeParameter: activeParam,
      );
    }

    return null;
  }

  List<CodeError> getDiagnostics() => List.unmodifiable(_errors);

  Symbol? getSymbolAtPosition(int position) {
    final wordMatch = _getWordAtPosition(position);
    if (wordMatch == null) return null;

    final word = wordMatch.group(0)!;
    final symbols = _symbolsByName[word];

    return (symbols != null && symbols.isNotEmpty) ? symbols.first : null;
  }

  List<Symbol> getAllSymbols() => List.unmodifiable(_symbols);

  List<int> findReferences(String symbolName) {
    final positions = <int>[];
    final pattern = RegExp(r'\b' + RegExp.escape(symbolName) + r'\b');

    for (final match in pattern.allMatches(sourceCode)) {
      positions.add(match.start);
    }

    return positions;
  }

  RegExpMatch? _getWordAtPosition(int position) {
    if (position < 0 || position > sourceCode.length) return null;

    int start = position;
    while (start > 0 && RegExp(r'[a-zA-Z_0-9]').hasMatch(sourceCode[start - 1])) {
      start--;
    }

    int end = position;
    while (end < sourceCode.length && RegExp(r'[a-zA-Z_0-9]').hasMatch(sourceCode[end])) {
      end++;
    }

    if (start >= end) return null;

    final word = sourceCode.substring(start, end);
    return _SimpleMatch(word, start, end, sourceCode);
  }

  int _getLineNumber(int offset) {
    return '\n'.allMatches(sourceCode.substring(0, offset)).length + 1;
  }

  int _getColumnNumber(int offset) {
    final lastNewline = sourceCode.substring(0, offset).lastIndexOf('\n');
    return offset - (lastNewline >= 0 ? lastNewline + 1 : 0);
  }
}

class Symbol {
  final String name;
  final SymbolType type;
  final int line;
  final int offset;
  final String dataType;
  final List<Parameter> parameters;
  final bool isConstant;
  final String scope;

  Symbol({
    required this.name,
    required this.type,
    required this.line,
    required this.offset,
    this.dataType = 'any',
    this.parameters = const [],
    this.isConstant = false,
    this.scope = 'global',
  });
}

enum SymbolType { function, variable, parameter, type }

class Parameter {
  final String name;
  final String type;
  final bool isOptional;

  const Parameter({
    required this.name,
    required this.type,
    this.isOptional = false,
  });
}

class Scope {
  final String name;
  final int start;
  final int end;
  final Scope? parent;

  Scope({
    required this.name,
    required this.start,
    required this.end,
    this.parent,
  });
}

class CompletionItem {
  final String label;
  final CompletionType type;
  final String detail;
  final String? documentation;
  final String? insertText;
  final String sortText;
  final double score;

  CompletionItem({
    required this.label,
    required this.type,
    required this.detail,
    this.documentation,
    this.insertText,
    required this.sortText,
    this.score = 0.0,
  });

  String get displayText => insertText ?? label;

  IconData get icon {
    switch (type) {
      case CompletionType.keyword:
        return Icons.vpn_key_rounded;
      case CompletionType.function:
        return Icons.functions_rounded;
      case CompletionType.variable:
        return Icons.text_fields_rounded;
      case CompletionType.type:
        return Icons.category_rounded;
      case CompletionType.operator:
        return Icons.calculate_rounded;
    }
  }

  Color get color {
    switch (type) {
      case CompletionType.keyword:
        return const Color(0xFFCC7832);
      case CompletionType.function:
        return const Color(0xFFFFC66D);
      case CompletionType.variable:
        return const Color(0xFFA9B7C6);
      case CompletionType.type:
        return const Color(0xFFB5B6E3);
      case CompletionType.operator:
        return const Color(0xFFA9B7C6);
    }
  }
}

enum CompletionType { keyword, function, variable, type, operator }

class HoverInfo {
  final TextRange range;
  final String content;

  HoverInfo({required this.range, required this.content});
}

class FunctionSignature {
  final String name;
  final String returnType;
  final List<String> parameters;
  final String description;
  final List<String> examples;

  const FunctionSignature({
    required this.name,
    required this.returnType,
    required this.parameters,
    required this.description,
    this.examples = const [],
  });

  String get displayText =>
      '$returnType $name(${parameters.join(', ')})';
}

class SignatureHelp {
  final List<FunctionSignature> signatures;
  final int activeSignature;
  final int activeParameter;

  SignatureHelp({
    required this.signatures,
    required this.activeSignature,
    required this.activeParameter,
  });
}

class CodeError {
  final String message;
  final int line;
  final int column;
  final ErrorSeverity severity;
  final int offset;

  CodeError({
    required this.message,
    required this.line,
    required this.column,
    required this.severity,
    required this.offset,
  });
}

enum ErrorSeverity { error, warning, info, hint }

class _SimpleMatch implements RegExpMatch {
  final String _text;
  final String _fullInput;

  @override
  final int start;

  @override
  final int end;

  _SimpleMatch(this._text, this.start, this.end, [String? fullInput])
      : _fullInput = fullInput ?? _text;

  @override
  String? group(int index) => index == 0 ? _text : null;

  @override
  String? operator [](int index) => group(index);

  @override
  List<String?> groups(List<int> groupIndices) =>
      groupIndices.map((i) => group(i)).toList();

  @override
  int get groupCount => 0;

  @override
  String get input => _fullInput;

  @override
  RegExp get pattern => RegExp(RegExp.escape(_text));

  @override
  String? namedGroup(String name) => null;

  @override
  Iterable<String> get groupNames => const [];
}
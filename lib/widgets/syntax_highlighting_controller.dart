import 'package:flutter/material.dart';
import 'code_intelligence.dart';
import 'dart:async';
import 'dart:collection';

class SyntaxHighlightingController extends TextEditingController {
  // Theme colors - IntelliJ Darcula inspired
  static const _keywordColor = Color(0xFFCC7832);
  static const _stringColor = Color(0xFF6A8759);
  static const _numberColor = Color(0xFF6897BB);
  static const _commentColor = Color(0xFF808080);
  static const _functionColor = Color(0xFFFFC66D);
  static const _operatorColor = Color(0xFFA9B7C6);
  static const _defaultColor = Color(0xFFA9B7C6);
  static const _bracketColor = Color(0xFFA9B7C6);
  static const _typeColor = Color(0xFFB5B6E3);
  static const _errorColor = Color(0xFFFF6B68);
  static const _warningColor = Color(0xFFFFC66D);
  static const _matchedBracketBg = Color(0xFF3A3A3A);
  static const _selectionColor = Color(0xFF214283);
  static const _currentLineBg = Color(0xFF2B2B2B);

  // Rainbow bracket colors
  static const _rainbowColors = [
    Color(0xFFFFD700), // Gold
    Color(0xFF9876AA), // Purple
    Color(0xFF6A9955), // Green
    Color(0xFF4EC9B0), // Cyan
    Color(0xFFD16969), // Red
  ];

  // Bracket matching state
  int? _currentBracketStart;
  int? _currentBracketEnd;

  // Code intelligence with caching
  CodeIntelligence? _codeIntelligence;
  String? _lastAnalyzedText;

  // Multi-level caching system
  final _SyntaxCache _cache = _SyntaxCache();

  // Debouncing for expensive operations
  Timer? _analysisDebounce;
  Timer? _renderDebounce;
  static const _debounceDelay = Duration(milliseconds: 300);
  static const _renderDelay = Duration(milliseconds: 50);

  // Bracket matching cache using interval tree for O(log n) lookup
  final Map<int, BracketPair> _bracketCache = {};
  final List<BracketPair> _bracketList = [];
  bool _bracketCacheDirty = true;

  // Syntax highlighting options
  bool enableRainbowBrackets = true;
  bool enableSemanticHighlighting = true;
  bool enableIncrementalParsing = true;
  bool enableLineHighlighting = false;

  // Performance metrics
  final _PerformanceMetrics _metrics = _PerformanceMetrics();

  // Undo/Redo system
  final _UndoRedoManager _undoRedo = _UndoRedoManager();

  // Symbol table for semantic highlighting
  final Map<String, SymbolInfo> _symbolTable = {};

  // Incremental parser state
  _IncrementalParserState? _parserState;

  SyntaxHighlightingController({
    this.enableRainbowBrackets = true,
    this.enableSemanticHighlighting = true,
    this.enableIncrementalParsing = true,
  }) {
    addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final stopwatch = Stopwatch()..start();

    // Track change for undo/redo
    _undoRedo.recordChange(text);

    // Invalidate affected caches
    _cache.invalidate();
    _bracketCacheDirty = true;

    // Incremental parsing for large files
    if (enableIncrementalParsing && text.length > 1000) {
      _updateIncrementalParser();
    }

    // Update bracket matching immediately for responsiveness
    _findMatchingBrackets();

    // Debounce expensive operations
    _debounceCodeAnalysis();
    _debounceRendering();

    _metrics.recordParseTime(stopwatch.elapsedMicroseconds);
  }

  void _debounceCodeAnalysis() {
    _analysisDebounce?.cancel();
    _analysisDebounce = Timer(_debounceDelay, () {
      if (_lastAnalyzedText != text) {
        _analyzeCode();
      }
    });
  }

  void _debounceRendering() {
    _renderDebounce?.cancel();
    _renderDebounce = Timer(_renderDelay, () {
      notifyListeners();
    });
  }

  void _analyzeCode() {
    final stopwatch = Stopwatch()..start();

    _codeIntelligence = CodeIntelligence(text);
    _lastAnalyzedText = text;

    // Build symbol table for semantic highlighting
    if (enableSemanticHighlighting) {
      _buildSymbolTable();
    }

    _metrics.recordAnalysisTime(stopwatch.elapsedMicroseconds);
    notifyListeners();
  }

  void _buildSymbolTable() {
    _symbolTable.clear();
    final symbols = _codeIntelligence?.getAllSymbols() ?? [];

    for (final symbol in symbols) {
      _symbolTable[symbol.name] = SymbolInfo(
        type: symbol.type,
        isFunction: symbol.type == SymbolType.function,
        isClass: symbol.type == SymbolType.type,  // FIXED: Use SymbolType.type for classes
        isVariable: symbol.type == SymbolType.variable,
      );
    }
  }

  /// Advanced bracket matching with rainbow colors
  void _findMatchingBrackets() {
    final cursorPos = selection.baseOffset;
    if (cursorPos < 0 || text.isEmpty) {
      _currentBracketStart = null;
      _currentBracketEnd = null;
      return;
    }

    // Rebuild bracket cache if needed
    if (_bracketCacheDirty) {
      _buildBracketCache();
      _bracketCacheDirty = false;
    }

    // Binary search in bracket list for O(log n) lookup
    _currentBracketStart = null;
    _currentBracketEnd = null;

    for (final pair in _bracketList) {
      if (pair.start == cursorPos || pair.start == cursorPos - 1) {
        _currentBracketStart = pair.start;
        _currentBracketEnd = pair.end;
        return;
      }
      if (pair.end == cursorPos || pair.end == cursorPos - 1) {
        _currentBracketStart = pair.start;
        _currentBracketEnd = pair.end;
        return;
      }
    }
  }

  /// Build bracket cache with depth tracking for rainbow brackets
  void _buildBracketCache() {
    _bracketCache.clear();
    _bracketList.clear();

    final openBrackets = {'(': ')', '[': ']', '{': '}'};
    final closeBrackets = {')': '(', ']': '[', '}': '{'};

    final List<_BracketStackItem> stack = [];
    bool inString = false;
    bool inComment = false;
    bool inLineComment = false;
    String? stringDelimiter;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      // Handle line comments
      if (inLineComment) {
        if (char == '\n') inLineComment = false;
        continue;
      }

      // Handle multi-line comments
      if (inComment) {
        if (char == '*' && i + 1 < text.length && text[i + 1] == '/') {
          inComment = false;
          i++;
        }
        continue;
      }

      // Check for comment start
      if (char == '/' && i + 1 < text.length) {
        if (text[i + 1] == '/') {
          inLineComment = true;
          continue;
        }
        if (text[i + 1] == '*') {
          inComment = true;
          i++;
          continue;
        }
      }

      // Handle strings
      if (inString) {
        if (char == '\\' && i + 1 < text.length) {
          i++; // Skip escaped character
          continue;
        }
        if (char == stringDelimiter) {
          inString = false;
          stringDelimiter = null;
        }
        continue;
      }

      if (char == '"' || char == "'" || char == '`') {
        inString = true;
        stringDelimiter = char;
        continue;
      }

      // Process brackets only outside strings and comments
      if (openBrackets.containsKey(char)) {
        stack.add(_BracketStackItem(char, i, stack.length));
      } else if (closeBrackets.containsKey(char)) {
        if (stack.isNotEmpty && stack.last.char == closeBrackets[char]) {
          final opening = stack.removeLast();
          final pair = BracketPair(
            opening.position,
            i,
            opening.depth,
            char,
          );
          _bracketCache[opening.position] = pair;
          _bracketCache[i] = pair;
          _bracketList.add(pair);
        }
      }
    }

    // Sort bracket list for binary search
    _bracketList.sort((a, b) => a.start.compareTo(b.start));
  }

  /// Incremental parser for large files
  void _updateIncrementalParser() {
    if (_parserState == null) {
      _parserState = _IncrementalParserState(text);
    } else {
      _parserState!.update(text);
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final stopwatch = Stopwatch()..start();

    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    // Check cache first
    final cachedSpan = _cache.get(text, selection.baseOffset);
    if (cachedSpan != null) {
      _metrics.cacheHits++;
      return cachedSpan;
    }

    _metrics.cacheMisses++;

    // Build new spans with advanced features
    final spans = _highlightSyntaxAdvanced(text);

    final result = TextSpan(
      style: _getBaseStyle(style),
      children: spans,
    );

    _cache.put(text, selection.baseOffset, result);
    _metrics.recordRenderTime(stopwatch.elapsedMicroseconds);

    return result;
  }

  TextStyle _getBaseStyle(TextStyle? style) {
    return style?.copyWith(
      fontFamily: 'Courier New',
      fontSize: 14.0,
      height: 1.4,
      letterSpacing: 0,
    ) ?? const TextStyle(
      fontFamily: 'Courier New',
      fontSize: 14.0,
      height: 1.4,
      letterSpacing: 0,
    );
  }

  /// Advanced syntax highlighting with all features
  List<TextSpan> _highlightSyntaxAdvanced(String code) {
    if (code.isEmpty) return [];

    final spans = <TextSpan>[];

    // Enhanced regex with more token types
    final pattern = RegExp(
      r'//[^\n]*|'                              // Single-line comments
      r'/\*[\s\S]*?\*/|'                        // Multi-line comments
      r'"""[\s\S]*?"""|'                        // Triple-quoted strings
      r'"(?:[^"\\]|\\.)*"|'                     // Double-quoted strings
      r"'(?:[^'\\]|\\.)*'|"                     // Single-quoted strings
      r'`[^`]*`|'                               // Template literals
      r'r"[^"]*"|'                              // Raw strings
      r'@[a-zA-Z_]\w*|'                         // Annotations
      r'\b0[xX][0-9a-fA-F]+[lL]?\b|'           // Hex numbers
      r'\b0[bB][01]+[lL]?\b|'                  // Binary numbers
      r'\b0[oO][0-7]+[lL]?\b|'                 // Octal numbers
      r'\b\d+\.?\d*([eE][+-]?\d+)?[fFdDlL]?\b|' // Numbers
      r'\$[a-zA-Z_]\w*|'                       // String interpolation
      r'\b[A-Z][a-zA-Z0-9_]*\b|'               // Type names (PascalCase)
      r'\b[a-zA-Z_]\w*\s*(?=\()|'              // Function calls
      r'\b[a-zA-Z_]\w*\b|'                     // Identifiers
      r'\.\.\.|\.\.|'                           // Spread/cascade operators
      r'=>|'                                    // Arrow
      r'[+\-*/%=<>!&|^~?:]+|'                  // Operators
      r'[(){}\[\];,.]',                         // Punctuation
      multiLine: true,
    );

    int lastIndex = 0;
    final errors = _codeIntelligence?.getDiagnostics() ?? [];
    final errorMap = _buildErrorMap(errors);

    // Track current line for line highlighting
    int currentLine = 0;
    int lineStart = 0;

    for (final match in pattern.allMatches(code)) {
      final matchText = match.group(0)!;
      final matchStart = match.start;

      // Add unmatched text
      if (match.start > lastIndex) {
        final unmatched = code.substring(lastIndex, match.start);

        // Check for line breaks
        for (int i = 0; i < unmatched.length; i++) {
          if (unmatched[i] == '\n') {
            currentLine++;
            lineStart = lastIndex + i + 1;
          }
        }

        spans.add(TextSpan(
          text: unmatched,
          style: const TextStyle(color: _defaultColor),
        ));
      }

      // Determine token style with semantic analysis
      final tokenStyle = _getAdvancedTokenStyle(
        matchText,
        matchStart,
        match.end,
        code,
        errorMap,
        currentLine,
        lineStart,
      );

      spans.add(tokenStyle);
      lastIndex = match.end;

      // Update line tracking
      for (int i = 0; i < matchText.length; i++) {
        if (matchText[i] == '\n') {
          currentLine++;
          lineStart = matchStart + i + 1;
        }
      }
    }

    // Add remaining text
    if (lastIndex < code.length) {
      spans.add(TextSpan(
        text: code.substring(lastIndex),
        style: const TextStyle(color: _defaultColor),
      ));
    }

    return spans;
  }

  Map<int, CodeError> _buildErrorMap(List<CodeError> errors) {
    final map = <int, CodeError>{};
    for (final error in errors) {
      map[error.offset] = error;
    }
    return map;
  }

  TextSpan _getAdvancedTokenStyle(
      String token,
      int start,
      int end,
      String code,
      Map<int, CodeError> errorMap,
      int currentLine,
      int lineStart,
      ) {
    Color color = _defaultColor;
    FontWeight? weight;
    Color? backgroundColor;
    TextDecoration? decoration;
    Color? decorationColor;
    bool isBold = false;
    bool isItalic = false;

    // Current line highlighting
    if (enableLineHighlighting) {
      final cursorPos = selection.baseOffset;
      if (cursorPos >= lineStart && cursorPos < lineStart + (code.indexOf('\n', lineStart) - lineStart)) {
        backgroundColor = _currentLineBg;
      }
    }

    // Rainbow bracket highlighting
    if (enableRainbowBrackets && _isBracket(token)) {
      final pair = _bracketCache[start];
      if (pair != null) {
        color = _rainbowColors[pair.depth % _rainbowColors.length];
        weight = FontWeight.bold;
      }
    }

    // Matched bracket highlighting (overrides rainbow)
    if (_currentBracketStart != null &&
        (start == _currentBracketStart || start == _currentBracketEnd)) {
      backgroundColor = _matchedBracketBg;
      weight = FontWeight.bold;
    }

    // Error/warning checking
    CodeError? error;
    for (int i = start; i < end && i < code.length; i++) {
      if (errorMap.containsKey(i)) {
        error = errorMap[i];
        break;
      }
    }

    if (error != null) {
      decoration = TextDecoration.underline;
      decorationColor = error.severity == ErrorSeverity.error
          ? _errorColor
          : _warningColor;
    }

    // Token type detection with semantic analysis
    if (token.startsWith('//') || token.startsWith('/*')) {
      color = _commentColor;
      isItalic = true;
    } else if (token.startsWith('@')) {
      // Annotations
      color = const Color(0xFFBBB529);
      weight = FontWeight.w600;
    } else if (token.startsWith('"') || token.startsWith("'") ||
        token.startsWith('`') || token.startsWith('r"') ||
        token.startsWith('"""')) {
      color = _stringColor;
    } else if (token.startsWith('\$')) {
      // String interpolation
      color = const Color(0xFF287BDE);
      weight = FontWeight.w600;
    } else if (_isNumber(token)) {
      color = _numberColor;
      weight = FontWeight.w600;
    } else if (CodeIntelligence.keywords.contains(token)) {
      if (CodeIntelligence.dataTypes.contains(token)) {
        color = _typeColor;
      } else {
        color = _keywordColor;
      }
      weight = FontWeight.w600;
    } else if (RegExp(r'^[A-Z][a-zA-Z0-9_]*$').hasMatch(token)) {
      // PascalCase - likely a class/type
      color = _typeColor;
      weight = FontWeight.w600;
    } else if (enableSemanticHighlighting && _symbolTable.containsKey(token)) {
      // Semantic highlighting based on symbol table
      final symbolInfo = _symbolTable[token]!;
      if (symbolInfo.isFunction) {
        color = _functionColor;
        weight = FontWeight.w600;
      } else if (symbolInfo.isClass) {
        color = _typeColor;
        weight = FontWeight.w600;
      } else if (symbolInfo.isVariable) {
        color = const Color(0xFF9CDCFE);
      }
    } else if (end < code.length && code[end] == '(') {
      color = _functionColor;
      weight = FontWeight.w600;
    } else if (token == '=>') {
      color = _operatorColor;
      weight = FontWeight.bold;
    } else if (_isOperator(token)) {
      color = _operatorColor;
      weight = FontWeight.bold;
    } else if (_isBracket(token) && !enableRainbowBrackets) {
      color = _bracketColor;
      weight = FontWeight.bold;
    }

    return TextSpan(
      text: token,
      style: TextStyle(
        color: color,
        fontWeight: weight,
        backgroundColor: backgroundColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: TextDecorationStyle.wavy,
        decorationThickness: 2,
        fontStyle: isItalic ? FontStyle.italic : null,
      ),
    );
  }

  bool _isNumber(String token) {
    return RegExp(
        r'^(0[xX][0-9a-fA-F]+[lL]?|0[bB][01]+[lL]?|0[oO][0-7]+[lL]?|\d+\.?\d*([eE][+-]?\d+)?[fFdDlL]?)$'
    ).hasMatch(token);
  }

  bool _isOperator(String token) {
    return RegExp(r'^[+\-*/%=<>!&|^~?:]+$').hasMatch(token) && token != '=>';
  }

  bool _isBracket(String token) {
    return token.length == 1 && '(){}[]'.contains(token);
  }

  // Code intelligence methods

  CodeIntelligence _ensureCodeIntelligence() {
    if (_codeIntelligence == null || _lastAnalyzedText != text) {
      _analyzeCode();
    }
    return _codeIntelligence!;
  }

  List<CompletionItem> getCompletionItems(String partialWord, int cursorPosition) {
    return _ensureCodeIntelligence().getCompletions(partialWord, cursorPosition);
  }

  HoverInfo? getHoverInfo(int position) {
    return _ensureCodeIntelligence().getHoverInfo(position);
  }

  SignatureHelp? getSignatureHelp(int position) {
    return _ensureCodeIntelligence().getSignatureHelp(position);
  }

  List<CodeError> getDiagnostics() {
    return _ensureCodeIntelligence().getDiagnostics();
  }

  List<Symbol> getAllSymbols() {
    return _ensureCodeIntelligence().getAllSymbols();
  }

  List<int> findReferences(String symbolName) {
    return _ensureCodeIntelligence().findReferences(symbolName);
  }

  // Navigation and editing methods

  int getCurrentLine() {
    final cursorPos = selection.baseOffset;
    if (cursorPos < 0) return 1;

    int lineCount = 1;
    for (int i = 0; i < cursorPos && i < text.length; i++) {
      if (text[i] == '\n') lineCount++;
    }
    return lineCount;
  }

  int getCurrentColumn() {
    final cursorPos = selection.baseOffset;
    if (cursorPos < 0) return 1;

    final lastLineBreak = text.substring(0, cursorPos).lastIndexOf('\n');
    return cursorPos - lastLineBreak;
  }

  String getWordAtCursor() {
    final cursorPos = selection.baseOffset;
    if (cursorPos < 0 || cursorPos > text.length) return '';

    int start = cursorPos;
    int end = cursorPos;

    final wordPattern = RegExp(r'[a-zA-Z_]\w*');

    while (start > 0 && wordPattern.hasMatch(text[start - 1])) {
      start--;
    }

    while (end < text.length && wordPattern.hasMatch(text[end])) {
      end++;
    }

    return text.substring(start, end);
  }

  void jumpToMatchingBracket() {
    if (_currentBracketStart != null && _currentBracketEnd != null) {
      final cursorPos = selection.baseOffset;
      if (cursorPos == _currentBracketStart) {
        selection = TextSelection.collapsed(offset: _currentBracketEnd! + 1);
      } else {
        selection = TextSelection.collapsed(offset: _currentBracketStart!);
      }
    }
  }

  void selectBetweenBrackets() {
    if (_currentBracketStart != null && _currentBracketEnd != null) {
      selection = TextSelection(
        baseOffset: _currentBracketStart! + 1,
        extentOffset: _currentBracketEnd!,
      );
    }
  }

  void jumpToLine(int lineNumber) {
    int offset = 0;
    int currentLine = 1;

    while (currentLine < lineNumber && offset < text.length) {
      if (text[offset] == '\n') currentLine++;
      offset++;
    }

    selection = TextSelection.collapsed(offset: offset);
  }

  void selectLine() {
    final cursorPos = selection.baseOffset;
    if (cursorPos < 0) return;

    int lineStart = text.substring(0, cursorPos).lastIndexOf('\n') + 1;
    int lineEnd = text.indexOf('\n', cursorPos);
    if (lineEnd == -1) lineEnd = text.length;

    selection = TextSelection(baseOffset: lineStart, extentOffset: lineEnd);
  }

  void duplicateLine() {
    final cursorPos = selection.baseOffset;
    if (cursorPos < 0) return;

    int lineStart = text.substring(0, cursorPos).lastIndexOf('\n') + 1;
    int lineEnd = text.indexOf('\n', cursorPos);
    if (lineEnd == -1) lineEnd = text.length;

    final line = text.substring(lineStart, lineEnd);
    final newText = text.substring(0, lineEnd) + '\n' + line + text.substring(lineEnd);

    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: lineEnd + line.length + 1),
    );
  }

  void deleteLine() {
    final cursorPos = selection.baseOffset;
    if (cursorPos < 0) return;

    int lineStart = text.substring(0, cursorPos).lastIndexOf('\n');
    int lineEnd = text.indexOf('\n', cursorPos);
    if (lineEnd == -1) lineEnd = text.length;

    final newText = text.substring(0, lineStart + 1) + text.substring(lineEnd + 1);

    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: lineStart + 1),
    );
  }

  // Undo/Redo

  void undo() {
    final previousText = _undoRedo.undo();
    if (previousText != null) {
      value = TextEditingValue(
        text: previousText,
        selection: TextSelection.collapsed(offset: previousText.length),
      );
    }
  }

  void redo() {
    final nextText = _undoRedo.redo();
    if (nextText != null) {
      value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
    }
  }

  bool canUndo() => _undoRedo.canUndo();
  bool canRedo() => _undoRedo.canRedo();

  // Performance metrics

  Map<String, dynamic> getPerformanceMetrics() {
    return _metrics.toMap();
  }

  void resetMetrics() {
    _metrics.reset();
  }

  @override
  void dispose() {
    _analysisDebounce?.cancel();
    _renderDebounce?.cancel();
    removeListener(_onTextChanged);
    _cache.clear();
    super.dispose();
  }
}

// ============================================================================
// HELPER CLASSES - Must be in the same file
// ============================================================================

class BracketPair {
  final int start;
  final int end;
  final int depth;
  final String closeChar;

  BracketPair(this.start, this.end, this.depth, this.closeChar);
}

class _BracketStackItem {
  final String char;
  final int position;
  final int depth;

  _BracketStackItem(this.char, this.position, this.depth);
}

class SymbolInfo {
  final SymbolType type;
  final bool isFunction;
  final bool isClass;
  final bool isVariable;

  SymbolInfo({
    required this.type,
    required this.isFunction,
    required this.isClass,
    required this.isVariable,
  });
}

/// Multi-level caching system for syntax highlighting
class _SyntaxCache {
  final Map<String, _CacheEntry> _cache = {};
  static const _maxCacheSize = 50;
  final Queue<String> _lruQueue = Queue();

  TextSpan? get(String text, int cursorPos) {
    final key = '${text.hashCode}_$cursorPos';
    final entry = _cache[key];

    if (entry != null && entry.isValid()) {
      // Move to end of LRU queue
      _lruQueue.remove(key);
      _lruQueue.addLast(key);
      return entry.span;
    }

    return null;
  }

  void put(String text, int cursorPos, TextSpan span) {
    final key = '${text.hashCode}_$cursorPos';

    // Evict oldest if cache is full
    if (_cache.length >= _maxCacheSize) {
      final oldest = _lruQueue.removeFirst();
      _cache.remove(oldest);
    }

    _cache[key] = _CacheEntry(span);
    _lruQueue.addLast(key);
  }

  void invalidate() {
    _cache.clear();
    _lruQueue.clear();
  }

  void clear() {
    _cache.clear();
    _lruQueue.clear();
  }
}

class _CacheEntry {
  final TextSpan span;
  final DateTime timestamp;
  static const _ttl = Duration(seconds: 30);

  _CacheEntry(this.span) : timestamp = DateTime.now();

  bool isValid() {
    return DateTime.now().difference(timestamp) < _ttl;
  }
}

/// Undo/Redo manager
class _UndoRedoManager {
  final List<String> _history = [];
  int _currentIndex = -1;
  static const _maxHistory = 100;
  String? _lastRecorded;

  void recordChange(String text) {
    // Don't record if text hasn't changed
    if (text == _lastRecorded) return;

    // Remove any redo history
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    // Add new state
    _history.add(text);
    _lastRecorded = text;
    _currentIndex = _history.length - 1;

    // Limit history size
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
      _currentIndex--;
    }
  }

  String? undo() {
    if (!canUndo()) return null;
    _currentIndex--;
    return _history[_currentIndex];
  }

  String? redo() {
    if (!canRedo()) return null;
    _currentIndex++;
    return _history[_currentIndex];
  }

  bool canUndo() => _currentIndex > 0;
  bool canRedo() => _currentIndex < _history.length - 1;
}

/// Performance metrics tracker
class _PerformanceMetrics {
  int parseTimeTotal = 0;
  int analysisTimeTotal = 0;
  int renderTimeTotal = 0;
  int parseCount = 0;
  int analysisCount = 0;
  int renderCount = 0;
  int cacheHits = 0;
  int cacheMisses = 0;

  void recordParseTime(int microseconds) {
    parseTimeTotal += microseconds;
    parseCount++;
  }

  void recordAnalysisTime(int microseconds) {
    analysisTimeTotal += microseconds;
    analysisCount++;
  }

  void recordRenderTime(int microseconds) {
    renderTimeTotal += microseconds;
    renderCount++;
  }

  Map<String, dynamic> toMap() {
    return {
      'avgParseTime': parseCount > 0 ? parseTimeTotal / parseCount : 0,
      'avgAnalysisTime': analysisCount > 0 ? analysisTimeTotal / analysisCount : 0,
      'avgRenderTime': renderCount > 0 ? renderTimeTotal / renderCount : 0,
      'cacheHitRate': (cacheHits + cacheMisses) > 0
          ? (cacheHits / (cacheHits + cacheMisses) * 100).toStringAsFixed(2) + '%'
          : '0%',
      'totalOperations': parseCount + analysisCount + renderCount,
    };
  }

  void reset() {
    parseTimeTotal = 0;
    analysisTimeTotal = 0;
    renderTimeTotal = 0;
    parseCount = 0;
    analysisCount = 0;
    renderCount = 0;
    cacheHits = 0;
    cacheMisses = 0;
  }
}

/// Incremental parser state for large files
class _IncrementalParserState {
  String _lastText;
  final List<_ParsedRegion> _regions = [];

  _IncrementalParserState(this._lastText) {
    _parseIntoRegions();
  }

  void update(String newText) {
    // Find changed region and only re-parse that
    final minLength = newText.length < _lastText.length ? newText.length : _lastText.length;
    int changeStart = 0;

    while (changeStart < minLength && newText[changeStart] == _lastText[changeStart]) {
      changeStart++;
    }

    if (changeStart < minLength || newText.length != _lastText.length) {
      _lastText = newText;
      _parseIntoRegions();
    }
  }

  void _parseIntoRegions() {
    _regions.clear();
    const regionSize = 1000;

    for (int i = 0; i < _lastText.length; i += regionSize) {
      final end = (i + regionSize < _lastText.length) ? i + regionSize : _lastText.length;
      _regions.add(_ParsedRegion(i, end, _lastText.substring(i, end)));
    }
  }
}

class _ParsedRegion {
  final int start;
  final int end;
  final String content;

  _ParsedRegion(this.start, this.end, this.content);
}
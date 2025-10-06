import 'package:flutter/material.dart';
import 'code_intelligence.dart';

class SyntaxHighlightingController extends TextEditingController {

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

  int? _currentBracketStart;
  int? _currentBracketEnd;

  // Code intelligence instance
  CodeIntelligence? _codeIntelligence;
  String? _lastAnalyzedText;

  SyntaxHighlightingController() {
    addListener(_updateBracketMatching);
  }

  void _updateBracketMatching() {
    _findMatchingBrackets();
  }

  void _findMatchingBrackets() {
    final cursorPos = selection.baseOffset;
    if (cursorPos < 0 || cursorPos >= text.length) {
      _currentBracketStart = null;
      _currentBracketEnd = null;
      return;
    }

    final bracketMap = {'(': ')', '[': ']', '{': '}'};
    final reverseBracketMap = {')': '(', ']': '[', '}': '{'};

    // Check if cursor is on opening bracket
    if (cursorPos < text.length && bracketMap.containsKey(text[cursorPos])) {
      final openBracket = text[cursorPos];
      final closeBracket = bracketMap[openBracket]!;
      int depth = 1;

      for (int i = cursorPos + 1; i < text.length; i++) {
        if (text[i] == openBracket) depth++;
        if (text[i] == closeBracket) depth--;

        if (depth == 0) {
          _currentBracketStart = cursorPos;
          _currentBracketEnd = i;
          return;
        }
      }
    }

    // Check if cursor is after closing bracket
    if (cursorPos > 0 && reverseBracketMap.containsKey(text[cursorPos - 1])) {
      final closeBracket = text[cursorPos - 1];
      final openBracket = reverseBracketMap[closeBracket]!;
      int depth = 1;

      for (int i = cursorPos - 2; i >= 0; i--) {
        if (text[i] == closeBracket) depth++;
        if (text[i] == openBracket) depth--;

        if (depth == 0) {
          _currentBracketStart = i;
          _currentBracketEnd = cursorPos - 1;
          return;
        }
      }
    }

    _currentBracketStart = null;
    _currentBracketEnd = null;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    if (_lastAnalyzedText != text) {
      _codeIntelligence = CodeIntelligence(text);
      _lastAnalyzedText = text;
    }

    return TextSpan(
      style: style?.copyWith(
        fontFamily: 'Courier New',
        fontSize: 14.0,
        height: 1.4,
        letterSpacing: 0,
      ),
      children: _highlightSyntax(text),
    );
  }

  List<TextSpan> _highlightSyntax(String code) {
    if (code.isEmpty) return [];

    final spans = <TextSpan>[];
    final pattern = RegExp(
      r'//[^\n]*|'
      r'"(?:[^"\\]|\\.)*"|'
      r"'(?:[^'\\]|\\.)*'|"
      r'\b\d+\.?\d*\b|'
      r'\b[a-zA-Z_]\w*\s*(?=\()|'
      r'\b[a-zA-Z_]\w*\b|'
      r'[+\-*/%=<>!&|]+|'
      r'[(){}\[\];,.]',
    );

    int lastIndex = 0;
    final errors = _codeIntelligence?.getDiagnostics() ?? [];

    for (final match in pattern.allMatches(code)) {
      final matchText = match.group(0)!;
      final matchStart = match.start;

      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: code.substring(lastIndex, match.start),
          style: const TextStyle(color: _defaultColor),
        ));
      }

      Color color = _defaultColor;
      FontWeight? weight;
      Color? backgroundColor;
      TextDecoration? decoration;

      // Highlight matching brackets
      if (_currentBracketStart != null &&
          (matchStart == _currentBracketStart || matchStart == _currentBracketEnd)) {
        backgroundColor = const Color(0xFF3A3A3A);
      }

      CodeError? errorAtPos;
      try {
        errorAtPos = errors.firstWhere(
              (e) => e.offset >= matchStart && e.offset < match.end,
          orElse: () => throw StateError('Not found'),
        );
      } catch (_) {
        errorAtPos = null;
      }

      if (errorAtPos != null) {
        decoration = TextDecoration.underline;
        // Error color based on severity
        if (errorAtPos.severity == ErrorSeverity.error) {
          decoration = TextDecoration.combine([
            TextDecoration.underline,
          ]);
        }
      }

      if (matchText.startsWith('//')) {
        color = _commentColor;
        weight = FontWeight.normal;
      } else if (matchText.startsWith('"') || matchText.startsWith("'")) {
        color = _stringColor;
        weight = FontWeight.normal;
      } else if (RegExp(r'^\d+\.?\d*$').hasMatch(matchText)) {
        color = _numberColor;
        weight = FontWeight.w600;
      } else if (CodeIntelligence.keywords.contains(matchText)) {
        // Differentiate keyword types
        if (CodeIntelligence.dataTypes.contains(matchText)) {
          color = _typeColor;
        } else {
          color = _keywordColor;
        }
        weight = FontWeight.w600;
      } else if (match.end < code.length && code[match.end] == '(') {
        color = _functionColor;
        weight = FontWeight.w600;
      } else if (RegExp(r'^[+\-*/%=<>!&|]+$').hasMatch(matchText)) {
        color = _operatorColor;
        weight = FontWeight.bold;
      } else if (RegExp(r'^[(){}\[\]]$').hasMatch(matchText)) {
        color = _bracketColor;
        weight = FontWeight.bold;
      } else if (RegExp(r'^[;,.]$').hasMatch(matchText)) {
        color = _defaultColor;
        weight = FontWeight.normal;
      }

      spans.add(TextSpan(
        text: matchText,
        style: TextStyle(
          color: color,
          fontWeight: weight,
          backgroundColor: backgroundColor,
          decoration: decoration,
          decorationColor: errorAtPos?.severity == ErrorSeverity.error
              ? _errorColor
              : _warningColor,
          decorationStyle: TextDecorationStyle.wavy,
          decorationThickness: 2,
        ),
      ));

      lastIndex = match.end;
    }

    if (lastIndex < code.length) {
      spans.add(TextSpan(
        text: code.substring(lastIndex),
        style: const TextStyle(color: _defaultColor),
      ));
    }

    return spans;
  }

  List<CompletionItem> getCompletionItems(String partialWord, int cursorPosition) {
    if (_codeIntelligence == null) {
      _codeIntelligence = CodeIntelligence(text);
    }
    return _codeIntelligence!.getCompletions(partialWord, cursorPosition);
  }

  HoverInfo? getHoverInfo(int position) {
    if (_codeIntelligence == null) {
      _codeIntelligence = CodeIntelligence(text);
    }
    return _codeIntelligence!.getHoverInfo(position);
  }

  SignatureHelp? getSignatureHelp(int position) {
    if (_codeIntelligence == null) {
      _codeIntelligence = CodeIntelligence(text);
    }
    return _codeIntelligence!.getSignatureHelp(position);
  }

  List<CodeError> getDiagnostics() {
    if (_codeIntelligence == null) {
      _codeIntelligence = CodeIntelligence(text);
    }
    return _codeIntelligence!.getDiagnostics();
  }

  List<Symbol> getAllSymbols() {
    if (_codeIntelligence == null) {
      _codeIntelligence = CodeIntelligence(text);
    }
    return _codeIntelligence!.getAllSymbols();
  }

  List<int> findReferences(String symbolName) {
    if (_codeIntelligence == null) {
      _codeIntelligence = CodeIntelligence(text);
    }
    return _codeIntelligence!.findReferences(symbolName);
  }

  int getCurrentLine() {
    final cursorPos = selection.baseOffset;
    if (cursorPos < 0) return 1;
    return '\n'.allMatches(text.substring(0, cursorPos)).length + 1;
  }

  int getCurrentColumn() {
    final cursorPos = selection.baseOffset;
    if (cursorPos < 0) return 1;
    final lastLineBreak = text.substring(0, cursorPos).lastIndexOf('\n');
    return cursorPos - lastLineBreak;
  }

  @override
  void dispose() {
    removeListener(_updateBracketMatching);
    super.dispose();
  }
}
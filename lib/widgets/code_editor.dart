import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/compiler_provider.dart';
import 'syntax_highlighting_controller.dart';
import 'code_intelligence.dart';
import 'code_folding.dart';
import 'editor_widgets.dart';
import 'editor_overlays.dart';

class CodeEditor extends StatefulWidget {
  const CodeEditor({super.key});

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> with SingleTickerProviderStateMixin {
  late final SyntaxHighlightingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _statusAnimController;
  late final ScrollController _scrollController;
  late final OverlayPortalController _autoCompleteController;
  late final OverlayPortalController _signatureHelpController;
  late final AdvancedCodeFoldingManager _foldingManager;

  bool _isHovering = false;
  int _lineCount = 1;
  int _currentLine = 1;
  int _currentColumn = 1;
  List<CompletionItem> _completions = [];
  int _selectedCompletionIndex = 0;
  final LayerLink _layerLink = LayerLink();

  SignatureHelp? _currentSignatureHelp;
  List<CodeError> _diagnostics = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialCode();
  }

  void _initializeControllers() {
    _controller = SyntaxHighlightingController();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _autoCompleteController = OverlayPortalController();
    _signatureHelpController = OverlayPortalController();
    _foldingManager = AdvancedCodeFoldingManager();
    _statusAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _controller.addListener(_updateLineCount);
    _controller.addListener(_updateCursorPosition);
    _controller.addListener(_updateDiagnostics);
    _controller.addListener(_updateFoldingRegions);
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _autoCompleteController.hide();
      _signatureHelpController.hide();
    }
  }

  void _loadInitialCode() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<CompilerProvider>();
        _updateControllerText(provider.sourceCode);
      }
    });
  }

  void _updateLineCount() {
    final newLineCount = '\n'.allMatches(_controller.text).length + 1;
    if (newLineCount != _lineCount) {
      setState(() => _lineCount = newLineCount);
    }
  }

  void _updateCursorPosition() {
    final cursorPos = _controller.selection.baseOffset;
    if (cursorPos < 0) return;

    final textBeforeCursor = _controller.text.substring(0, cursorPos);
    final newLine = '\n'.allMatches(textBeforeCursor).length + 1;
    final lastLineBreak = textBeforeCursor.lastIndexOf('\n');
    final newColumn = cursorPos - (lastLineBreak >= 0 ? lastLineBreak + 1 : 0);

    if (newLine != _currentLine || newColumn != _currentColumn) {
      setState(() {
        _currentLine = newLine;
        _currentColumn = newColumn;
      });
    }
  }

  void _updateDiagnostics() {
    final diagnostics = _controller.getDiagnostics();
    if (diagnostics.length != _diagnostics.length || !identical(diagnostics, _diagnostics)) {
      setState(() {
        _diagnostics = diagnostics;
      });
    }
  }

  void _updateFoldingRegions() {
    _foldingManager.analyzeFoldingRegions(_controller.text);
    setState(() {});
  }

  void _updateControllerText(String newText) {
    if (_controller.text != newText) {
      final cursorPos = _controller.selection.baseOffset;
      _controller.text = newText;

      final newPos = cursorPos.clamp(0, newText.length);
      _controller.selection = TextSelection.collapsed(offset: newPos);

      _foldingManager.analyzeFoldingRegions(newText);
    }
  }

  void _handleTextChange(String text) {
    _checkAutoComplete();
    _checkSignatureHelp();
  }

  void _checkAutoComplete() {
    final cursorPos = _controller.selection.baseOffset;
    if (cursorPos <= 0) {
      _autoCompleteController.hide();
      return;
    }

    final textBeforeCursor = _controller.text.substring(0, cursorPos);
    final wordMatch = RegExp(r'[a-zA-Z_]\w*$').firstMatch(textBeforeCursor);

    if (wordMatch != null) {
      final partialWord = wordMatch.group(0)!;
      if (partialWord.length >= 2) {
        final completions = _controller.getCompletionItems(partialWord, cursorPos);
        if (completions.isNotEmpty) {
          setState(() {
            _completions = completions;
            _selectedCompletionIndex = 0;
          });
          _autoCompleteController.show();
          return;
        }
      }
    }

    _autoCompleteController.hide();
  }

  void _checkSignatureHelp() {
    final cursorPos = _controller.selection.baseOffset;
    final signatureHelp = _controller.getSignatureHelp(cursorPos);

    if (signatureHelp != null) {
      setState(() {
        _currentSignatureHelp = signatureHelp;
      });
      _signatureHelpController.show();
    } else {
      _signatureHelpController.hide();
    }
  }

  void _insertCompletion(CompletionItem completion) {
    final cursorPos = _controller.selection.baseOffset;
    final textBeforeCursor = _controller.text.substring(0, cursorPos);
    final wordMatch = RegExp(r'[a-zA-Z_]\w*$').firstMatch(textBeforeCursor);

    if (wordMatch != null) {
      final startPos = wordMatch.start;
      final insertText = completion.displayText;
      final newText = _controller.text.substring(0, startPos) +
          insertText +
          _controller.text.substring(cursorPos);

      _controller.text = newText;

      int cursorOffset = startPos + insertText.length;
      if (insertText.endsWith('()')) {
        cursorOffset -= 1;
      }

      _controller.selection = TextSelection.collapsed(offset: cursorOffset);

      if (insertText.endsWith('()')) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _checkSignatureHelp();
        });
      }
    }

    _autoCompleteController.hide();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (_autoCompleteController.isShowing) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          setState(() {
            _selectedCompletionIndex = (_selectedCompletionIndex + 1) % _completions.length;
          });
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          setState(() {
            _selectedCompletionIndex = (_selectedCompletionIndex - 1) % _completions.length;
            if (_selectedCompletionIndex < 0) _selectedCompletionIndex = _completions.length - 1;
          });
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.tab) {
          _insertCompletion(_completions[_selectedCompletionIndex]);
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          _autoCompleteController.hide();
          return true;
        }
      }

      if ((event.logicalKey == LogicalKeyboardKey.keyD) &&
          (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed) &&
          !HardwareKeyboard.instance.isShiftPressed) {
        _duplicateLine();
        return true;
      }

      if ((event.logicalKey == LogicalKeyboardKey.slash) &&
          (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed)) {
        _toggleComment();
        return true;
      }

      if ((event.logicalKey == LogicalKeyboardKey.space) &&
          (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed)) {
        _checkAutoComplete();
        return true;
      }
    }
    return false;
  }

  void _duplicateLine() {
    final cursorPos = _controller.selection.baseOffset;
    final text = _controller.text;

    final lineStart = text.lastIndexOf('\n', cursorPos - 1) + 1;
    final lineEnd = text.indexOf('\n', cursorPos);
    final actualLineEnd = lineEnd == -1 ? text.length : lineEnd;

    final currentLine = text.substring(lineStart, actualLineEnd);
    final newText = text.substring(0, actualLineEnd) + '\n' + currentLine + text.substring(actualLineEnd);

    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: actualLineEnd + currentLine.length + 1);
  }

  void _toggleComment() {
    final cursorPos = _controller.selection.baseOffset;
    final text = _controller.text;

    final lineStart = text.lastIndexOf('\n', cursorPos - 1) + 1;
    final lineEnd = text.indexOf('\n', cursorPos);
    final actualLineEnd = lineEnd == -1 ? text.length : lineEnd;

    final currentLine = text.substring(lineStart, actualLineEnd);
    final trimmedLine = currentLine.trimLeft();
    final leadingSpaces = currentLine.substring(0, currentLine.length - trimmedLine.length);

    String newLine;
    int cursorOffset = 0;

    if (trimmedLine.startsWith('//')) {
      newLine = leadingSpaces + trimmedLine.substring(2).trimLeft();
      cursorOffset = -3;
    } else {
      newLine = leadingSpaces + '// ' + trimmedLine;
      cursorOffset = 3;
    }

    final newText = text.substring(0, lineStart) + newLine + text.substring(actualLineEnd);
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: cursorPos + cursorOffset);
  }

  void _formatCode() {
    final lines = _controller.text.split('\n');
    final formattedLines = <String>[];
    int indentLevel = 0;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.startsWith('}') || trimmed.startsWith(')') || trimmed.startsWith(']')) {
        indentLevel = (indentLevel - 1).clamp(0, 100);
      }

      formattedLines.add('  ' * indentLevel + trimmed);

      if (trimmed.endsWith('{') || trimmed.endsWith('(') || trimmed.endsWith('[')) {
        indentLevel++;
      }
    }

    _controller.text = formattedLines.join('\n');
    HapticFeedback.lightImpact();
  }

  void _updateStatusAnimation(CompilerState state) {
    if (state == CompilerState.idle || state == CompilerState.completed) {
      _statusAnimController.forward();
    } else {
      _statusAnimController.repeat(reverse: true);
    }
  }

  void _handleClear(CompilerProvider provider) {
    _controller.clear();
    provider.clear();
    _foldingManager.clear();
    setState(() {
      _diagnostics.clear();
    });
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _statusAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompilerProvider>(
      builder: (context, provider, _) {
        _updateControllerText(provider.sourceCode);
        _updateStatusAnimation(provider.state);

        return CompositedTransformTarget(
          link: _layerLink,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: _handleKeyEvent,
            child: Stack(
              children: [
                OverlayPortal(
                  controller: _autoCompleteController,
                  overlayChildBuilder: (context) => AutoCompleteOverlay(
                    layerLink: _layerLink,
                    currentLine: _currentLine,
                    completions: _completions,
                    selectedIndex: _selectedCompletionIndex,
                    onSelect: _insertCompletion,
                  ),
                  child: OverlayPortal(
                    controller: _signatureHelpController,
                    overlayChildBuilder: (context) => SignatureHelpOverlay(
                      layerLink: _layerLink,
                      currentLine: _currentLine,
                      signatureHelp: _currentSignatureHelp,
                    ),
                    child: CodeEditorContainer(
                      isRunning: provider.isRunning,
                      isFocused: _focusNode.hasFocus,
                      isHovering: _isHovering,
                      onHoverChange: (hovering) => setState(() => _isHovering = hovering),
                      child: Column(
                        children: [
                          EditorHeader(
                            provider: provider,
                            onClear: () => _handleClear(provider),
                            onLoadExample: () => provider.loadExampleCode('simple'),
                            onFormat: _formatCode,
                            errorCount: _diagnostics.where((d) => d.severity == ErrorSeverity.error).length,
                            warningCount: _diagnostics.where((d) => d.severity == ErrorSeverity.warning).length,
                          ),
                          Expanded(
                            child: EditorBody(
                              controller: _controller,
                              focusNode: _focusNode,
                              scrollController: _scrollController,
                              isRunning: provider.isRunning,
                              lineCount: _lineCount,
                              currentLine: _currentLine,
                              diagnostics: _diagnostics,
                              foldingManager: _foldingManager,
                              onChanged: (text) {
                                provider.setSourceCode(text);
                                _handleTextChange(text);
                              },
                              onFoldingToggle: () => setState(() {}),
                            ),
                          ),
                          EditorFooter(
                            provider: provider,
                            charCount: _controller.text.length,
                            lineCount: _lineCount,
                            currentLine: _currentLine,
                            currentColumn: _currentColumn,
                            statusAnimController: _statusAnimController,
                            diagnostics: _diagnostics,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
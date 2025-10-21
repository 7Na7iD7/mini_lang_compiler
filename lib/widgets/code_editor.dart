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

class _CodeEditorState extends State<CodeEditor>
    with SingleTickerProviderStateMixin {

  late final SyntaxHighlightingController _textController;
  late final FocusNode _focusNode;

  late final ScrollController _textScrollController;
  late final ScrollController _lineNumberScrollController;
  late final ScrollController _foldingScrollController;

  late final AnimationController _statusAnimController;

  // Overlay portal controllers for floating UI
  late final OverlayPortalController _autoCompletePortal;
  late final OverlayPortalController _signatureHelpPortal;

  // Code intelligence
  late final AdvancedCodeFoldingManager _foldingManager;
  final LayerLink _layerLink = LayerLink();

  // UI state
  bool _isHovering = false;
  bool _isInitialized = false;

  // Editor metrics
  int _lineCount = 1;
  int _currentLine = 1;
  int _currentColumn = 0;

  // Code intelligence state
  List<CompletionItem> _completions = [];
  int _selectedCompletionIndex = 0;
  SignatureHelp? _currentSignatureHelp;
  List<CodeError> _diagnostics = [];

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    _setupEventListeners();
    _scheduleInitialLoad();
  }

  void _initializeComponents() {
    _textController = SyntaxHighlightingController();
    _focusNode = FocusNode();

    _textScrollController = ScrollController();
    _lineNumberScrollController = ScrollController();
    _foldingScrollController = ScrollController();

    _autoCompletePortal = OverlayPortalController();
    _signatureHelpPortal = OverlayPortalController();
    _foldingManager = AdvancedCodeFoldingManager();

    _statusAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _setupEventListeners() {
    _textController.addListener(_onTextControllerChanged);
    _focusNode.addListener(_onFocusChanged);

    _textScrollController.addListener(_syncScrollPositions);
  }

  void _syncScrollPositions() {
    if (!_textScrollController.hasClients) return;

    final offset = _textScrollController.offset;

    if (_lineNumberScrollController.hasClients &&
        _lineNumberScrollController.offset != offset) {
      _lineNumberScrollController.jumpTo(offset);
    }

    // folding gutter
    if (_foldingScrollController.hasClients &&
        _foldingScrollController.offset != offset) {
      _foldingScrollController.jumpTo(offset);
    }
  }

  void _scheduleInitialLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _loadInitialCode();
        _isInitialized = true;
      }
    });
  }

  void _loadInitialCode() {
    final provider = context.read<CompilerProvider>();
    _syncTextWithProvider(provider.sourceCode);
  }

  void _onTextControllerChanged() {
    _updateEditorMetrics();
    _updateCodeIntelligence();
  }

  void _updateEditorMetrics() {
    final text = _textController.text;
    final selection = _textController.selection;

    // Calculate new metrics
    final newLineCount = text.split('\n').length;
    final cursorPos = selection.baseOffset.clamp(0, text.length);
    final textBeforeCursor = text.substring(0, cursorPos);
    final lines = textBeforeCursor.split('\n');
    final newLine = lines.length;
    final newColumn = lines.last.length;

    // Batch update if anything changed
    if (newLineCount != _lineCount ||
        newLine != _currentLine ||
        newColumn != _currentColumn) {
      setState(() {
        _lineCount = newLineCount;
        _currentLine = newLine;
        _currentColumn = newColumn;
      });
    }
  }

  void _updateCodeIntelligence() {
    _updateDiagnostics();
    _updateFoldingRegions();
  }

  void _updateDiagnostics() {
    final newDiagnostics = _textController.getDiagnostics();
    if (!_areDiagnosticsEqual(newDiagnostics, _diagnostics)) {
      setState(() => _diagnostics = newDiagnostics);
    }
  }

  bool _areDiagnosticsEqual(List<CodeError> a, List<CodeError> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].line != b[i].line ||
          a[i].message != b[i].message ||
          a[i].severity != b[i].severity) {
        return false;
      }
    }
    return true;
  }

  void _updateFoldingRegions() {
    _foldingManager.analyzeFoldingRegions(_textController.text);
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _hideAllOverlays();
    }
  }

  /// Hide all floating overlays
  void _hideAllOverlays() {
    _autoCompletePortal.hide();
    _signatureHelpPortal.hide();
  }

  // Text Synchronization
  void _syncTextWithProvider(String newText) {
    if (_textController.text == newText) return;

    final cursorPos = _textController.selection.baseOffset;
    _textController.text = newText;

    // Restore cursor position intelligently
    final newPos = cursorPos.clamp(0, newText.length);
    _textController.selection = TextSelection.collapsed(offset: newPos);

    _foldingManager.analyzeFoldingRegions(newText);
  }

  void _handleUserTextChange(String text) {
    _triggerAutoComplete();
    _triggerSignatureHelp();
  }

  // Auto-Completion System
  void _triggerAutoComplete() {
    final cursorPos = _textController.selection.baseOffset;
    if (cursorPos <= 0) {
      _autoCompletePortal.hide();
      return;
    }

    final textBeforeCursor = _textController.text.substring(0, cursorPos);
    final match = RegExp(r'[a-zA-Z_]\w*$').firstMatch(textBeforeCursor);

    if (match != null) {
      final word = match.group(0)!;
      if (word.length >= 2) {
        final items = _textController.getCompletionItems(word, cursorPos);
        if (items.isNotEmpty) {
          _showAutoComplete(items);
          return;
        }
      }
    }

    _autoCompletePortal.hide();
  }

  void _showAutoComplete(List<CompletionItem> items) {
    setState(() {
      _completions = items;
      _selectedCompletionIndex = 0;
    });
    _autoCompletePortal.show();
  }

  void _insertCompletion(CompletionItem item) {
    final cursorPos = _textController.selection.baseOffset;
    final textBeforeCursor = _textController.text.substring(0, cursorPos);
    final match = RegExp(r'[a-zA-Z_]\w*$').firstMatch(textBeforeCursor);

    if (match == null) return;

    final startPos = match.start;
    final insertText = item.displayText;

    // Build new text with completion
    final newText = _textController.text.substring(0, startPos) +
        insertText +
        _textController.text.substring(cursorPos);

    _textController.text = newText;

    // Smart cursor positioning
    int newCursorPos = startPos + insertText.length;
    if (insertText.endsWith('()')) {
      newCursorPos -= 1; // Place cursor inside parentheses

      Future.delayed(const Duration(milliseconds: 100), _triggerSignatureHelp);
    }

    _textController.selection = TextSelection.collapsed(offset: newCursorPos);
    _autoCompletePortal.hide();

    HapticFeedback.selectionClick();
  }

  // Signature Help System
  void _triggerSignatureHelp() {
    final cursorPos = _textController.selection.baseOffset;
    final signatureHelp = _textController.getSignatureHelp(cursorPos);

    if (signatureHelp != null) {
      setState(() => _currentSignatureHelp = signatureHelp);
      _signatureHelpPortal.show();
    } else {
      _signatureHelpPortal.hide();
    }
  }

  // Keyboard Shortcuts

  bool _handleKeyboardEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    // Handle auto-complete overlay navigation
    if (_autoCompletePortal.isShowing) {
      return _handleAutoCompleteKeys(event);
    }

    // Handle global editor shortcuts
    return _handleEditorShortcuts(event);
  }

  bool _handleAutoCompleteKeys(KeyEvent event) {
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedCompletionIndex =
            (_selectedCompletionIndex + 1) % _completions.length;
      });
      return true;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedCompletionIndex =
            (_selectedCompletionIndex - 1 + _completions.length) % _completions.length;
      });
      return true;
    }

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.tab) {
      _insertCompletion(_completions[_selectedCompletionIndex]);
      return true;
    }

    if (key == LogicalKeyboardKey.escape) {
      _autoCompletePortal.hide();
      return true;
    }

    return false;
  }

  bool _handleEditorShortcuts(KeyEvent event) {
    final isModifier = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (!isModifier) return false;

    final key = event.logicalKey;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    // Ctrl/Cmd + D: Duplicate line
    if (key == LogicalKeyboardKey.keyD && !isShift) {
      _duplicateCurrentLine();
      return true;
    }

    // Ctrl/Cmd + /: Toggle comment
    if (key == LogicalKeyboardKey.slash) {
      _toggleLineComment();
      return true;
    }

    // Ctrl/Cmd + Space: Force auto-complete
    if (key == LogicalKeyboardKey.space) {
      _triggerAutoComplete();
      return true;
    }

    // Ctrl/Cmd + S: Format code (custom)
    if (key == LogicalKeyboardKey.keyS && isShift) {
      _formatCode();
      return true;
    }

    return false;
  }

  // Editor Commands
  void _duplicateCurrentLine() {
    final text = _textController.text;
    final cursorPos = _textController.selection.baseOffset;
    final lines = text.split('\n');

    // Find current line
    int pos = 0;
    int lineIndex = 0;
    for (int i = 0; i < lines.length; i++) {
      if (pos + lines[i].length >= cursorPos) {
        lineIndex = i;
        break;
      }
      pos += lines[i].length + 1;
    }

    // Duplicate line
    final currentLine = lines[lineIndex];
    lines.insert(lineIndex + 1, currentLine);

    final newText = lines.join('\n');
    _textController.text = newText;

    // Move cursor to duplicated line
    final newCursorPos = pos + currentLine.length + 1;
    _textController.selection = TextSelection.collapsed(offset: newCursorPos);

    HapticFeedback.mediumImpact();
  }

  void _toggleLineComment() {
    final text = _textController.text;
    final cursorPos = _textController.selection.baseOffset;

    final lineStart = text.lastIndexOf('\n', cursorPos - 1) + 1;
    final lineEnd = text.indexOf('\n', cursorPos);
    final actualLineEnd = lineEnd == -1 ? text.length : lineEnd;

    final currentLine = text.substring(lineStart, actualLineEnd);
    final trimmed = currentLine.trimLeft();
    final spaces = currentLine.substring(0, currentLine.length - trimmed.length);

    String newLine;
    int cursorOffset;

    if (trimmed.startsWith('//')) {
      // Remove comment
      final withoutComment = trimmed.substring(2).trimLeft();
      newLine = spaces + withoutComment;
      cursorOffset = -(trimmed.length - withoutComment.length);
    } else {
      newLine = '$spaces// $trimmed';
      cursorOffset = 3;
    }

    final newText = text.substring(0, lineStart) +
        newLine +
        text.substring(actualLineEnd);

    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(
        offset: cursorPos + cursorOffset
    );

    HapticFeedback.lightImpact();
  }

  void _formatCode() {
    final lines = _textController.text.split('\n');
    final formatted = <String>[];
    int indentLevel = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        formatted.add('');
        continue;
      }

      // Decrease indent for closing brackets
      if (_startsWithClosing(trimmed)) {
        indentLevel = (indentLevel - 1).clamp(0, 50);
      }

      // Add formatted line
      formatted.add('  ' * indentLevel + trimmed);

      // Increase indent for opening brackets
      if (_endsWithOpening(trimmed)) {
        indentLevel++;
      }
    }

    _textController.text = formatted.join('\n');
    HapticFeedback.mediumImpact();
  }

  bool _startsWithClosing(String line) {
    return line.startsWith('}') ||
        line.startsWith(')') ||
        line.startsWith(']');
  }

  bool _endsWithOpening(String line) {
    return line.endsWith('{') ||
        line.endsWith('(') ||
        line.endsWith('[');
  }

  void _handleClearCommand(CompilerProvider provider) {
    _textController.clear();
    provider.clear();
    _foldingManager.clear();
    setState(() => _diagnostics.clear());
    _hideAllOverlays();

    HapticFeedback.heavyImpact();
  }

  // Animation Management
  void _updateStatusAnimation(CompilerState state) {
    if (state == CompilerState.idle || state == CompilerState.completed) {
      _statusAnimController.forward();
    } else {
      _statusAnimController.repeat(reverse: true);
    }
  }

  // Lifecycle
  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();

    _textScrollController.dispose();
    _lineNumberScrollController.dispose();
    _foldingScrollController.dispose();

    _statusAnimController.dispose();
    super.dispose();
  }

  // Build Method
  @override
  Widget build(BuildContext context) {
    return Consumer<CompilerProvider>(
      builder: (context, provider, _) {
        // Sync text with provider
        _syncTextWithProvider(provider.sourceCode);

        _updateStatusAnimation(provider.state);

        return _buildEditorLayout(provider);
      },
    );
  }

  Widget _buildEditorLayout(CompilerProvider provider) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyboardEvent,
        child: _buildOverlayStack(provider),
      ),
    );
  }

  Widget _buildOverlayStack(CompilerProvider provider) {
    return Stack(
      children: [
        OverlayPortal(
          controller: _autoCompletePortal,
          overlayChildBuilder: (_) => AutoCompleteOverlay(
            layerLink: _layerLink,
            currentLine: _currentLine,
            completions: _completions,
            selectedIndex: _selectedCompletionIndex,
            onSelect: _insertCompletion,
          ),
          child: OverlayPortal(
            controller: _signatureHelpPortal,
            overlayChildBuilder: (_) => SignatureHelpOverlay(
              layerLink: _layerLink,
              currentLine: _currentLine,
              signatureHelp: _currentSignatureHelp,
            ),
            child: _buildEditorContent(provider),
          ),
        ),
      ],
    );
  }

  Widget _buildEditorContent(CompilerProvider provider) {
    return CodeEditorContainer(
      isRunning: provider.isRunning,
      isFocused: _focusNode.hasFocus,
      isHovering: _isHovering,
      onHoverChange: (hovering) => setState(() => _isHovering = hovering),
      child: Column(
        children: [
          EditorHeader(
            provider: provider,
            onClear: () => _handleClearCommand(provider),
            onLoadExample: () => provider.loadExampleCode('simple'),
            onFormat: _formatCode,
            errorCount: _diagnostics
                .where((d) => d.severity == ErrorSeverity.error)
                .length,
            warningCount: _diagnostics
                .where((d) => d.severity == ErrorSeverity.warning)
                .length,
          ),
          Expanded(
            child: EditorBody(
              controller: _textController,
              focusNode: _focusNode,
              textScrollController: _textScrollController,
              lineNumberScrollController: _lineNumberScrollController,
              foldingScrollController: _foldingScrollController,

              isRunning: provider.isRunning,
              lineCount: _lineCount,
              currentLine: _currentLine,
              diagnostics: _diagnostics,
              foldingManager: _foldingManager,
              onChanged: (text) {
                provider.setSourceCode(text);
                _handleUserTextChange(text);
              },
              onFoldingToggle: () => setState(() {}),
            ),
          ),
          EditorFooter(
            provider: provider,
            charCount: _textController.text.length,
            lineCount: _lineCount,
            currentLine: _currentLine,
            currentColumn: _currentColumn,
            statusAnimController: _statusAnimController,
            diagnostics: _diagnostics,
          ),
        ],
      ),
    );
  }
}
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

  // Overlay portal controllers
  late final OverlayPortalController _autoCompletePortal;
  late final OverlayPortalController _signatureHelpPortal;

  // Code intelligence
  late final AdvancedCodeFoldingManager _foldingManager;
  final LayerLink _layerLink = LayerLink();

  // UI state
  bool _isHovering = false;
  bool _isInitialized = false;
  bool _isSyncing = false;

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

    if (_lineNumberScrollController.hasClients) {
      final diff = (_lineNumberScrollController.offset - offset).abs();
      if (diff > 0.5) {
        _lineNumberScrollController.jumpTo(offset);
      }
    }

    if (_foldingScrollController.hasClients) {
      final diff = (_foldingScrollController.offset - offset).abs();
      if (diff > 0.5) {
        _foldingScrollController.jumpTo(offset);
      }
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
    if (_isSyncing) return;

    _updateEditorMetrics();
    _updateCodeIntelligence();
  }

  void _updateEditorMetrics() {
    final text = _textController.text;
    final selection = _textController.selection;

    final lines = text.split('\n');
    final newLineCount = lines.length;

    final cursorPos = selection.baseOffset.clamp(0, text.length);
    final textBeforeCursor = text.substring(0, cursorPos);
    final linesBeforeCursor = textBeforeCursor.split('\n');
    final newCurrentLine = linesBeforeCursor.length;
    final newCurrentColumn = linesBeforeCursor.isEmpty ? 0 : linesBeforeCursor.last.length;

    if (newLineCount != _lineCount ||
        newCurrentLine != _currentLine ||
        newCurrentColumn != _currentColumn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _lineCount = newLineCount;
            _currentLine = newCurrentLine;
            _currentColumn = newCurrentColumn;
          });
        }
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _diagnostics = newDiagnostics);
        }
      });
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _hideAllOverlays();
    }
  }

  void _hideAllOverlays() {
    _autoCompletePortal.hide();
    _signatureHelpPortal.hide();
  }

  void _syncTextWithProvider(String newText) {
    if (_textController.text == newText) return;

    _isSyncing = true; // شروع sync

    final cursorPos = _textController.selection.baseOffset;
    _textController.text = newText;

    final newPos = cursorPos.clamp(0, newText.length);
    _textController.selection = TextSelection.collapsed(offset: newPos);

    _foldingManager.analyzeFoldingRegions(newText);

    _isSyncing = false; // پایان sync
  }

  void _handleUserTextChange(String text) {
    _triggerAutoComplete();
    _triggerSignatureHelp();
  }

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

    final newText = _textController.text.substring(0, startPos) +
        insertText +
        _textController.text.substring(cursorPos);

    _textController.text = newText;

    int newCursorPos = startPos + insertText.length;
    if (insertText.endsWith('()')) {
      newCursorPos -= 1;
      Future.delayed(const Duration(milliseconds: 100), _triggerSignatureHelp);
    }

    _textController.selection = TextSelection.collapsed(offset: newCursorPos);
    _autoCompletePortal.hide();

    HapticFeedback.selectionClick();
  }

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

  bool _handleKeyboardEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    if (_autoCompletePortal.isShowing) {
      return _handleAutoCompleteKeys(event);
    }

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

    if (key == LogicalKeyboardKey.keyD && !isShift) {
      _duplicateCurrentLine();
      return true;
    }

    if (key == LogicalKeyboardKey.slash) {
      _toggleLineComment();
      return true;
    }

    if (key == LogicalKeyboardKey.space) {
      _triggerAutoComplete();
      return true;
    }

    if (key == LogicalKeyboardKey.keyS && isShift) {
      _formatCode();
      return true;
    }

    return false;
  }

  void _duplicateCurrentLine() {
    final text = _textController.text;
    final cursorPos = _textController.selection.baseOffset;
    final lines = text.split('\n');

    int pos = 0;
    int lineIndex = 0;
    for (int i = 0; i < lines.length; i++) {
      final lineLength = lines[i].length;
      if (pos + lineLength >= cursorPos) {
        lineIndex = i;
        break;
      }
      pos += lineLength + 1;
    }

    final currentLine = lines[lineIndex];
    lines.insert(lineIndex + 1, currentLine);

    final newText = lines.join('\n');
    _textController.text = newText;

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

      if (_startsWithClosing(trimmed)) {
        indentLevel = (indentLevel - 1).clamp(0, 50);
      }

      formatted.add('  ' * indentLevel + trimmed);

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
    setState(() {
      _diagnostics.clear();
      _lineCount = 1;
      _currentLine = 1;
      _currentColumn = 0;
    });
    _hideAllOverlays();

    HapticFeedback.heavyImpact();
  }

  void _updateStatusAnimation(CompilerState state) {
    if (state == CompilerState.idle || state == CompilerState.completed) {
      _statusAnimController.forward();
    } else {
      _statusAnimController.repeat(reverse: true);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Consumer<CompilerProvider>(
      builder: (context, provider, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _syncTextWithProvider(provider.sourceCode);
            _updateStatusAnimation(provider.state);
          }
        });

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
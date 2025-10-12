import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import 'dart:math' as math;
import '../providers/compiler_provider.dart';
import 'syntax_highlighting_controller.dart';
import 'code_intelligence.dart';
import 'code_folding.dart';

class ModernEditorTheme {
  static const double lineNumberWidth = 42.0;
  static const double foldingGutterWidth = 24.0;
  static const double padding = 10.0;
  static const double borderRadius = 16.0;
  static const double smallRadius = 10.0;

  static const double fontSize = 14.5;
  static const double lineHeight = 1.5;
  static const double calculatedLineHeight = fontSize * lineHeight;

  static final primaryGradient = [Color(0xFF667eea), Color(0xFF764ba2)];
  static final successGradient = [Color(0xFF11998e), Color(0xFF38ef7d)];
  static final dangerGradient = [Color(0xFFf093fb), Color(0xFFf5576c)];
  static final warningGradient = [Color(0xFFf2994a), Color(0xFFf2c94c)];
}

class AdvancedScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildOverscrollIndicator(context, child, details) => child;
}

class CodeEditorContainer extends StatefulWidget {
  final Widget child;
  final bool isRunning;
  final bool isFocused;
  final bool isHovering;
  final ValueChanged<bool> onHoverChange;

  const CodeEditorContainer({
    super.key,
    required this.child,
    required this.isRunning,
    required this.isFocused,
    required this.isHovering,
    required this.onHoverChange,
  });

  @override
  State<CodeEditorContainer> createState() => _CodeEditorContainerState();
}

class _CodeEditorContainerState extends State<CodeEditorContainer>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late Animation<double> _glowAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.onHoverChange(true),
      onExit: (_) => widget.onHoverChange(false),
      child: AnimatedBuilder(
        animation: Listenable.merge([_glowController, _pulseController]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isFocused ? _pulseAnim.value : 1.0,
            child: Container(
              decoration: _buildPremiumDecoration(),
              child: child,
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ModernEditorTheme.borderRadius),
          child: widget.child,
        ),
      ),
    );
  }

  BoxDecoration _buildPremiumDecoration() {
    final theme = Theme.of(context);

    return BoxDecoration(
      borderRadius: BorderRadius.circular(ModernEditorTheme.borderRadius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.surface,
          theme.colorScheme.surface.withOpacity(0.95),
        ],
      ),
      border: Border.all(
        width: widget.isFocused ? 2.5 : 1.5,
        color: _getBorderColor(),
      ),
      boxShadow: _buildAdvancedShadows(),
    );
  }

  Color _getBorderColor() {
    if (widget.isRunning) {
      return Color.lerp(
        ModernEditorTheme.primaryGradient[0],
        ModernEditorTheme.primaryGradient[1],
        _glowAnim.value,
      )!;
    }
    if (widget.isFocused) {
      return Color.lerp(
        ModernEditorTheme.primaryGradient[0],
        ModernEditorTheme.primaryGradient[1],
        _glowAnim.value,
      )!;
    }
    if (widget.isHovering) {
      return Theme.of(context).colorScheme.outline;
    }
    return Theme.of(context).colorScheme.outline.withOpacity(0.3);
  }

  List<BoxShadow> _buildAdvancedShadows() {
    final shadows = <BoxShadow>[
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ];

    if (widget.isFocused) {
      shadows.insert(0, BoxShadow(
        color: ModernEditorTheme.primaryGradient[0].withOpacity(0.3 * _glowAnim.value),
        blurRadius: 30,
        spreadRadius: 2,
        offset: Offset(0, 8),
      ));
    }

    return shadows;
  }
}

class EditorHeader extends StatefulWidget {
  final CompilerProvider provider;
  final VoidCallback onClear;
  final VoidCallback onLoadExample;
  final VoidCallback onFormat;
  final int errorCount;
  final int warningCount;

  const EditorHeader({
    super.key,
    required this.provider,
    required this.onClear,
    required this.onLoadExample,
    required this.onFormat,
    required this.errorCount,
    required this.warningCount,
  });

  @override
  State<EditorHeader> createState() => _EditorHeaderState();
}

class _EditorHeaderState extends State<EditorHeader> with TickerProviderStateMixin {
  late AnimationController _saveController;
  late AnimationController _backgroundController;
  Timer? _saveTimer;
  bool _showSaved = false;

  @override
  void initState() {
    super.initState();
    _saveController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _saveController.dispose();
    _backgroundController.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + _backgroundController.value * 2, -1),
              end: Alignment(1 - _backgroundController.value * 2, 1),
              colors: [
                theme.colorScheme.surfaceVariant.withOpacity(0.6),
                theme.colorScheme.surfaceVariant.withOpacity(0.3),
                theme.colorScheme.surfaceVariant.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(ModernEditorTheme.borderRadius),
              topRight: Radius.circular(ModernEditorTheme.borderRadius),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          _buildActionButtons(),
          Expanded(child: _buildCenterSection()),
          _buildDiagnostics(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        PremiumActionButton(
          icon: Icons.auto_fix_high,
          gradient: ModernEditorTheme.primaryGradient,
          tooltip: 'Format Code',
          onPressed: widget.provider.isRunning ? null : widget.onFormat,
        ),
        SizedBox(width: 10),
        PremiumActionButton(
          icon: Icons.delete_sweep,
          gradient: ModernEditorTheme.dangerGradient,
          tooltip: 'Clear Code',
          onPressed: widget.provider.isRunning ? null : widget.onClear,
        ),
        SizedBox(width: 10),
        PremiumActionButton(
          icon: Icons.lightbulb,
          gradient: ModernEditorTheme.warningGradient,
          tooltip: 'Load Example',
          onPressed: widget.provider.isRunning ? null : widget.onLoadExample,
        ),
      ],
    );
  }

  Widget _buildCenterSection() {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.15),
              theme.colorScheme.primary.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: ModernEditorTheme.primaryGradient),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ModernEditorTheme.primaryGradient[0].withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(Icons.code, size: 16, color: Colors.white),
            ),
            SizedBox(width: 10),
            Text(
              'MiniLang Studio',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            if (_showSaved) ...[
              SizedBox(width: 12),
              FadeTransition(
                opacity: _saveController,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: ModernEditorTheme.successGradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Saved', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnostics() {
    return Row(
      children: [
        if (widget.errorCount > 0)
          DiagnosticPill(
            icon: Icons.error,
            count: widget.errorCount,
            gradient: ModernEditorTheme.dangerGradient,
          ),
        if (widget.warningCount > 0) ...[
          if (widget.errorCount > 0) SizedBox(width: 8),
          DiagnosticPill(
            icon: Icons.warning,
            count: widget.warningCount,
            gradient: ModernEditorTheme.warningGradient,
          ),
        ],
      ],
    );
  }
}

class PremiumActionButton extends StatefulWidget {
  final IconData icon;
  final List<Color> gradient;
  final String tooltip;
  final VoidCallback? onPressed;

  const PremiumActionButton({
    super.key,
    required this.icon,
    required this.gradient,
    required this.tooltip,
    this.onPressed,
  });

  @override
  State<PremiumActionButton> createState() => _PremiumActionButtonState();
}

class _PremiumActionButtonState extends State<PremiumActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovering = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        _controller.reverse();
      },
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTapDown: (_) => _controller.reverse(),
          onTapUp: (_) {
            _controller.forward();
            if (widget.onPressed != null) {
              HapticFeedback.mediumImpact();
              widget.onPressed!();
            }
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 - (_controller.value * 0.1),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: widget.gradient),
                    borderRadius: BorderRadius.circular(ModernEditorTheme.smallRadius),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradient[0].withOpacity(0.4 * _controller.value),
                        blurRadius: 12,
                        spreadRadius: _isHovering ? 0 : -4,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class DiagnosticPill extends StatelessWidget {
  final IconData icon;
  final int count;
  final List<Color> gradient;

  const DiagnosticPill({
    super.key,
    required this.icon,
    required this.count,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: -3,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class EditorBody extends StatelessWidget {
  final SyntaxHighlightingController controller;
  final FocusNode focusNode;
  final ScrollController textScrollController;
  final ScrollController lineNumberScrollController;
  final ScrollController foldingScrollController;
  final bool isRunning;
  final int lineCount;
  final int currentLine;
  final List<CodeError> diagnostics;
  final AdvancedCodeFoldingManager foldingManager;
  final ValueChanged<String> onChanged;
  final VoidCallback onFoldingToggle;

  const EditorBody({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.textScrollController,
    required this.lineNumberScrollController,
    required this.foldingScrollController,
    required this.isRunning,
    required this.lineCount,
    required this.currentLine,
    required this.diagnostics,
    required this.foldingManager,
    required this.onChanged,
    required this.onFoldingToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: AdvancedScrollBehavior(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModernLineNumbers(
            lineCount: lineCount,
            scrollController: lineNumberScrollController,
            currentLine: currentLine,
            diagnostics: diagnostics,
            foldingManager: foldingManager,
          ),
          AdvancedFoldingGutter(
            lineCount: lineCount,
            foldingManager: foldingManager,
            onToggle: onFoldingToggle,
            scrollController: foldingScrollController,
            currentLine: currentLine,
          ),
          Container(
            width: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                AdvancedIndentGuides(
                  sourceCode: controller.text,
                  foldingManager: foldingManager,
                  scrollController: textScrollController,
                  currentLine: currentLine,
                ),
                // ============ NEW: TextField با Hover و Long Press ============
                ModernTextFieldWithHover(
                  controller: controller,
                  focusNode: focusNode,
                  scrollController: textScrollController,
                  enabled: !isRunning,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ModernTextFieldWithHover extends StatefulWidget {
  final SyntaxHighlightingController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const ModernTextFieldWithHover({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<ModernTextFieldWithHover> createState() => _ModernTextFieldWithHoverState();
}

class _ModernTextFieldWithHoverState extends State<ModernTextFieldWithHover> {
  String _lastText = '';
  static const _pairs = {'(': ')', '[': ']', '{': '}', '"': '"', "'": "'"};

  OverlayEntry? _hoverOverlay;
  Timer? _longPressTimer;
  Offset? _lastTapPosition;

  @override
  void dispose() {
    _removeHoverOverlay();
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Listener(
      onPointerHover: (event) {
        _handleHover(event.position);
      },
      onPointerDown: (event) {
        _lastTapPosition = event.position;
        _startLongPressTimer();
      },
      onPointerUp: (event) {
        _longPressTimer?.cancel();
      },
      onPointerMove: (event) {
        // Cancel long press if finger moves
        if (_lastTapPosition != null) {
          final distance = (event.position - _lastTapPosition!).distance;
          if (distance > 10) {
            _longPressTimer?.cancel();
          }
        }
      },
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        scrollController: widget.scrollController,
        scrollPhysics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        enabled: widget.enabled,
        maxLines: null,
        expands: true,
        cursorColor: ModernEditorTheme.primaryGradient[0],
        cursorWidth: 2.5,
        cursorHeight: ModernEditorTheme.calculatedLineHeight,
        cursorRadius: Radius.circular(2),
        decoration: InputDecoration(
          hintText: '// Start coding with MiniLang\n'
              '// Long press on code to see info\n'
              '//   Ctrl+Space → Auto-complete\n'
              '//   Ctrl+D → Duplicate line\n'
              '//   Ctrl+/ → Toggle comment\n\n'
              'int result = 42;\n'
              'print("Hello, World!");',
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          hintStyle: TextStyle(
            fontFamily: 'Courier New',
            fontSize: ModernEditorTheme.fontSize,
            height: ModernEditorTheme.lineHeight,
            color: theme.colorScheme.onSurface.withOpacity(0.25),
          ),
        ),
        style: TextStyle(
          fontFamily: 'Courier New',
          fontSize: ModernEditorTheme.fontSize,
          height: ModernEditorTheme.lineHeight,
        ),
        onChanged: (text) {
          _handleBrackets(text);
          widget.onChanged(text);
        },
        textAlignVertical: TextAlignVertical.top,
        inputFormatters: [SmartIndentFormatter()],
      ),
    );
  }

  void _handleHover(Offset position) {
    final textPosition = _getTextPositionFromOffset(position);
    if (textPosition == null) return;

    final intelligence = CodeIntelligence(widget.controller.text);
    final hoverInfo = intelligence.getHoverInfo(textPosition);

    if (hoverInfo != null) {
      _showHoverOverlay(position, hoverInfo);
    } else {
      _removeHoverOverlay();
    }
  }

  void _startLongPressTimer() {
    _longPressTimer?.cancel();
    _longPressTimer = Timer(Duration(milliseconds: 500), () {
      if (_lastTapPosition != null) {
        _handleLongPress(_lastTapPosition!);
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _handleLongPress(Offset position) {
    final textPosition = _getTextPositionFromOffset(position);
    if (textPosition == null) return;

    final intelligence = CodeIntelligence(widget.controller.text);
    final hoverInfo = intelligence.getHoverInfo(textPosition);

    if (hoverInfo != null) {
      _showHoverOverlay(position, hoverInfo);

      Future.delayed(Duration(seconds: 3), () {
        _removeHoverOverlay();
      });
    }
  }

  void _showHoverOverlay(Offset position, HoverInfo hoverInfo) {
    _removeHoverOverlay();

    _hoverOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy + 20,
        child: GestureDetector(
          onTap: _removeHoverOverlay,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxWidth: 350, maxHeight: 300),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surfaceVariant,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ModernEditorTheme.primaryGradient[0].withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: ModernEditorTheme.primaryGradient[0],
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Code Info',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, size: 18),
                        onPressed: _removeHoverOverlay,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        hoverInfo.content,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_hoverOverlay!);
  }

  void _removeHoverOverlay() {
    _hoverOverlay?.remove();
    _hoverOverlay = null;
  }

  int? _getTextPositionFromOffset(Offset globalPosition) {
    try {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return null;

      final localPosition = renderBox.globalToLocal(globalPosition);

      final lineHeight = ModernEditorTheme.calculatedLineHeight;
      final line = (localPosition.dy / lineHeight).floor();
      final charWidth = ModernEditorTheme.fontSize * 0.6; // تقریبی
      final column = (localPosition.dx / charWidth).floor();

      final lines = widget.controller.text.split('\n');
      if (line < 0 || line >= lines.length) return null;

      int offset = 0;
      for (int i = 0; i < line; i++) {
        offset += lines[i].length + 1; // +1 برای \n
      }
      offset += column.clamp(0, lines[line].length);

      return offset.clamp(0, widget.controller.text.length);
    } catch (e) {
      return null;
    }
  }

  void _handleBrackets(String newText) {
    if (newText.length <= _lastText.length) {
      _lastText = newText;
      return;
    }

    final pos = widget.controller.selection.baseOffset;
    if (pos <= 0) {
      _lastText = newText;
      return;
    }

    final char = newText[pos - 1];
    final close = _pairs[char];

    if (close != null) {
      final after = newText.substring(pos);
      if (after.isEmpty || after[0] != close) {
        final updated = newText.substring(0, pos) + close + newText.substring(pos);
        widget.controller.value = TextEditingValue(
          text: updated,
          selection: TextSelection.collapsed(offset: pos),
        );
        _lastText = updated;
        return;
      }
    }

    _lastText = newText;
  }
}

class SmartIndentFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue val) {
    if (val.text.length > old.text.length &&
        val.selection.baseOffset > 0 &&
        val.text[val.selection.baseOffset - 1] == '\n') {
      return _indentNewline(old, val);
    }

    if (val.text.length > old.text.length && val.selection.baseOffset > 0) {
      final char = val.text[val.selection.baseOffset - 1];
      if (char == '}' || char == ')' || char == ']') {
        return _dedentClosing(val);
      }
    }

    return val;
  }

  TextEditingValue _indentNewline(TextEditingValue old, TextEditingValue val) {
    final before = old.text.substring(0, old.selection.baseOffset);
    final lines = before.split('\n');
    if (lines.isEmpty) return val;

    final line = lines.last;
    final spaces = RegExp(r'^\s*').firstMatch(line)?.group(0) ?? '';
    final trimmed = line.trim();
    final extra = (trimmed.endsWith('{') || trimmed.endsWith('(') || trimmed.endsWith('[')) ? '  ' : '';
    final indent = spaces + extra;

    if (indent.isEmpty) return val;

    final pos = val.selection.baseOffset;
    final text = val.text.substring(0, pos) + indent + val.text.substring(pos);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: pos + indent.length),
    );
  }

  TextEditingValue _dedentClosing(TextEditingValue val) {
    final pos = val.selection.baseOffset;
    final before = val.text.substring(0, pos - 1);
    final lines = before.split('\n');
    if (lines.isEmpty) return val;

    final line = lines.last;
    if (line.trim().isEmpty && line.length >= 2) {
      final text = val.text.substring(0, pos - 3) + val.text.substring(pos - 1);
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: pos - 2),
      );
    }

    return val;
  }
}

class ModernLineNumbers extends StatelessWidget {
  final int lineCount;
  final ScrollController scrollController;
  final int currentLine;
  final List<CodeError> diagnostics;
  final AdvancedCodeFoldingManager foldingManager;

  const ModernLineNumbers({
    super.key,
    required this.lineCount,
    required this.scrollController,
    required this.currentLine,
    required this.diagnostics,
    required this.foldingManager,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diags = <int, List<CodeError>>{};
    for (final d in diagnostics) {
      diags.putIfAbsent(d.line, () => []).add(d);
    }

    return Container(
      width: ModernEditorTheme.lineNumberWidth,
      padding: EdgeInsets.only(top: 16, left: 4, right: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.3),
            theme.colorScheme.surface.withOpacity(0.5),
          ],
        ),
      ),
      child: ScrollConfiguration(
        behavior: AdvancedScrollBehavior(),
        child: ListView.builder(
          controller: scrollController,
          physics: NeverScrollableScrollPhysics(),
          itemCount: lineCount,
          itemBuilder: (context, index) {
            final num = index + 1;
            if (foldingManager.isLineHidden(num)) return SizedBox.shrink();

            final isCurrent = num == currentLine;
            final lineDiags = diags[num] ?? [];
            final hasError = lineDiags.any((d) => d.severity == ErrorSeverity.error);
            final hasWarn = lineDiags.any((d) => d.severity == ErrorSeverity.warning);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: SizedBox(
                height: ModernEditorTheme.calculatedLineHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: 10,
                      child: (hasError || hasWarn)
                          ? Icon(
                        hasError ? Icons.error : Icons.warning,
                        size: 10,
                        color: hasError ? Colors.red.shade400 : Colors.orange.shade400,
                      )
                          : null,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: isCurrent
                              ? LinearGradient(
                            colors: [
                              ModernEditorTheme.primaryGradient[0].withOpacity(0.2),
                              ModernEditorTheme.primaryGradient[1].withOpacity(0.15),
                            ],
                          )
                              : null,
                          borderRadius: BorderRadius.circular(6),
                          border: isCurrent
                              ? Border.all(
                            color: ModernEditorTheme.primaryGradient[0].withOpacity(0.4),
                            width: 1,
                          )
                              : null,
                        ),
                        child: Text(
                          '$num',
                          style: TextStyle(
                            fontFamily: 'Courier New',
                            fontSize: 12,
                            height: ModernEditorTheme.lineHeight,
                            color: isCurrent
                                ? ModernEditorTheme.primaryGradient[0]
                                : theme.colorScheme.onSurface.withOpacity(0.4),
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class EditorFooter extends StatelessWidget {
  final CompilerProvider provider;
  final int charCount;
  final int lineCount;
  final int currentLine;
  final int currentColumn;
  final AnimationController statusAnimController;
  final List<CodeError> diagnostics;

  const EditorFooter({
    super.key,
    required this.provider,
    required this.charCount,
    required this.lineCount,
    required this.currentLine,
    required this.currentColumn,
    required this.statusAnimController,
    required this.diagnostics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.4),
            theme.colorScheme.surfaceVariant.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(ModernEditorTheme.borderRadius),
          bottomRight: Radius.circular(ModernEditorTheme.borderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          ModernStatusIndicator(state: provider.state, controller: statusAnimController),
          Spacer(),
          FooterBadge(icon: Icons.my_location, text: 'Ln $currentLine, Col $currentColumn'),
          SizedBox(width: 12),
          FooterBadge(icon: Icons.view_headline, text: '$lineCount lines'),
          SizedBox(width: 12),
          FooterBadge(icon: Icons.text_fields, text: '$charCount chars'),
        ],
      ),
    );
  }
}

class ModernStatusIndicator extends StatelessWidget {
  final CompilerState state;
  final AnimationController controller;

  const ModernStatusIndicator({super.key, required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final info = _getInfo(state);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: info.gradient),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: info.gradient[0].withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: -3,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(_isIdle ? 1.0 : 0.4 + controller.value * 0.6),
                ),
              ),
              SizedBox(width: 8),
              Icon(info.icon, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Text(
                info.text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool get _isIdle => state == CompilerState.idle || state == CompilerState.completed;

  _StatusData _getInfo(CompilerState state) {
    switch (state) {
      case CompilerState.idle:
        return _StatusData(Icons.edit_note, 'Ready', ModernEditorTheme.primaryGradient);
      case CompilerState.lexing:
        return _StatusData(Icons.token, 'Lexing...', [Colors.blue.shade400, Colors.cyan.shade400]);
      case CompilerState.parsing:
        return _StatusData(Icons.account_tree, 'Parsing...', [Colors.purple.shade400, Colors.pink.shade400]);
      case CompilerState.analyzing:
        return _StatusData(Icons.analytics, 'Analyzing...', ModernEditorTheme.warningGradient);
      case CompilerState.interpreting:
        return _StatusData(Icons.play_arrow, 'Running...', [Colors.blue.shade400, Colors.indigo.shade400]);
      case CompilerState.completed:
        return _StatusData(Icons.check_circle, 'Done', ModernEditorTheme.successGradient);
      case CompilerState.error:
        return _StatusData(Icons.error, 'Error', ModernEditorTheme.dangerGradient);
      case CompilerState.optimizing:
        return _StatusData(Icons.speed, 'Optimizing...', [Colors.teal.shade400, Colors.green.shade400]);
    }
  }
}

class _StatusData {
  final IconData icon;
  final String text;
  final List<Color> gradient;
  _StatusData(this.icon, this.text, this.gradient);
}

class FooterBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const FooterBadge({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
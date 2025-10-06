import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../providers/compiler_provider.dart';
import 'syntax_highlighting_controller.dart';
import 'code_intelligence.dart';
import 'code_folding.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.onHoverChange(true),
      onExit: (_) => widget.onHoverChange(false),
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              border: Border.all(
                color: _getBorderColor(context),
                width: widget.isFocused ? 2.5 : 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                if (widget.isFocused || widget.isHovering)
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.15 * _glowController.value),
                    blurRadius: widget.isFocused ? 20 : 12,
                    spreadRadius: widget.isFocused ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: widget.child,
        ),
      ),
    );
  }

  Color _getBorderColor(BuildContext context) {
    if (widget.isRunning) {
      return Theme.of(context).colorScheme.secondary.withOpacity(0.6);
    }
    if (widget.isFocused) {
      return Theme.of(context).colorScheme.primary;
    }
    if (widget.isHovering) {
      return Theme.of(context).colorScheme.outline;
    }
    return Theme.of(context).colorScheme.outline.withOpacity(0.3);
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

class _EditorHeaderState extends State<EditorHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _saveController;
  Timer? _saveTimer;
  bool _showSaved = false;

  @override
  void initState() {
    super.initState();
    _saveController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _saveController.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  void _triggerAutoSave() {
    setState(() => _showSaved = true);
    _saveController.forward();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _saveController.reverse();
        setState(() => _showSaved = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.4),
            theme.colorScheme.surfaceVariant.withOpacity(0.2),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.2),
                  theme.colorScheme.primary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.code_rounded, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MiniLang Editor',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 0.3,
                ),
              ),
              if (_showSaved)
                FadeTransition(
                  opacity: _saveController,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 10,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Auto-saved',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          if (widget.errorCount > 0)
            DiagnosticBadge(
              icon: Icons.error_outline,
              count: widget.errorCount,
              color: Colors.red,
            ),
          if (widget.warningCount > 0) ...[
            const SizedBox(width: 8),
            DiagnosticBadge(
              icon: Icons.warning_amber_rounded,
              count: widget.warningCount,
              color: Colors.orange,
            ),
          ],
          const Spacer(),
          ActionButton(
            icon: Icons.format_align_left_rounded,
            tooltip: 'Format Code',
            onPressed: widget.provider.isRunning ? null : widget.onFormat,
          ),
          const SizedBox(width: 8),
          ActionButton(
            icon: Icons.clear_rounded,
            tooltip: 'Clear Code',
            onPressed: widget.provider.isRunning ? null : widget.onClear,
          ),
          const SizedBox(width: 8),
          ActionButton(
            icon: Icons.auto_awesome_rounded,
            tooltip: 'Load Example',
            onPressed: widget.provider.isRunning ? null : widget.onLoadExample,
          ),
        ],
      ),
    );
  }
}

// Diagnostic Badge
class DiagnosticBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const DiagnosticBadge({
    super.key,
    required this.icon,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text('$count', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Action Button
class ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const ActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Tooltip(
        message: widget.tooltip,
        waitDuration: const Duration(milliseconds: 500),
        child: IconButton(
          icon: Icon(widget.icon, size: 18),
          onPressed: widget.onPressed == null ? null : () {
            _scaleController.forward().then((_) => _scaleController.reverse());
            HapticFeedback.lightImpact();
            widget.onPressed!();
          },
          style: IconButton.styleFrom(
            minimumSize: const Size(36, 36),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}

// Editor Body
class EditorBody extends StatelessWidget {
  final SyntaxHighlightingController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
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
    required this.scrollController,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LineNumberColumn(
          lineCount: lineCount,
          scrollController: scrollController,
          currentLine: currentLine,
          diagnostics: diagnostics,
          foldingManager: foldingManager,
        ),
        AdvancedFoldingGutter(
          lineCount: lineCount,
          foldingManager: foldingManager,
          onToggle: onFoldingToggle,
          scrollController: scrollController,
          currentLine: currentLine,
        ),
        Container(width: 1, color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        Expanded(
          child: Stack(
            children: [
              AdvancedIndentGuides(
                sourceCode: controller.text,
                foldingManager: foldingManager,
                scrollController: scrollController,
                currentLine: currentLine,
              ),
              SyntaxHighlightedTextField(
                controller: controller,
                focusNode: focusNode,
                scrollController: scrollController,
                enabled: !isRunning,
                onChanged: onChanged,
                foldingManager: foldingManager,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Syntax Highlighted Text Field
class SyntaxHighlightedTextField extends StatefulWidget {
  final SyntaxHighlightingController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final AdvancedCodeFoldingManager foldingManager;

  const SyntaxHighlightedTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.enabled,
    required this.onChanged,
    required this.foldingManager,
  });

  @override
  State<SyntaxHighlightedTextField> createState() => _SyntaxHighlightedTextFieldState();
}

class _SyntaxHighlightedTextFieldState extends State<SyntaxHighlightedTextField> {
  static const double _fontSize = 14.0;
  static const double _lineHeight = 1.4;
  static const double _calculatedHeight = _fontSize * _lineHeight;
  static const EdgeInsets _padding = EdgeInsets.all(16);

  String _lastText = '';
  final _bracketPairs = {'(': ')', '[': ']', '{': '}', '"': '"', "'": "'"};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      scrollController: widget.scrollController,
      enabled: widget.enabled,
      maxLines: null,
      expands: true,
      cursorColor: theme.colorScheme.primary,
      cursorWidth: 2,
      cursorHeight: _calculatedHeight,
      decoration: InputDecoration(
        hintText: '// Write your MiniLang code here\n// Ctrl+Space for auto-complete\n// Ctrl+D to duplicate line\n// Ctrl+/ to toggle comment\n// Click [-] to fold code blocks\n\nint a = 42;\nprint(a);',
        border: InputBorder.none,
        contentPadding: _padding,
        isDense: true,
        hintStyle: TextStyle(
          fontFamily: 'Courier New',
          fontSize: _fontSize,
          height: _lineHeight,
          color: theme.colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
      onChanged: (text) {
        _handleTextChange(text);
        widget.onChanged(text);
      },
      textAlignVertical: TextAlignVertical.top,
      inputFormatters: [AutoIndentFormatter()],
    );
  }

  void _handleTextChange(String newText) {
    if (newText.length > _lastText.length && _lastText.isNotEmpty) {
      final cursorPos = widget.controller.selection.baseOffset;
      if (cursorPos > 0) {
        final addedChar = newText[cursorPos - 1];
        if (_bracketPairs.containsKey(addedChar)) {
          final closeChar = _bracketPairs[addedChar]!;
          final textAfter = newText.substring(cursorPos);
          if (textAfter.isEmpty || textAfter[0] != closeChar) {
            final updatedText = newText.substring(0, cursorPos) + closeChar + newText.substring(cursorPos);
            widget.controller.value = TextEditingValue(
              text: updatedText,
              selection: TextSelection.collapsed(offset: cursorPos),
            );
            _lastText = updatedText;
            return;
          }
        }
      }
    }
    _lastText = newText;
  }
}

// Auto Indent Formatter
class AutoIndentFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.length > oldValue.text.length &&
        newValue.selection.baseOffset > 0 &&
        newValue.text[newValue.selection.baseOffset - 1] == '\n') {
      final beforeCursor = oldValue.text.substring(0, oldValue.selection.baseOffset);
      final lines = beforeCursor.split('\n');
      if (lines.isEmpty) return newValue;

      final currentLine = lines.last;
      final leadingSpaces = RegExp(r'^\s*').firstMatch(currentLine)?.group(0) ?? '';
      final trimmedLine = currentLine.trim();
      final needsExtraIndent = trimmedLine.endsWith('{') || trimmedLine.endsWith('(') || trimmedLine.endsWith('[');
      final newIndent = leadingSpaces + (needsExtraIndent ? '  ' : '');

      if (newIndent.isNotEmpty) {
        final cursorPos = newValue.selection.baseOffset;
        final newText = newValue.text.substring(0, cursorPos) + newIndent + newValue.text.substring(cursorPos);
        return TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: cursorPos + newIndent.length));
      }
    }

    if (newValue.text.length > oldValue.text.length && newValue.selection.baseOffset > 0) {
      final lastChar = newValue.text[newValue.selection.baseOffset - 1];
      if (lastChar == '}' || lastChar == ')' || lastChar == ']') {
        final cursorPos = newValue.selection.baseOffset;
        final beforeCursor = newValue.text.substring(0, cursorPos - 1);
        final lines = beforeCursor.split('\n');
        if (lines.isNotEmpty) {
          final currentLine = lines.last;
          if (currentLine.trim().isEmpty && currentLine.length >= 2) {
            final newText = newValue.text.substring(0, cursorPos - 3) + newValue.text.substring(cursorPos - 1);
            return TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: cursorPos - 2));
          }
        }
      }
    }
    return newValue;
  }
}

// Line Number Column
class LineNumberColumn extends StatelessWidget {
  final int lineCount;
  final ScrollController scrollController;
  final int currentLine;
  final List<CodeError> diagnostics;
  final AdvancedCodeFoldingManager foldingManager;

  const LineNumberColumn({
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
    const double lineHeight = 14.0 * 1.4;

    final maxDigits = lineCount.toString().length;
    const double baseHorizontalSpace = 40.0;
    final dynamicWidth = baseHorizontalSpace + (maxDigits * 10.0);

    final diagnosticsByLine = <int, List<CodeError>>{};
    for (final diagnostic in diagnostics) {
      diagnosticsByLine.putIfAbsent(diagnostic.line, () => []).add(diagnostic);
    }

    return Container(
      width: dynamicWidth,
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.1),
            theme.colorScheme.surface
          ],
        ),
      ),
      child: ListView.builder(
        controller: scrollController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: lineCount,
        itemBuilder: (context, index) {
          final lineNumber = index + 1;

          if (foldingManager.isLineHidden(lineNumber)) {
            return const SizedBox.shrink();
          }

          final isCurrentLine = lineNumber == currentLine;
          final lineDiagnostics = diagnosticsByLine[lineNumber] ?? [];
          final hasError = lineDiagnostics.any((d) => d.severity == ErrorSeverity.error);
          final hasWarning = lineDiagnostics.any((d) => d.severity == ErrorSeverity.warning);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              height: lineHeight,
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    child: (hasError || hasWarning)
                        ? Icon(
                      hasError ? Icons.error : Icons.warning_amber_rounded,
                      size: 12,
                      color: hasError ? Colors.red : Colors.orange,
                    )
                        : null,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: isCurrentLine ? theme.colorScheme.primary.withOpacity(0.1) : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '$lineNumber',
                        style: TextStyle(
                          fontFamily: 'Courier New',
                          fontSize: 14,
                          height: 1.4,
                          color: isCurrentLine
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.4),
                          fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.normal,
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
    );
  }
}

// Editor Footer
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
      ),
      child: Row(
        children: [
          StatusIndicator(state: provider.state, animController: statusAnimController),
          const Spacer(),
          FooterInfo(icon: Icons.location_on_outlined, text: 'Ln $currentLine, Col $currentColumn'),
          const SizedBox(width: 16),
          FooterInfo(icon: Icons.format_list_numbered_rounded, text: '$lineCount lines'),
          const SizedBox(width: 16),
          FooterInfo(icon: Icons.text_fields_rounded, text: '$charCount chars'),
        ],
      ),
    );
  }
}

// Status Indicator
class StatusIndicator extends StatelessWidget {
  final CompilerState state;
  final AnimationController animController;

  const StatusIndicator({
    super.key,
    required this.state,
    required this.animController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusInfo = _getStatusInfo(state, theme);

    return AnimatedBuilder(
      animation: animController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusInfo.color.withOpacity(
                  state == CompilerState.idle || state == CompilerState.completed ? 1.0 : 0.3 + (animController.value * 0.7),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(statusInfo.icon, size: 14, color: statusInfo.color),
            const SizedBox(width: 6),
            Text(statusInfo.text, style: theme.textTheme.bodySmall?.copyWith(color: statusInfo.color, fontWeight: FontWeight.w500)),
          ],
        );
      },
    );
  }

  _StatusInfo _getStatusInfo(CompilerState state, ThemeData theme) {
    switch (state) {
      case CompilerState.idle: return _StatusInfo(Icons.edit_outlined, 'Ready', theme.colorScheme.primary);
      case CompilerState.lexing: return _StatusInfo(Icons.token_rounded, 'Tokenizing...', Colors.blue);
      case CompilerState.parsing: return _StatusInfo(Icons.account_tree_rounded, 'Parsing...', Colors.purple);
      case CompilerState.analyzing: return _StatusInfo(Icons.analytics_outlined, 'Analyzing...', Colors.orange);
      case CompilerState.interpreting: return _StatusInfo(Icons.play_circle_outline, 'Executing...', Colors.blue);
      case CompilerState.completed: return _StatusInfo(Icons.check_circle_outline, 'Completed', Colors.green);
      case CompilerState.error: return _StatusInfo(Icons.error_outline, 'Error', Colors.red);
      case CompilerState.optimizing: return _StatusInfo(Icons.speed_rounded, 'Optimizing...', Colors.teal);
    }
  }
}

class _StatusInfo {
  final IconData icon;
  final String text;
  final Color color;
  _StatusInfo(this.icon, this.text, this.color);
}

// Footer Info
class FooterInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const FooterInfo({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
      ],
    );
  }
}
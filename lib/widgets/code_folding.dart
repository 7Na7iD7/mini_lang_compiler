import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdvancedCodeFoldingManager {
  final List<FoldingRegion> _regions = [];
  final Set<int> _collapsedRegions = {};
  final List<FoldingHistory> _history = [];
  int _historyMaxSize = 50;
  String _currentFilePath = '';

  AdvancedCodeFoldingManager();

  void setFilePath(String path) {
    _currentFilePath = path;
  }

  void analyzeFoldingRegions(String sourceCode) {
    if (sourceCode.isEmpty) {
      clear();
      return;
    }

    _regions.clear();
    final lines = sourceCode.split('\n');

    _findFunctionRegions(lines);
    _findClassRegions(lines);
    _findControlFlowRegions(lines);
    _findCommentBlocks(lines);
    _findImportBlocks(lines);
    _findBraceRegions(lines);

    // Sort regions by start line
    _regions.sort((a, b) => a.startLine.compareTo(b.startLine));

    // Detect nested regions
    _detectNestedRegions();

    // Generate preview text for each region
    _generatePreviews(lines);
  }

  void _generatePreviews(List<String> lines) {
    for (final region in _regions) {
      if (region.startLine <= lines.length) {
        final startLineText = lines[region.startLine - 1].trim();
        final contentLines = <String>[];

        // Collect first few lines of content
        for (int i = region.startLine; i < math.min(region.startLine + 3, region.endLine); i++) {
          if (i < lines.length) {
            final line = lines[i].trim();
            if (line.isNotEmpty) {
              contentLines.add(line);
            }
          }
        }

        // Generate preview based on type
        String preview = '';
        switch (region.type) {
          case FoldingType.function:
            preview = '$startLineText { ... } // ${region.lineCount} lines';
            break;
          case FoldingType.classStruct:
            preview = '$startLineText { ... } // ${region.lineCount} lines';
            break;
          case FoldingType.comment:
            preview = '/* ... ${region.lineCount} lines of comments */';
            break;
          case FoldingType.imports:
            preview = '// ... ${region.lineCount} imports';
            break;
          case FoldingType.controlFlow:
            final content = contentLines.isNotEmpty ? contentLines.first : '...';
            preview = '$startLineText { $content ... }';
            break;
          case FoldingType.block:
            preview = '{ ... } // ${region.lineCount} lines';
            break;
        }

        region.metadata.preview = preview;
      }
    }
  }

  void _findFunctionRegions(List<String> lines) {
    final patterns = [
      RegExp(r'^\s*(void|int|String|double|bool|var|dynamic|Future|Stream)?\s+([a-zA-Z_]\w*)\s*\(([^)]*)\)\s*\{?\s*'),
          RegExp(r'^\s*(public|private|protected)?\s*func\s+([a-zA-Z_]\w*)\s*\(([^)]*)\)\s*\{?'),
      RegExp(r'^\s*def\s+([a-zA-Z_]\w*)\s*\(([^)]*)\)\s*:'),
      RegExp(r'^\s*function\s+([a-zA-Z_]\w*)\s*\(([^)]*)\)\s*\{'),
    ];

    for (int i = 0; i < lines.length; i++) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(lines[i]);
        if (match != null) {
          final endLine = _findClosingBrace(lines, i);
          if (endLine > i) {
            String funcName = '';
            String params = '';

            if (match.groupCount >= 2) {
              funcName = match.group(2) ?? match.group(1) ?? '';
              params = match.groupCount >= 3 ? (match.group(3) ?? '') : '';
            } else if (match.groupCount >= 1) {
              funcName = match.group(1) ?? '';
            }

            if (funcName.isNotEmpty) {
              _regions.add(FoldingRegion(
                startLine: i + 1,
                endLine: endLine + 1,
                type: FoldingType.function,
                displayText: funcName,
                metadata: FoldingMetadata(
                  parameters: params,
                  lineCount: endLine - i + 1,
                  complexity: _calculateComplexity(lines, i, endLine),
                ),
              ));
            }
          }
          break;
        }
      }
    }
  }

  void _findClassRegions(List<String> lines) {
    final patterns = [
      RegExp(r'^\s*class\s+([a-zA-Z_]\w*)'),
      RegExp(r'^\s*struct\s+([a-zA-Z_]\w*)'),
      RegExp(r'^\s*interface\s+([a-zA-Z_]\w*)'),
      RegExp(r'^\s*enum\s+([a-zA-Z_]\w*)'),
    ];

    for (int i = 0; i < lines.length; i++) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(lines[i]);
        if (match != null && match.group(1) != null) {
          final endLine = _findClosingBrace(lines, i);
          if (endLine > i) {
            _regions.add(FoldingRegion(
              startLine: i + 1,
              endLine: endLine + 1,
              type: FoldingType.classStruct,
              displayText: match.group(1)!,
              metadata: FoldingMetadata(
                lineCount: endLine - i + 1,
                complexity: _calculateComplexity(lines, i, endLine),
              ),
            ));
          }
          break;
        }
      }
    }
  }

  void _findControlFlowRegions(List<String> lines) {
    final pattern = RegExp(r'^\s*(if|else|while|for|do|switch)\s*[\(\{]');

    for (int i = 0; i < lines.length; i++) {
      final match = pattern.firstMatch(lines[i]);
      if (match != null && match.group(1) != null) {
        final endLine = _findClosingBrace(lines, i);
        if (endLine > i + 1) {
          _regions.add(FoldingRegion(
            startLine: i + 1,
            endLine: endLine + 1,
            type: FoldingType.controlFlow,
            displayText: match.group(1)!,
            metadata: FoldingMetadata(
              lineCount: endLine - i + 1,
            ),
          ));
        }
      }
    }
  }

  void _findCommentBlocks(List<String> lines) {
    int? blockStart;
    bool inMultiLineComment = false;

    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();

      if (trimmed.contains('/*')) {
        blockStart = i;
        inMultiLineComment = true;
      }

      if (inMultiLineComment && trimmed.contains('*/')) {
        if (blockStart != null && i - blockStart >= 2) {
          _regions.add(FoldingRegion(
            startLine: blockStart + 1,
            endLine: i + 1,
            type: FoldingType.comment,
            displayText: 'Comment Block',
            metadata: FoldingMetadata(lineCount: i - blockStart + 1),
          ));
        }
        blockStart = null;
        inMultiLineComment = false;
      }

      if (!inMultiLineComment) {
        if (trimmed.startsWith('//') && blockStart == null) {
          blockStart = i;
        } else if (!trimmed.startsWith('//') && blockStart != null) {
          if (i - blockStart >= 3) {
            _regions.add(FoldingRegion(
              startLine: blockStart + 1,
              endLine: i,
              type: FoldingType.comment,
              displayText: 'Comments',
              metadata: FoldingMetadata(lineCount: i - blockStart),
            ));
          }
          blockStart = null;
        }
      }
    }

    if (blockStart != null && lines.length - blockStart >= 3) {
      _regions.add(FoldingRegion(
        startLine: blockStart + 1,
        endLine: lines.length,
        type: FoldingType.comment,
        displayText: inMultiLineComment ? 'Comment Block' : 'Comments',
        metadata: FoldingMetadata(lineCount: lines.length - blockStart),
      ));
    }
  }

  void _findImportBlocks(List<String> lines) {
    int? blockStart;

    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();

      if (trimmed.startsWith('import ') ||
          trimmed.startsWith('package ') ||
          trimmed.startsWith('using ')) {
        blockStart ??= i;
      } else if (blockStart != null && trimmed.isNotEmpty) {
        if (i - blockStart >= 2) {
          _regions.add(FoldingRegion(
            startLine: blockStart + 1,
            endLine: i,
            type: FoldingType.imports,
            displayText: 'Imports',
            metadata: FoldingMetadata(lineCount: i - blockStart),
          ));
        }
        blockStart = null;
      }
    }
  }

  void _findBraceRegions(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('{')) {
        final endLine = _findClosingBrace(lines, i);
        if (endLine > i + 1) {
          final alreadyExists = _regions.any((r) =>
          r.startLine == i + 1 && r.endLine == endLine + 1);

          if (!alreadyExists) {
            _regions.add(FoldingRegion(
              startLine: i + 1,
              endLine: endLine + 1,
              type: FoldingType.block,
              displayText: 'Block',
              metadata: FoldingMetadata(lineCount: endLine - i + 1),
            ));
          }
        }
      }
    }
  }

  int _findClosingBrace(List<String> lines, int startLine) {
    int depth = 0;
    bool foundOpen = false;
    bool inString = false;
    bool inComment = false;
    String stringChar = '';

    for (int i = startLine; i < lines.length; i++) {
      final line = lines[i];

      for (int j = 0; j < line.length; j++) {
        final char = line[j];

        if (j > 0 && line[j - 1] == '\\') {
          continue;
        }

        if ((char == '"' || char == "'") && !inComment) {
          if (!inString) {
            inString = true;
            stringChar = char;
          } else if (char == stringChar) {
            inString = false;
            stringChar = '';
          }
          continue;
        }

        if (inString) continue;

        if (j < line.length - 1 && !inComment) {
          if (line[j] == '/' && line[j + 1] == '/') {
            break;
          }
          if (line[j] == '/' && line[j + 1] == '*') {
            inComment = true;
            j++;
            continue;
          }
        }

        if (inComment && j < line.length - 1) {
          if (line[j] == '*' && line[j + 1] == '/') {
            inComment = false;
            j++;
            continue;
          }
        }

        if (!inString && !inComment) {
          if (char == '{') {
            depth++;
            foundOpen = true;
          } else if (char == '}') {
            depth--;
            if (foundOpen && depth == 0) {
              return i;
            }
          }
        }
      }
    }
    return startLine;
  }

  void _detectNestedRegions() {
    for (int i = 0; i < _regions.length; i++) {
      for (int j = 0; j < _regions.length; j++) {
        if (i != j &&
            _regions[j].startLine > _regions[i].startLine &&
            _regions[j].endLine <= _regions[i].endLine) {
          _regions[i].metadata.nestedRegions++;
        }
      }
    }
  }

  int _calculateComplexity(List<String> lines, int start, int end) {
    int complexity = 1;
    final complexityPattern = RegExp(r'\b(if|while|for|switch|case|catch)\b');

    for (int i = start; i <= end && i < lines.length; i++) {
      if (complexityPattern.hasMatch(lines[i])) {
        complexity++;
      }
    }
    return complexity;
  }

  void toggleRegion(int startLine) {
    final wasCollapsed = _collapsedRegions.contains(startLine);

    if (wasCollapsed) {
      _collapsedRegions.remove(startLine);
    } else {
      _collapsedRegions.add(startLine);
    }

    _addHistory(startLine, wasCollapsed ? FoldingAction.expand : FoldingAction.collapse);
    _saveState();
  }

  void _addHistory(int line, FoldingAction action) {
    _history.add(FoldingHistory(
      timestamp: DateTime.now(),
      line: line,
      action: action,
    ));

    if (_history.length > _historyMaxSize) {
      _history.removeAt(0);
    }
  }

  void collapseAll() {
    for (final region in _regions) {
      _collapsedRegions.add(region.startLine);
    }
    _saveState();
  }

  void expandAll() {
    _collapsedRegions.clear();
    _saveState();
  }

  void collapseByType(FoldingType type) {
    for (final region in _regions) {
      if (region.type == type) {
        _collapsedRegions.add(region.startLine);
      }
    }
    _saveState();
  }

  void expandByType(FoldingType type) {
    _regions.where((r) => r.type == type).forEach((region) {
      _collapsedRegions.remove(region.startLine);
    });
    _saveState();
  }

  void collapseAllExcept(int currentLine) {
    final protectedRegions = <int>{};

    for (final region in _regions) {
      if (currentLine >= region.startLine && currentLine <= region.endLine) {
        protectedRegions.add(region.startLine);
      }
    }

    for (final region in _regions) {
      if (!protectedRegions.contains(region.startLine)) {
        _collapsedRegions.add(region.startLine);
      }
    }
    _saveState();
  }

  void collapseToLevel(int level) {
    expandAll();
    for (final region in _regions) {
      if (getRegionLevel(region) <= level) {
        _collapsedRegions.add(region.startLine);
      }
    }
    _saveState();
  }

  int getRegionLevel(FoldingRegion region) {
    int level = 0;
    for (final other in _regions) {
      if (other != region &&
          region.startLine > other.startLine &&
          region.endLine <= other.endLine) {
        level++;
      }
    }
    return level;
  }

  bool isCollapsed(int startLine) => _collapsedRegions.contains(startLine);

  FoldingRegion? getRegionAtLine(int line) {
    for (final region in _regions) {
      if (region.startLine == line) return region;
    }
    return null;
  }

  bool isLineHidden(int line) {
    for (final collapsedStart in _collapsedRegions) {
      final region = getRegionAtLine(collapsedStart);
      if (region != null &&
          line > region.startLine &&
          line <= region.endLine) {
        return true;
      }
    }
    return false;
  }

  int getIndentLevel(String line) {
    int level = 0;
    for (int i = 0; i < line.length; i++) {
      if (line[i] == ' ') {
        level++;
      } else if (line[i] == '\t') {
        level += 2;
      } else {
        break;
      }
    }
    return level ~/ 2;
  }

  Future<void> _saveState() async {
    if (_currentFilePath.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'folding_state_$_currentFilePath';
      final state = jsonEncode(_collapsedRegions.toList());
      await prefs.setString(key, state);
    } catch (e) {
      print('Failed to save folding state: $e');
    }
  }

  Future<void> loadState() async {
    if (_currentFilePath.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'folding_state_$_currentFilePath';
      final state = prefs.getString(key);

      if (state != null) {
        final List<dynamic> decoded = jsonDecode(state);
        _collapsedRegions.clear();
        _collapsedRegions.addAll(decoded.cast<int>());
      }
    } catch (e) {
      print('Failed to load folding state: $e');
    }
  }

  List<FoldingRegion> get allRegions => List.unmodifiable(_regions);

  Set<int> get collapsedRegions => Set.unmodifiable(_collapsedRegions);

  List<FoldingHistory> get history => List.unmodifiable(_history);

  void clear() {
    _regions.clear();
    _collapsedRegions.clear();
    _history.clear();
  }
}

class FoldingRegion {
  final int startLine;
  final int endLine;
  final FoldingType type;
  final String displayText;
  final FoldingMetadata metadata;

  FoldingRegion({
    required this.startLine,
    required this.endLine,
    required this.type,
    required this.displayText,
    FoldingMetadata? metadata,
  }) : metadata = metadata ?? FoldingMetadata();

  int get lineCount => endLine - startLine + 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FoldingRegion &&
              runtimeType == other.runtimeType &&
              startLine == other.startLine &&
              endLine == other.endLine;

  @override
  int get hashCode => startLine.hashCode ^ endLine.hashCode;
}

class FoldingMetadata {
  String? parameters;
  int lineCount;
  int complexity;
  int nestedRegions;
  String? preview;

  FoldingMetadata({
    this.parameters,
    this.lineCount = 0,
    this.complexity = 0,
    this.nestedRegions = 0,
    this.preview,
  });
}

enum FoldingType {
  function,
  classStruct,
  controlFlow,
  block,
  comment,
  imports,
}

class FoldingHistory {
  final DateTime timestamp;
  final int line;
  final FoldingAction action;

  FoldingHistory({
    required this.timestamp,
    required this.line,
    required this.action,
  });
}

enum FoldingAction { collapse, expand }

class FoldingKeyboardHandler extends StatelessWidget {
  final Widget child;
  final AdvancedCodeFoldingManager foldingManager;
  final VoidCallback onUpdate;
  final int Function() getCurrentLine;

  const FoldingKeyboardHandler({
    Key? key,
    required this.child,
    required this.foldingManager,
    required this.onUpdate,
    required this.getCurrentLine,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // Ctrl+Shift+[ : Collapse at current line
          if (event.logicalKey == LogicalKeyboardKey.bracketLeft &&
              HardwareKeyboard.instance.isControlPressed &&
              HardwareKeyboard.instance.isShiftPressed) {
            final currentLine = getCurrentLine();
            final region = foldingManager.getRegionAtLine(currentLine);
            if (region != null) {
              foldingManager.toggleRegion(currentLine);
              onUpdate();
            }
            return KeyEventResult.handled;
          }

          // Ctrl+Shift+] : Expand at current line
          if (event.logicalKey == LogicalKeyboardKey.bracketRight &&
              HardwareKeyboard.instance.isControlPressed &&
              HardwareKeyboard.instance.isShiftPressed) {
            final currentLine = getCurrentLine();
            final region = foldingManager.getRegionAtLine(currentLine);
            if (region != null && foldingManager.isCollapsed(currentLine)) {
              foldingManager.toggleRegion(currentLine);
              onUpdate();
            }
            return KeyEventResult.handled;
          }

          // Ctrl+K Ctrl+0 : Collapse All
          if (event.logicalKey == LogicalKeyboardKey.digit0 &&
              HardwareKeyboard.instance.isControlPressed) {
            foldingManager.collapseAll();
            onUpdate();
            return KeyEventResult.handled;
          }

          // Ctrl+K Ctrl+J : Expand All
          if (event.logicalKey == LogicalKeyboardKey.keyJ &&
              HardwareKeyboard.instance.isControlPressed) {
            foldingManager.expandAll();
            onUpdate();
            return KeyEventResult.handled;
          }

          // Ctrl+K Ctrl+1-9 : Collapse to level
          for (int i = 1; i <= 9; i++) {
            if (event.logicalKey == LogicalKeyboardKey(0x00000031 + (i - 1)) &&
                HardwareKeyboard.instance.isControlPressed) {
              foldingManager.collapseToLevel(i);
              onUpdate();
              return KeyEventResult.handled;
            }
          }

          // Ctrl+K Ctrl+- : Collapse All Except Current
          if (event.logicalKey == LogicalKeyboardKey.minus &&
              HardwareKeyboard.instance.isControlPressed) {
            foldingManager.collapseAllExcept(getCurrentLine());
            onUpdate();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

class AdvancedFoldingGutter extends StatefulWidget {
  final int lineCount;
  final AdvancedCodeFoldingManager foldingManager;
  final VoidCallback onToggle;
  final ScrollController scrollController;
  final int currentLine;
  final bool showAnimations;
  final bool enableHapticFeedback;

  const AdvancedFoldingGutter({
    Key? key,
    required this.lineCount,
    required this.foldingManager,
    required this.onToggle,
    required this.scrollController,
    required this.currentLine,
    this.showAnimations = true,
    this.enableHapticFeedback = true,
  }) : super(key: key);

  @override
  State<AdvancedFoldingGutter> createState() => _AdvancedFoldingGutterState();
}

class _AdvancedFoldingGutterState extends State<AdvancedFoldingGutter>
    with TickerProviderStateMixin {
  final Map<int, AnimationController> _controllers = {};
  int? _hoveredLine;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  AnimationController _getController(int line) {
    if (!_controllers.containsKey(line)) {
      _controllers[line] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );
    }
    return _controllers[line]!;
  }

  @override
  Widget build(BuildContext context) {
    const double lineHeight = 14.0 * 1.4;
    final theme = Theme.of(context);

    return MouseRegion(
      onExit: (_) => setState(() => _hoveredLine = null),
      child: Container(
        width: 24,
        padding: const EdgeInsets.only(top: 16),
        child: ListView.builder(
          controller: widget.scrollController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.lineCount,
          itemBuilder: (context, index) {
            final lineNumber = index + 1;

            if (widget.foldingManager.isLineHidden(lineNumber)) {
              return const SizedBox.shrink();
            }

            final region = widget.foldingManager.getRegionAtLine(lineNumber);
            final isCollapsed = region != null &&
                widget.foldingManager.isCollapsed(lineNumber);

            if (region != null && widget.showAnimations) {
              final controller = _getController(lineNumber);
              if (isCollapsed) {
                controller.forward();
              } else {
                controller.reverse();
              }
            }

            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredLine = lineNumber),
              child: SizedBox(
                height: lineHeight,
                child: region != null
                    ? _buildFoldingButton(
                  context,
                  lineNumber,
                  region,
                  isCollapsed,
                  theme,
                  _hoveredLine == lineNumber,
                )
                    : _buildConnectorLine(context, lineNumber, theme),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFoldingButton(
      BuildContext context,
      int lineNumber,
      FoldingRegion region,
      bool isCollapsed,
      ThemeData theme,
      bool isHovered,
      ) {
    final controller = widget.showAnimations ? _getController(lineNumber) : null;

    Widget button = widget.showAnimations && controller != null
        ? AnimatedBuilder(
      animation: controller,
      builder: (context, child) => _buildButton(
        context,
        lineNumber,
        region,
        isCollapsed,
        theme,
        isHovered,
        controller.value,
      ),
    )
        : _buildButton(
      context,
      lineNumber,
      region,
      isCollapsed,
      theme,
      isHovered,
      isCollapsed ? 1.0 : 0.0,
    );

    if (isHovered && region.metadata.preview != null) {
      return Tooltip(
        message: '${region.displayText}\n'
            'Lines: ${region.metadata.lineCount}\n'
            '${region.metadata.complexity > 1 ? "Complexity: ${region.metadata.complexity}\n" : ""}'
            '${region.metadata.nestedRegions > 0 ? "Nested: ${region.metadata.nestedRegions}\n" : ""}'
            'Click to ${isCollapsed ? "expand" : "collapse"}\n'
            'Ctrl+Shift+[ to toggle',
        preferBelow: false,
        verticalOffset: 20,
        child: button,
      );
    }

    return Center(child: button);
  }

  Widget _buildButton(
      BuildContext context,
      int lineNumber,
      FoldingRegion region,
      bool isCollapsed,
      ThemeData theme,
      bool isHovered,
      double animationValue,
      ) {
    return InkWell(
      onTap: () {
        widget.foldingManager.toggleRegion(lineNumber);
        widget.onToggle();
        if (widget.enableHapticFeedback) {
          HapticFeedback.lightImpact();
        }
      },
      borderRadius: BorderRadius.circular(3),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getColorForType(region.type).withOpacity(0.2),
              _getColorForType(region.type).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isHovered
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.4),
            width: isHovered ? 1.5 : 1,
          ),
          boxShadow: isHovered
              ? [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 4,
            ),
          ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Transform.rotate(
                angle: animationValue * math.pi / 2,
                child: Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: _getColorForType(region.type),
                ),
              ),
            ),
            if (region.metadata.nestedRegions > 0)
              Positioned(
                right: 1,
                top: 1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectorLine(
      BuildContext context,
      int lineNumber,
      ThemeData theme,
      ) {
    final hasParent = widget.foldingManager.allRegions.any((r) =>
    lineNumber > r.startLine &&
        lineNumber <= r.endLine &&
        !widget.foldingManager.isCollapsed(r.startLine));

    if (!hasParent) return const SizedBox.shrink();

    return Center(
      child: Container(
        width: 1,
        height: 14.0 * 1.4,
        color: theme.colorScheme.outline.withOpacity(0.2),
      ),
    );
  }

  Color _getColorForType(FoldingType type) {
    switch (type) {
      case FoldingType.function:
        return Colors.amber;
      case FoldingType.classStruct:
        return Colors.purple;
      case FoldingType.controlFlow:
        return Colors.blue;
      case FoldingType.comment:
        return Colors.grey;
      case FoldingType.imports:
        return Colors.green;
      case FoldingType.block:
        return Colors.cyan;
    }
  }
}

class FoldedCodePreview extends StatelessWidget {
  final FoldingRegion region;
  final VoidCallback onExpand;
  final ThemeData theme;

  const FoldedCodePreview({
    Key? key,
    required this.region,
    required this.onExpand,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColorForType(region.type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getColorForType(region.type).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.chevron_right,
            size: 16,
            color: _getColorForType(region.type),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              region.metadata.preview ?? '...',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.unfold_more, size: 16),
            onPressed: onExpand,
            tooltip: 'Expand (Ctrl+Shift+])',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Color _getColorForType(FoldingType type) {
    switch (type) {
      case FoldingType.function:
        return Colors.amber;
      case FoldingType.classStruct:
        return Colors.purple;
      case FoldingType.controlFlow:
        return Colors.blue;
      case FoldingType.comment:
        return Colors.grey;
      case FoldingType.imports:
        return Colors.green;
      case FoldingType.block:
        return Colors.cyan;
    }
  }
}

class FoldingQuickActions extends StatelessWidget {
  final AdvancedCodeFoldingManager foldingManager;
  final VoidCallback onUpdate;
  final int currentLine;

  const FoldingQuickActions({
    Key? key,
    required this.foldingManager,
    required this.onUpdate,
    required this.currentLine,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildActionButton(
            context,
            'Collapse All',
            Icons.unfold_less,
                () {
              foldingManager.collapseAll();
              onUpdate();
            },
            'Ctrl+K Ctrl+0',
          ),
          _buildActionButton(
            context,
            'Expand All',
            Icons.unfold_more,
                () {
              foldingManager.expandAll();
              onUpdate();
            },
            'Ctrl+K Ctrl+J',
          ),
          _buildActionButton(
            context,
            'Collapse Functions',
            Icons.functions,
                () {
              foldingManager.collapseByType(FoldingType.function);
              onUpdate();
            },
          ),
          _buildActionButton(
            context,
            'Collapse Comments',
            Icons.comment,
                () {
              foldingManager.collapseByType(FoldingType.comment);
              onUpdate();
            },
          ),
          _buildActionButton(
            context,
            'Collapse Imports',
            Icons.file_download,
                () {
              foldingManager.collapseByType(FoldingType.imports);
              onUpdate();
            },
          ),
          _buildActionButton(
            context,
            'Collapse Others',
            Icons.filter_center_focus,
                () {
              foldingManager.collapseAllExcept(currentLine);
              onUpdate();
            },
            'Ctrl+K Ctrl+-',
          ),
          _buildActionButton(
            context,
            'Level 1',
            Icons.looks_one,
                () {
              foldingManager.collapseToLevel(1);
              onUpdate();
            },
            'Ctrl+K Ctrl+1',
          ),
          _buildActionButton(
            context,
            'Level 2',
            Icons.looks_two,
                () {
              foldingManager.collapseToLevel(2);
              onUpdate();
            },
            'Ctrl+K Ctrl+2',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      String label,
      IconData icon,
      VoidCallback onPressed, [
        String? shortcut,
      ]) {
    return Tooltip(
      message: shortcut ?? label,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 32),
        ),
      ),
    );
  }
}

class AdvancedIndentGuides extends StatelessWidget {
  final String sourceCode;
  final AdvancedCodeFoldingManager foldingManager;
  final ScrollController scrollController;
  final int currentLine;
  final bool showRainbow;

  const AdvancedIndentGuides({
    Key? key,
    required this.sourceCode,
    required this.foldingManager,
    required this.scrollController,
    required this.currentLine,
    this.showRainbow = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lines = sourceCode.split('\n');
    const double lineHeight = 14.0 * 1.4;
    const double indentWidth = 16.0;
    final theme = Theme.of(context);

    return CustomPaint(
      painter: AdvancedIndentGuidesPainter(
        lines: lines,
        foldingManager: foldingManager,
        lineHeight: lineHeight,
        indentWidth: indentWidth,
        currentLine: currentLine,
        showRainbow: showRainbow,
        baseColor: theme.colorScheme.outline.withOpacity(0.15),
        activeColor: theme.colorScheme.primary.withOpacity(0.4),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class AdvancedIndentGuidesPainter extends CustomPainter {
  final List<String> lines;
  final AdvancedCodeFoldingManager foldingManager;
  final double lineHeight;
  final double indentWidth;
  final int currentLine;
  final bool showRainbow;
  final Color baseColor;
  final Color activeColor;

  static final List<Color> rainbowColors = [
    Colors.red.withOpacity(0.3),
    Colors.orange.withOpacity(0.3),
    Colors.yellow.withOpacity(0.3),
    Colors.green.withOpacity(0.3),
    Colors.blue.withOpacity(0.3),
    Colors.purple.withOpacity(0.3),
  ];

  AdvancedIndentGuidesPainter({
    required this.lines,
    required this.foldingManager,
    required this.lineHeight,
    required this.indentWidth,
    required this.currentLine,
    required this.showRainbow,
    required this.baseColor,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < lines.length; i++) {
      final lineNumber = i + 1;

      if (foldingManager.isLineHidden(lineNumber)) continue;

      final level = foldingManager.getIndentLevel(lines[i]);
      final y = i * lineHeight + lineHeight / 2 + 16;
      final isCurrentLine = lineNumber == currentLine;

      for (int l = 1; l <= level; l++) {
        final x = l * indentWidth + 36;

        final paint = Paint()
          ..strokeWidth = isCurrentLine && l == level ? 2.0 : 1.0
          ..style = PaintingStyle.stroke;

        if (showRainbow) {
          paint.color = rainbowColors[l % rainbowColors.length];
        } else {
          paint.color = isCurrentLine && l == level ? activeColor : baseColor;
        }

        _drawDashedLine(
          canvas,
          Offset(x, y - lineHeight / 2),
          Offset(x, y + lineHeight / 2),
          paint,
        );
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 3.0;
    const dashSpace = 2.0;
    final distance = (end - start).distance;
    final dashCount = distance / (dashWidth + dashSpace);

    for (int i = 0; i < dashCount; i++) {
      final startY = start.dy + (i * (dashWidth + dashSpace));
      final endY = (startY + dashWidth).clamp(start.dy, end.dy);
      canvas.drawLine(Offset(start.dx, startY), Offset(start.dx, endY), paint);
    }
  }

  @override
  bool shouldRepaint(AdvancedIndentGuidesPainter oldDelegate) {
    return oldDelegate.lines.length != lines.length ||
        oldDelegate.currentLine != currentLine;
  }
}
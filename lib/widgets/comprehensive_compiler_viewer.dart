import 'package:flutter/material.dart';
import '../models/token_types.dart';
import '../models/ast_nodes.dart';
import '../compiler/lexer.dart';
import '../compiler/parser.dart';
import '../compiler/semantic_analyzer.dart';
import '../compiler/interpreter.dart';
import '../compiler/minilang_optimizer.dart';
import '../widgets/compiler_phase_viewers.dart';

class ComprehensiveCompilerViewer extends StatefulWidget {
  final String sourceCode;

  const ComprehensiveCompilerViewer({
    super.key,
    required this.sourceCode,
  });

  @override
  State<ComprehensiveCompilerViewer> createState() => _ComprehensiveCompilerViewerState();
}

class _ComprehensiveCompilerViewerState extends State<ComprehensiveCompilerViewer> {
  int _selectedPhaseIndex = 0;

  // Compiler components
  late Lexer _lexer;
  late Parser _parser;
  late SemanticAnalyzer _semanticAnalyzer;
  late Optimizer _optimizer;
  late Interpreter _interpreter;

  // Compilation artifacts
  List<Token>? _tokens;
  Program? _ast;
  Map<String, dynamic>? _symbolTable;
  OptimizationResult? _optimizationResult;
  InterpreterResult? _interpreterResult;

  // List of all phases for the UI
  final List<CompilerPhaseInfo> _phases = [
    CompilerPhaseInfo(
      name: 'Lexical Analysis',
      icon: Icons.token_rounded,
      color: const Color(0xFF8B5CF6),
      description: 'Converts source code into tokens',
    ),
    CompilerPhaseInfo(
      name: 'Syntax Analysis',
      icon: Icons.account_tree_rounded,
      color: const Color(0xFF3B82F6),
      description: 'Builds Abstract Syntax Tree',
    ),
    CompilerPhaseInfo(
      name: 'Semantic Analysis',
      icon: Icons.table_chart_rounded,
      color: const Color(0xFF10B981),
      description: 'Type checking and validation',
    ),
    CompilerPhaseInfo(
      name: 'Optimization',
      icon: Icons.speed_rounded,
      color: const Color(0xFFEC4899),
      description: 'Code optimization passes',
    ),
    CompilerPhaseInfo(
      name: 'Interpretation',
      icon: Icons.play_circle_outline_rounded,
      color: const Color(0xFFF59E0B),
      description: 'Executes the program',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _compileCode();
  }

  void _compileCode() {
    // Reset previous results
    _tokens = null;
    _ast = null;
    _symbolTable = null;
    _optimizationResult = null;
    _interpreterResult = null;

    try {
      // 1. Lexical Analysis
      _lexer = Lexer(widget.sourceCode);
      _tokens = _lexer.tokenize();
      if (_lexer.hasErrors) return;

      // 2. Syntax Analysis
      _parser = Parser(_tokens!);
      _ast = _parser.parse();
      if (_parser.hasErrors) return;

      // 3. Semantic Analysis
      if (_ast != null) {
        _semanticAnalyzer = SemanticAnalyzer();
        _semanticAnalyzer.analyze(_ast!);
        _symbolTable = _semanticAnalyzer.getSymbolTableAsMap();
        if (_semanticAnalyzer.hasErrors) return;
      }

      // 4. Optimization
      if (_ast != null) {
        _optimizer = Optimizer(config: OptimizerConfig.aggressive);
        _optimizationResult = _optimizer.optimize(_ast!);
      }

      // 5. Interpretation
      final astToInterpret = _optimizationResult?.optimizedProgram ?? _ast;
      if (astToInterpret != null) {
        _interpreter = Interpreter(astToInterpret);
        _interpreterResult = _interpreter.interpret();
      }
    } catch (e) {
      debugPrint('A critical error occurred during compilation: $e');
    } finally {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 700;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Compiler Viewer',
          style: TextStyle(fontSize: isTablet ? 20 : 16),
        ),
        backgroundColor: theme.colorScheme.surfaceVariant,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: 'Recompile',
            onPressed: _compileCode,
          ),
        ],
      ),
      body: isLandscape && isTablet
          ? _buildLandscapeLayout(context)
          : _buildPortraitLayout(context),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 280,
          child: _buildSidebar(context),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.background,
            child: _buildPhaseContent(context),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Column(
      children: [
        _buildCompactHeader(context, isSmallScreen),
        const Divider(height: 1),
        Expanded(
          child: _buildPhaseContent(context),
        ),
      ],
    );
  }

  Widget _buildCompactHeader(BuildContext context, bool isSmallScreen) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_phases.length, (index) {
                final phase = _phases[index];
                final isSelected = _selectedPhaseIndex == index;
                final hasError = _getPhaseHasError(index);
                final isComplete = _getPhaseIsComplete(index);

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(phase.icon, size: 14, color: isSelected ? Colors.white : phase.color),
                        const SizedBox(width: 4),
                        Text(
                          phase.name.split(' ').first,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 11,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                      ],
                    ),
                    avatar: _buildCompactStatusIcon(isComplete, hasError, isSelected),
                    onSelected: (selected) {
                      setState(() {
                        _selectedPhaseIndex = index;
                      });
                    },
                    backgroundColor: theme.colorScheme.surface,
                    selectedColor: phase.color,
                    checkmarkColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : 8,
                      vertical: 4,
                    ),
                  ),
                );
              }),
            ),
          ),
          if (!isSmallScreen) ...[
            const SizedBox(height: 8),
            _buildCompilationSummaryCompact(context),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactStatusIcon(bool isComplete, bool hasError, bool isSelected) {
    if (hasError) {
      return Icon(Icons.error, size: 14, color: isSelected ? Colors.white : Colors.red);
    }
    if (isComplete) {
      return Icon(Icons.check_circle, size: 14, color: isSelected ? Colors.white : Colors.green);
    }
    return Icon(Icons.radio_button_unchecked, size: 14, color: isSelected ? Colors.white : Colors.grey);
  }

  Widget _buildCompilationSummaryCompact(BuildContext context) {
    final theme = Theme.of(context);

    int totalErrors = (_lexer.errors.length) +
        (_parser.errors.length) +
        (_semanticAnalyzer.errors.length) +
        (_interpreter.errors.where((e) => e.type == MessageType.error).length);

    int totalWarnings = (_lexer.warnings.length) +
        (_parser.warnings.length) +
        (_semanticAnalyzer.warnings.length) +
        (_optimizationResult?.warnings.length ?? 0) +
        (_interpreter.errors.where((e) => e.type == MessageType.warning).length);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (totalErrors > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  '$totalErrors',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        if (totalErrors > 0 && totalWarnings > 0) const SizedBox(width: 8),
        if (totalWarnings > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_outlined, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  '$totalWarnings',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSourceCodePreview(context),
          const Divider(height: 16),
          ...List.generate(_phases.length, (index) {
            return _buildPhaseCard(context, index);
          }),
          const Divider(height: 16),
          _buildCompilationSummary(context),
        ],
      ),
    );
  }

  Widget _buildSourceCodePreview(BuildContext context) {
    final theme = Theme.of(context);
    final lines = widget.sourceCode.split('\n');
    final preview = lines.take(3).join('\n');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.code, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Source Code',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Text(
              preview + (lines.length > 3 ? '\n...' : ''),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 10,
                height: 1.3,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${lines.length} lines • ${widget.sourceCode.length} chars',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(BuildContext context, int index) {
    final theme = Theme.of(context);
    final phase = _phases[index];
    final isSelected = _selectedPhaseIndex == index;
    final hasError = _getPhaseHasError(index);
    final isComplete = _getPhaseIsComplete(index);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: isSelected ? 3 : 0,
      color: isSelected ? phase.color.withOpacity(0.1) : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? phase.color : theme.colorScheme.outline.withOpacity(0.2),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPhaseIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(phase.icon, size: 20, color: phase.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      phase.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildPhaseStatusIcon(isComplete, hasError),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseStatusIcon(bool isComplete, bool hasError) {
    if (hasError) {
      return const Icon(Icons.error_outline, color: Colors.red, size: 20);
    }
    if (isComplete) {
      return const Icon(Icons.check_circle_outline, color: Colors.green, size: 20);
    }
    return Icon(Icons.radio_button_unchecked, color: Colors.grey.withOpacity(0.5), size: 20);
  }

  bool _getPhaseHasError(int index) {
    switch (index) {
      case 0: return _lexer.hasErrors;
      case 1: return _parser.hasErrors;
      case 2: return _semanticAnalyzer.hasErrors;
      case 3: return _optimizationResult?.warnings.isNotEmpty ?? false;
      case 4: return _interpreter.errors.isNotEmpty;
      default: return false;
    }
  }

  bool _getPhaseIsComplete(int index) {
    switch (index) {
      case 0: return _tokens != null;
      case 1: return _ast != null;
      case 2: return _symbolTable != null;
      case 3: return _optimizationResult != null;
      case 4: return _interpreterResult != null;
      default: return false;
    }
  }

  Widget _buildCompilationSummary(BuildContext context) {
    final theme = Theme.of(context);

    int totalErrors = (_lexer.errors.length) +
        (_parser.errors.length) +
        (_semanticAnalyzer.errors.length) +
        (_interpreter.errors.where((e) => e.type == MessageType.error).length);

    int totalWarnings = (_lexer.warnings.length) +
        (_parser.warnings.length) +
        (_semanticAnalyzer.warnings.length) +
        (_optimizationResult?.warnings.length ?? 0) +
        (_interpreter.errors.where((e) => e.type == MessageType.warning).length);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              context,
              'Errors',
              totalErrors.toString(),
              Icons.error_outline,
              totalErrors > 0 ? Colors.red : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryItem(
              context,
              'Warnings',
              totalWarnings.toString(),
              Icons.warning_amber_outlined,
              totalWarnings > 0 ? Colors.orange : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent(BuildContext context) {
    switch (_selectedPhaseIndex) {
      case 0:
        return LexerPhaseViewer(
          tokens: _tokens,
          errors: _lexer.errors,
          warnings: _lexer.warnings,
        );
      case 1:
        return ParserPhaseViewer(
          ast: _ast,
          errors: _parser.errors,
          warnings: _parser.warnings,
        );
      case 2:
        return SemanticPhaseViewer(
          symbolTable: _symbolTable,
          errors: _semanticAnalyzer.errors,
          warnings: _semanticAnalyzer.warnings,
        );
      case 3:
        return OptimizerPhaseViewer(
          optimizationResult: _optimizationResult,
          originalAST: _ast,
        );
      case 4:
        return InterpreterPhaseViewer(
          result: _interpreterResult,
          errors: _interpreter.errors,
        );
      default:
        return const Center(child: Text('Select a compilation phase'));
    }
  }
}

class CompilerPhaseInfo {
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  CompilerPhaseInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}
import 'package:flutter/material.dart';
import '../models/token_types.dart';
import '../models/ast_nodes.dart';
import '../compiler/lexer.dart';
import '../compiler/parser.dart';
import '../compiler/semantic_analyzer.dart';
import '../compiler/interpreter.dart';
import 'compiler_phase_viewers.dart';

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

  late Lexer _lexer;
  late Parser _parser;
  late SemanticAnalyzer _semanticAnalyzer;
  late Interpreter _interpreter;

  List<Token>? _tokens;
  Program? _ast;
  Map<String, dynamic>? _symbolTable;
  InterpreterResult? _interpreterResult;

  final List<CompilerPhaseInfo> _phases = [
    CompilerPhaseInfo(
      name: 'Lexical Analysis',
      icon: Icons.token_rounded,
      color: Color(0xFF8B5CF6),
      description: 'Converts source code into tokens',
    ),
    CompilerPhaseInfo(
      name: 'Syntax Analysis',
      icon: Icons.account_tree_rounded,
      color: Color(0xFF3B82F6),
      description: 'Builds Abstract Syntax Tree',
    ),
    CompilerPhaseInfo(
      name: 'Semantic Analysis',
      icon: Icons.table_chart_rounded,
      color: Color(0xFF10B981),
      description: 'Type checking and validation',
    ),
    CompilerPhaseInfo(
      name: 'Interpretation',
      icon: Icons.play_circle_outline_rounded,
      color: Color(0xFFF59E0B),
      description: 'Executes the program',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _compileCode();
  }

  void _compileCode() {
    try {
      _lexer = Lexer(widget.sourceCode);
      _tokens = _lexer.tokenize();

      if (_tokens != null && !_lexer.hasErrors) {
        _parser = Parser(_tokens!);
        _ast = _parser.parse();
      }

      if (_ast != null && !_parser.hasErrors) {
        _semanticAnalyzer = SemanticAnalyzer();
        _semanticAnalyzer.analyze(_ast!);
        _symbolTable = _semanticAnalyzer.getSymbolTableAsMap();
      }

      if (_ast != null && !_semanticAnalyzer.hasErrors) {
        _interpreter = Interpreter(_ast!);
        _interpreterResult = _interpreter.interpret();
      }
    } catch (e) {
      print('Compilation error: $e');
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

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
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSidebar(context),
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: _buildPhaseContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSourceCodePreview(context),
          const Divider(height: 1),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: _phases.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 160,
                  child: _buildPhaseCard(context, index),
                );
              },
            ),
          ),
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
      padding: const EdgeInsets.all(12),
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
      margin: const EdgeInsets.only(bottom: 6, right: 6),
      elevation: isSelected ? 3 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? phase.color : theme.colorScheme.outline.withOpacity(0.2),
          width: isSelected ? 2 : 1,
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
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: phase.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(phase.icon, size: 16, color: phase.color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phase.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          phase.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildPhaseStatusIcon(isComplete, hasError),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseStatusIcon(bool isComplete, bool hasError) {
    return Icon(
      hasError ? Icons.error_outline : (isComplete ? Icons.check_circle_outline : Icons.radio_button_unchecked),
      color: hasError ? Colors.red : (isComplete ? Colors.green : Colors.grey),
      size: 18,
    );
  }

  bool _getPhaseHasError(int index) {
    switch (index) {
      case 0: return _lexer.hasErrors;
      case 1: return _parser.hasErrors;
      case 2: return _semanticAnalyzer.hasErrors;
      case 3: return _interpreter.errors.isNotEmpty;
      default: return false;
    }
  }

  bool _getPhaseIsComplete(int index) {
    switch (index) {
      case 0: return _tokens != null;
      case 1: return _ast != null;
      case 2: return _symbolTable != null;
      case 3: return _interpreterResult != null;
      default: return false;
    }
  }

  Widget _buildCompilationSummary(BuildContext context) {
    final theme = Theme.of(context);

    int totalErrors = 0;
    int totalWarnings = 0;

    totalErrors += _lexer.errors.length;
    totalWarnings += _lexer.warnings.length;

    if (_parser != null) {
      totalErrors += _parser.errors.length;
      totalWarnings += _parser.warnings.length;
    }

    if (_semanticAnalyzer != null) {
      totalErrors += _semanticAnalyzer.errors.length;
      totalWarnings += _semanticAnalyzer.warnings.length;
    }

    if (_interpreter != null) {
      totalErrors += _interpreter.errors.where((e) => e.type == MessageType.error).length;
      totalWarnings += _interpreter.errors.where((e) => e.type == MessageType.warning).length;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
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
          errors: _parser?.errors ?? [],
          warnings: _parser?.warnings ?? [],
        );
      case 2:
        return SemanticPhaseViewer(
          symbolTable: _symbolTable,
          errors: _semanticAnalyzer?.errors ?? [],
          warnings: _semanticAnalyzer?.warnings ?? [],
        );
      case 3:
        return InterpreterPhaseViewer(
          result: _interpreterResult,
          errors: _interpreter?.errors ?? [],
        );
      default:
        return const Center(child: Text('Unknown phase'));
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
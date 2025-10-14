import 'package:flutter/material.dart';
import '../models/token_types.dart';
import '../models/ast_nodes.dart';
import '../compiler/interpreter.dart';
import '../compiler/minilang_optimizer.dart';

// Lexer Phase Viewer
class LexerPhaseViewer extends StatefulWidget {
  final List<Token>? tokens;
  final List<CompilerError> errors;
  final List<CompilerError> warnings;

  const LexerPhaseViewer({
    super.key,
    this.tokens,
    required this.errors,
    required this.warnings,
  });

  @override
  State<LexerPhaseViewer> createState() => _LexerPhaseViewerState();
}

class _LexerPhaseViewerState extends State<LexerPhaseViewer> {
  String _filterType = 'All';
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildHeader(context),
        if (widget.errors.isNotEmpty || widget.warnings.isNotEmpty)
          _buildMessagesSection(context),
        if (widget.tokens != null && widget.tokens!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildFilterChips(context),
          const SizedBox(height: 8),
          _buildStatistics(context),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: widget.tokens == null || widget.tokens!.isEmpty
              ? _buildEmptyState(context)
              : _buildTokensView(context),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6),
                  const Color(0xFF8B5CF6).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.token_rounded, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lexical Analysis',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Tokenizing source code',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_problem_outlined, color: theme.colorScheme.error, size: 18),
              const SizedBox(width: 6),
              Text(
                'Compilation Messages',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.errors.map((error) => _buildMessageItem(context, error, true)),
          ...widget.warnings.map((warning) => _buildMessageItem(context, warning, false)),
        ],
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, CompilerError message, bool isError) {
    final theme = Theme.of(context);
    final color = isError ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.warning_amber_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final categories = ['All', 'Keywords', 'Identifiers', 'Literals', 'Operators'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: categories.map((category) {
          final isSelected = _filterType == category;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(category, style: TextStyle(fontSize: 11)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filterType = category;
                });
              },
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              selectedColor: const Color(0xFF8B5CF6).withOpacity(0.2),
              checkmarkColor: const Color(0xFF8B5CF6),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF8B5CF6) : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatistics(BuildContext context) {
    final theme = Theme.of(context);
    final filteredTokens = _filterType == 'All'
        ? widget.tokens!
        : widget.tokens!.where((t) => _getTokenCategory(t.type) == _filterType).toList();
    final types = filteredTokens.map((t) => t.type).toSet().length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(context, 'Total', '${filteredTokens.length}', Icons.numbers),
          ),
          Container(
            width: 1,
            height: 30,
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(context, 'Types', '$types', Icons.category_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8B5CF6)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8B5CF6),
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTokensView(BuildContext context) {
    final theme = Theme.of(context);
    final filteredTokens = _filterType == 'All'
        ? widget.tokens!
        : widget.tokens!.where((t) => _getTokenCategory(t.type) == _filterType).toList();

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: (filteredTokens.length / 3).ceil(),
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, rowIndex) {
          final startIndex = rowIndex * 3;
          final endIndex = (startIndex + 3).clamp(0, filteredTokens.length);
          final rowTokens = filteredTokens.sublist(startIndex, endIndex);

          return Wrap(
            spacing: 6,
            runSpacing: 6,
            children: rowTokens.map((token) => _buildTokenChip(context, token)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildTokenChip(BuildContext context, Token token) {
    final theme = Theme.of(context);
    final color = _getTokenColor(token.type);

    return InkWell(
      onTap: () => _showTokenDetails(context, token),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              token.type.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 8,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              token.value.isEmpty ? '(empty)' : token.value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showTokenDetails(BuildContext context, Token token) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: _getTokenColor(token.type), size: 20),
            const SizedBox(width: 8),
            const Text('Token Details', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', token.type.name),
            _buildDetailRow('Value', token.value),
            _buildDetailRow('Line', '${token.line}'),
            _buildDetailRow('Column', '${token.column}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Color _getTokenColor(TokenType type) {
    final category = _getTokenCategory(type);
    switch (category) {
      case 'Keywords': return const Color(0xFFEF4444);
      case 'Identifiers': return const Color(0xFF3B82F6);
      case 'Literals': return const Color(0xFF10B981);
      case 'Operators': return const Color(0xFFF59E0B);
      case 'Delimiters': return const Color(0xFF8B5CF6);
      default: return Colors.grey;
    }
  }

  String _getTokenCategory(TokenType type) {
    if ([
      TokenType.INT, TokenType.STRING, TokenType.BOOLEAN, TokenType.FLOAT,
      TokenType.VOID, TokenType.VAR, TokenType.FOR, TokenType.WHILE,
      TokenType.DO, TokenType.IF, TokenType.ELSE, TokenType.SWITCH,
      TokenType.CASE, TokenType.DEFAULT, TokenType.PRINT, TokenType.RETURN,
      TokenType.BREAK, TokenType.CONTINUE, TokenType.CONST, TokenType.TRUE,
      TokenType.FALSE, TokenType.NULL,
    ].contains(type)) {
      return 'Keywords';
    } else if (type == TokenType.IDENTIFIER) {
      return 'Identifiers';
    } else if ([
      TokenType.NUMBER, TokenType.STRING_LITERAL, TokenType.FLOAT_LITERAL,
    ].contains(type)) {
      return 'Literals';
    } else if ([
      TokenType.ASSIGN, TokenType.PLUS, TokenType.MINUS, TokenType.MULTIPLY,
      TokenType.DIVIDE, TokenType.MODULO, TokenType.EQUAL, TokenType.NOT_EQUAL,
      TokenType.GREATER, TokenType.LESS, TokenType.AND, TokenType.OR, TokenType.NOT,
    ].contains(type)) {
      return 'Operators';
    } else if ([
      TokenType.SEMICOLON, TokenType.DOT, TokenType.COMMA, TokenType.COLON,
      TokenType.LPAREN, TokenType.RPAREN, TokenType.LBRACE, TokenType.RBRACE,
      TokenType.LBRACKET, TokenType.RBRACKET,
    ].contains(type)) {
      return 'Delimiters';
    }
    return 'Other';
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.token_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No tokens generated',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// Parser Phase Viewer
class ParserPhaseViewer extends StatefulWidget {
  final Program? ast;
  final List<CompilerError> errors;
  final List<CompilerError> warnings;

  const ParserPhaseViewer({
    super.key,
    this.ast,
    required this.errors,
    required this.warnings,
  });

  @override
  State<ParserPhaseViewer> createState() => _ParserPhaseViewerState();
}

class _ParserPhaseViewerState extends State<ParserPhaseViewer> {
  final _scrollController = ScrollController();
  final Set<String> _expandedNodes = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        if (widget.errors.isNotEmpty || widget.warnings.isNotEmpty)
          _buildMessagesSection(context),
        if (widget.ast != null) ...[
          const SizedBox(height: 8),
          _buildStatistics(context),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: widget.ast == null
              ? _buildEmptyState(context)
              : _buildASTView(context),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.1),
            const Color(0xFF3B82F6).withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6),
                  const Color(0xFF3B82F6).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.account_tree_rounded, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Syntax Analysis',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Building AST',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (widget.ast != null)
            IconButton(
              icon: const Icon(Icons.unfold_more, size: 20),
              tooltip: 'Expand All',
              onPressed: () {
                setState(() {
                  _expandAllNodes(widget.ast!);
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMessagesSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_problem_outlined, color: theme.colorScheme.error, size: 18),
              const SizedBox(width: 6),
              Text(
                'Parsing Messages',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.errors.map((error) => _buildMessageItem(context, error, true)),
          ...widget.warnings.map((warning) => _buildMessageItem(context, warning, false)),
        ],
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, CompilerError message, bool isError) {
    final theme = Theme.of(context);
    final color = isError ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.warning_amber_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _expandAllNodes(ASTNode node, [String path = '']) {
    _expandedNodes.add(path);
    if (node is Program) {
      for (int i = 0; i < node.statements.length; i++) {
        _expandAllNodes(node.statements[i], '$path/$i');
      }
    } else if (node is Block) {
      for (int i = 0; i < node.statements.length; i++) {
        _expandAllNodes(node.statements[i], '$path/$i');
      }
    }
  }

  Widget _buildStatistics(BuildContext context) {
    final stats = _calculateASTStats(widget.ast!);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.1),
            const Color(0xFF3B82F6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _buildStatChip(context, 'Nodes', '${stats['total']}', Icons.hub_rounded),
          _buildStatChip(context, 'Depth', '${stats['depth']}', Icons.height_rounded),
          _buildStatChip(context, 'Funcs', '${stats['functions']}', Icons.functions_rounded),
          _buildStatChip(context, 'Vars', '${stats['variables']}', Icons.code_rounded),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3B82F6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateASTStats(ASTNode node, [int depth = 0]) {
    var total = 1;
    var maxDepth = depth;
    var functions = node is FunctionDeclaration ? 1 : 0;
    var variables = node is VariableDeclaration ? 1 : 0;

    final children = _getNodeChildren(node);
    for (final child in children) {
      final childStats = _calculateASTStats(child, depth + 1);
      total += childStats['total']!;
      maxDepth = maxDepth > childStats['depth']! ? maxDepth : childStats['depth']!;
      functions += childStats['functions']!;
      variables += childStats['variables']!;
    }

    return {
      'total': total,
      'depth': maxDepth,
      'functions': functions,
      'variables': variables,
    };
  }

  List<ASTNode> _getNodeChildren(ASTNode node) {
    if (node is Program) return node.statements;
    if (node is Block) return node.statements;
    if (node is FunctionDeclaration) return [node.body];
    if (node is IfStatement) {
      return [
        node.condition,
        node.thenBranch,
        if (node.elseBranch != null) node.elseBranch!,
      ];
    }
    if (node is WhileStatement) return [node.condition, node.body];
    if (node is BinaryExpression) return [node.left, node.right];
    if (node is UnaryExpression) return [node.operand];
    return [];
  }

  Widget _buildASTView(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        children: [
          _buildASTTree(context, widget.ast!, '', true),
        ],
      ),
    );
  }

  Widget _buildASTTree(BuildContext context, ASTNode node, String path, bool isLast) {
    final theme = Theme.of(context);
    final nodeId = path;
    final isExpanded = _expandedNodes.contains(nodeId);
    final children = _getNodeChildren(node);
    final hasChildren = children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: hasChildren
              ? () {
            setState(() {
              if (isExpanded) {
                _expandedNodes.remove(nodeId);
              } else {
                _expandedNodes.add(nodeId);
              }
            });
          }
              : null,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getNodeColor(node).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _getNodeColor(node).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasChildren)
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 16,
                    color: _getNodeColor(node),
                  )
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 6),
                Icon(_getNodeIcon(node), size: 14, color: _getNodeColor(node)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _getNodeLabel(node),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded && hasChildren) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children.asMap().entries.map((entry) {
                final index = entry.key;
                final child = entry.value;
                final childPath = '$path/$index';
                final isLastChild = index == children.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildASTTree(context, child, childPath, isLastChild),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Color _getNodeColor(ASTNode node) {
    if (node is Program || node is Block) return const Color(0xFF8B5CF6);
    if (node is FunctionDeclaration) return const Color(0xFFEF4444);
    if (node is VariableDeclaration || node is Assignment) return const Color(0xFF3B82F6);
    if (node is IfStatement || node is WhileStatement) return const Color(0xFFF59E0B);
    if (node is BinaryExpression) return const Color(0xFF10B981);
    return Colors.grey;
  }

  IconData _getNodeIcon(ASTNode node) {
    if (node is Program) return Icons.source_rounded;
    if (node is Block) return Icons.data_object_rounded;
    if (node is FunctionDeclaration) return Icons.functions_rounded;
    if (node is VariableDeclaration) return Icons.code_rounded;
    if (node is IfStatement) return Icons.alt_route_rounded;
    if (node is WhileStatement) return Icons.loop_rounded;
    if (node is BinaryExpression) return Icons.calculate_rounded;
    if (node is PrintStatement) return Icons.print_rounded;
    return Icons.circle_outlined;
  }

  String _getNodeLabel(ASTNode node) {
    if (node is Program) return 'Program (${node.statements.length} stmts)';
    if (node is Block) return 'Block (${node.statements.length} stmts)';
    if (node is FunctionDeclaration) return 'Func ${node.name}()';
    if (node is VariableDeclaration) return 'var ${node.name}';
    if (node is IfStatement) return 'If Statement';
    if (node is WhileStatement) return 'While Loop';
    if (node is BinaryExpression) return 'Binary: ${node.operator}';
    if (node is PrintStatement) return 'Print';
    return node.runtimeType.toString();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No AST generated',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// Semantic Phase Viewer
class SemanticPhaseViewer extends StatefulWidget {
  final Map<String, dynamic>? symbolTable;
  final List<CompilerError> errors;
  final List<CompilerError> warnings;

  const SemanticPhaseViewer({
    super.key,
    this.symbolTable,
    required this.errors,
    required this.warnings,
  });

  @override
  State<SemanticPhaseViewer> createState() => _SemanticPhaseViewerState();
}

class _SemanticPhaseViewerState extends State<SemanticPhaseViewer> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        if (widget.errors.isNotEmpty || widget.warnings.isNotEmpty)
          _buildMessagesSection(context),
        if (widget.symbolTable != null && widget.symbolTable!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildStatistics(context),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: widget.symbolTable == null || widget.symbolTable!.isEmpty
              ? _buildEmptyState(context)
              : _buildSymbolTableView(context),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF10B981).withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981),
                  const Color(0xFF10B981).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.table_chart_rounded, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semantic Analysis',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Type checking',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_problem_outlined, color: theme.colorScheme.error, size: 18),
              const SizedBox(width: 6),
              Text(
                'Semantic Messages',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.errors.map((error) => _buildMessageItem(context, error, true)),
          ...widget.warnings.map((warning) => _buildMessageItem(context, warning, false)),
        ],
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, CompilerError message, bool isError) {
    final theme = Theme.of(context);
    final color = isError ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.warning_amber_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(BuildContext context) {
    final theme = Theme.of(context);
    final functions = _getFunctions().length;
    final variables = _getVariables().length;
    final total = functions + variables;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF10B981).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _buildStatChip(context, 'Total', '$total', Icons.label_rounded),
          _buildStatChip(context, 'Funcs', '$functions', Icons.functions_rounded),
          _buildStatChip(context, 'Vars', '$variables', Icons.code_rounded),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF10B981)),
          const SizedBox(width: 4),
          Text('$label: ', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF10B981),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, dynamic>> _getFunctions() {
    return widget.symbolTable!.entries
        .where((e) => e.value is Map && (e.value['isFunction'] ?? false))
        .toList();
  }

  List<MapEntry<String, dynamic>> _getVariables() {
    return widget.symbolTable!.entries
        .where((e) => e.value is Map && !(e.value['isFunction'] ?? false))
        .toList();
  }

  Widget _buildSymbolTableView(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        children: [
          if (_getFunctions().isNotEmpty) ...[
            _buildSymbolSection(context, 'Functions', _getFunctions()),
            const SizedBox(height: 12),
          ],
          if (_getVariables().isNotEmpty)
            _buildSymbolSection(context, 'Variables', _getVariables()),
        ],
      ),
    );
  }

  Widget _buildSymbolSection(
      BuildContext context,
      String title,
      List<MapEntry<String, dynamic>> symbols,
      ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                title == 'Functions' ? Icons.functions_rounded : Icons.code_rounded,
                size: 16,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
              Text(
                '$title (${symbols.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...symbols.map((symbol) => _buildSymbolCard(context, symbol)),
      ],
    );
  }

  Widget _buildSymbolCard(BuildContext context, MapEntry<String, dynamic> symbol) {
    final theme = Theme.of(context);
    final name = symbol.key;
    final data = symbol.value as Map;
    final type = data['type'] ?? 'unknown';
    final isFunction = data['isFunction'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isFunction ? const Color(0xFFEF4444) : const Color(0xFF3B82F6)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                isFunction ? Icons.functions_rounded : Icons.code_rounded,
                size: 14,
                color: isFunction ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: (isFunction ? const Color(0xFFEF4444) : const Color(0xFF3B82F6)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                type,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isFunction ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No symbol table available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class OptimizerPhaseViewer extends StatefulWidget {
  final OptimizationResult? optimizationResult;
  final Program? originalAST;

  const OptimizerPhaseViewer({
    super.key,
    required this.optimizationResult,
    required this.originalAST,
  });

  @override
  State<OptimizerPhaseViewer> createState() => _OptimizerPhaseViewerState();
}

class _OptimizerPhaseViewerState extends State<OptimizerPhaseViewer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        if (widget.optimizationResult?.warnings.isNotEmpty ?? false)
          _buildMessagesSection(context),
        if (widget.optimizationResult != null) ...[
          const SizedBox(height: 8),
          _buildStatistics(context),
          const SizedBox(height: 8),
          _buildTabs(context),
        ],
        Expanded(
          child: widget.optimizationResult == null
              ? _buildEmptyState(context, 'No optimization data available')
              : TabBarView(
            controller: _tabController,
            children: [
              _ASTComparisonView(
                originalAst: widget.originalAST,
                optimizedAst: widget.optimizationResult!.optimizedProgram,
              ),
              _OptimizationLogView(
                optimizations: widget.optimizationResult!.optimizations,
                scrollController: _scrollController,
              ),
              _buildWarningsView(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    const color = Color(0xFFEC4899);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.speed_rounded, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Optimization',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Improving code efficiency',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 18),
              const SizedBox(width: 6),
              Text(
                'Optimization Warnings',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.optimizationResult!.warnings.map((warning) =>
              _buildMessageItem(context, warning, false)),
        ],
      ),
    );
  }

  Widget _buildStatistics(BuildContext context) {
    final theme = Theme.of(context);
    const color = Color(0xFFEC4899);
    final stats = widget.optimizationResult!.statistics;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          _buildStatChip(context, 'Passes', '${stats['passes'] ?? 0}', Icons.sync_rounded),
          _buildStatChip(context, 'Folded', '${stats['constantsFolded'] ?? 0}', Icons.compress_rounded),
          _buildStatChip(context, 'Removed', '${stats['deadCodeRemoved'] ?? 0}', Icons.delete_sweep_rounded),
          _buildStatChip(context, 'Simplified', '${stats['expressionsSimplified'] ?? 0}', Icons.transform_rounded),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    const color = Color(0xFFEC4899);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    final theme = Theme.of(context);
    const color = Color(0xFFEC4899);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: TabBar(
        controller: _tabController,
        labelColor: color,
        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.1),
        ),
        tabs: [
          Tab(
            icon: Icon(Icons.compare_arrows_rounded, size: 18),
            text: 'AST Diff',
          ),
          Tab(
            icon: Icon(Icons.list_alt_rounded, size: 18),
            text: 'Log',
          ),
          Tab(
            icon: Icon(Icons.warning_amber_rounded, size: 18),
            text: 'Warnings',
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, CompilerError message, bool isError) {
    final theme = Theme.of(context);
    final color = isError ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.warning_amber_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsView(BuildContext context) {
    final warnings = widget.optimizationResult?.warnings ?? [];
    if (warnings.isEmpty) {
      return _buildEmptyState(context, 'No optimization warnings');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: warnings.length,
      itemBuilder: (context, index) {
        return _buildMessageItem(context, warnings[index], false);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.speed_rounded,
            size: 48,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ASTComparisonView extends StatelessWidget {
  final Program? originalAst;
  final Program? optimizedAst;

  const _ASTComparisonView({required this.originalAst, required this.optimizedAst});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (originalAst == null || optimizedAst == null) {
      return const Center(child: Text('AST not available'));
    }

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(child: _ASTTreeView(title: 'Original AST', ast: originalAst!)),
          VerticalDivider(width: 1, color: theme.colorScheme.outline.withOpacity(0.2)),
          Expanded(child: _ASTTreeView(title: 'Optimized AST', ast: optimizedAst!, isOptimized: true)),
        ],
      ),
    );
  }
}

class _OptimizationLogView extends StatelessWidget {
  final List<String> optimizations;
  final ScrollController scrollController;

  const _OptimizationLogView({
    required this.optimizations,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = Color(0xFFEC4899);

    if (optimizations.isEmpty) {
      return Center(
        child: Text(
          'No optimization logs available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: optimizations.length,
        itemBuilder: (context, index) {
          final log = optimizations[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 12, color: color.withOpacity(0.8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      height: 1.3,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ASTTreeView extends StatefulWidget {
  final String title;
  final Program ast;
  final bool isOptimized;

  const _ASTTreeView({
    required this.title,
    required this.ast,
    this.isOptimized = false,
  });

  @override
  State<_ASTTreeView> createState() => _ASTTreeViewState();
}

class _ASTTreeViewState extends State<_ASTTreeView> {
  final Set<String> _expandedNodes = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isOptimized ? const Color(0xFF10B981) : const Color(0xFF3B82F6);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.account_tree_rounded, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                widget.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [_buildASTTree(context, widget.ast, '', true)],
          ),
        ),
      ],
    );
  }

  List<ASTNode> _getNodeChildren(ASTNode node) {
    if (node is Program) return node.statements;
    if (node is Block) return node.statements;
    if (node is FunctionDeclaration) return [node.body];
    if (node is IfStatement) {
      return [
        node.condition,
        node.thenBranch,
        if (node.elseBranch != null) node.elseBranch!,
      ];
    }
    if (node is WhileStatement) return [node.condition, node.body];
    if (node is BinaryExpression) return [node.left, node.right];
    if (node is UnaryExpression) return [node.operand];
    return [];
  }

  Color _getNodeColor(ASTNode node) {
    if (node is Program || node is Block) return const Color(0xFF8B5CF6);
    if (node is FunctionDeclaration) return const Color(0xFFEF4444);
    if (node is VariableDeclaration || node is Assignment) return const Color(0xFF3B82F6);
    if (node is IfStatement || node is WhileStatement) return const Color(0xFFF59E0B);
    if (node is BinaryExpression) return const Color(0xFF10B981);
    if (node is NumberLiteral || node is StringLiteral || node is BooleanLiteral) return Colors.teal;
    return Colors.grey;
  }

  IconData _getNodeIcon(ASTNode node) {
    if (node is Program) return Icons.source_rounded;
    if (node is Block) return Icons.data_object_rounded;
    if (node is FunctionDeclaration) return Icons.functions_rounded;
    if (node is VariableDeclaration) return Icons.code_rounded;
    if (node is IfStatement) return Icons.alt_route_rounded;
    if (node is WhileStatement) return Icons.loop_rounded;
    if (node is BinaryExpression) return Icons.calculate_rounded;
    if (node is PrintStatement) return Icons.print_rounded;
    if (node is NumberLiteral) return Icons.pin_rounded;
    return Icons.circle_outlined;
  }

  String _getNodeLabel(ASTNode node) {
    if (node is Program) return 'Program (${node.statements.length} stmts)';
    if (node is Block) return 'Block (${node.statements.length} stmts)';
    if (node is FunctionDeclaration) return 'Func ${node.name}()';
    if (node is VariableDeclaration) return 'var ${node.name}';
    if (node is IfStatement) return 'If Statement';
    if (node is WhileStatement) return 'While Loop';
    if (node is BinaryExpression) return 'Binary: ${node.operator}';
    if (node is NumberLiteral) return 'Num: ${node.value}';
    if (node is StringLiteral) return 'Str: "${node.value}"';
    if (node is BooleanLiteral) return 'Bool: ${node.value}';
    if (node is Identifier) return 'ID: ${node.name}';
    if (node is PrintStatement) return 'Print';
    return node.runtimeType.toString();
  }

  Widget _buildASTTree(BuildContext context, ASTNode node, String path, bool isLast) {
    final theme = Theme.of(context);
    final nodeId = path;
    final isExpanded = _expandedNodes.contains(nodeId);
    final children = _getNodeChildren(node);
    final hasChildren = children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: hasChildren
              ? () {
            setState(() {
              if (isExpanded) {
                _expandedNodes.remove(nodeId);
              } else {
                _expandedNodes.add(nodeId);
              }
            });
          }
              : null,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getNodeColor(node).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _getNodeColor(node).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasChildren)
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 16,
                    color: _getNodeColor(node),
                  )
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 6),
                Icon(_getNodeIcon(node), size: 14, color: _getNodeColor(node)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _getNodeLabel(node),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded && hasChildren) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children.asMap().entries.map((entry) {
                final index = entry.key;
                final child = entry.value;
                final childPath = '$path/$index';
                final isLastChild = index == children.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildASTTree(context, child, childPath, isLastChild),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

// Interpreter Phase Viewer
class InterpreterPhaseViewer extends StatefulWidget {
  final InterpreterResult? result;
  final List<CompilerError> errors;

  const InterpreterPhaseViewer({
    super.key,
    this.result,
    required this.errors,
  });

  @override
  State<InterpreterPhaseViewer> createState() => _InterpreterPhaseViewerState();
}

class _InterpreterPhaseViewerState extends State<InterpreterPhaseViewer> {
  final _scrollController = ScrollController();
  int _selectedTab = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        if (widget.errors.isNotEmpty)
          _buildMessagesSection(context),
        if (widget.result != null) ...[
          const SizedBox(height: 8),
          _buildStatistics(context),
          const SizedBox(height: 8),
          _buildTabSelector(context),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: widget.result == null
              ? _buildEmptyState(context)
              : _buildContentView(context),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withOpacity(0.1),
            const Color(0xFFF59E0B).withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF59E0B),
                  const Color(0xFFF59E0B).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.play_circle_outline_rounded, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interpretation',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Executing program',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_problem_outlined, color: theme.colorScheme.error, size: 18),
              const SizedBox(width: 6),
              Text(
                'Runtime Messages',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.errors.map((error) => _buildMessageItem(context, error)),
        ],
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, CompilerError message) {
    final theme = Theme.of(context);
    final isError = message.type == MessageType.error;
    final color = isError ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.warning_amber_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(BuildContext context) {
    final theme = Theme.of(context);
    final steps = widget.result!.executionLog.length;
    final outputLines = widget.result!.output.split('\n').where((l) => l.isNotEmpty).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withOpacity(0.1),
            const Color(0xFFF59E0B).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(context, 'Time', '${widget.result!.executionTime}ms', Icons.timer_outlined),
          ),
          Container(
            width: 1,
            height: 30,
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(context, 'Steps', '$steps', Icons.list_alt_rounded),
          ),
          Container(
            width: 1,
            height: 30,
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(context, 'Lines', '$outputLines', Icons.output_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFF59E0B)),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFF59E0B),
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(context, 'Output', Icons.output_rounded, 0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton(context, 'Log', Icons.list_alt_rounded, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String label, IconData icon, int index) {
    final theme = Theme.of(context);
    final isSelected = _selectedTab == index;

    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _selectedTab = index;
        });
      },
      icon: Icon(icon, size: 16),
      label: Text(label, style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFFF59E0B) : theme.colorScheme.surfaceVariant,
        foregroundColor: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
        elevation: isSelected ? 3 : 0,
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

  Widget _buildContentView(BuildContext context) {
    return _selectedTab == 0
        ? _buildOutputView(context)
        : _buildExecutionLogView(context);
  }

  Widget _buildOutputView(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Text(
                  'Program Output',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF59E0B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              child: widget.result!.output.isEmpty
                  ? Center(
                child: Text(
                  'No output produced',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              )
                  : SelectableText(
                widget.result!.output,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.4,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionLogView(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: widget.result!.executionLog.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return _buildLogEntry(context, index, widget.result!.executionLog[index]);
        },
      ),
    );
  }

  Widget _buildLogEntry(BuildContext context, int index, String log) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF59E0B),
                fontSize: 9,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            child: Text(
              log,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.3,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No execution result available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
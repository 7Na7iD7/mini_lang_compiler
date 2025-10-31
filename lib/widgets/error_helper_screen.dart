import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/compiler_provider.dart';
import 'dart:ui';
import 'error_explanations.dart';

class ErrorHelperScreen extends StatefulWidget {
  final List<String> errors;
  final List<String> warnings;
  final List<CompilationPhase>? phases;
  final String? sourceCode;

  const ErrorHelperScreen({
    super.key,
    required this.errors,
    this.warnings = const [],
    this.phases,
    this.sourceCode,
  });

  @override
  State<ErrorHelperScreen> createState() => _ErrorHelperScreenState();
}

class _ErrorHelperScreenState extends State<ErrorHelperScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedPhaseFilter = 'All Phases';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getErrorsWithPhaseInfo() {
    final List<Map<String, dynamic>> result = [];

    for (final error in widget.errors) {
      String? phaseSource;

      if (widget.phases != null) {
        for (final phase in widget.phases!) {
          if (phase.errors.contains(error)) {
            phaseSource = phase.name;
            break;
          }
        }
      }

      result.add({
        'error': error,
        'phaseSource': phaseSource,
      });
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allIssues = _getErrorsWithPhaseInfo();

    if (allIssues.isEmpty) {
      return _buildSuccessScreen(theme);
    }

    final filteredIssues = _filterIssues(allIssues);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          _buildSearchAndFilter(theme),
          if (widget.phases != null && widget.phases!.isNotEmpty)
            _buildPhaseTimeline(theme),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredIssues.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildHeader(context, filteredIssues.length);
                }

                final issueData = filteredIssues[index - 1];
                final error = issueData['error'] as String;
                final phaseSource = issueData['phaseSource'] as String?;
                final explanation = ErrorExplainer.explainError(error, phaseSource: phaseSource);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: explanation != null
                      ? _buildExplanationCard(context, error, explanation)
                      : _buildSimpleErrorCard(context, error, index, phaseSource),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActions(context, allIssues.length),
    );
  }

  List<Map<String, dynamic>> _filterIssues(List<Map<String, dynamic>> issues) {
    var filtered = issues;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((issueData) {
        final error = issueData['error'] as String;
        return error.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedFilter != 'All') {
      filtered = filtered.where((issueData) {
        final error = issueData['error'] as String;
        final explanation = ErrorExplainer.explainError(error);
        if (explanation == null) return false;
        return explanation.category.name == _selectedFilter.toLowerCase();
      }).toList();
    }

    if (_selectedPhaseFilter != 'All Phases') {
      filtered = filtered.where((issueData) {
        final phaseSource = issueData['phaseSource'] as String?;
        return phaseSource == _selectedPhaseFilter;
      }).toList();
    }

    return filtered;
  }

  Widget _buildPhaseTimeline(ThemeData theme) {
    final phases = widget.phases!;
    final errorPhases = phases.where((p) => p.errors.isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.errorContainer.withOpacity(0.3),
            theme.colorScheme.errorContainer.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, size: 16, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Text(
                'Error Timeline',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: errorPhases.map((phase) {
              return _PhaseErrorBadge(
                phase: phase,
                isSelected: _selectedPhaseFilter == phase.name,
                onTap: () {
                  setState(() {
                    _selectedPhaseFilter = _selectedPhaseFilter == phase.name
                        ? 'All Phases'
                        : phase.name;
                  });
                },
              );
            }).toList(),
          ),
          if (_selectedPhaseFilter != 'All Phases') ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() => _selectedPhaseFilter = 'All Phases');
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear Filter'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessScreen(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Helper'),
        backgroundColor: theme.colorScheme.primaryContainer,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.1),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 80,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'No Errors Found!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your code compiled successfully',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),
              _buildSuccessStats(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessStats(ThemeData theme) {
    final hasPhases = widget.phases != null && widget.phases!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.code, 'Clean Code', Colors.blue),
              _buildStatItem(Icons.speed, 'Fast Compile', Colors.orange),
              _buildStatItem(Icons.security, 'No Issues', Colors.green),
            ],
          ),
          if (hasPhases) ...[
            const SizedBox(height: 16),
            Divider(color: theme.colorScheme.outline.withOpacity(0.2)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.rocket_launch, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${widget.phases!.length} phases completed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.bug_report,
              color: theme.colorScheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Error Helper')),
        ],
      ),
      backgroundColor: theme.colorScheme.errorContainer,
      foregroundColor: theme.colorScheme.onErrorContainer,
      elevation: 0,
      actions: [
        if (widget.sourceCode != null)
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: () => _showSourceCode(context),
            tooltip: 'View Source',
          ),
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () => _showHelpDialog(context),
          tooltip: 'Help',
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search errors...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() => _searchQuery = '');
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', theme),
                _buildFilterChip('Lexer', theme),
                _buildFilterChip('Parser', theme),
                _buildFilterChip('Semantic', theme),
                _buildFilterChip('Runtime', theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ThemeData theme) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? label : 'All';
          });
        },
        backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        selectedColor: theme.colorScheme.primaryContainer,
        checkmarkColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.error,
                        theme.colorScheme.error.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.error.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Found $count Issue${count > 1 ? "s" : ""}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Don\'t worry! Let\'s fix these together.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard(
      BuildContext context,
      String originalError,
      ErrorExplanation explanation,
      ) {
    final theme = Theme.of(context);

    Color categoryColor;
    IconData categoryIcon;
    String categoryName;

    switch (explanation.category) {
      case ErrorCategory.lexer:
        categoryColor = Colors.purple;
        categoryIcon = Icons.text_fields;
        categoryName = 'Syntax Error';
        break;
      case ErrorCategory.parser:
        categoryColor = Colors.orange;
        categoryIcon = Icons.account_tree;
        categoryName = 'Structure Error';
        break;
      case ErrorCategory.semantic:
        categoryColor = Colors.red;
        categoryIcon = Icons.warning;
        categoryName = 'Logic Error';
        break;
      case ErrorCategory.runtime:
        categoryColor = Colors.deepOrange;
        categoryIcon = Icons.bug_report;
        categoryName = 'Runtime Error';
        break;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                categoryColor.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: categoryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryIcon, size: 16, color: categoryColor),
                          const SizedBox(width: 6),
                          Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (explanation.phaseSource != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.source,
                              size: 12,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              explanation.phaseSource!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  explanation.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),

                _buildSection(
                  context,
                  icon: Icons.error_outline,
                  title: 'What\'s Wrong?',
                  content: explanation.problem,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),

                _buildSection(
                  context,
                  icon: Icons.build,
                  title: 'How to Fix It?',
                  content: explanation.solution,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.code, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Examples',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildCodeExample(
                        context,
                        '❌ Wrong',
                        explanation.wrongExample,
                        Colors.red,
                      ),
                      const SizedBox(height: 8),
                      _buildCodeExample(
                        context,
                        '✅ Correct',
                        explanation.correctExample,
                        Colors.green,
                      ),
                    ],
                  ),
                ),

                if (explanation.tips.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    icon: Icons.lightbulb_outline,
                    title: 'Tips',
                    content: explanation.tips.map((tip) => '• $tip').join('\n'),
                    color: Colors.amber,
                  ),
                ],

                if (explanation.quickFix != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_fix_high, size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Quick Fix: ${explanation.quickFix}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (explanation.relatedTopics != null && explanation.relatedTopics!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: explanation.relatedTopics!.map((topic) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: categoryColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tag, size: 12, color: categoryColor),
                            const SizedBox(width: 4),
                            Text(
                              topic,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: categoryColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Show Original Error Message',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        originalError,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String content,
        required Color color,
      }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeExample(
      BuildContext context,
      String label,
      String code,
      Color labelColor,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SelectableText(
                  code.trim(),
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Colors.green.shade300,
                    height: 1.4,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                color: Colors.white70,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code.trim()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Code copied!'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleErrorCard(BuildContext context, String error, int index, String? phaseSource) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (phaseSource != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            phaseSource,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        error,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActions(BuildContext context, int errorCount) {
    if (errorCount == 0) return null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'copy_all',
          onPressed: () => _copyAllErrors(),
          tooltip: 'Copy All Errors',
          child: const Icon(Icons.copy_all),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'clear',
          onPressed: () => _showClearDialog(context),
          tooltip: 'Clear',
          backgroundColor: Theme.of(context).colorScheme.error,
          child: const Icon(Icons.clear_all),
        ),
      ],
    );
  }

  void _copyAllErrors() {
    final allText = widget.errors.join('\n\n');
    Clipboard.setData(ClipboardData(text: allText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${widget.errors.length} error(s)'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Errors?'),
        content: const Text('This will dismiss all error messages. You can view them again by recompiling.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showSourceCode(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0f0c29),
                  const Color(0xFF302b63),
                  const Color(0xFF24243e),
                ],
              ),
              border: Border.all(
                width: 2,
                color: Colors.white.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 60,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Column(
                children: [
                  // Futuristic Header with Glow Effect
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF667eea),
                              const Color(0xFF764ba2),
                              const Color(0xFFf093fb),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            // Animated Icon Container
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.code_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.white.withOpacity(0.9),
                                      ],
                                    ).createShader(bounds),
                                    child: const Text(
                                      'Source Code Viewer',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 24,
                                        color: Colors.white,
                                        letterSpacing: 1.2,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black38,
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00ff88),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF00ff88),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Compiled Successfully',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Action Buttons
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  _buildHeaderButton(
                                    context,
                                    Icons.download_rounded,
                                    'Download',
                                        () {
                                      // Download logic
                                    },
                                  ),
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  _buildHeaderButton(
                                    context,
                                    Icons.copy_all_rounded,
                                    'Copy',
                                        () {
                                      Clipboard.setData(ClipboardData(text: widget.sourceCode ?? ''));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      const Color(0xFF00ff88),
                                                      const Color(0xFF00cc6a),
                                                    ],
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.check, color: Colors.white, size: 16),
                                              ),
                                              const SizedBox(width: 12),
                                              const Text(
                                                'Code copied to clipboard!',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: const Color(0xFF1a1a2e),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            side: BorderSide(
                                              color: const Color(0xFF00ff88).withOpacity(0.5),
                                            ),
                                          ),
                                          margin: const EdgeInsets.all(16),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  _buildHeaderButton(
                                    context,
                                    Icons.close_rounded,
                                    'Close',
                                        () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Glowing line at bottom of header
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF00ff88),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00ff88),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Code Editor Section
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0a0a0f),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          width: 2,
                          color: const Color(0xFF667eea).withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // VS Code Style Top Bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF1e1e2e),
                                  const Color(0xFF16161f),
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: const Color(0xFF667eea).withOpacity(0.3),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Row(
                                  children: [
                                    _buildWindowButton(const Color(0xFFff5f57)),
                                    const SizedBox(width: 8),
                                    _buildWindowButton(const Color(0xFFfebc2e)),
                                    const SizedBox(width: 8),
                                    _buildWindowButton(const Color(0xFF28c840)),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF667eea).withOpacity(0.2),
                                        const Color(0xFF764ba2).withOpacity(0.2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF667eea).withOpacity(0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.insert_drive_file_rounded,
                                        size: 14,
                                        color: const Color(0xFF00ff88),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'main.lang',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00ff88),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF00ff88),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                _buildTopBarIcon(Icons.settings_rounded),
                                const SizedBox(width: 12),
                                _buildTopBarIcon(Icons.fullscreen_rounded),
                              ],
                            ),
                          ),

                          // Code Content with Syntax Highlighting
                          Expanded(
                            child: Stack(
                              children: [
                                // Background Pattern
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _GridPatternPainter(),
                                  ),
                                ),

                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Line Numbers with Gradient
                                      Container(
                                        padding: const EdgeInsets.only(right: 20),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              width: 2,
                                              color: const Color(0xFF667eea).withOpacity(0.3),
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: List.generate(
                                            (widget.sourceCode ?? '').split('\n').length,
                                                (index) => Container(
                                              margin: const EdgeInsets.symmetric(vertical: 2),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                gradient: index % 5 == 0
                                                    ? LinearGradient(
                                                  colors: [
                                                    const Color(0xFF667eea).withOpacity(0.2),
                                                    Colors.transparent,
                                                  ],
                                                )
                                                    : null,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${index + 1}'.padLeft(3),
                                                style: TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 13,
                                                  fontWeight: index % 5 == 0 ? FontWeight.bold : FontWeight.normal,
                                                  color: index % 5 == 0
                                                      ? const Color(0xFF667eea)
                                                      : Colors.grey.shade600,
                                                  height: 1.6,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),

                                      // Code with Enhanced Syntax Highlighting
                                      Expanded(
                                        child: _buildSyntaxHighlightedCode(widget.sourceCode ?? ''),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Futuristic Footer
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1a1a2e).withOpacity(0.9),
                          const Color(0xFF16213e).withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        width: 2,
                        color: const Color(0xFF667eea).withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.2),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildFooterStat(Icons.code_rounded, 'Lines', '${(widget.sourceCode ?? '').split('\n').length}'),
                        _buildFooterDivider(),
                        _buildFooterStat(Icons.text_fields_rounded, 'Characters', '${widget.sourceCode?.length ?? 0}'),
                        _buildFooterDivider(),
                        _buildFooterStat(Icons.check_circle_rounded, 'Status', 'Clean'),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF667eea),
                                const Color(0xFF764ba2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667eea).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.rocket_launch_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Ready to Execute',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton(BuildContext context, IconData icon, String label, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWindowButton(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Icon(
        icon,
        size: 16,
        color: Colors.white70,
      ),
    );
  }

  Widget _buildFooterStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                const Color(0xFF667eea).withOpacity(0.3),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF667eea).withOpacity(0.3),
            ),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF00ff88)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: 2,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF667eea).withOpacity(0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildSyntaxHighlightedCode(String code) {
    final lines = code.split('\n');
    return SelectableText.rich(
      TextSpan(
        children: lines.asMap().entries.map((entry) {
          return TextSpan(
            children: [
              ..._highlightLine(entry.value),
              const TextSpan(text: '\n'),
            ],
          );
        }).toList(),
      ),
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        height: 1.6,
        letterSpacing: 0.5,
      ),
    );
  }

  List<TextSpan> _highlightLine(String line) {
    final List<TextSpan> spans = [];

    // Keywords
    final keywords = ['int', 'string', 'boolean', 'float', 'char', 'void', 'var', 'if', 'else', 'for', 'while', 'do', 'break', 'continue', 'return', 'switch', 'case', 'default'];

    // Simple syntax highlighting
    String remaining = line;
    int offset = 0;

    while (remaining.isNotEmpty) {
      bool matched = false;

      // Check for keywords
      for (var keyword in keywords) {
        if (remaining.startsWith(keyword) &&
            (remaining.length == keyword.length || !RegExp(r'[a-zA-Z0-9_]').hasMatch(remaining[keyword.length]))) {
          if (offset > 0) {
            spans.add(TextSpan(
              text: line.substring(line.length - remaining.length - offset, line.length - remaining.length),
              style: const TextStyle(color: Color(0xFFa8a8a8)),
            ));
            offset = 0;
          }
          spans.add(TextSpan(
            text: keyword,
            style: const TextStyle(
              color: Color(0xFFff79c6),
              fontWeight: FontWeight.bold,
            ),
          ));
          remaining = remaining.substring(keyword.length);
          matched = true;
          break;
        }
      }

      if (!matched) {
        // Check for numbers
        final numberMatch = RegExp(r'^\d+(\.\d+)?').firstMatch(remaining);
        if (numberMatch != null) {
          if (offset > 0) {
            spans.add(TextSpan(
              text: line.substring(line.length - remaining.length - offset, line.length - remaining.length),
              style: const TextStyle(color: Color(0xFFa8a8a8)),
            ));
            offset = 0;
          }
          spans.add(TextSpan(
            text: numberMatch.group(0)!,
            style: const TextStyle(color: Color(0xFFbd93f9)),
          ));
          remaining = remaining.substring(numberMatch.group(0)!.length);
          matched = true;
        }
      }

      if (!matched) {
        // Check for strings
        if (remaining.startsWith('"')) {
          if (offset > 0) {
            spans.add(TextSpan(
              text: line.substring(line.length - remaining.length - offset, line.length - remaining.length),
              style: const TextStyle(color: Color(0xFFa8a8a8)),
            ));
            offset = 0;
          }
          final stringEnd = remaining.indexOf('"', 1);
          if (stringEnd != -1) {
            spans.add(TextSpan(
              text: remaining.substring(0, stringEnd + 1),
              style: const TextStyle(color: Color(0xFFf1fa8c)),
            ));
            remaining = remaining.substring(stringEnd + 1);
            matched = true;
          }
        }
      }

      if (!matched) {
        // Check for function calls
        final funcMatch = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*(?=\()').firstMatch(remaining);
        if (funcMatch != null) {
          if (offset > 0) {
            spans.add(TextSpan(
              text: line.substring(line.length - remaining.length - offset, line.length - remaining.length),
              style: const TextStyle(color: Color(0xFFa8a8a8)),
            ));
            offset = 0;
          }
          spans.add(TextSpan(
            text: funcMatch.group(0)!,
            style: const TextStyle(
              color: Color(0xFF50fa7b),
              fontWeight: FontWeight.w600,
            ),
          ));
          remaining = remaining.substring(funcMatch.group(0)!.length);
          matched = true;
        }
      }

      if (!matched) {
        offset++;
        remaining = remaining.substring(1);
      }
    }

    if (offset > 0) {
      spans.add(TextSpan(
        text: line.substring(line.length - offset),
        style: const TextStyle(color: Color(0xFFa8a8a8)),
      ));
    }

    return spans.isEmpty ? [TextSpan(text: line, style: const TextStyle(color: Color(0xFFa8a8a8)))] : spans;
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Error Helper Guide'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                '🔍 Search',
                'Use the search bar to find specific errors',
              ),
              _buildHelpItem(
                '🏷️ Filter',
                'Filter errors by category: Lexer, Parser, Semantic, or Runtime',
              ),
              _buildHelpItem(
                '⏱️ Phase Timeline',
                'See which compilation phase generated each error',
              ),
              _buildHelpItem(
                '💡 Tips',
                'Each error includes tips and best practices',
              ),
              _buildHelpItem(
                '📋 Examples',
                'View wrong and correct code examples for each error',
              ),
              _buildHelpItem(
                '🔧 Quick Fix',
                'Get instant suggestions to fix common errors',
              ),
              _buildHelpItem(
                '📚 Related Topics',
                'Explore related concepts to deepen your understanding',
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseErrorBadge extends StatelessWidget {
  final CompilationPhase phase;
  final bool isSelected;
  final VoidCallback onTap;

  const _PhaseErrorBadge({
    required this.phase,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorCount = phase.errors.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.error.withOpacity(0.2)
                : theme.colorScheme.errorContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.error
                  : theme.colorScheme.error.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getPhaseIcon(phase.name),
                size: 14,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 6),
              Text(
                phase.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$errorCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPhaseIcon(String phaseName) {
    final lower = phaseName.toLowerCase();
    if (lower.contains('lex')) {
      return Icons.text_fields;
    } else if (lower.contains('pars')) {
      return Icons.account_tree;
    } else if (lower.contains('semantic')) {
      return Icons.analytics;
    } else if (lower.contains('optim')) {
      return Icons.speed;
    } else if (lower.contains('runtime') || lower.contains('execut')) {
      return Icons.play_circle;
    }
    return Icons.source;
  }
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF667eea).withOpacity(0.03)
      ..strokeWidth = 1;

    const gridSize = 20.0;

    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
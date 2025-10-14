import 'package:flutter/material.dart';
import '../compiler/minilang_optimizer.dart';
import '../models/ast_nodes.dart';
import '../models/token_types.dart';

class OptimizerPhaseViewer extends StatefulWidget {
  final OptimizationResult? optimizationResult;
  final Program? originalAST;

  const OptimizerPhaseViewer({
    super.key,
    this.optimizationResult,
    this.originalAST,
  });

  @override
  State<OptimizerPhaseViewer> createState() => _OptimizerPhaseViewerState();
}

class _OptimizerPhaseViewerState extends State<OptimizerPhaseViewer> {
  int _selectedTab = 0;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.optimizationResult == null) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        _buildHeader(context),
        const SizedBox(height: 8),
        _buildStatistics(context),
        const SizedBox(height: 8),
        _buildTabBar(context),
        const SizedBox(height: 8),
        Expanded(
          child: _buildTabContent(context),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.speed_rounded,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Optimization Data',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optimization phase not completed',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final stats = widget.optimizationResult!.statistics;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEC4899).withOpacity(0.1),
            const Color(0xFFEC4899).withOpacity(0.05),
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
                  const Color(0xFFEC4899),
                  const Color(0xFFEC4899).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEC4899).withOpacity(0.3),
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
                  'Code Optimization',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${stats['passes']} optimization passes completed',
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

  Widget _buildStatistics(BuildContext context) {
    final theme = Theme.of(context);
    final stats = widget.optimizationResult!.statistics;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEC4899).withOpacity(0.1),
            const Color(0xFFEC4899).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.3)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildStatChip(
            context,
            'Folded',
            stats['constantsFolded'].toString(),
            Icons.calculate_rounded,
            Colors.blue,
          ),
          _buildStatChip(
            context,
            'Dead Code',
            stats['deadCodeRemoved'].toString(),
            Icons.delete_sweep_rounded,
            Colors.red,
          ),
          _buildStatChip(
            context,
            'Simplified',
            stats['expressionsSimplified'].toString(),
            Icons.merge_type_rounded,
            Colors.green,
          ),
          _buildStatChip(
            context,
            'Propagated',
            stats['propagations'].toString(),
            Icons.arrow_forward_rounded,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
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

  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(context, 'Optimizations', Icons.auto_fix_high, 0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton(context, 'Warnings', Icons.warning_amber_rounded, 1),
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
        backgroundColor: isSelected ? const Color(0xFFEC4899) : theme.colorScheme.surfaceVariant,
        foregroundColor: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
        elevation: isSelected ? 3 : 0,
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    return _selectedTab == 0
        ? _buildOptimizationsTab(context)
        : _buildWarningsTab(context);
  }

  Widget _buildOptimizationsTab(BuildContext context) {
    final theme = Theme.of(context);
    final optimizations = widget.optimizationResult!.optimizations;

    if (optimizations.isEmpty) {
      return Center(
        child: Text(
          'No optimizations recorded',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
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
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: optimizations.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final optimization = optimizations[index];
          final isHeader = optimization.startsWith('===') ||
              optimization.startsWith('Pass') ||
              optimization.contains('شروع') ||
              optimization.contains('پایان');

          return isHeader
              ? _buildOptimizationHeader(context, optimization)
              : _buildOptimizationItem(context, optimization, index);
        },
      ),
    );
  }

  Widget _buildOptimizationHeader(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEC4899).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.flag_rounded,
            size: 16,
            color: Color(0xFFEC4899),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text.replaceAll('===', '').trim(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFEC4899),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationItem(BuildContext context, String text, int index) {
    final theme = Theme.of(context);
    IconData icon;
    Color color;

    if (text.contains('fold') || text.contains('Fold')) {
      icon = Icons.calculate_rounded;
      color = Colors.blue;
    } else if (text.contains('حذف') || text.contains('Removed') || text.contains('مرده')) {
      icon = Icons.delete_sweep_rounded;
      color = Colors.red;
    } else if (text.contains('ساده') || text.contains('Simplif')) {
      icon = Icons.merge_type_rounded;
      color = Colors.green;
    } else if (text.contains('Propagate') || text.contains('ثابت') || text.contains('propagation')) {
      icon = Icons.arrow_forward_rounded;
      color = Colors.orange;
    } else if (text.contains('تعداد') || text.contains('Pass')) {
      icon = Icons.info_outline;
      color = const Color(0xFFEC4899);
    } else {
      icon = Icons.check_circle_outline;
      color = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.4,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsTab(BuildContext context) {
    final theme = Theme.of(context);
    final warnings = widget.optimizationResult!.warnings;

    if (warnings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Warnings',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All optimizations completed successfully',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
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
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: warnings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final warning = warnings[index];
          return _buildWarningItem(context, warning);
        },
      ),
    );
  }

  Widget _buildWarningItem(BuildContext context, CompilerError warning) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: Colors.orange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              warning.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange.withOpacity(0.9),
                fontFamily: 'monospace',
                height: 1.4,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

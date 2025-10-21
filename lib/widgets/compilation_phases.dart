import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/compiler_provider.dart';
import 'comprehensive_compiler_viewer.dart';

class PhaseColors {
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const cached = Color(0xFF3B82F6);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF8B5CF6);
  static const optimization = Color(0xFFEC4899);
}

class CompilationPhases extends StatefulWidget {
  const CompilationPhases({super.key});

  @override
  State<CompilationPhases> createState() => _CompilationPhasesState();
}

class _CompilationPhasesState extends State<CompilationPhases>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _pulseController;
  final Map<int, AnimationController> _phaseControllers = {};
  final Map<int, bool> _expandedPhases = {};
  final ScrollController _scrollController = ScrollController();
  bool _expandAll = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    for (var controller in _phaseControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _ensurePhaseController(int index) {
    if (!_phaseControllers.containsKey(index)) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _phaseControllers[index] = controller;

      Future.delayed(Duration(milliseconds: index * 80), () {
        if (mounted && _phaseControllers.containsKey(index)) {
          controller.forward();
        }
      });
    }

    if (!_expandedPhases.containsKey(index)) {
      _expandedPhases[index] = false;
    }
  }

  void _toggleExpandAll() {
    setState(() {
      _expandAll = !_expandAll;
      for (var key in _expandedPhases.keys) {
        _expandedPhases[key] = _expandAll;
      }
    });
  }

  void _showPhaseDetails(BuildContext context, CompilerProvider provider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ComprehensiveCompilerViewer(
          sourceCode: provider.sourceCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompilerProvider>(
      builder: (context, provider, _) {
        _updateProgressAnimation(provider);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PhasesHeader(
                isRunning: provider.isCompiling,
                pulseController: _pulseController,
                hasPhases: provider.phases.isNotEmpty,
                expandAll: _expandAll,
                onToggleExpandAll: _toggleExpandAll,
                onShowDetailsAll: provider.phases.isNotEmpty
                    ? () => _showPhaseDetails(context, provider)
                    : null,
              ),
              if (provider.isCompiling)
                _ProgressBar(controller: _progressController),
              Expanded(
                child: _PhasesBody(
                  provider: provider,
                  scrollController: _scrollController,
                  phaseControllers: _phaseControllers,
                  expandedPhases: _expandedPhases,
                  onEnsureController: _ensurePhaseController,
                  onToggleExpand: (index) {
                    setState(() {
                      _expandedPhases[index] = !(_expandedPhases[index] ?? false);
                    });
                  },
                ),
              ),
              if (provider.phases.isNotEmpty)
                _PhasesFooter(provider: provider),
            ],
          ),
        );
      },
    );
  }

  void _updateProgressAnimation(CompilerProvider provider) {
    if (provider.isCompiling) {
      if (!_progressController.isAnimating) {
        _progressController.repeat();
      }
    } else {
      _progressController.stop();
      _progressController.value = 0;
    }
  }
}

class _PhasesHeader extends StatelessWidget {
  final bool isRunning;
  final AnimationController pulseController;
  final bool hasPhases;
  final bool expandAll;
  final VoidCallback onToggleExpandAll;
  final VoidCallback? onShowDetailsAll;

  const _PhasesHeader({
    required this.isRunning,
    required this.pulseController,
    required this.hasPhases,
    required this.expandAll,
    required this.onToggleExpandAll,
    this.onShowDetailsAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.3),
            theme.colorScheme.surfaceVariant.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: isSmallScreen ? 16 : 18,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compilation Pipeline',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                    if (!isSmallScreen) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Build process visualization',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isRunning)
                AnimatedBuilder(
                  animation: pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 10 : 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.15 + pulseController.value * 0.1),
                            theme.colorScheme.primary.withOpacity(0.1 + pulseController.value * 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Processing',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          if (hasPhases && !isRunning) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onShowDetailsAll,
                    icon: const Icon(Icons.visibility_rounded, size: 16),
                    label: Text(
                      'View Details',
                      style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ExpandAllButton(
                  expanded: expandAll,
                  onTap: onToggleExpandAll,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpandAllButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _ExpandAllButton({
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Icon(
            expanded ? Icons.unfold_less : Icons.unfold_more,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final AnimationController controller;

  const _ProgressBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return LinearProgressIndicator(
            value: null,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation(
              Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }
}

class _PhasesBody extends StatelessWidget {
  final CompilerProvider provider;
  final ScrollController scrollController;
  final Map<int, AnimationController> phaseControllers;
  final Map<int, bool> expandedPhases;
  final Function(int) onEnsureController;
  final Function(int) onToggleExpand;

  const _PhasesBody({
    required this.provider,
    required this.scrollController,
    required this.phaseControllers,
    required this.expandedPhases,
    required this.onEnsureController,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.phases.isEmpty) {
      return _EmptyState();
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: provider.phases.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        onEnsureController(index);

        final phase = provider.phases[index];
        final controller = phaseControllers[index];
        final isLast = index == provider.phases.length - 1;
        final isExpanded = expandedPhases[index] ?? false;

        return _PhaseItem(
          phase: phase,
          isLast: isLast,
          isExpanded: isExpanded,
          currentState: provider.state,
          animController: controller,
          onToggle: () => onToggleExpand(index),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withOpacity(0.3),
                  theme.colorScheme.primaryContainer.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rocket_launch_rounded,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to Compile',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Click "Compile & Run" to start',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PhaseItem extends StatefulWidget {
  final CompilationPhase phase;
  final bool isLast;
  final bool isExpanded;
  final CompilerState currentState;
  final AnimationController? animController;
  final VoidCallback onToggle;

  const _PhaseItem({
    required this.phase,
    required this.isLast,
    required this.isExpanded,
    required this.currentState,
    required this.onToggle,
    this.animController,
  });

  @override
  State<_PhaseItem> createState() => _PhaseItemState();
}

class _PhaseItemState extends State<_PhaseItem> {
  @override
  Widget build(BuildContext context) {
    if (widget.animController == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: widget.animController!,
      builder: (context, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(-0.2, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: widget.animController!,
          curve: Curves.easeOutCubic,
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: widget.animController!,
          curve: Curves.easeOut,
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: _buildPhaseContent(context),
          ),
        );
      },
    );
  }

  Widget _buildPhaseContent(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _getPhaseBackgroundColor(widget.phase, theme),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getPhaseColor(widget.phase, theme).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhaseHeader(context, isSmallScreen),
                    const SizedBox(height: 8),
                    _buildPhaseResultSummary(context, isSmallScreen),
                  ],
                ),
              ),
            ),
          ),
          if (widget.isExpanded) ...[
            Divider(
              height: 1,
              color: _getPhaseColor(widget.phase, theme).withOpacity(0.2),
              indent: 12,
              endIndent: 12,
            ),
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailedPhaseInfo(context, isSmallScreen),
                  if (widget.phase.errors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildPhaseErrors(context, isSmallScreen),
                  ],
                  if (widget.phase.warnings.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildPhaseWarnings(context, isSmallScreen),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhaseHeader(BuildContext context, bool isSmallScreen) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _PhaseStatusIcon(
          isSuccessful: widget.phase.isSuccessful ?? false,
          wasCached: widget.phase.wasCached ?? false,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getPhaseHeaderIcon(widget.phase.name),
                    size: 14,
                    color: _getPhaseColor(widget.phase, theme),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.phase.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        fontSize: isSmallScreen ? 12 : 13,
                      ),
                    ),
                  ),
                  if (widget.phase.wasCached ?? false) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: PhaseColors.cached.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: PhaseColors.cached.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flash_on,
                            size: 10,
                            color: PhaseColors.cached,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'CACHE',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: PhaseColors.cached,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.phase.duration.inMilliseconds}ms',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AnimatedRotation(
          turns: widget.isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseResultSummary(BuildContext context, bool isSmallScreen) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Text(
        widget.phase.result,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
          height: 1.4,
          fontSize: isSmallScreen ? 11 : 12,
        ),
        maxLines: widget.isExpanded ? null : 2,
        overflow: widget.isExpanded ? null : TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDetailedPhaseInfo(BuildContext context, bool isSmallScreen) {
    final theme = Theme.of(context);
    final details = _extractPhaseDetails(widget.phase.name, widget.phase.result);

    if (details.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 14,
                color: PhaseColors.info,
              ),
              const SizedBox(width: 6),
              Text(
                'Phase Details',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: PhaseColors.info,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...details.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: PhaseColors.info,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${entry.key}: ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                              fontSize: 10,
                            ),
                          ),
                          TextSpan(
                            text: entry.value,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                              fontFamily: 'monospace',
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Map<String, String> _extractPhaseDetails(String phaseName, String result) {
    final details = <String, String>{};
    final lower = phaseName.toLowerCase();

    if (lower.contains('lexical') || lower.contains('lex')) {
      final tokenMatch = RegExp(r'(\d+)\s+tokens').firstMatch(result);
      final typesMatch = RegExp(r'\((\d+)\s+types\)').firstMatch(result);

      if (tokenMatch != null) details['Tokens'] = tokenMatch.group(1)!;
      if (typesMatch != null) details['Token Types'] = typesMatch.group(1)!;
    } else if (lower.contains('pars')) {
      final nodesMatch = RegExp(r'(\d+)\s+nodes').firstMatch(result);
      if (nodesMatch != null) details['AST Nodes'] = nodesMatch.group(1)!;
    } else if (lower.contains('semantic')) {
      final symbolsMatch = RegExp(r'Symbols:\s*(\d+)').firstMatch(result);
      final functionsMatch = RegExp(r'Functions:\s*(\d+)').firstMatch(result);
      final variablesMatch = RegExp(r'Variables:\s*(\d+)').firstMatch(result);

      if (symbolsMatch != null) details['Symbols'] = symbolsMatch.group(1)!;
      if (functionsMatch != null) details['Functions'] = functionsMatch.group(1)!;
      if (variablesMatch != null) details['Variables'] = variablesMatch.group(1)!;
    } else if (lower.contains('optim')) {
      final foldedMatch = RegExp(r'(\d+)\s+constants folded').firstMatch(result);
      final deadCodeMatch = RegExp(r'(\d+)\s+dead code removed').firstMatch(result);
      final simplifiedMatch = RegExp(r'(\d+)\s+expressions simplified').firstMatch(result);
      final passesMatch = RegExp(r'(\d+)\s+passes').firstMatch(result);

      if (passesMatch != null) details['Passes'] = passesMatch.group(1)!;
      if (foldedMatch != null) details['Constants Folded'] = foldedMatch.group(1)!;
      if (deadCodeMatch != null) details['Dead Code Removed'] = deadCodeMatch.group(1)!;
      if (simplifiedMatch != null) details['Expressions Simplified'] = simplifiedMatch.group(1)!;
    } else if (lower.contains('interpret') || lower.contains('execut')) {
      final linesMatch = RegExp(r'(\d+)\s+lines').firstMatch(result);
      if (linesMatch != null) details['Output Lines'] = linesMatch.group(1)!;
    }

    return details;
  }

  Widget _buildPhaseErrors(BuildContext context, bool isSmallScreen) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: PhaseColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PhaseColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: PhaseColors.error,
              ),
              const SizedBox(width: 6),
              Text(
                'Errors (${widget.phase.errors.length})',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: PhaseColors.error,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.phase.errors.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(top: entry.key > 0 ? 6 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: PhaseColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: PhaseColors.error.withOpacity(0.9),
                        fontFamily: 'monospace',
                        height: 1.4,
                        fontSize: isSmallScreen ? 10 : 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPhaseWarnings(BuildContext context, bool isSmallScreen) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: PhaseColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PhaseColors.warning.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 14,
                color: PhaseColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                'Warnings (${widget.phase.warnings.length})',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: PhaseColors.warning,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.phase.warnings.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(top: entry.key > 0 ? 6 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: PhaseColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: PhaseColors.warning.withOpacity(0.9),
                        fontFamily: 'monospace',
                        height: 1.4,
                        fontSize: isSmallScreen ? 10 : 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getPhaseColor(CompilationPhase phase, ThemeData theme) {
    if ((phase.wasCached ?? false) && (phase.isSuccessful ?? false)) {
      return PhaseColors.cached;
    }
    return (phase.isSuccessful ?? false) ? PhaseColors.success : PhaseColors.error;
  }

  Color _getPhaseBackgroundColor(CompilationPhase phase, ThemeData theme) {
    if ((phase.wasCached ?? false) && (phase.isSuccessful ?? false)) {
      return PhaseColors.cached.withOpacity(0.05);
    }
    return (phase.isSuccessful ?? false)
        ? PhaseColors.success.withOpacity(0.05)
        : PhaseColors.error.withOpacity(0.05);
  }

  IconData _getPhaseHeaderIcon(String phaseName) {
    final lower = phaseName.toLowerCase();
    if (lower.contains('cache')) {
      return Icons.flash_on;
    } else if (lower.contains('lex')) {
      return Icons.text_fields_rounded;
    } else if (lower.contains('pars')) {
      return Icons.account_tree_rounded;
    } else if (lower.contains('analyz') || lower.contains('semantic')) {
      return Icons.analytics_outlined;
    } else if (lower.contains('optim')) {
      return Icons.speed_rounded;
    } else if (lower.contains('interpre') || lower.contains('execut')) {
      return Icons.play_circle_outline_rounded;
    }
    return Icons.settings_rounded;
  }
}

class _PhaseStatusIcon extends StatelessWidget {
  final bool isSuccessful;
  final bool wasCached;

  const _PhaseStatusIcon({
    required this.isSuccessful,
    this.wasCached = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = wasCached && isSuccessful
        ? PhaseColors.cached
        : (isSuccessful ? PhaseColors.success : PhaseColors.error);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              isSuccessful
                  ? (wasCached ? Icons.flash_on : Icons.check_rounded)
                  : Icons.close_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _PhasesFooter extends StatelessWidget {
  final CompilerProvider provider;

  const _PhasesFooter({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    final totalDuration = provider.phases.fold<int>(
      0,
          (sum, phase) => sum + phase.duration.inMilliseconds,
    );
    final successCount = provider.phases.where((p) => p.isSuccessful ?? false).length;
    final errorCount = provider.phases.where((p) => !(p.isSuccessful ?? true)).length;
    final cachedCount = provider.phases.where((p) => p.wasCached ?? false).length;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.3),
            theme.colorScheme.surfaceVariant.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _StatBadge(
            icon: Icons.timer_rounded,
            label: 'Total',
            value: '${totalDuration}ms',
            color: theme.colorScheme.primary,
            isSmall: isSmallScreen,
          ),
          _StatBadge(
            icon: Icons.check_circle_rounded,
            label: 'Success',
            value: '$successCount',
            color: PhaseColors.success,
            isSmall: isSmallScreen,
          ),
          if (errorCount > 0)
            _StatBadge(
              icon: Icons.error_rounded,
              label: 'Errors',
              value: '$errorCount',
              color: PhaseColors.error,
              isSmall: isSmallScreen,
            ),
          if (cachedCount > 0)
            _StatBadge(
              icon: Icons.flash_on,
              label: 'Cached',
              value: '$cachedCount',
              color: PhaseColors.cached,
              isSmall: isSmallScreen,
            ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isSmall;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 10 : 12,
        vertical: isSmall ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 14 : 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: isSmall ? 9 : 10,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: isSmall ? 12 : 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/compiler_provider.dart';

class PhaseColors {
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const cached = Color(0xFF3B82F6);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF8B5CF6);
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

  @override
  Widget build(BuildContext context) {
    return Consumer<CompilerProvider>(
      builder: (context, provider, _) {
        _updateProgressAnimation(provider);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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

  const _PhasesHeader({
    required this.isRunning,
    required this.pulseController,
    required this.hasPhases,
    required this.expandAll,
    required this.onToggleExpandAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
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
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compilation Pipeline',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Build process visualization',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (hasPhases && !isRunning) ...[
            _ExpandAllButton(
              expanded: expandAll,
              onTap: onToggleExpandAll,
            ),
            const SizedBox(width: 12),
          ],
          if (isRunning)
            AnimatedBuilder(
              animation: pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.15 + pulseController.value * 0.1),
                        theme.colorScheme.primary.withOpacity(0.1 + pulseController.value * 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Processing',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              Icon(
                expanded ? Icons.unfold_less : Icons.unfold_more,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                expanded ? 'Collapse' : 'Expand',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
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
      padding: const EdgeInsets.all(24),
      itemCount: provider.phases.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
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
            padding: const EdgeInsets.all(32),
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
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ready to Compile',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Compile & Run" to see the magic happen',
            style: theme.textTheme.bodyMedium?.copyWith(
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
  bool _isHovered = false;

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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -2.0 : 0.0),
        decoration: BoxDecoration(
          color: _getPhaseBackgroundColor(widget.phase, theme),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getPhaseColor(widget.phase, theme).withOpacity(
              _isHovered ? 0.5 : 0.3,
            ),
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: _isHovered ? [
            BoxShadow(
              color: _getPhaseColor(widget.phase, theme).withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onToggle,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPhaseHeader(context),
                      const SizedBox(height: 12),
                      _buildPhaseResultSummary(context),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.isExpanded) ...[
              Divider(
                height: 1,
                color: _getPhaseColor(widget.phase, theme).withOpacity(0.2),
                indent: 20,
                endIndent: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailedPhaseInfo(context),
                    if (widget.phase.errors.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildPhaseErrors(context),
                    ],
                    if (widget.phase.warnings.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildPhaseWarnings(context),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _PhaseStatusIcon(
          isSuccessful: widget.phase.isSuccessful ?? false,
          wasCached: widget.phase.wasCached ?? false,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getPhaseHeaderIcon(widget.phase.name),
                    size: 18,
                    color: _getPhaseColor(widget.phase, theme),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.phase.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (widget.phase.wasCached ?? false) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: PhaseColors.cached.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: PhaseColors.cached.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flash_on,
                            size: 12,
                            color: PhaseColors.cached,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'CACHED',
                            style: TextStyle(
                              fontSize: 10,
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
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.phase.duration.inMilliseconds}ms',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AnimatedRotation(
          turns: widget.isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 24,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseResultSummary(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Text(
        widget.phase.result,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
          height: 1.5,
          fontSize: 13,
        ),
        maxLines: widget.isExpanded ? null : 2,
        overflow: widget.isExpanded ? null : TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDetailedPhaseInfo(BuildContext context) {
    final theme = Theme.of(context);
    final details = _extractPhaseDetails(widget.phase.name, widget.phase.result);

    if (details.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
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
                size: 16,
                color: PhaseColors.info,
              ),
              const SizedBox(width: 8),
              Text(
                'Phase Details',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: PhaseColors.info,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...details.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: PhaseColors.info,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${entry.key}: ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          TextSpan(
                            text: entry.value,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                              fontFamily: 'monospace',
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

    if (phaseName.toLowerCase().contains('lexical') || phaseName.toLowerCase().contains('lex')) {
      final tokenMatch = RegExp(r'(\d+)\s+tokens').firstMatch(result);
      final typesMatch = RegExp(r'\((\d+)\s+types\)').firstMatch(result);

      if (tokenMatch != null) details['Tokens'] = tokenMatch.group(1)!;
      if (typesMatch != null) details['Token Types'] = typesMatch.group(1)!;
    } else if (phaseName.toLowerCase().contains('pars')) {
      final nodesMatch = RegExp(r'(\d+)\s+nodes').firstMatch(result);
      if (nodesMatch != null) details['AST Nodes'] = nodesMatch.group(1)!;
      details['Structure'] = 'Parse Tree';
    } else if (phaseName.toLowerCase().contains('semantic')) {
      final symbolsMatch = RegExp(r'Symbols:\s*(\d+)').firstMatch(result);
      final functionsMatch = RegExp(r'Functions:\s*(\d+)').firstMatch(result);
      final variablesMatch = RegExp(r'Variables:\s*(\d+)').firstMatch(result);

      if (symbolsMatch != null) details['Symbols'] = symbolsMatch.group(1)!;
      if (functionsMatch != null) details['Functions'] = functionsMatch.group(1)!;
      if (variablesMatch != null) details['Variables'] = variablesMatch.group(1)!;
    } else if (phaseName.toLowerCase().contains('interpret') || phaseName.toLowerCase().contains('execut')) {
      final linesMatch = RegExp(r'(\d+)\s+lines').firstMatch(result);
      if (linesMatch != null) details['Output Lines'] = linesMatch.group(1)!;
      details['Status'] = (widget.phase.isSuccessful ?? false) ? 'Success' : 'Failed';
    }

    return details;
  }

  Widget _buildPhaseErrors(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PhaseColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
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
                size: 18,
                color: PhaseColors.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Errors (${widget.phase.errors.length})',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: PhaseColors.error,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.phase.errors.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(top: entry.key > 0 ? 8 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: PhaseColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: PhaseColors.error.withOpacity(0.9),
                        fontFamily: 'monospace',
                        height: 1.5,
                        fontSize: 12,
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

  Widget _buildPhaseWarnings(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PhaseColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
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
                size: 18,
                color: PhaseColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                'Warnings (${widget.phase.warnings.length})',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: PhaseColors.warning,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.phase.warnings.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(top: entry.key > 0 ? 8 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: PhaseColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: PhaseColors.warning.withOpacity(0.9),
                        fontFamily: 'monospace',
                        height: 1.5,
                        fontSize: 12,
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
            width: 40,
            height: 40,
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
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isSuccessful
                  ? (wasCached ? Icons.flash_on : Icons.check_rounded)
                  : Icons.close_rounded,
              size: 20,
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
    final totalDuration = provider.phases.fold<int>(
      0,
          (sum, phase) => sum + phase.duration.inMilliseconds,
    );
    final successCount = provider.phases.where((p) => p.isSuccessful ?? false).length;
    final errorCount = provider.phases.where((p) => !(p.isSuccessful ?? true)).length;
    final cachedCount = provider.phases.where((p) => p.wasCached ?? false).length;

    return Container(
      padding: const EdgeInsets.all(20),
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
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatBadge(
                  icon: Icons.timer_rounded,
                  label: 'Total Time',
                  value: '${totalDuration}ms',
                  color: theme.colorScheme.primary,
                ),
                _StatBadge(
                  icon: Icons.check_circle_rounded,
                  label: 'Success',
                  value: '$successCount',
                  color: PhaseColors.success,
                ),
                if (errorCount > 0)
                  _StatBadge(
                    icon: Icons.error_rounded,
                    label: 'Errors',
                    value: '$errorCount',
                    color: PhaseColors.error,
                  ),
                if (cachedCount > 0)
                  _StatBadge(
                    icon: Icons.flash_on,
                    label: 'Cached',
                    value: '$cachedCount',
                    color: PhaseColors.cached,
                  ),
              ],
            ),
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

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
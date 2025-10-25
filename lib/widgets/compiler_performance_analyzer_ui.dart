import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'compiler_performance_analyzer.dart';
import 'performance_report_fullscreen_viewer.dart';

class PerformanceAnalyzerWidget extends StatefulWidget {
  final CompilerPerformanceAnalyzer analyzer;

  const PerformanceAnalyzerWidget({
    super.key,
    required this.analyzer,
  });

  @override
  State<PerformanceAnalyzerWidget> createState() => _PerformanceAnalyzerWidgetState();
}

class _PerformanceAnalyzerWidgetState extends State<PerformanceAnalyzerWidget>
    with TickerProviderStateMixin {
  PerformanceStatistics? _statistics;
  bool _isLoading = false;
  String? _error;

  late AnimationController _refreshController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;

  String _selectedView = 'overview';
  bool _isDarkMode = true;
  bool _showCharts = true;

  @override
  void initState() {
    super.initState();

    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _calculateStatistics();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _calculateStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    _refreshController.forward(from: 0);
    _fadeController.forward(from: 0);

    try {
      final stats = await Future.microtask(() => widget.analyzer.calculateStatistics());

      if (mounted) {
        setState(() {
          _statistics = stats;
          _isLoading = false;
        });
        _scaleController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  ThemeData get _darkTheme => ThemeData.dark();
  ThemeData get _lightTheme => ThemeData.light();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? _darkTheme : _lightTheme,
      child: Scaffold(
        backgroundColor: _isDarkMode ? const Color(0xFF0A0E27) : Colors.grey[50],
        body: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: _buildBody(),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActions(),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: _isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isDarkMode
                  ? [const Color(0xFF6B4CE6), const Color(0xFF9333EA), const Color(0xFFEC4899)]
                  : [Colors.blue[400]!, Colors.purple[400]!, Colors.pink[400]!],
            ),
          ),
          child: Stack(
            children: [
              ...List.generate(20, (index) => _buildParticle(index)),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RotationTransition(
                          turns: _refreshController,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.analytics, color: Colors.white, size: 32),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Performance Analyzer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _statistics != null
                                    ? '${_statistics!.totalCompilations} compilations analyzed'
                                    : 'Loading...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
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
            ],
          ),
        ),
        title: const Text(''),
      ),
      actions: [
        IconButton(
          icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: () {
            setState(() {
              _isDarkMode = !_isDarkMode;
            });
          },
        ),
        IconButton(
          icon: Icon(_showCharts ? Icons.table_chart : Icons.bar_chart),
          onPressed: () {
            setState(() {
              _showCharts = !_showCharts;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _calculateStatistics,
        ),
        IconButton(
          icon: const Icon(Icons.fullscreen),
          onPressed: _openFullscreenReport,
          tooltip: 'View Fullscreen Report',
        ),
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: _exportReport,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildParticle(int index) {
    final random = math.Random(index);
    final size = random.nextDouble() * 4 + 2;
    final left = random.nextDouble() * 400;
    final top = random.nextDouble() * 200;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final offset = math.sin((_shimmerController.value + index * 0.1) * math.pi * 2) * 20;
        return Positioned(
          left: left,
          top: top + offset,
          child: Opacity(
            opacity: 0.3 + math.sin(_shimmerController.value * math.pi * 2) * 0.3,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation(
                    _isDarkMode ? const Color(0xFF9333EA) : Colors.purple[400],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Analyzing Performance...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorView();
    }

    if (_statistics == null) {
      return const Center(child: Text('No statistics available'));
    }

    return Column(
      children: [
        _buildViewSelector(),
        const SizedBox(height: 16),
        FadeTransition(
          opacity: _fadeController,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
            ),
            child: _buildSelectedView(),
          ),
        ),
      ],
    );
  }

  Widget _buildViewSelector() {
    final views = {
      'overview': Icons.dashboard,
      'phases': Icons.layers,
      'cache': Icons.memory,
      'temporal': Icons.timeline,
      'complexity': Icons.functions,
      'issues': Icons.warning_amber,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: views.length,
        itemBuilder: (context, index) {
          final entry = views.entries.elementAt(index);
          final isSelected = _selectedView == entry.key;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedView = entry.key;
                  });
                  _scaleController.forward(from: 0);
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                      colors: _isDarkMode
                          ? [const Color(0xFF6B4CE6), const Color(0xFF9333EA)]
                          : [Colors.blue[400]!, Colors.purple[400]!],
                    )
                        : null,
                    color: isSelected ? null : (_isDarkMode ? const Color(0xFF1A1F3A) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: (_isDarkMode ? const Color(0xFF9333EA) : Colors.purple[400]!)
                            .withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        entry.value,
                        color: isSelected
                            ? Colors.white
                            : (_isDarkMode ? Colors.white70 : Colors.black87),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key.toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (_isDarkMode ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedView) {
      case 'overview':
        return _buildOverviewView();
      case 'phases':
        return _buildPhasesView();
      case 'cache':
        return _buildCacheView();
      case 'temporal':
        return _buildTemporalView();
      case 'complexity':
        return _buildComplexityView();
      case 'issues':
        return _buildIssuesView();
      default:
        return _buildOverviewView();
    }
  }

  Widget _buildOverviewView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetricCards(),
          const SizedBox(height: 16),
          _buildAdvancedCard(
            title: 'Statistical Overview',
            icon: Icons.analytics,
            child: Column(
              children: [
                _buildAnimatedStatRow('Mean Time', _formatDuration(_statistics!.overallStats.mean), 0),
                _buildAnimatedStatRow('Median Time', _formatDuration(_statistics!.overallStats.median), 1),
                _buildAnimatedStatRow('Std Deviation', _formatDuration(_statistics!.overallStats.stdDev), 2),
                _buildAnimatedStatRow('95th Percentile', _formatDuration(_statistics!.overallStats.p95), 3),
                _buildAnimatedStatRow('99th Percentile', _formatDuration(_statistics!.overallStats.p99), 4),
                const SizedBox(height: 16),
                _buildConfidenceInterval(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhasesView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _statistics!.phaseStats.entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildAdvancedCard(
              title: entry.key,
              icon: Icons.layers,
              child: Column(
                children: [
                  _buildAnimatedStatRow('Mean', _formatDuration(entry.value.mean), 0),
                  _buildAnimatedStatRow('Median', _formatDuration(entry.value.median), 1),
                  _buildAnimatedStatRow('Std Dev', _formatDuration(entry.value.stdDev), 2),
                  _buildAnimatedStatRow('Min', _formatDuration(entry.value.min), 3),
                  _buildAnimatedStatRow('Max', _formatDuration(entry.value.max), 4),
                  _buildAnimatedStatRow('P95', _formatDuration(entry.value.p95), 5),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCacheView() {
    final cache = _statistics!.cacheEfficiency;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAdvancedCard(
            title: 'Cache Performance',
            icon: Icons.memory,
            child: Column(
              children: [
                _buildAnimatedStatRow('Hit Rate', '${(cache.hitRate * 100).toStringAsFixed(2)}%', 0),
                _buildAnimatedStatRow('Miss Rate', '${(cache.missRate * 100).toStringAsFixed(2)}%', 1),
                _buildAnimatedStatRow('Total Hits', '${cache.totalHits}', 2),
                _buildAnimatedStatRow('Total Misses', '${cache.totalMisses}', 3),
                _buildAnimatedStatRow('Avg Cached Time', _formatDuration(cache.avgCachedTime), 4),
                _buildAnimatedStatRow('Avg Uncached Time', _formatDuration(cache.avgUncachedTime), 5),
                _buildAnimatedStatRow('Time Saved', _formatDuration(cache.timeSavedMicroseconds), 6),
                _buildAnimatedStatRow('Speedup Factor', '${cache.speedupFactor.toStringAsFixed(2)}x', 7),
                _buildAnimatedStatRow('Effectiveness', '${(cache.effectiveness * 100).toStringAsFixed(2)}%', 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemporalView() {
    final temporal = _statistics!.temporalAnalysis;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAdvancedCard(
            title: 'Trend Analysis',
            icon: Icons.trending_up,
            child: Column(
              children: [
                _buildAnimatedStatRow('Interpretation', temporal.trend.interpretation, 0),
                _buildAnimatedStatRow('Slope', '${temporal.trend.slope.toStringAsFixed(6)} μs/comp', 1),
                _buildAnimatedStatRow('R²', temporal.trend.rSquared.toStringAsFixed(4), 2),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (temporal.cyclicalPatterns.detected)
            _buildAdvancedCard(
              title: 'Cyclical Patterns',
              icon: Icons.repeat,
              child: Column(
                children: [
                  _buildAnimatedStatRow('Period', '${temporal.cyclicalPatterns.period.toStringAsFixed(2)} compilations', 0),
                  _buildAnimatedStatRow('Strength', temporal.cyclicalPatterns.strength.toStringAsFixed(2), 1),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComplexityView() {
    final complexity = _statistics!.complexityAnalysis;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAdvancedCard(
            title: 'Complexity Analysis',
            icon: Icons.functions,
            child: Column(
              children: [
                _buildAnimatedStatRow('Estimated Complexity', complexity.estimatedComplexity, 0),
                _buildAnimatedStatRow('Confidence', '${(complexity.confidence * 100).toStringAsFixed(2)}%', 1),
                _buildAnimatedStatRow('Best Model Degree', '${complexity.bestModel.degree}', 2),
                _buildAnimatedStatRow('R² Score', complexity.bestModel.rSquared.toStringAsFixed(4), 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesView() {
    final outliers = _statistics!.outlierDetection;
    final regression = _statistics!.performanceRegression;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (outliers.outliers.isNotEmpty)
            _buildAdvancedCard(
              title: 'Outliers Detected',
              icon: Icons.warning_amber,
              child: Column(
                children: [
                  _buildAnimatedStatRow('Total Outliers', '${outliers.outliers.length}', 0),
                  _buildAnimatedStatRow('IQR Method', '${outliers.iqrCount}', 1),
                  _buildAnimatedStatRow('Z-Score Method', '${outliers.zScoreCount}', 2),
                  _buildAnimatedStatRow('MAD Method', '${outliers.madCount}', 3),
                  const SizedBox(height: 12),
                  ...outliers.outliers.take(5).toList().asMap().entries.map((e) {
                    final idx = e.key;
                    final outlier = e.value;
                    return _buildAnimatedStatRow(
                      'Outlier ${idx + 1}',
                      'Index: ${outlier.index}, Severity: ${outlier.severity.toStringAsFixed(2)}',
                      idx + 4,
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (regression.detected)
            _buildAdvancedCard(
              title: 'Performance Regression',
              icon: Icons.trending_down,
              child: Column(
                children: [
                  _buildAnimatedStatRow('Severity', regression.severity, 0),
                  _buildAnimatedStatRow('Increase', '${regression.percentageIncrease.toStringAsFixed(2)}%', 1),
                  _buildAnimatedStatRow('t-statistic', regression.tStatistic.toStringAsFixed(4), 2),
                  _buildAnimatedStatRow('p-value', regression.pValue.toStringAsFixed(6), 3),
                  _buildAnimatedStatRow('Cohen\'s d', regression.cohensD.toStringAsFixed(4), 4),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      regression.interpretation,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            _buildAdvancedCard(
              title: 'No Issues Detected',
              icon: Icons.check_circle,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'No performance regressions or significant outliers detected.',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white70 : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMiniCard(
            'Total',
            '${_statistics!.totalCompilations}',
            Icons.numbers,
            Colors.blue,
            0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniCard(
            'Min Time',
            _formatDuration(_statistics!.overallStats.min),
            Icons.speed,
            Colors.green,
            1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniCard(
            'Max Time',
            _formatDuration(_statistics!.overallStats.max),
            Icons.timer,
            Colors.orange,
            2,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCard(String label, String value, IconData icon, Color color, int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay * 100),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.8),
                  color,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvancedCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_isDarkMode ? Colors.black : Colors.grey).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDarkMode
                    ? [const Color(0xFF6B4CE6), const Color(0xFF9333EA)]
                    : [Colors.blue[400]!, Colors.purple[400]!],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatRow(String label, String value, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 100),
      curve: Curves.easeOut,
      builder: (context, animation, child) {
        return Opacity(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_isDarkMode ? const Color(0xFF0A0E27) : Colors.grey[100])?.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfidenceInterval() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [const Color(0xFF6B4CE6).withOpacity(0.2), const Color(0xFF9333EA).withOpacity(0.2)]
              : [Colors.blue.withOpacity(0.1), Colors.purple.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (_isDarkMode ? const Color(0xFF9333EA) : Colors.purple).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: _isDarkMode ? const Color(0xFF9333EA) : Colors.purple,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '95% Confidence Interval',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDuration(_statistics!.overallStats.ci95Lower)} - ${_formatDuration(_statistics!.overallStats.ci95Upper)}',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.black87,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _calculateStatistics,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActions() {
    return null;
  }

  void _openFullscreenReport() {
    if (_statistics != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PerformanceReportFullscreenViewer(
            reportContent: _generateTextReport(),
            title: 'Performance Report',
          ),
        ),
      );
    }
  }

  void _exportReport() {
    if (_statistics == null) return;

    final report = _generateTextReport();
    Clipboard.setData(ClipboardData(text: report));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Report copied to clipboard'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _generateTextReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Performance Analysis Report ===\n');
    buffer.writeln('Total Compilations: ${_statistics!.totalCompilations}');
    buffer.writeln('\nOverall Statistics:');
    buffer.writeln('  Mean: ${_formatDuration(_statistics!.overallStats.mean)}');
    buffer.writeln('  Median: ${_formatDuration(_statistics!.overallStats.median)}');
    buffer.writeln('  Std Dev: ${_formatDuration(_statistics!.overallStats.stdDev)}');
    buffer.writeln('  Min: ${_formatDuration(_statistics!.overallStats.min)}');
    buffer.writeln('  Max: ${_formatDuration(_statistics!.overallStats.max)}');
    buffer.writeln('  P95: ${_formatDuration(_statistics!.overallStats.p95)}');
    buffer.writeln('  P99: ${_formatDuration(_statistics!.overallStats.p99)}');

    buffer.writeln('\nCache Efficiency:');
    final cache = _statistics!.cacheEfficiency;
    buffer.writeln('  Hit Rate: ${(cache.hitRate * 100).toStringAsFixed(2)}%');
    buffer.writeln('  Speedup: ${cache.speedupFactor.toStringAsFixed(2)}x');

    return buffer.toString();
  }

  String _formatDuration(double microseconds) {
    if (microseconds < 1000) {
      return '${microseconds.toStringAsFixed(2)} μs';
    } else if (microseconds < 1000000) {
      return '${(microseconds / 1000).toStringAsFixed(2)} ms';
    } else {
      return '${(microseconds / 1000000).toStringAsFixed(2)} s';
    }
  }
}
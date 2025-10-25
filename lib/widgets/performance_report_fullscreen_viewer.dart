import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class PerformanceReportFullscreenViewer extends StatefulWidget {
  final String reportContent;
  final String title;

  const PerformanceReportFullscreenViewer({
    super.key,
    required this.reportContent,
    this.title = 'Performance Report',
  });

  @override
  State<PerformanceReportFullscreenViewer> createState() =>
      _PerformanceReportFullscreenViewerState();
}

class _PerformanceReportFullscreenViewerState
    extends State<PerformanceReportFullscreenViewer>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _particleController;
  late AnimationController _glowController;

  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  bool _isCopied = false;
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scrollController.addListener(() {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      setState(() {
        _scrollProgress =
        maxScroll > 0 ? (currentScroll / maxScroll).clamp(0.0, 1.0) : 0.0;
      });

      if (_scrollController.offset > 300 && !_showScrollToTop) {
        setState(() => _showScrollToTop = true);
      } else if (_scrollController.offset <= 300 && _showScrollToTop) {
        setState(() => _showScrollToTop = false);
      }
    });

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9333EA),
          secondary: Color(0xFF6B4CE6),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E27),
        body: Stack(
          children: [
            _buildAnimatedBackground(),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildReportContent(),
                  ),
                  _buildFooter(),
                ],
              ),
            ),
            if (_showScrollToTop)
              Positioned(
                bottom: 80,
                right: 20,
                child: _buildScrollToTopButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFF0A0E27),
                Color(0xFF1A1F3A),
                Color(0xFF0A0E27),
              ],
              stops: [
                0.0,
                0.5 + math.sin(_particleController.value * math.pi * 2) * 0.1,
                1.0,
              ],
            ),
          ),
          child: Stack(
            children: [
              ...List.generate(30, (index) => _buildFloatingParticle(index)),
              CustomPaint(
                size: Size.infinite,
                painter: GridPainter(
                  color: Colors.white.withOpacity(0.02),
                  animation: _particleController,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = math.Random(index);
    final size = random.nextDouble() * 6 + 2;
    final startX = random.nextDouble();
    final startY = random.nextDouble();

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + index * 0.1) % 1.0;
        final x = startX + math.sin(progress * math.pi * 2) * 0.2;
        final y = (startY + progress) % 1.0;

        return Positioned(
          left: MediaQuery.of(context).size.width * x,
          top: MediaQuery.of(context).size.height * y,
          child: Opacity(
            opacity: (math.sin(progress * math.pi) * 0.5 + 0.3).clamp(0.0, 1.0),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF9333EA),
                    const Color(0xFF9333EA).withOpacity(0),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9333EA).withOpacity(0.5),
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

  Widget _buildHeader() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1F3A).withOpacity(0.95),
              const Color(0xFF0A0E27).withOpacity(0.9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9333EA).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildGlassButton(
              icon: Icons.arrow_back,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: const [
                              Colors.white,
                              Color(0xFF9333EA),
                              Color(0xFFEC4899),
                              Colors.white,
                            ],
                            stops: [
                              0.0,
                              _glowController.value * 0.5,
                              _glowController.value * 0.5 + 0.1,
                              1.0,
                            ],
                          ).createShader(bounds);
                        },
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Comprehensive Analysis Report',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            _buildGlassButton(
              icon: _isCopied ? Icons.check : Icons.copy,
              onPressed: _copyToClipboard,
              color: _isCopied ? Colors.green : null,
            ),
            const SizedBox(width: 12),
            _buildGlassButton(
              icon: Icons.share,
              onPressed: _shareReport,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (color ?? Colors.white).withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: (color ?? const Color(0xFF9333EA)).withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color ?? Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    return FadeTransition(
      opacity: _fadeController,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildParsedReport(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final lines = widget.reportContent.split('\n');
    String totalCompilations = '0';
    String avgTime = 'N/A';

    for (final line in lines) {
      if (line.contains('Count:')) {
        totalCompilations = line.split(':').last.trim();
      } else if (line.contains('Mean:')) {
        avgTime = line.split(':').last.trim();
      }
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Container(
            margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6B4CE6).withOpacity(0.9),
                  const Color(0xFF9333EA).withOpacity(0.9),
                  const Color(0xFFEC4899).withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9333EA).withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    'Total Compilations',
                    totalCompilations,
                    Icons.code,
                    0,
                  ),
                ),
                Container(
                  width: 2,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0),
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _buildSummaryMetric(
                    'Average Time',
                    avgTime,
                    Icons.timer,
                    1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryMetric(
      String label, String value, IconData icon, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 200),
      curve: Curves.easeOut,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParsedReport() {
    final lines = widget.reportContent.split('\n');
    final widgets = <Widget>[];
    int index = 0;

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      if (line.startsWith('═')) {
        widgets.add(_buildTitleSection(line, index++));
      } else if (line.startsWith('▓')) {
        widgets.add(_buildSectionHeader(line, index++));
      } else if (line.contains(':') && !line.startsWith(' ')) {
        widgets.add(_buildKeyValueRow(line, index++));
      } else if (line.trim().startsWith('-')) {
        widgets.add(_buildBulletPoint(line, index++));
      } else {
        widgets.add(_buildNormalText(line, index++));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  Widget _buildTitleSection(String line, int index) {
    final text = line.replaceAll('═', '').trim();
    if (text.isEmpty) return const SizedBox(height: 8);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 50),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9333EA)
                                  .withOpacity(0.3 * _glowController.value),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6B4CE6).withOpacity(0.4),
                        const Color(0xFF9333EA).withOpacity(0.4),
                        const Color(0xFFEC4899).withOpacity(0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      width: 2,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, iconValue, child) {
                          return Transform.rotate(
                            angle: iconValue * math.pi * 2,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.analytics_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Color.lerp(Colors.white,
                                      const Color(0xFFEC4899), _glowController.value)!,
                                  Colors.white,
                                ],
                              ).createShader(bounds);
                            },
                            child: Text(
                              text,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 800 + index * 50),
                        curve: Curves.easeOut,
                        builder: (context, lineValue, child) {
                          return Container(
                            height: 3,
                            width: 200 * lineValue,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white,
                                  Colors.transparent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String line, int index) {
    final text = line.replaceAll('▓', '').trim();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + index * 50),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(top: 28, bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9333EA).withOpacity(0.4 * value),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(
                            const Color(0xFF6B4CE6),
                            const Color(0xFF9333EA),
                            _glowController.value,
                          )!,
                          Color.lerp(
                            const Color(0xFF9333EA),
                            const Color(0xFFEC4899),
                            _glowController.value,
                          )!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 800 + index * 50),
                          builder: (context, iconValue, child) {
                            return Transform.rotate(
                              angle: iconValue * math.pi * 2,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getSectionIcon(text),
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration:
                                Duration(milliseconds: 600 + index * 50),
                                curve: Curves.easeOut,
                                builder: (context, lineValue, child) {
                                  return Container(
                                    height: 2,
                                    width: 150 * lineValue,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Colors.white.withOpacity(0),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white
                                        .withOpacity(_glowController.value),
                                    blurRadius: 15,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeyValueRow(String line, int index) {
    final parts = line.split(':');
    if (parts.length < 2) return _buildNormalText(line, index);

    final key = parts[0].trim();
    final value = parts.sublist(1).join(':').trim();

    final hasPercentage = value.contains('%');
    final percentMatch = RegExp(r'(\d+\.?\d*)%').firstMatch(value);
    double? progressValue;

    if (percentMatch != null) {
      final parsedValue = double.tryParse(percentMatch.group(1)!);
      if (parsedValue != null) {
        progressValue = parsedValue / 100;
      }
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 50),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - animValue), 0),
          child: Opacity(
            opacity: animValue,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1F3A).withOpacity(0.8),
                    const Color(0xFF252B4A).withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _getValueColor(value).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getValueColor(value).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getValueColor(value).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getKeyIcon(key),
                          color: _getValueColor(value),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: Text(
                          key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _getValueColor(value),
                            fontFamily: 'monospace',
                            letterSpacing: 0.5,
                          ),
                          child: Text(
                            value,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (progressValue != null && hasPercentage) ...[
                    const SizedBox(height: 12),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: progressValue),
                      duration: Duration(milliseconds: 1000 + index * 50),
                      curve: Curves.easeOutCubic,
                      builder: (context, barValue, child) {
                        return Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: barValue,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getValueColor(value),
                                      _getValueColor(value).withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                      _getValueColor(value).withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getKeyIcon(String key) {
    final lower = key.toLowerCase();
    if (lower.contains('count')) return Icons.numbers;
    if (lower.contains('mean') || lower.contains('average')) {
      return Icons.analytics;
    }
    if (lower.contains('median')) return Icons.insights;
    if (lower.contains('std') || lower.contains('deviation')) {
      return Icons.trending_flat;
    }
    if (lower.contains('min')) return Icons.arrow_downward;
    if (lower.contains('max')) return Icons.arrow_upward;
    if (lower.contains('p95') ||
        lower.contains('p99') ||
        lower.contains('percentile')) return Icons.show_chart;
    if (lower.contains('cv')) return Icons.percent;
    if (lower.contains('skewness')) return Icons.align_horizontal_left;
    if (lower.contains('kurtosis')) return Icons.signal_cellular_alt;
    if (lower.contains('ci') || lower.contains('confidence')) {
      return Icons.check_circle_outline;
    }
    if (lower.contains('q1') || lower.contains('q3')) {
      return Icons.compare_arrows;
    }
    if (lower.contains('iqr')) return Icons.view_week;
    return Icons.info_outline;
  }

  Widget _buildBulletPoint(String line, int index) {
    final text = line.trim().substring(1).trim();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 40),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          alignment: Alignment.centerLeft,
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(left: 16, bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6B4CE6).withOpacity(0.15),
                    const Color(0xFF9333EA).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF9333EA).withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 600 + index * 40),
                    builder: (context, pulseValue, child) {
                      return Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: const RadialGradient(
                            colors: [
                              Color(0xFF9333EA),
                              Color(0xFFEC4899),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9333EA)
                                  .withOpacity(0.6 * pulseValue),
                              blurRadius: 12 * pulseValue,
                              spreadRadius: 3 * pulseValue,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildNormalText(String line, int index) {
    final hasIndentation = line.startsWith('  ');
    final isMonospace = line.contains('  ') || hasIndentation;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 250 + index * 30),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value * 0.9,
          child: Container(
            margin: EdgeInsets.only(
              left: hasIndentation ? 24 : 12,
              bottom: 6,
              right: 12,
            ),
            padding: isMonospace
                ? const EdgeInsets.all(12)
                : const EdgeInsets.symmetric(vertical: 4),
            decoration: isMonospace
                ? BoxDecoration(
              color: const Color(0xFF0A0E27).withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
              ),
            )
                : null,
            child: Text(
              line,
              style: TextStyle(
                fontSize: isMonospace ? 12 : 13,
                color: Colors.white.withOpacity(0.85),
                height: 1.6,
                fontFamily: isMonospace ? 'monospace' : null,
                fontWeight: isMonospace ? FontWeight.w400 : FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0E27).withOpacity(0.9),
              const Color(0xFF1A1F3A).withOpacity(0.95),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9333EA).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Color(0xFF9333EA),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Generated by MiniLang Compiler Performance Analyzer',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            _buildActionButton(
              'Copy All',
              Icons.copy_all,
              _copyToClipboard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6B4CE6), Color(0xFF9333EA)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9333EA).withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollToTopButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B4CE6), Color(0xFF9333EA)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9333EA).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_upward,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getSectionIcon(String section) {
    final lower = section.toLowerCase();
    if (lower.contains('overall')) return Icons.analytics;
    if (lower.contains('phase')) return Icons.layers;
    if (lower.contains('cache')) return Icons.memory;
    if (lower.contains('temporal')) return Icons.timeline;
    if (lower.contains('complexity')) return Icons.functions;
    if (lower.contains('outlier')) return Icons.warning_amber;
    if (lower.contains('regression')) return Icons.trending_down;
    if (lower.contains('recommendation')) return Icons.lightbulb;
    return Icons.info;
  }

  Color _getValueColor(String value) {
    if (value.contains('ms') || value.contains('us') || value.contains('s')) {
      final num = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
      if (num != null) {
        if (num < 1000) return const Color(0xFF10B981);
        if (num < 5000) return const Color(0xFF3B82F6);
        return const Color(0xFFF59E0B);
      }
      return const Color(0xFF10B981);
    }

    if (value.contains('%')) {
      final num = double.tryParse(value.replaceAll('%', ''));
      if (num != null) {
        if (num < 30) return const Color(0xFFEF4444);
        if (num < 70) return const Color(0xFFF59E0B);
        return const Color(0xFF10B981);
      }
      return const Color(0xFF3B82F6);
    }

    if (value.contains('O(')) {
      return const Color(0xFFF59E0B);
    }

    if (RegExp(r'^\d+\.?\d*$').hasMatch(value)) {
      return const Color(0xFF9333EA);
    }

    if (value.contains('[') || value.contains(',')) {
      return const Color(0xFF06B6D4);
    }

    return Colors.white;
  }
  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.reportContent));
    setState(() => _isCopied = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Report copied to clipboard!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }

  void _shareReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.share, color: Colors.white),
            SizedBox(width: 12),
            Text('Share functionality coming soon!'),
          ],
        ),
        backgroundColor: const Color(0xFF6B4CE6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  final Animation<double> animation;

  GridPainter({required this.color, required this.animation})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    final spacing = 50.0;
    final offset = animation.value * spacing;

    for (double x = offset % spacing; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = offset % spacing; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => true;
}
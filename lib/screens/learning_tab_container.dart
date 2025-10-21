import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'learning_screen.dart';
import 'learning_screen_advanced.dart';
import 'learning_screen_pro.dart';

class LearningTabContainer extends StatefulWidget {
  const LearningTabContainer({super.key});

  @override
  State<LearningTabContainer> createState() => _LearningTabContainerState();
}

class _LearningTabContainerState extends State<LearningTabContainer>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _bounceController;
  late AnimationController _shimmerController;
  int _currentIndex = 0;
  double _animationValue = 0.0;

  final List<TabData> _tabs = [
    TabData(
      title: 'پایه',
      subtitle: 'شروع سفر یادگیری',
      description: '15 درس • 1 ساعت',
      icon: Icons.rocket_launch_rounded,
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
      accentColor: Color(0xFF9D50BB),
      particles: [
        Particle(emoji: '🚀', delay: 0.0),
        Particle(emoji: '⭐', delay: 0.3),
        Particle(emoji: '✨', delay: 0.6),
      ],
    ),
    TabData(
      title: 'پیشرفته',
      subtitle: 'گام بعدی شما',
      description: '20 درس • 1 ساعت',
      icon: Icons.auto_awesome_rounded,
      gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
      accentColor: Color(0xFFFF6B9D),
      particles: [
        Particle(emoji: '🔥', delay: 0.0),
        Particle(emoji: '💎', delay: 0.3),
        Particle(emoji: '⚡', delay: 0.6),
      ],
    ),
    TabData(
      title: 'حرفه‌ای',
      subtitle: 'تسلط کامل',
      description: '9 درس • 1 ساعت',
      icon: Icons.military_tech_rounded,
      gradient: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      accentColor: Color(0xFF00D4FF),
      particles: [
        Particle(emoji: '👑', delay: 0.0),
        Particle(emoji: '🏆', delay: 0.3),
        Particle(emoji: '💫', delay: 0.6),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _tabController.animation?.addListener(_handleAnimation);

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  void _handleAnimation() {
    setState(() {
      _animationValue = _tabController.animation?.value ?? 0.0;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.animation?.removeListener(_handleAnimation);
    _tabController.dispose();
    _bounceController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Color _getInterpolatedColor() {
    final progress = _animationValue;
    final index = progress.floor();
    final fraction = progress - index;

    if (index >= _tabs.length - 1) {
      return _tabs[_tabs.length - 1].gradient[0];
    }

    return Color.lerp(
      _tabs[index].gradient[0],
      _tabs[index + 1].gradient[0],
      fraction,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentColor = _getInterpolatedColor();

    return Stack(
      children: [
        // Animated particles background
        ..._buildParticles(),

        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Floating header with morphism
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Animated glow background
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    top: -80,
                    right: _currentIndex == 0
                        ? -40
                        : _currentIndex == 1
                        ? MediaQuery.of(context).size.width / 2 - 100
                        : MediaQuery.of(context).size.width - 120,
                    child: AnimatedBuilder(
                      animation: _bounceController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_bounceController.value * 0.15),
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  currentColor.withOpacity(0.25),
                                  currentColor.withOpacity(0.05),
                                  currentColor.withOpacity(0.0),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Main header card
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [
                                Colors.white.withOpacity(0.12),
                                Colors.white.withOpacity(0.06),
                              ]
                                  : [
                                Colors.white.withOpacity(0.98),
                                Colors.white.withOpacity(0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(
                              width: 2,
                              color: isDark
                                  ? Colors.white.withOpacity(0.25)
                                  : Colors.white.withOpacity(0.9),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: currentColor.withOpacity(0.35),
                                blurRadius: 50,
                                offset: const Offset(0, 20),
                                spreadRadius: -10,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.6 : 0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Header with particles
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 450),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.25),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      )),
                                      child: ScaleTransition(
                                        scale: Tween<double>(begin: 0.9, end: 1.0)
                                            .animate(animation),
                                        child: child,
                                      ),
                                    ),
                                  );
                                },
                                child: _buildHeaderInfo(_tabs[_currentIndex]),
                              ),

                              const SizedBox(height: 24),

                              // Tab selector with shimmer
                              _buildCustomTabBar(),

                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Animated progress with gradient trail
              _buildProgressIndicator(),

              const SizedBox(height: 12),

              // Content with fixed height
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: TabBarView(
                  controller: _tabController,
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    LearningScreen(),
                    LearningScreenAdvanced(),
                    LearningScreenPro(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildParticles() {
    return _tabs[_currentIndex].particles.asMap().entries.map((entry) {
      final index = entry.key;
      final particle = entry.value;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        top: 60 + (index * 30.0),
        right: 20 + (index * 15.0),
        child: TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 800 + (index * 200)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -20 * value),
              child: Opacity(
                opacity: value * 0.6,
                child: Transform.rotate(
                  angle: value * math.pi * 0.5,
                  child: Text(
                    particle.emoji,
                    style: TextStyle(fontSize: 24 + (value * 8)),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildHeaderInfo(TabData tab) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: ValueKey(tab.title),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 12),
      child: Row(
        children: [
          // Premium 3D Icon
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            tween: Tween(begin: 0, end: 1),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Transform.rotate(
                  angle: (1 - value) * math.pi * 0.8,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: tab.gradient,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: tab.gradient[0].withOpacity(0.7),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                    spreadRadius: -6,
                  ),
                  BoxShadow(
                    color: tab.gradient[1].withOpacity(0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated shimmer
                  AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return Positioned(
                        top: -40 + (_shimmerController.value * 120),
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Glossy top
                  Positioned(
                    top: 10,
                    left: 12,
                    right: 12,
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.5),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  // Icon
                  Center(
                    child: Icon(
                      tab.icon,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Text with badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        tab.accentColor.withOpacity(0.2),
                        tab.accentColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: tab.accentColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'LEVEL ${_currentIndex + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: tab.accentColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Title
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: tab.gradient,
                  ).createShader(bounds),
                  child: Text(
                    tab.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Subtitle
                Text(
                  tab.subtitle,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                // Stats
                Row(
                  children: [
                    _buildStatChip(
                      Icons.play_circle_outline_rounded,
                      tab.description.split(' • ')[0],
                      tab.accentColor,
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      Icons.access_time_rounded,
                      tab.description.split(' • ')[1],
                      tab.accentColor,
                      isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.grey.shade100.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color.withOpacity(0.8),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 66,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.25)
            : Colors.grey.shade50.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.shade200.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _currentIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                    colors: _tabs[index].gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: _tabs[index].gradient[0].withOpacity(0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: -4,
                    ),
                  ]
                      : null,
                ),
                child: Stack(
                  children: [
                    // Shimmer on selected
                    if (isSelected)
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          return Positioned(
                            left: -100 + (_shimmerController.value * 200),
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.0),
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    // Glossy top
                    if (isSelected)
                      Positioned(
                        top: 6,
                        left: 16,
                        right: 16,
                        child: Container(
                          height: 18,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.35),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    // Content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              fontSize: isSelected ? 16 : 14,
                              fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              letterSpacing: 0.5,
                              shadows: isSelected
                                  ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ]
                                  : null,
                            ),
                            child: Text(_tabs[index].title),
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 4),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.8),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentColor = _getInterpolatedColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      height: 6,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final position = (constraints.maxWidth / 3) * _animationValue;

          return Stack(
            children: [
              // Trail effect
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                left: 0,
                child: Container(
                  width: position + (constraints.maxWidth / 3),
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        currentColor.withOpacity(0.1),
                        currentColor.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Main progress
              Positioned(
                left: position,
                child: Container(
                  width: constraints.maxWidth / 3,
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _tabs[_currentIndex].gradient,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: currentColor.withOpacity(0.8),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class TabData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final Color accentColor;
  final List<Particle> particles;

  TabData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.particles,
  });
}

class Particle {
  final String emoji;
  final double delay;

  Particle({required this.emoji, required this.delay});
}
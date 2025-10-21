import 'package:flutter/material.dart';
import 'dart:math' as math;

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _floatingAnimationController;
  late AnimationController _particlesController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _particlesController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.4, 1.0, curve: Curves.bounceOut),
    ));

    _mainAnimationController.forward();
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _floatingAnimationController.dispose();
    _particlesController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(context, isDark, size),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernAppBar(context, theme, isDark),
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _slideAnimation,
                    _fadeAnimation,
                    _scaleAnimation,
                  ]),
                  builder: (context, child) {
                    return SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _buildHeroSection(context, isDark),
                                const SizedBox(height: 32),
                                _buildFeaturesTitle(context, isDark),
                                const SizedBox(height: 20),
                                _buildFeatureCard(
                                  context,
                                  icon: Icons.visibility_rounded,
                                  title: 'مشاهده مراحل کامپایل',
                                  description:
                                  'تمام فازهای کامپایل را گام به گام ببینید',
                                  color: Colors.blue,
                                  isDark: isDark,
                                  delay: 0,
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureCard(
                                  context,
                                  icon: Icons.edit_rounded,
                                  title: 'ویرایشگر کد پیشرفته',
                                  description:
                                  'ویرایشگر با قابلیت Syntax Highlighting',
                                  color: Colors.green,
                                  isDark: isDark,
                                  delay: 200,
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureCard(
                                  context,
                                  icon: Icons.play_arrow_rounded,
                                  title: 'اجرای فوری و آنی',
                                  description: 'کامپایل و اجرای سریع کدهای شما',
                                  color: Colors.orange,
                                  isDark: isDark,
                                  delay: 400,
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureCard(
                                  context,
                                  icon: Icons.school_rounded,
                                  title: 'مناسب برای آموزش',
                                  description:
                                  'ابزاری عالی برای یادگیری مفاهیم کامپایلر',
                                  color: Colors.pink,
                                  isDark: isDark,
                                  delay: 600,
                                ),
                                const SizedBox(height: 32),
                                _buildTechSection(context, isDark),
                                const SizedBox(height: 32),
                                _buildDeveloperCard(context, isDark),
                                const SizedBox(height: 24),
                                _buildBackButton(context),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(
      BuildContext context, bool isDark, Size size) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F3460),
            ]
                : [
              const Color(0xFFE8EAF6),
              const Color(0xFFF3E5F5),
              const Color(0xFFE1F5FE),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: AnimatedBuilder(
          animation: _particlesController,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlesPainter(
                animation: _particlesController,
                isDark: isDark,
              ),
              size: size,
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernAppBar(
      BuildContext context, ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                      (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (isDark ? Colors.black : Colors.white).withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          title: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'درباره برنامه',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              );
            },
          ),
          centerTitle: true,
          background: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Center(
                child: Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.1),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _floatingAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              0, math.sin(_floatingAnimationController.value * math.pi) * 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                  const Color(0xFF2D1B69).withOpacity(0.3),
                  const Color(0xFF11998E).withOpacity(0.2),
                ]
                    : [
                  Colors.deepPurple.shade100.withOpacity(0.5),
                  Colors.deepPurple.shade50.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.1),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withOpacity(0.7),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.code_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'یک ابزار آموزشی قدرتمند برای درک و مشاهده تمام مراحل کامپایل',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    height: 1.8,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturesTitle(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Row(
      textDirection: TextDirection.rtl,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.1),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade600,
                      Colors.deepPurple.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        Text(
          'ویژگی‌های برنامه',
          textDirection: TextDirection.rtl,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
        required Color color,
        required bool isDark,
        required int delay,
      }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + delay),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(isDark ? 0.2 : 0.15),
                  color.withOpacity(isDark ? 0.1 : 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.6),
                          height: 1.4,
                        ),
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

  Widget _buildTechSection(BuildContext context, bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                  Colors.deepPurple.shade900.withOpacity(0.3),
                  Colors.deepPurple.shade800.withOpacity(0.2),
                ]
                    : [
                  Colors.deepPurple.shade100,
                  Colors.deepPurple.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.deepPurple.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple.shade700,
                            Colors.deepPurple.shade500,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.build_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'تکنولوژی‌های استفاده شده',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTechItem('Flutter', 'فریمورک توسعه اپلیکیشن',
                    Colors.deepPurple.shade600, isDark),
                const SizedBox(height: 14),
                _buildTechItem('Dart', 'زبان برنامه‌نویسی',
                    Colors.deepPurple.shade600, isDark),
                const SizedBox(height: 14),
                _buildTechItem(
                    'Provider', 'مدیریت state', Colors.deepPurple.shade600, isDark),
                const SizedBox(height: 14),
                _buildTechItem('Material Design 3', 'طراحی رابط کاربری',
                    Colors.deepPurple.shade600, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTechItem(
      String title, String subtitle, Color color, bool isDark) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                subtitle,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? Colors.white.withOpacity(0.6)
                      : Colors.black.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeveloperCard(BuildContext context, bool isDark) {
    return AnimatedBuilder(
      animation: _floatingAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              0, math.sin(_floatingAnimationController.value * math.pi) * 6),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                  Colors.deepPurple.shade900.withOpacity(0.4),
                  Colors.deepPurple.shade800.withOpacity(0.3),
                ]
                    : [
                  Colors.deepPurple.shade100,
                  Colors.deepPurple.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.deepPurple.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.25),
                  blurRadius: 25,
                  spreadRadius: 3,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.08),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.shade600,
                              Colors.deepPurple.shade400,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'TNa7iDT',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'MiniLang Compiler',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.deepPurple.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'تمامی حقوق محفوظ است',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withOpacity(0.8)
                          : Colors.black.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatingAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              0,
              math.sin(_floatingAnimationController.value * math.pi * 2) * 3),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('بازگشت به برنامه'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
              backgroundColor: Colors.deepPurple.shade600,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: Colors.deepPurple.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ParticlesPainter extends CustomPainter {
  final AnimationController animation;
  final bool isDark;

  ParticlesPainter({
    required this.animation,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final particleCount = 30;
    final random = math.Random(42);

    for (int i = 0; i < particleCount; i++) {
      final progress = (animation.value + (i / particleCount)) % 1.0;
      final x = random.nextDouble() * size.width;
      final y =
          (random.nextDouble() * size.height + progress * 50) % size.height;
      final radius = random.nextDouble() * 3 + 1;

      final opacity = (math.sin(progress * math.pi * 2) * 0.5 + 0.5) * 0.3;

      paint.color = isDark
          ? Colors.white.withOpacity(opacity)
          : Colors.black.withOpacity(opacity * 0.5);

      canvas.drawCircle(Offset(x, y), radius, paint);

      for (int j = i + 1; j < math.min(i + 5, particleCount); j++) {
        final progress2 = (animation.value + (j / particleCount)) % 1.0;
        final x2 = random.nextDouble() * size.width;
        final y2 =
            (random.nextDouble() * size.height + progress2 * 50) % size.height;

        final distance =
        math.sqrt(math.pow(x2 - x, 2) + math.pow(y2 - y, 2));
        if (distance < 100) {
          paint.color = isDark
              ? Colors.white.withOpacity(opacity * 0.1)
              : Colors.black.withOpacity(opacity * 0.05);
          paint.strokeWidth = 1;
          canvas.drawLine(Offset(x, y), Offset(x2, y2), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
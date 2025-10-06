import 'package:flutter/material.dart';
import 'dart:math' as math;

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _floatingAnimationController;
  late AnimationController _particlesController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

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

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_particlesController);

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

          // Main content
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
                                const SizedBox(height: 40),
                                _buildImportantTips(context, isDark),
                                const SizedBox(height: 40),
                                _buildHelpSection(
                                  context,
                                  icon: Icons.code_rounded,
                                  iconColor: Colors.purple,
                                  title: 'ویرایشگر کد',
                                  description: 'کد MiniLang خود را در این بخش بنویسید و ویرایش کنید.',
                                  tips: [
                                    'از دکمه‌های کمکی برای درج سریع استفاده کنید',
                                    'کد شما به صورت خودکار ذخیره می‌شود',
                                    'می‌توانید از نمونه کدها استفاده کنید',
                                    'پشتیبانی از Syntax Highlighting برای خوانایی بهتر',
                                  ],
                                  delay: 0,
                                ),
                                const SizedBox(height: 20),
                                _buildHelpSection(
                                  context,
                                  icon: Icons.timeline_rounded,
                                  iconColor: Colors.pink,
                                  title: 'فازهای کامپایل',
                                  description: 'تمام مراحل کامپایل را گام به گام مشاهده کنید.',
                                  tips: [
                                    'تحلیل لغوی (Lexical Analysis) - شناسایی توکن‌ها',
                                    'تحلیل نحوی (Syntax Analysis) - بررسی ساختار',
                                    'تحلیل معنایی (Semantic Analysis) - بررسی معنا',
                                    'تولید کد میانی و نهایی',
                                    'مشاهده جزئیات هر فاز به صورت جداگانه',
                                  ],
                                  delay: 200,
                                ),
                                const SizedBox(height: 20),
                                _buildHelpSection(
                                  context,
                                  icon: Icons.terminal_rounded,
                                  iconColor: Colors.cyan,
                                  title: 'خروجی کنسول',
                                  description: 'نتیجه اجرای برنامه و خطاها را ببینید.',
                                  tips: [
                                    'خطاها با رنگ قرمز نمایش داده می‌شوند',
                                    'خروجی موفق با رنگ سبز',
                                    'می‌توانید خروجی را کپی کنید',
                                    'مشاهده زمان اجرا و اطلاعات تکمیلی',
                                    'پاک کردن کنسول با یک کلیک',
                                  ],
                                  delay: 400,
                                ),
                                const SizedBox(height: 20),
                                _buildHelpSection(
                                  context,
                                  icon: Icons.library_books_rounded,
                                  iconColor: Colors.green,
                                  title: 'نمونه کدها',
                                  description: 'مجموعه‌ای از کدهای آماده برای شروع سریع.',
                                  tips: [
                                    'کدهای ساده برای یادگیری مبانی',
                                    'مثال‌های پیشرفته برای کاربران حرفه‌ای',
                                    'با یک کلیک در ویرایشگر بارگذاری می‌شوند',
                                    'توضیحات کامل برای هر نمونه کد',
                                  ],
                                  delay: 600,
                                ),
                                const SizedBox(height: 40),
                                _buildActionButtons(context),
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

  Widget _buildAnimatedBackground(BuildContext context, bool isDark, Size size) {
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
              const Color(0xFFE3F2FD),
              const Color(0xFFF3E5F5),
              const Color(0xFFFFF3E0),
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

  Widget _buildModernAppBar(BuildContext context, ThemeData theme, bool isDark) {
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
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
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
                    'راهنمای جامع',
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
                      Icons.help_outline_rounded,
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
          offset: Offset(0, math.sin(_floatingAnimationController.value * math.pi) * 8),
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
                  Colors.blue.shade100.withOpacity(0.5),
                  Colors.blue.shade50.withOpacity(0.3),
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
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: theme.colorScheme.primary,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'به راهنمای MiniLang Compiler خوش آمدید! در اینجا با تمام قابلیت‌های برنامه آشنا می‌شوید.',
                    textDirection: TextDirection.rtl,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withOpacity(0.9),
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

  Widget _buildImportantTips(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            Colors.orange.shade900.withOpacity(0.2),
            Colors.orange.shade800.withOpacity(0.1),
          ]
              : [
            Colors.orange.shade100,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
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
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.15),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade700,
                            Colors.orange.shade500,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Text(
                'نکات مهم',
                textDirection: TextDirection.rtl,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTipItem('از دکمه "کامپایل و اجرا" برای شروع استفاده کنید', Colors.orange.shade700),
          _buildTipItem('هر تغییر در کد به صورت خودکار ذخیره می‌شود', Colors.orange.shade700),
          _buildTipItem('می‌توانید بین تب‌ها جابجا شوید بدون از دست دادن کد', Colors.orange.shade700),
          _buildTipItem('برای مشاهده جزئیات بیشتر، روی هر فاز کلیک کنید', Colors.orange.shade700),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String description,
        required List<String> tips,
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor.withOpacity(0.1),
                  iconColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: iconColor.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.15),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            iconColor,
                            iconColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [iconColor, iconColor.withOpacity(0.7)],
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _floatingAnimationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, math.sin(_floatingAnimationController.value * math.pi * 2) * 3),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('بازگشت به برنامه'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: Colors.blue.withOpacity(0.4),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
      final y = (random.nextDouble() * size.height + progress * 50) % size.height;
      final radius = random.nextDouble() * 3 + 1;

      final opacity = (math.sin(progress * math.pi * 2) * 0.5 + 0.5) * 0.3;

      paint.color = isDark
          ? Colors.white.withOpacity(opacity)
          : Colors.black.withOpacity(opacity * 0.5);

      canvas.drawCircle(Offset(x, y), radius, paint);

      for (int j = i + 1; j < math.min(i + 5, particleCount); j++) {
        final progress2 = (animation.value + (j / particleCount)) % 1.0;
        final x2 = random.nextDouble() * size.width;
        final y2 = (random.nextDouble() * size.height + progress2 * 50) % size.height;

        final distance = math.sqrt(math.pow(x2 - x, 2) + math.pow(y2 - y, 2));
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
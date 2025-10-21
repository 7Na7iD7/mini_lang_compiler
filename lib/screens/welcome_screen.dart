import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class WelcomeScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const WelcomeScreen({
    super.key,
    this.onCompleted,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _backgroundController;
  late final AnimationController _floatController;
  late final AnimationController _pulseController;
  late final AnimationController _transformController;
  late final AnimationController _particleController;
  late final AnimationController _glowController;

  int _currentPage = 0;
  static const int _totalPages = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _transformController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _transformController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_currentPage < _totalPages - 1) {
      await HapticFeedback.lightImpact();
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubicEmphasized,
      );
    } else {
      await HapticFeedback.mediumImpact();
      _completeWelcome();
    }
  }

  Future<void> _previousPage() async {
    if (_currentPage > 0) {
      await HapticFeedback.selectionClick();
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubicEmphasized,
      );
    }
  }

  void _completeWelcome() {
    widget.onCompleted?.call();
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/main',
          (route) => false,
    );
  }

  void _skipWelcome() {
    HapticFeedback.lightImpact();
    _completeWelcome();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Mesh Gradient Background
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        math.sin(_backgroundController.value * 2 * math.pi) * 0.3,
                        math.cos(_backgroundController.value * 2 * math.pi) * 0.3,
                      ),
                      radius: 1.5,
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.15),
                        theme.colorScheme.secondary.withOpacity(0.1),
                        theme.colorScheme.surface,
                        theme.colorScheme.tertiary.withOpacity(0.08),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // Glassmorphism Particles
          RepaintBoundary(
            child: _GlassmorphismParticles(
              controller: _particleController,
              size: size,
            ),
          ),

          // Floating Code Tokens
          RepaintBoundary(
            child: _PageSpecificTokens(
              controller: _floatController,
              size: size,
              currentPage: _currentPage,
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(theme),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      HapticFeedback.selectionClick();
                    },
                    children: [
                      _buildFirstPage(theme),
                      _buildSecondPage(theme),
                      _buildThirdPage(theme),
                    ],
                  ),
                ),
                _buildBottomNavigation(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          // Back Button , Morphing Animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _currentPage > 0 ? 1 : 0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.secondaryContainer,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _currentPage > 0 ? _previousPage : null,
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const Spacer(),

          // Liquid Progress Indicators
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                _totalPages,
                    (index) => _buildLiquidDot(index, theme),
              ),
            ),
          ),

          const Spacer(),

          // Skip Button , Hover Effect
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface.withOpacity(0.5),
                  theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _skipWelcome,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'رد کردن',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidDot(int index, ThemeData theme) {
    final isActive = index == _currentPage;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubicEmphasized,
          margin: const EdgeInsets.symmetric(horizontal: 3.0),
          height: isActive ? 10.0 : 8.0,
          width: isActive ? 28.0 : 8.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            gradient: isActive
                ? LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            )
                : null,
            color: isActive
                ? null
                : theme.colorScheme.primary.withOpacity(0.3),
            boxShadow: isActive
                ? [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(
                  0.3 + _pulseController.value * 0.2,
                ),
                blurRadius: 8 + _pulseController.value * 4,
                spreadRadius: 1,
              ),
            ]
                : null,
          ),
        );
      },
    );
  }

  Widget _buildFirstPage(ThemeData theme) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // 3D Floating Card Animation
            RepaintBoundary(
              child: _build3DCodeAnimation(theme),
            ),

            const SizedBox(height: 56.0),

            // Title , Gradient Text
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                  theme.colorScheme.tertiary,
                ],
              ).createShader(bounds),
              child: Text(
                'به کامپایلر MiniLang \nخوش آمدید',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                  fontSize: 28,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            const SizedBox(height: 24.0),

            // Subtitle , Fade Animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 15 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Text(
                'یک ابزار آموزشی قدرتمند برای درک و مشاهده تمام مراحل کامپایل، از کد منبع تا اجرای نهایی.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.7,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondPage(ThemeData theme) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Interactive AST , Particle Effect
            RepaintBoundary(
              child: _buildInteractiveAST(theme),
            ),

            const SizedBox(height: 56.0),

            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  theme.colorScheme.secondary,
                  theme.colorScheme.tertiary,
                ],
              ).createShader(bounds),
              child: Text(
                'تحلیل تعاملی و با جزئیات',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                  fontSize: 28,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            const SizedBox(height: 24.0),

            Text(
              'با ویرایشگر هوشمند کد بنویسید و نتیجه هر مرحله از تحلیل لغوی، نحوی و معنایی را به صورت زنده مشاهده کنید.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.7,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildThirdPage(ThemeData theme) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Morphing Animation
            RepaintBoundary(
              child: _buildMorphingAnimation(theme),
            ),

            const SizedBox(height: 56.0),

            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF00897B),
                  Color(0xFF26A69A),
                ],
              ).createShader(bounds),
              child: Text(
                'از تحلیل تا اجرا',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                  fontSize: 28,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            const SizedBox(height: 24.0),

            Text(
              'کد تحلیل‌شده شما توسط مفسر به صورت مرحله به مرحله اجرا شده و خروجی در یک کنسول پیشرفته نمایش داده می‌شود.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.7,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _build3DCodeAnimation(ThemeData theme) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _glowController]),
      builder: (context, child) {
        final float = math.sin(_floatController.value * 2 * math.pi) * 15;
        final rotation = math.sin(_floatController.value * 2 * math.pi) * 0.1;

        return Transform.translate(
          offset: Offset(0, float),
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(rotation * 0.3)
              ..rotateY(rotation),
            alignment: Alignment.center,
            child: Container(
              width: 320,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primaryContainer.withOpacity(0.3),
                    theme.colorScheme.secondaryContainer.withOpacity(0.2),
                  ],
                ),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(
                      0.2 + _glowController.value * 0.3,
                    ),
                    blurRadius: 30 + _glowController.value * 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Grid Pattern
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GridPainter(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCodeLine(theme, 'var x = 10;', 0),
                        const SizedBox(height: 12),
                        _buildCodeLine(theme, 'if (x > 5) {', 0.2),
                        const SizedBox(height: 12),
                        _buildCodeLine(theme, '  print(x);', 0.4),
                        const SizedBox(height: 12),
                        _buildCodeLine(theme, '}', 0.6),
                      ],
                    ),
                  ),

                  // Shimmer Effect
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _transformController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _ShimmerPainter(
                            progress: _transformController.value,
                            color: theme.colorScheme.primary,
                          ),
                        );
                      },
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

  Widget _buildCodeLine(ThemeData theme, String text, double delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + (delay * 400).toInt()),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInteractiveAST(ThemeData theme) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _transformController]),
      builder: (context, child) {
        return Container(
          width: 280,
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.secondaryContainer.withOpacity(0.3),
                theme.colorScheme.tertiaryContainer.withOpacity(0.2),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.secondary.withOpacity(0.3),
                blurRadius: 25,
                spreadRadius: 3,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _InteractiveASTPainter(
              progress: _transformController.value,
              pulse: _pulseController.value,
              color: theme.colorScheme.secondary,
            ),
            child: Center(
              child: Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.secondary,
                        theme.colorScheme.tertiary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.secondary.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_tree_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMorphingAnimation(ThemeData theme) {
    return AnimatedBuilder(
      animation: _transformController,
      builder: (context, child) {
        final progress = _transformController.value;

        return Container(
          width: 320,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00897B).withOpacity(0.2),
                const Color(0xFF26A69A).withOpacity(0.15),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00897B).withOpacity(0.3),
                blurRadius: 25,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Source Icon
              Positioned(
                left: 30 + (progress * 40),
                child: Transform.scale(
                  scale: 1.2 - (progress * 0.4),
                  child: Opacity(
                    opacity: 1.0 - (progress * 0.5),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00897B),
                            Color(0xFF26A69A),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00897B).withOpacity(0.5),
                            blurRadius: 15,
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
                  ),
                ),
              ),

              // Morphing Particles
              ...List.generate(5, (i) {
                final angle = (progress * 2 * math.pi) + (i * math.pi / 2.5);
                final radius = 40.0 * progress;
                return Positioned(
                  left: 160 + math.cos(angle) * radius,
                  top: 90 + math.sin(angle) * radius,
                  child: Opacity(
                    opacity: progress,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.greenAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Output Console
              Positioned(
                right: 20,
                child: Transform.scale(
                  scale: 0.8 + (progress * 0.4),
                  child: Opacity(
                    opacity: progress,
                    child: Container(
                      width: 150,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.greenAccent.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildConsoleText('> Hello', progress * 1.2),
                          const SizedBox(height: 4),
                          _buildConsoleText('> World', progress * 1.5),
                          const SizedBox(height: 4),
                          _buildConsoleText('> 42', progress * 1.8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConsoleText(String text, double opacity) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.greenAccent,
          fontFamily: 'monospace',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: _buildNeumorphicButton(
                onPressed: _previousPage,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'قبلی',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                isPrimary: false,
                theme: theme,
              ),
            ),

          if (_currentPage > 0) const SizedBox(width: 16.0),

          Expanded(
            flex: _currentPage == 0 ? 1 : 2,
            child: _buildPrimaryButton(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(ThemeData theme) {
    final isLastPage = _currentPage == _totalPages - 1;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _glowController]),
      builder: (context, child) {
        final scale = isLastPage ? 1.0 + (_pulseController.value * 0.04) : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: isLastPage
                    ? [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ]
                    : [
                  theme.colorScheme.secondary,
                  theme.colorScheme.tertiary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isLastPage
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary)
                      .withOpacity(0.4 + _glowController.value * 0.3),
                  blurRadius: 20 + _glowController.value * 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _nextPage,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastPage ? 'شروع کدنویسی' : 'بعدی',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isLastPage
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNeumorphicButton({
    required VoidCallback onPressed,
    required Widget child,
    required bool isPrimary,
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PageSpecificTokens extends StatelessWidget {
  final AnimationController controller;
  final Size size;
  final int currentPage;

  const _PageSpecificTokens({
    required this.controller,
    required this.size,
    required this.currentPage,
  });

  List<String> _getTokensForPage() {
    switch (currentPage) {
      case 0:
        return ['var', 'int', '=', ';', 'id', '10', 'x', 'num', 'float', 'bool'];
      case 1:
        return ['if', 'else', 'while', 'for', '{ }', '( )', '>', '<', '==', '&&'];
      case 2:
        return ['print', 'return', 'func', '=>', 'void', 'output', 'run', 'exec'];
      default:
        return ['var', 'int', '='];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = _getTokensForPage();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          children: List.generate(12, (index) {
            final random = math.Random(index * 50 + currentPage * 100);
            final x = random.nextDouble() * size.width;
            final y = random.nextDouble() * size.height;
            final delay = random.nextDouble() * 2.0;
            final token = tokens[index % tokens.length];

            final offset = math.sin(
              controller.value * 2 * math.pi + delay,
            ) * 25.0;

            final opacity = 0.08 + math.sin(
              controller.value * math.pi + delay,
            ) * 0.15;

            final rotation = math.sin(
              controller.value * math.pi + delay,
            ) * 0.1;

            return Positioned(
              left: x,
              top: y + offset,
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('$currentPage-$index'),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (index * 50)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: opacity * value,
                        child: child,
                      ),
                    );
                  },
                  child: Transform.rotate(
                    angle: rotation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.25),
                            theme.colorScheme.secondary.withOpacity(0.2),
                          ],
                        ),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        token,
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const spacing = 20.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ShimmerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          color.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: [
          (progress - 0.3).clamp(0.0, 1.0),
          progress.clamp(0.0, 1.0),
          (progress + 0.3).clamp(0.0, 1.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) => true;
}

class _InteractiveASTPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final Color color;

  _InteractiveASTPainter({
    required this.progress,
    required this.pulse,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);

    // Animated circles
    for (int i = 0; i < 3; i++) {
      final radius = (size.width / 4) + (i * 20.0);
      final animatedRadius = radius * (0.8 + pulse * 0.2);
      final opacity = 0.3 - (i * 0.1) - (pulse * 0.1);

      canvas.drawCircle(
        center,
        animatedRadius,
        paint..color = color.withOpacity(opacity),
      );
    }

    // Tree structure
    final root = Offset(center.dx, center.dy - 50);
    final child1 = Offset(center.dx - 50, center.dy + 30);
    final child2 = Offset(center.dx + 50, center.dy + 30);
    final child3 = Offset(center.dx - 25, center.dy + 70);
    final child4 = Offset(center.dx + 25, center.dy + 70);

    // Animated progress reveal
    final revealProgress = (progress * 4).clamp(0.0, 1.0);

    paint
      ..color = color.withOpacity(0.9)
      ..strokeWidth = 3.5;

    if (revealProgress > 0.25) {
      canvas.drawLine(root, child1, paint);
    }
    if (revealProgress > 0.5) {
      canvas.drawLine(root, child2, paint);
    }
    if (revealProgress > 0.75) {
      canvas.drawLine(child1, child3, paint);
      canvas.drawLine(child2, child4, paint);
    }

    // Nodes
    paint.style = PaintingStyle.fill;

    if (revealProgress > 0) {
      canvas.drawCircle(root, 10.0 + pulse * 2, paint);
    }
    if (revealProgress > 0.25) {
      canvas.drawCircle(child1, 8.0 + pulse * 1.5, paint);
    }
    if (revealProgress > 0.5) {
      canvas.drawCircle(child2, 8.0 + pulse * 1.5, paint);
    }
    if (revealProgress > 0.75) {
      canvas.drawCircle(child3, 6.0 + pulse * 1, paint);
      canvas.drawCircle(child4, 6.0 + pulse * 1, paint);
    }
  }

  @override
  bool shouldRepaint(_InteractiveASTPainter oldDelegate) => true;
}

class _GlassmorphismParticles extends StatelessWidget {
  final AnimationController controller;
  final Size size;

  const _GlassmorphismParticles({
    required this.controller,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          children: List.generate(6, (index) {
            final random = math.Random(index * 100);
            final x = random.nextDouble() * size.width;
            final y = random.nextDouble() * size.height;
            final delay = random.nextDouble() * 2.0;
            final speed = 0.3 + random.nextDouble() * 0.4;

            final offset = math.sin(
              controller.value * 2 * math.pi * speed + delay,
            ) * 30.0;

            return Positioned(
              left: x,
              top: y + offset,
              child: _GlassParticle(
                size: 80.0 + (index % 3) * 40.0,
                color: index % 2 == 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary,
                opacity: 0.05 + (index % 3) * 0.02,
              ),
            );
          }),
        );
      },
    );
  }
}

class _GlassParticle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlassParticle({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * 0.3),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(opacity * 0.5),
            blurRadius: size * 0.5,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}
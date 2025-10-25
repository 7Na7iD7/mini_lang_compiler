import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/compiler_provider.dart';
import '../widgets/code_editor.dart';
import '../widgets/compilation_phases.dart';
import '../widgets/console_output.dart';
import '../widgets/example_code_selector.dart';
import 'compiler_ui_components.dart';
import 'help_screen.dart';
import 'about_screen.dart';
import 'settings_screen.dart';
import 'learning_tab_container.dart';
import 'chatbot_screen.dart';
import 'dart:ui';
import 'dart:math' as math;

class ShiningIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final List<Color> gradient;
  final Duration duration;
  final Color? iconColor;

  const ShiningIcon({
    super.key,
    required this.icon,
    this.size = 48,
    this.gradient = const [Colors.yellow, Colors.orange],
    this.duration = const Duration(milliseconds: 1200),
    this.iconColor,
  });

  @override
  State<ShiningIcon> createState() => _ShiningIconState();
}

class _ShiningIconState extends State<ShiningIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: ShinePainter(
                  progress: _controller.value,
                  gradient: widget.gradient,
                ),
                size: Size(widget.size, widget.size),
              );
            },
          ),
          Icon(
            widget.icon,
            size: widget.size * 0.6,
            color: widget.iconColor ?? Colors.white,
          ),
        ],
      ),
    );
  }
}

class ShinePainter extends CustomPainter {
  final double progress;
  final List<Color> gradient;

  ShinePainter({
    required this.progress,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angle = progress * 2 * math.pi;

    for (int i = 0; i < 4; i++) {
      final currentAngle = angle + (i * math.pi / 2);
      final startX = center.dx + (math.cos(currentAngle) * size.width * 0.3);
      final startY = center.dy + (math.sin(currentAngle) * size.height * 0.3);
      final endX = center.dx + (math.cos(currentAngle) * size.width * 0.6);
      final endY = center.dy + (math.sin(currentAngle) * size.height * 0.6);

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            gradient.first.withOpacity(0),
            gradient.first.withOpacity(0.3),
            gradient.last.withOpacity(0),
          ],
        ).createShader(Rect.fromPoints(
          Offset(startX, startY),
          Offset(endX, endY),
        ))
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(ShinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class CompilerShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final cutSize = 12.0;

    path.moveTo(cutSize, 0);
    path.lineTo(w - cutSize, 0);
    path.lineTo(w, cutSize);
    path.lineTo(w, h - cutSize);
    path.lineTo(w - cutSize, h);
    path.lineTo(cutSize, h);
    path.lineTo(0, h - cutSize);
    path.lineTo(0, cutSize);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Painter for border of compiler shape
class CompilerShapeBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final w = size.width;
    final h = size.height;
    final cutSize = 12.0;

    final path = Path();
    path.moveTo(cutSize, 0);
    path.lineTo(w - cutSize, 0);
    path.lineTo(w, cutSize);
    path.lineTo(w, h - cutSize);
    path.lineTo(w - cutSize, h);
    path.lineTo(cutSize, h);
    path.lineTo(0, h - cutSize);
    path.lineTo(0, cutSize);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Glow painter for compiler shape
class CompilerShapeGlowPainter extends CustomPainter {
  final List<Color> gradient;

  CompilerShapeGlowPainter({required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cutSize = 15.0;

    final path = Path();
    path.moveTo(cutSize, 0);
    path.lineTo(w - cutSize, 0);
    path.lineTo(w, cutSize);
    path.lineTo(w, h - cutSize);
    path.lineTo(w - cutSize, h);
    path.lineTo(cutSize, h);
    path.lineTo(0, h - cutSize);
    path.lineTo(0, cutSize);
    path.close();

    final paint1 = Paint()
      ..color = gradient.first.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);

    final paint2 = Paint()
      ..color = gradient.last.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    canvas.drawPath(path, paint1);
    canvas.drawPath(path, paint2);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom painter for shimmer effect
class ShimmerPainter extends CustomPainter {
  final double progress;

  ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(
        Rect.fromLTWH(
          size.width * progress - size.width,
          0,
          size.width,
          size.height,
        ),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(ShimmerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fabController;

  int _selectedIndex = 0;

  static const double _navHeight = 70.0;
  static const double _navMarginBottom = 16.0;
  static const double _fabHeight = 60.0;
  static const double _fabMarginBetweenNav = 12.0;

  final List<TabConfig> _tabs = const [
    TabConfig(
      icon: Icons.code_rounded,
      activeIcon: Icons.code,
      label: 'ویرایشگر',
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
    ),
    TabConfig(
      icon: Icons.timeline_rounded,
      activeIcon: Icons.timeline,
      label: 'فازها',
      gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
    ),
    TabConfig(
      icon: Icons.terminal_rounded,
      activeIcon: Icons.terminal,
      label: 'خروجی',
      gradient: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    ),
    TabConfig(
      icon: Icons.school_rounded,
      activeIcon: Icons.school,
      label: 'آموزش',
      gradient: [Color(0xFF43e97b), Color(0xFF38f9d7)],
    ),
    TabConfig(
      icon: Icons.psychology_rounded,
      activeIcon: Icons.psychology,
      label: 'چت‌بات',
      gradient: [Color(0xFF667eea), Color(0xFFf093fb)],
    ),
    TabConfig(
      icon: Icons.library_books_rounded,
      activeIcon: Icons.library_books,
      label: 'نمونه‌ها',
      gradient: [Color(0xFFfa709a), Color(0xFFfee140)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  double get _contentBottomPadding {
    if (_selectedIndex == 0) {
      return _navHeight + _navMarginBottom + _fabHeight + _fabMarginBetweenNav + 8;
    } else {
      return _navHeight + _navMarginBottom + 8;
    }
  }

  double get _fabBottomMargin {
    return _navHeight + _navMarginBottom + _fabMarginBetweenNav;
  }

  void _onItemTapped(int index, {bool force = false}) {
    if (_selectedIndex == index && !force) return;

    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);

    if (index == 0) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);

    if (index == 0) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompilerProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          extendBody: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _buildModernAppBar(provider),
          body: _buildPageView(),
          bottomNavigationBar: _buildBottomNav(),
          floatingActionButton: _buildAdvancedFAB(provider),
          floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  PreferredSizeWidget _buildModernAppBar(CompilerProvider provider) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          Hero(
            tag: 'app_logo',
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ShiningIcon(
                icon: Icons.code,
                size: 32,
                gradient: [
                  Colors.white.withOpacity(0.8),
                  Colors.white.withOpacity(0.4),
                ],
                iconColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MiniLang Compiler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _tabs[_selectedIndex].label,
                    key: ValueKey(_selectedIndex),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'فعال/غیرفعال کردن بهینه‌سازی',
          icon: Icon(
            provider.isOptimizationEnabled
                ? Icons.speed_rounded
                : Icons.speed_outlined,
            color: provider.isOptimizationEnabled
                ? const Color(0xFFEC4899)
                : Colors.white.withOpacity(0.8),
          ),
          onPressed: () {
            provider.toggleOptimization();
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AnimatedStatusIndicator(),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          tooltip: 'منوی بیشتر',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          offset: const Offset(0, 50),
          onSelected: (value) {
            switch (value) {
              case 'settings':
                _showSettingsScreen();
                break;
              case 'about':
                _showAboutScreen();
                break;
              case 'help':
                _showHelpScreen();
                break;
            }
          },
          itemBuilder: (context) => [
            _buildMenuItem(Icons.settings_rounded, 'تنظیمات', 'settings'),
            _buildMenuItem(Icons.help_outline_rounded, 'راهنما', 'help'),
            _buildMenuItem(Icons.info_outline_rounded, 'درباره', 'about'),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      IconData icon, String text, String value) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return PageView(
      controller: _pageController,
      onPageChanged: _handlePageChanged,
      physics: const BouncingScrollPhysics(),
      children: [
        CodeEditorTab(bottomPadding: _contentBottomPadding),
        CompilationPhasesTab(bottomPadding: _contentBottomPadding),
        ConsoleOutputTab(bottomPadding: _contentBottomPadding),
        UnifiedLearningTab(bottomPadding: _contentBottomPadding),
        ChatbotTab(bottomPadding: _contentBottomPadding),
        ExampleCodeSelectorTab(
          bottomPadding: _contentBottomPadding,
          onExampleSelected: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _onItemTapped(0, force: true);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: _navMarginBottom,
      ),
      height: _navHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 3,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: List.generate(_tabs.length, (index) {
                    return Expanded(
                      child: _buildNavItem(index),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildNavItem(int index) {
    final isSelected = _selectedIndex == index;
    final tab = _tabs[index];

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                  colors: tab.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: tab.gradient.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
                    : null,
              ),
              child: Icon(
                isSelected ? tab.activeIcon : tab.icon,
                color:
                isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                isSelected ? Colors.white : Colors.white.withOpacity(0.6),
              ),
              child: Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFAB(CompilerProvider provider) {
    final currentTab = _tabs[_selectedIndex];

    return ScaleTransition(
      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fabController,
          curve: Curves.easeOutBack,
        ),
      ),
      child: Visibility(
        visible: _selectedIndex == 0,
        child: AdvancedCompileButton(
          onPressed: provider.isRunning
              ? null
              : () {
            HapticFeedback.mediumImpact();
            provider.compile();
          },
          isRunning: provider.isRunning,
          gradient: currentTab.gradient,
        ),
      ),
    );
  }

  void _showSettingsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _showAboutScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AboutScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _showHelpScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HelpScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}

class AdvancedCompileButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isRunning;
  final List<Color> gradient;

  const AdvancedCompileButton({
    super.key,
    required this.onPressed,
    required this.isRunning,
    required this.gradient,
  });

  @override
  State<AdvancedCompileButton> createState() => _AdvancedCompileButtonState();
}

class _AdvancedCompileButtonState extends State<AdvancedCompileButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.isRunning || widget.onPressed == null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!isDisabled) widget.onPressed!();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: Listenable.merge(
            [_pulseAnimation, _shimmerAnimation, _waveController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? 0.95 : 1.0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!isDisabled)
                  Transform.scale(
                    scale: _pulseAnimation.value,
                    child: CustomPaint(
                      size: const Size(190, 65),
                      painter: CompilerShapeGlowPainter(
                        gradient: widget.gradient,
                      ),
                    ),
                  ),
                ClipPath(
                  clipper: CompilerShapeClipper(),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 190,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDisabled
                              ? [
                            Colors.grey.withOpacity(0.3),
                            Colors.grey.withOpacity(0.2),
                          ]
                              : [
                            widget.gradient.first.withOpacity(0.85),
                            widget.gradient.last.withOpacity(0.75),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: CompilerShapeBorderPainter(),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (!isDisabled)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: ShimmerPainter(
                                    progress: _shimmerAnimation.value,
                                  ),
                                ),
                              ),
                            if (!isDisabled) ...[
                              Positioned(
                                left: 15,
                                child: Opacity(
                                  opacity: 0.3,
                                  child: const Text(
                                    '{',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 10,
                                child: Opacity(
                                  opacity: 0.3,
                                  child: const Text(
                                    '}',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (!isDisabled)
                              ...List.generate(4, (index) {
                                final offset = index * 0.25;
                                return Positioned(
                                  left: 30.0 + (index * 35.0),
                                  bottom: 8,
                                  child: Transform.translate(
                                    offset: Offset(
                                      math.sin((_waveController.value +
                                          offset) *
                                          2 *
                                          math.pi) *
                                          2,
                                      -(_waveController.value * 8 +
                                          (index % 2) * 4),
                                    ),
                                    child: Opacity(
                                      opacity:
                                      (1 - _waveController.value) * 0.4,
                                      child: Text(
                                        index % 2 == 0 ? '0' : '1',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: widget.isRunning
                                      ? Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                          AlwaysStoppedAnimation<
                                              Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.settings,
                                        size: 12,
                                        color: Colors.white
                                            .withOpacity(0.9),
                                      ),
                                    ],
                                  )
                                      : TweenAnimationBuilder<double>(
                                    tween: Tween(
                                        begin: 0,
                                        end: _isPressed ? 0.5 : 0),
                                    duration:
                                    const Duration(milliseconds: 200),
                                    builder: (context, value, child) {
                                      return Transform.rotate(
                                        angle: value,
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 28,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Color.fromRGBO(
                                                  0, 0, 0, 0.4),
                                              offset: Offset(0, 2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  widget.isRunning
                                      ? 'در حال اجرا...'
                                      : 'کامپایل و اجرا',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.3),
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                if (!widget.isRunning) ...[
                                  const SizedBox(width: 6),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(
                                        begin: 0, end: _isPressed ? 0.3 : 0),
                                    duration:
                                    const Duration(milliseconds: 200),
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(value * 10, 0),
                                        child: Icon(
                                          Icons.double_arrow_rounded,
                                          size: 18,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
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
      ),
    );
  }
}

class TabConfig {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final List<Color> gradient;

  const TabConfig({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.gradient,
  });
}

abstract class KeepAliveTab extends StatefulWidget {
  final double bottomPadding;
  const KeepAliveTab({super.key, required this.bottomPadding});
}

abstract class KeepAliveTabState<T extends KeepAliveTab> extends State<T>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildTab(context);
  }

  Widget buildTab(BuildContext context);
}

class CodeEditorTab extends KeepAliveTab {
  const CodeEditorTab({super.key, required super.bottomPadding});

  @override
  State<CodeEditorTab> createState() => _CodeEditorTabState();
}

class _CodeEditorTabState extends KeepAliveTabState<CodeEditorTab> {
  @override
  Widget buildTab(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16.0, right: 16.0, top: 16.0, bottom: widget.bottomPadding),
      child: const CodeEditor(),
    );
  }
}

class CompilationPhasesTab extends KeepAliveTab {
  const CompilationPhasesTab({super.key, required super.bottomPadding});

  @override
  State<CompilationPhasesTab> createState() => _CompilationPhasesTabState();
}

class _CompilationPhasesTabState
    extends KeepAliveTabState<CompilationPhasesTab> {
  @override
  Widget buildTab(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16.0, right: 16.0, top: 16.0, bottom: widget.bottomPadding),
      child: const CompilationPhases(),
    );
  }
}

class ConsoleOutputTab extends KeepAliveTab {
  const ConsoleOutputTab({super.key, required super.bottomPadding});

  @override
  State<ConsoleOutputTab> createState() => _ConsoleOutputTabState();
}

class _ConsoleOutputTabState extends KeepAliveTabState<ConsoleOutputTab> {
  @override
  Widget buildTab(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16.0, right: 16.0, top: 16.0, bottom: widget.bottomPadding),
      child: const ConsoleOutput(),
    );
  }
}

class UnifiedLearningTab extends KeepAliveTab {
  const UnifiedLearningTab({super.key, required super.bottomPadding});

  @override
  State<UnifiedLearningTab> createState() => _UnifiedLearningTabState();
}

class _UnifiedLearningTabState extends KeepAliveTabState<UnifiedLearningTab> {
  @override
  Widget buildTab(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
      child: const LearningTabContainer(),
    );
  }
}

class ChatbotTab extends KeepAliveTab {
  const ChatbotTab({super.key, required super.bottomPadding});

  @override
  State<ChatbotTab> createState() => _ChatbotTabState();
}

class _ChatbotTabState extends KeepAliveTabState<ChatbotTab> {
  @override
  Widget buildTab(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
      child: const ChatbotScreen(),
    );
  }
}

class ExampleCodeSelectorTab extends KeepAliveTab {
  final VoidCallback? onExampleSelected;
  const ExampleCodeSelectorTab(
      {super.key, required super.bottomPadding, this.onExampleSelected});

  @override
  State<ExampleCodeSelectorTab> createState() => _ExampleCodeSelectorTabState();
}

class _ExampleCodeSelectorTabState
    extends KeepAliveTabState<ExampleCodeSelectorTab> {
  @override
  Widget buildTab(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
          left: 16.0, right: 16.0, top: 16.0, bottom: widget.bottomPadding),
      child: ExampleCodeSelector(onExampleSelected: widget.onExampleSelected),
    );
  }
}
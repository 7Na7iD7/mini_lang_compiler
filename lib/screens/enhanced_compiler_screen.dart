import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/compiler_provider.dart';
import '../widgets/code_editor.dart';
import '../widgets/example_code_selector.dart';
import '../widgets/compilation_phases.dart';
import '../widgets/console_output.dart';
import 'compiler_ui_components.dart';

class EnhancedCompilerScreen extends StatefulWidget {
  const EnhancedCompilerScreen({super.key});

  @override
  State<EnhancedCompilerScreen> createState() => _EnhancedCompilerScreenState();
}

class _EnhancedCompilerScreenState extends State<EnhancedCompilerScreen>
    with TickerProviderStateMixin {

  late AnimationController _pageAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _layoutTransitionController;
  late Animation<double> _layoutAnimation;

  final GlobalKey _codeEditorKey = GlobalKey();
  final GlobalKey _compilationPhasesKey = GlobalKey();
  final GlobalKey _consoleOutputKey = GlobalKey();

  LayoutType _currentLayout = LayoutType.desktop;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startPageEntryAnimation();
  }

  void _initializeAnimations() {
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _layoutTransitionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _layoutAnimation = CurvedAnimation(
      parent: _layoutTransitionController,
      curve: Curves.easeInOutCubic,
    );
  }

  void _startPageEntryAnimation() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _pageAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    _layoutTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompilerProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: _buildEnhancedAppBar(provider),
          body: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildResponsiveLayout(context, provider),
                ),
              );
            },
          ),
          floatingActionButton: _buildFloatingActionMenu(provider),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  /// AppBar
  PreferredSizeWidget _buildEnhancedAppBar(CompilerProvider provider) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Hero(
            tag: 'compiler_logo',
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.developer_mode,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'MiniLang',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade600,
              Colors.purple.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      actions: [
        const AnimatedStatusIndicator(),
        const SizedBox(width: 16),
        AnimatedRunButton(
          isRunning: provider.isRunning,
          onPressed: () => _handleCompileAction(provider),
        ),
        const SizedBox(width: 16),
        _buildAdvancedOptionsMenu(provider),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAdvancedOptionsMenu(CompilerProvider provider) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.tune, color: Colors.white),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) => _handleMenuAction(value, provider),
      itemBuilder: (context) => [
        _buildMenuItemWithIcon(Icons.clear_all, 'پاک کردن همه', 'clear', !provider.isRunning),
        _buildMenuItemWithIcon(Icons.code_rounded, 'نمونه کدها', 'examples', !provider.isRunning),
        _buildMenuItemWithIcon(Icons.speed, 'تنظیمات سرعت', 'speed', true),
        _buildMenuItemWithIcon(Icons.palette, 'تغییر تم', 'theme', true),
        const PopupMenuDivider(),
        _buildMenuItemWithIcon(Icons.help_outline, 'راهنما', 'help', true),
        _buildMenuItemWithIcon(Icons.info_outline, 'درباره', 'about', true),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItemWithIcon(
      IconData icon,
      String title,
      String value,
      bool enabled
      ) {
    return PopupMenuItem(
      value: value,
      enabled: enabled,
      child: Row(
        children: [
          Icon(icon, size: 20, color: enabled ? Colors.grey.shade700 : Colors.grey.shade400),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: enabled ? Colors.grey.shade700 : Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context, CompilerProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final newLayout = _determineLayout(constraints.maxWidth);

        if (newLayout != _currentLayout) {
          _currentLayout = newLayout;
          _layoutTransitionController.forward(from: 0);
        }

        return AnimatedBuilder(
          animation: _layoutAnimation,
          builder: (context, child) {
            switch (_currentLayout) {
              case LayoutType.desktop:
                return _buildDesktopLayout(context, provider);
              case LayoutType.tablet:
                return _buildTabletLayout(context, provider);
              case LayoutType.mobile:
                return _buildMobileLayout(context, provider);
            }
          },
        );
      },
    );
  }

  LayoutType _determineLayout(double width) {
    if (width > 1200) return LayoutType.desktop;
    if (width > 800) return LayoutType.tablet;
    return LayoutType.mobile;
  }

  Widget _buildDesktopLayout(BuildContext context, CompilerProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade50,
            Colors.blue.shade50.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  _buildCompactExampleSelector(provider),
                  const SizedBox(height: 16),
                  Expanded(
                    child: AnimatedInfoCard(
                      title: 'ویرایشگر کد',
                      icon: Icons.code_rounded,
                      color: Colors.blue.shade600,
                      child: CodeEditor(key: _codeEditorKey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: AnimatedInfoCard(
                      title: 'مراحل کامپایل',
                      icon: Icons.timeline_rounded,
                      color: Colors.purple.shade600,
                      child: CompilationPhases(key: _compilationPhasesKey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 2,
                    child: AnimatedInfoCard(
                      title: 'خروجی کنسول',
                      icon: Icons.terminal_rounded,
                      color: Colors.green.shade600,
                      child: ConsoleOutput(key: _consoleOutputKey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, CompilerProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade50,
            Colors.blue.shade50.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCompactExampleSelector(provider),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AnimatedInfoCard(
                      title: 'ویرایشگر کد',
                      icon: Icons.code_rounded,
                      color: Colors.blue.shade600,
                      child: CodeEditor(key: _codeEditorKey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child: AnimatedInfoCard(
                            title: 'مراحل کامپایل',
                            icon: Icons.timeline_rounded,
                            color: Colors.purple.shade600,
                            child: CompilationPhases(key: _compilationPhasesKey),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          flex: 2,
                          child: AnimatedInfoCard(
                            title: 'خروجی',
                            icon: Icons.terminal_rounded,
                            color: Colors.green.shade600,
                            child: ConsoleOutput(key: _consoleOutputKey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, CompilerProvider provider) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              labelColor: Colors.blue.shade700,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.blue.shade700,
              indicatorWeight: 3.0,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(icon: Icon(Icons.code_rounded), text: 'کد'),
                Tab(icon: Icon(Icons.timeline_rounded), text: 'مراحل'),
                Tab(icon: Icon(Icons.terminal_rounded), text: 'خروجی'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      _buildCompactExampleSelector(provider),
                      const SizedBox(height: 12),
                      Expanded(
                        child: AnimatedInfoCard(
                          title: 'ویرایشگر کد',
                          icon: Icons.code_rounded,
                          color: Colors.blue.shade600,
                          child: CodeEditor(key: _codeEditorKey),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: AnimatedInfoCard(
                    title: 'مراحل کامپایل',
                    icon: Icons.timeline_rounded,
                    color: Colors.purple.shade600,
                    child: SingleChildScrollView(
                      child: CompilationPhases(key: _compilationPhasesKey),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: AnimatedInfoCard(
                    title: 'خروجی کنسول',
                    icon: Icons.terminal_rounded,
                    color: Colors.green.shade600,
                    child: SingleChildScrollView(
                      child: ConsoleOutput(key: _consoleOutputKey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactExampleSelector(CompilerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.library_books_rounded, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'نمونه کدها',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCompactButton(
                icon: Icons.waving_hand_rounded,
                label: 'سلام',
                color: Colors.blue,
                onTap: () => _loadExample('hello', provider),
              ),
              _buildCompactButton(
                icon: Icons.calculate_rounded,
                label: 'حسابی',
                color: Colors.green,
                onTap: () => _loadExample('arithmetic', provider),
              ),
              _buildCompactButton(
                icon: Icons.alt_route_rounded,
                label: 'شرطی',
                color: Colors.orange,
                onTap: () => _loadExample('conditional', provider),
              ),
              _buildCompactButton(
                icon: Icons.loop_rounded,
                label: 'حلقه',
                color: Colors.purple,
                onTap: () => _loadExample('loop', provider),
              ),
              _buildCompactButton(
                icon: Icons.functions_rounded,
                label: 'پیچیده',
                color: Colors.red,
                onTap: () => _loadExample('complex', provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButton({
    required IconData icon,
    required String label,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color.shade700),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadExample(String exampleKey, CompilerProvider provider) {
    provider.loadExampleCode(exampleKey);
    final exampleNames = {
      'hello': 'سلام دنیا',
      'arithmetic': 'عملیات حسابی',
      'conditional': 'دستور شرطی',
      'loop': 'حلقه',
      'complex': 'فاکتوریل',
    };
    _showEnhancedSnackBar(
      'نمونه "${exampleNames[exampleKey]}" بارگذاری شد',
      Colors.blue.shade600,
      Icons.check_circle_rounded,
    );
  }

  Widget _buildFloatingActionMenu(CompilerProvider provider) {
    if (_currentLayout == LayoutType.mobile) {
      return const SizedBox.shrink();
    }
    return Consumer<CompilerProvider>(
      builder: (context, provider, child) {
        return MouseRegion(
          cursor: provider.isRunning ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
          child: AnimatedScale(
            scale: provider.isRunning ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            child: FloatingActionButton.extended(
              onPressed: provider.isRunning ? null : () => _handleCompileAction(provider),
              backgroundColor: Colors.transparent,
              elevation: 0,
              highlightElevation: 0,
              hoverElevation: 0,
              focusElevation: 0,
              heroTag: 'compile_fab',
              label: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: provider.isRunning
                      ? LinearGradient(
                    colors: [Colors.grey.shade400, Colors.grey.shade500],
                  )
                      : LinearGradient(
                    colors: [
                      Colors.green.shade600,
                      Colors.green.shade700,
                      Colors.teal.shade600,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: provider.isRunning
                      ? []
                      : [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (provider.isRunning) ...[
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'در حال اجرا',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildAnimatedDots(),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'کامپایل و اجرا',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.rocket_launch_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedDots() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Row(
          children: List.generate(3, (index) {
            final delay = index * 0.33;
            final animValue = (value + delay) % 1.0;
            final opacity = animValue > 0.5 ? 1.0 : 0.3;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: opacity,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: opacity > 0.5 ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ] : [],
                  ),
                ),
              ),
            );
          }),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  void _handleCompileAction(CompilerProvider provider) {
    if (provider.sourceCode.trim().isEmpty) {
      _showEnhancedSnackBar(
        'لطفاً ابتدا کدی وارد کنید',
        Colors.orange.shade600,
        Icons.warning_rounded,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    provider.compile();

    _showEnhancedSnackBar(
      'کامپایل شروع شد...',
      Colors.blue.shade600,
      Icons.play_circle_outline_rounded,
    );
  }

  void _handleMenuAction(String action, CompilerProvider provider) {
    switch (action) {
      case 'clear':
        _showClearConfirmationDialog(provider);
        break;
      case 'examples':
        _showEnhancedExamplesDialog(provider);
        break;
      case 'speed':
        _showSpeedSettingsDialog();
        break;
      case 'theme':
        _showThemeDialog();
        break;
      case 'help':
        _showHelpDialog();
        break;
      case 'about':
        _showEnhancedAboutDialog();
        break;
    }
  }

  void _showEnhancedSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'بستن',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showClearConfirmationDialog(CompilerProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('پاک کردن همه'),
          ],
        ),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید همه کدها و نتایج را پاک کنید؟\n\nاین عمل قابل بازگشت نیست.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('انصراف', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clear();
              Navigator.pop(context);
              _showEnhancedSnackBar(
                'همه محتوا پاک شد',
                Colors.green.shade600,
                Icons.check_circle_rounded,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('پاک کن'),
          ),
        ],
      ),
    );
  }

  void _showEnhancedExamplesDialog(CompilerProvider provider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.library_books_rounded, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'انتخاب نمونه کد',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ..._buildExampleOptions(provider),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('بستن'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExampleOptions(CompilerProvider provider) {
    final examples = [
      ExampleInfo('hello', 'سلام دنیا', 'متغیر ساده و چاپ', Icons.waving_hand_rounded),
      ExampleInfo('arithmetic', 'عملیات حسابی', 'محاسبات ریاضی پایه', Icons.calculate_rounded),
      ExampleInfo('conditional', 'دستور شرطی', 'اجرای شرطی', Icons.alt_route_rounded),
      ExampleInfo('loop', 'حلقه', 'تکرار دستورات', Icons.loop_rounded),
      ExampleInfo('complex', 'فاکتوریل', 'محاسبه پیچیده', Icons.functions_rounded),
    ];

    return examples.map((example) => _buildExampleCard(example, provider)).toList();
  }

  Widget _buildExampleCard(ExampleInfo example, CompilerProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(example.icon, color: Colors.blue.shade700),
        ),
        title: Text(example.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(example.description),
        onTap: () {
          provider.loadExampleCode(example.key);
          Navigator.pop(context);
          _showEnhancedSnackBar(
            'نمونه "${example.title}" بارگذاری شد',
            Colors.blue.shade600,
            Icons.check_circle_rounded,
          );
        },
      ),
    );
  }

  void _showSpeedSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.speed_rounded),
            SizedBox(width: 8),
            Text('تنظیمات سرعت'),
          ],
        ),
        content: const Text('تنظیمات سرعت اجرا در نسخه‌های آینده اضافه خواهد شد.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('متوجه شدم'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.palette_rounded),
            SizedBox(width: 8),
            Text('تنظیمات تم'),
          ],
        ),
        content: const Text('تنظیمات تم در نسخه‌های آینده اضافه خواهد شد.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('متوجه شدم'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded),
            SizedBox(width: 8),
            Text('راهنما'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('نحوه استفاده:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• کد خود را در بخش ویرایشگر بنویسید'),
              Text('• دکمه "کامپایل و اجرا" را فشار دهید'),
              Text('• مراحل کامپایل را مشاهده کنید'),
              Text('• نتیجه را در بخش خروجی ببینید'),
              SizedBox(height: 16),
              Text('ویژگی‌ها:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• پشتیبانی از متغیرها'),
              Text('• عملیات حسابی'),
              Text('• دستورات شرطی'),
              Text('• حلقه‌ها'),
              Text('• نمونه کدهای آماده'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('متوجه شدم'),
          ),
        ],
      ),
    );
  }

  void _showEnhancedAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'about_logo',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.purple.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.developer_mode_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'MiniLang Compiler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'نسخه 2.0.0',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              const Text(
                'یک کامپایلر آموزشی کامل با رابط کاربری پیشرفته که تمام مراحل کامپایل را نمایش می‌دهد.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFeatureChip('تحلیل لغوی', Icons.text_fields_rounded),
                  _buildFeatureChip('تجزیه نحوی', Icons.account_tree_rounded),
                  _buildFeatureChip('تحلیل معنایی', Icons.analytics_rounded),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('عالی!', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.blue.shade700),
      label: Text(
        label,
        style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
      ),
      backgroundColor: Colors.blue.shade50,
    );
  }
}

enum LayoutType { desktop, tablet, mobile }

class ExampleInfo {
  final String key;
  final String title;
  final String description;
  final IconData icon;

  ExampleInfo(this.key, this.title, this.description, this.icon);
}
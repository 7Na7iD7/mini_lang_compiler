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
import 'dart:ui';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fabController;
  int _selectedIndex = 0;

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

    _pageController.addListener(_handlePageScroll);
  }

  void _handlePageScroll() {
    if (_pageController.page != null) {
      final offset = (_pageController.page! - _selectedIndex).abs();
      if (offset > 0.1) {
        _fabController.reverse();
      } else {
        _fabController.forward();
      }
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageScroll);
    _pageController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index, {bool force = false}) {
    if (_selectedIndex == index && !force) return;

    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompilerProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          extendBody: true,
          appBar: _buildModernAppBar(provider),
          body: _buildPageView(),
          bottomNavigationBar: _buildModernBottomNav(),
          floatingActionButton: _buildSmartFAB(provider),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.code, size: 24),
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

  PopupMenuItem<String> _buildMenuItem(IconData icon, String text, String value) {
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
      onPageChanged: (index) {
        HapticFeedback.selectionClick();
        setState(() => _selectedIndex = index);
      },
      physics: const BouncingScrollPhysics(),
      children: [
        const CodeEditorTab(),
        const CompilationPhasesTab(),
        const ConsoleOutputTab(),
        const UnifiedLearningTab(),
        ExampleCodeSelectorTab(
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

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.15),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_tabs.length, (index) {
                    return _buildNavItem(index);
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

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(8),
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
                      color: tab.gradient.first.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                      : null,
                ),
                child: Icon(
                  isSelected ? tab.activeIcon : tab.icon,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? tab.gradient.first : Colors.grey.shade600,
                ),
                child: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartFAB(CompilerProvider provider) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fabController,
          curve: Curves.easeOutBack,
        ),
      ),
      child: Visibility(
        visible: _selectedIndex == 0,
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: provider.isRunning
                    ? Colors.grey.withOpacity(0.25)
                    : Colors.blue.withOpacity(0.35),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: provider.isRunning
                ? null
                : () {
              HapticFeedback.mediumImpact();
              provider.compile();
            },
            elevation: 0,
            backgroundColor: provider.isRunning ? Colors.grey[400] : Colors.blue[600],
            icon: provider.isRunning
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(Icons.play_arrow_rounded, size: 26),
            label: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: Text(
                provider.isRunning ? 'در حال اجرا...' : 'کامپایل و اجرا',
                key: ValueKey(provider.isRunning),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // *** تغییر: نمایش فول‌اسکرین به جای Dialog ***
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

class CodeEditorTab extends StatefulWidget {
  const CodeEditorTab({super.key});

  @override
  State<CodeEditorTab> createState() => _CodeEditorTabState();
}

class _CodeEditorTabState extends State<CodeEditorTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: CodeEditor(),
    );
  }
}

class CompilationPhasesTab extends StatefulWidget {
  const CompilationPhasesTab({super.key});

  @override
  State<CompilationPhasesTab> createState() => _CompilationPhasesTabState();
}

class _CompilationPhasesTabState extends State<CompilationPhasesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: CompilationPhases(),
    );
  }
}

class ConsoleOutputTab extends StatefulWidget {
  const ConsoleOutputTab({super.key});

  @override
  State<ConsoleOutputTab> createState() => _ConsoleOutputTabState();
}

class _ConsoleOutputTabState extends State<ConsoleOutputTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: ConsoleOutput(),
    );
  }
}

class UnifiedLearningTab extends StatefulWidget {
  const UnifiedLearningTab({super.key});

  @override
  State<UnifiedLearningTab> createState() => _UnifiedLearningTabState();
}

class _UnifiedLearningTabState extends State<UnifiedLearningTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const LearningTabContainer();
  }
}

class ExampleCodeSelectorTab extends StatefulWidget {
  final VoidCallback? onExampleSelected;
  const ExampleCodeSelectorTab({super.key, this.onExampleSelected});

  @override
  State<ExampleCodeSelectorTab> createState() => _ExampleCodeSelectorTabState();
}

class _ExampleCodeSelectorTabState extends State<ExampleCodeSelectorTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: ExampleCodeSelector(onExampleSelected: widget.onExampleSelected),
    );
  }
}
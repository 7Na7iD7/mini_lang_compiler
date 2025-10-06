import 'package:flutter/material.dart';
import 'learning_screen.dart';
import 'learning_screen_advanced.dart';
import 'learning_screen_pro.dart';

class LearningTabContainer extends StatefulWidget {
  const LearningTabContainer({super.key});

  @override
  State<LearningTabContainer> createState() => _LearningTabContainerState();
}

class _LearningTabContainerState extends State<LearningTabContainer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  final List<TabData> _tabs = [
    TabData(
      title: 'پایه',
      subtitle: 'شروع سفر یادگیری',
      icon: Icons.rocket_launch_rounded,
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
    ),
    TabData(
      title: 'پیشرفته',
      subtitle: 'گام بعدی شما',
      icon: Icons.auto_awesome_rounded,
      gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
    ),
    TabData(
      title: 'حرفه‌ای',
      subtitle: 'تسلط کامل',
      icon: Icons.military_tech_rounded,
      gradient: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Header section , Glassmorphism
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.02),
              ]
                  : [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _tabs[_currentIndex].gradient[0].withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Animated header
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildHeaderInfo(_tabs[_currentIndex]),
              ),

              const SizedBox(height: 16),

              // Custom Tab Selector
              _buildCustomTabBar(),

              const SizedBox(height: 4),
            ],
          ),
        ),

        // Progress indicator
        _buildProgressIndicator(),

        const SizedBox(height: 8),

        Expanded(
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
    );
  }

  Widget _buildHeaderInfo(TabData tab) {
    return Container(
      key: ValueKey(tab.title),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: tab.gradient,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: tab.gradient[0].withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              tab.icon,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tab.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: tab.gradient,
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tab.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _currentIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                _tabController.animateTo(index);
                setState(() => _currentIndex = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                    colors: _tabs[index].gradient,
                  )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.grey.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: isSelected ? 14 : 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                    child: Text(_tabs[index].title),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 3,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: (constraints.maxWidth / 3) * _currentIndex,
                child: Container(
                  width: constraints.maxWidth / 3,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _tabs[_currentIndex].gradient,
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: _tabs[_currentIndex].gradient[0].withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
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
  final IconData icon;
  final List<Color> gradient;

  TabData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}
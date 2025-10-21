import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'dart:math' as math;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
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
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (!settings.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isDark = settings.darkMode;
        final size = MediaQuery.of(context).size;
        final theme = Theme.of(context);

        return Scaffold(
          body: Stack(
            children: [
              _buildAnimatedBackground(context, isDark, size),
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildModernAppBar(context, theme, isDark, settings),
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
                                    _buildAppearanceSection(context, settings),
                                    const SizedBox(height: 20),
                                    _buildEditorSection(context, settings),
                                    const SizedBox(height: 20),
                                    _buildGeneralSection(context, settings),
                                    const SizedBox(height: 32),
                                    _buildInfoCard(context, settings),
                                    const SizedBox(height: 24),
                                    _buildActionButtons(context, settings),
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
      },
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

  Widget _buildModernAppBar(
      BuildContext context, ThemeData theme, bool isDark, SettingsProvider settings) {
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
      actions: [
        if (settings.hasChangedFromDefaults())
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showResetDialog(context, settings),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.4),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.orange,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
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
                    'تنظیمات',
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
                      Icons.settings_rounded,
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

  Widget _buildAppearanceSection(BuildContext context, SettingsProvider settings) {
    return _buildSettingsSection(
      context,
      icon: Icons.palette_rounded,
      iconColor: Colors.purple,
      title: 'ظاهر و تم',
      delay: 0,
      children: [
        _buildSwitchTile(
          context,
          icon: Icons.dark_mode_rounded,
          title: 'حالت تاریک',
          subtitle: 'فعال‌سازی تم تاریک برای کاهش فشار چشم',
          value: settings.darkMode,
          onChanged: (val) => settings.setDarkMode(val),
          activeColor: Colors.purple,
          isDark: settings.darkMode,
        ),
        const SizedBox(height: 12),
        _buildDropdownTile(
          context,
          icon: Icons.color_lens_rounded,
          title: 'تم ویرایشگر',
          subtitle: 'انتخاب رنگ‌بندی کد',
          value: settings.editorTheme,
          items: const ['default', 'monokai', 'dracula', 'solarized'],
          itemLabels: const ['پیش‌فرض', 'Monokai', 'Dracula', 'Solarized'],
          onChanged: (val) => settings.setEditorTheme(val!),
          activeColor: Colors.purple,
          isDark: settings.darkMode,
        ),
        const SizedBox(height: 12),
        _buildDropdownTile(
          context,
          icon: Icons.language_rounded,
          title: 'زبان برنامه',
          subtitle: 'تغییر زبان رابط کاربری',
          value: settings.language,
          items: const ['fa', 'en'],
          itemLabels: const ['فارسی', 'English'],
          onChanged: (val) => settings.setLanguage(val!),
          activeColor: Colors.purple,
          isDark: settings.darkMode,
        ),
      ],
    );
  }

  Widget _buildEditorSection(BuildContext context, SettingsProvider settings) {
    return _buildSettingsSection(
      context,
      icon: Icons.code_rounded,
      iconColor: Colors.orange,
      title: 'ویرایشگر کد',
      delay: 200,
      children: [
        _buildSwitchTile(
          context,
          icon: Icons.format_line_spacing_rounded,
          title: 'نمایش شماره خطوط',
          subtitle: 'نمایش شماره در کنار هر خط از کد',
          value: settings.showLineNumbers,
          onChanged: (val) => settings.setShowLineNumbers(val),
          activeColor: Colors.orange,
          isDark: settings.darkMode,
        ),
        const SizedBox(height: 12),
        _buildSwitchTile(
          context,
          icon: Icons.highlight_rounded,
          title: 'برجسته‌سازی نحوی',
          subtitle: 'رنگ‌آمیزی خودکار بخش‌های مختلف کد',
          value: settings.syntaxHighlight,
          onChanged: (val) => settings.setSyntaxHighlight(val),
          activeColor: Colors.orange,
          isDark: settings.darkMode,
        ),
        const SizedBox(height: 12),
        _buildSwitchTile(
          context,
          icon: Icons.auto_fix_high_rounded,
          title: 'تکمیل خودکار',
          subtitle: 'پیشنهاد خودکار کدها هنگام تایپ',
          value: settings.autoComplete,
          onChanged: (val) => settings.setAutoComplete(val),
          activeColor: Colors.orange,
          isDark: settings.darkMode,
        ),
        const SizedBox(height: 12),
        _buildSliderTile(
          context,
          icon: Icons.format_size_rounded,
          title: 'اندازه فونت',
          subtitle: '${settings.fontSize.toInt()} پیکسل',
          value: settings.fontSize,
          min: SettingsProvider.minFontSize,
          max: SettingsProvider.maxFontSize,
          divisions: 14,
          onChanged: (val) => settings.setFontSize(val),
          activeColor: Colors.orange,
          isDark: settings.darkMode,
        ),
      ],
    );
  }

  Widget _buildGeneralSection(BuildContext context, SettingsProvider settings) {
    return _buildSettingsSection(
      context,
      icon: Icons.tune_rounded,
      iconColor: Colors.green,
      title: 'تنظیمات عمومی',
      delay: 400,
      children: [
        _buildSwitchTile(
          context,
          icon: Icons.save_rounded,
          title: 'ذخیره خودکار',
          subtitle: 'ذخیره تغییرات به صورت خودکار بدون نیاز به کلیک',
          value: settings.autoSave,
          onChanged: (val) => settings.setAutoSave(val),
          activeColor: Colors.green,
          isDark: settings.darkMode,
        ),
        const SizedBox(height: 12),
        _buildSwitchTile(
          context,
          icon: Icons.notifications_rounded,
          title: 'اعلان‌ها',
          subtitle: 'نمایش پیام‌های سیستم و اعلان‌ها',
          value: settings.notifications,
          onChanged: (val) => settings.setNotifications(val),
          activeColor: Colors.green,
          isDark: settings.darkMode,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required List<Widget> children,
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
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwitchTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required bool value,
        required ValueChanged<bool> onChanged,
        required Color activeColor,
        required bool isDark,
      }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? activeColor.withOpacity(0.5)
              : (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          width: 2,
        ),
        boxShadow: value
            ? [
          BoxShadow(
            color: activeColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ]
            : [],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: activeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: activeColor, size: 22),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withOpacity(0.6)
                        : Colors.black.withOpacity(0.5),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required String value,
        required List<String> items,
        required List<String> itemLabels,
        required ValueChanged<String?> onChanged,
        required Color activeColor,
        required bool isDark,
      }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: activeColor, size: 22),
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
                    const SizedBox(height: 4),
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
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: activeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: activeColor.withOpacity(0.3),
              ),
            ),
            child: DropdownButton<String>(
              value: value,
              underline: const SizedBox(),
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              icon: Icon(Icons.arrow_drop_down, color: activeColor),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              items: List.generate(
                items.length,
                    (index) => DropdownMenuItem(
                  value: items[index],
                  child: Text(
                    itemLabels[index],
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required double value,
        required double min,
        required double max,
        required int divisions,
        required ValueChanged<double> onChanged,
        required Color activeColor,
        required bool isDark,
      }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: activeColor, size: 22),
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
                    const SizedBox(height: 4),
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
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: activeColor,
              inactiveTrackColor: activeColor.withOpacity(0.2),
              thumbColor: activeColor,
              overlayColor: activeColor.withOpacity(0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, SettingsProvider settings) {
    return AnimatedBuilder(
      animation: _floatingAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              0, math.sin(_floatingAnimationController.value * math.pi) * 6),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: settings.darkMode
                    ? [
                  Colors.blue.shade900.withOpacity(0.3),
                  Colors.blue.shade800.withOpacity(0.2)
                ]
                    : [Colors.blue.shade100, Colors.blue.shade50],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.1),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade600,
                              Colors.blue.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'تنظیمات شما ${settings.autoSave ? "به صورت خودکار" : "پس از کلیک دکمه ذخیره"} ذخیره می‌شود و در دفعات بعدی اعمال خواهد شد.',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: settings.darkMode
                          ? Colors.white.withOpacity(0.85)
                          : Colors.black87,
                      height: 1.5,
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

  Widget _buildActionButtons(BuildContext context, SettingsProvider settings) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _floatingAnimationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                    0,
                    math.sin(_floatingAnimationController.value * math.pi * 2) *
                        3),
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('انصراف'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    foregroundColor: settings.darkMode
                        ? Colors.grey.shade300
                        : Colors.grey.shade700,
                    side: BorderSide(
                      color: settings.darkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedBuilder(
            animation: _floatingAnimationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                    0,
                    math.sin(_floatingAnimationController.value * math.pi * 2 +
                        math.pi) *
                        3),
                child: ElevatedButton.icon(
                  onPressed: () => _saveAndExit(context, settings),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('ذخیره تغییرات'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: Colors.blue.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showResetDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor:
          settings.darkMode ? const Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.warning_rounded,
                    color: Colors.orange, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'بازنشانی تنظیمات',
                  style: TextStyle(
                    color: settings.darkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'آیا مطمئن هستید که می‌خواهید تمام تنظیمات را به حالت پیش‌فرض برگردانید؟',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              height: 1.6,
              fontSize: 15,
              color: settings.darkMode
                  ? Colors.grey.shade300
                  : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'انصراف',
                style: TextStyle(
                  color: settings.darkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _resetToDefaults(context, settings);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('بازنشانی'),
            ),
          ],
          actionsAlignment: MainAxisAlignment.start,
        ),
      ),
    );
  }

  void _resetToDefaults(
      BuildContext context, SettingsProvider settings) async {
    final success = await settings.resetToDefaults();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              success
                  ? 'تنظیمات به حالت پیش‌فرض بازگشت'
                  : 'خطا در بازنشانی تنظیمات',
            ),
          ],
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _saveAndExit(BuildContext context, SettingsProvider settings) async {
    if (!settings.autoSave) {
      final success = await settings.saveSettings();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                success
                    ? 'تنظیمات با موفقیت ذخیره شد'
                    : 'خطا در ذخیره تنظیمات',
              ),
            ],
          ),
          backgroundColor: success ? Colors.blue : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      if (success) {
        Navigator.of(context).pop(settings.exportSettings());
      }
    } else {
      Navigator.of(context).pop(settings.exportSettings());
    }
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: settings.darkMode
                    ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                    : [Colors.blue.shade50, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, settings),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildAppearanceSection(context, settings),
                      const SizedBox(height: 32),
                      _buildEditorSection(context, settings),
                      const SizedBox(height: 32),
                      _buildGeneralSection(context, settings),
                      const SizedBox(height: 32),
                      _buildInfoCard(context, settings),
                      const SizedBox(height: 24),
                      _buildActionButtons(context, settings),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, SettingsProvider settings) {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: settings.darkMode ? const Color(0xFF1E1E1E) : Colors.blue.shade700,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'تنظیمات',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: settings.darkMode
                  ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
                  : [Colors.blue.shade800, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
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
                  );
                },
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (settings.hasChangedFromDefaults())
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'بازنشانی',
            onPressed: () => _showResetDialog(context, settings),
          ),
      ],
    );
  }

  Widget _buildAppearanceSection(BuildContext context, SettingsProvider settings) {
    return Column(
      children: [
        _buildSectionHeader(
          context,
          icon: Icons.palette_rounded,
          title: 'ظاهر و تم',
          color: Colors.purple,
          isDark: settings.darkMode,
        ),
        const SizedBox(height: 16),
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
    return Column(
      children: [
        _buildSectionHeader(
          context,
          icon: Icons.code_rounded,
          title: 'ویرایشگر کد',
          color: Colors.orange,
          isDark: settings.darkMode,
        ),
        const SizedBox(height: 16),
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
    return Column(
      children: [
        _buildSectionHeader(
          context,
          icon: Icons.tune_rounded,
          title: 'تنظیمات عمومی',
          color: Colors.green,
          isDark: settings.darkMode,
        ),
        const SizedBox(height: 16),
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

  Widget _buildSectionHeader(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        required bool isDark,
      }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(isDark ? 0.2 : 0.1),
            color.withOpacity(isDark ? 0.1 : 0.05)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? activeColor.withOpacity(0.5)
              : (isDark ? Colors.grey.shade800 : Colors.grey.withOpacity(0.2)),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: value
                ? activeColor.withOpacity(0.15)
                : (isDark ? Colors.transparent : Colors.grey.withOpacity(0.05)),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: activeColor.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: activeColor, size: 24),
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
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                    height: 1.4,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.withOpacity(0.2),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: activeColor, size: 24),
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
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: activeColor.withOpacity(isDark ? 0.15 : 0.1),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.withOpacity(0.2),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: activeColor, size: 24),
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
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey[600],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: settings.darkMode
              ? [Colors.blue.shade900.withOpacity(0.3), Colors.blue.shade800.withOpacity(0.2)]
              : [Colors.blue.shade100, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: settings.darkMode ? Colors.blue.shade300 : Colors.blue.shade700,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'تنظیمات شما ${settings.autoSave ? "به صورت خودکار" : "پس از کلیک دکمه ذخیره"} ذخیره می‌شود و در دفعات بعدی اعمال خواهد شد.',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 14,
                color: settings.darkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, SettingsProvider settings) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            label: const Text('انصراف'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: settings.darkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              side: BorderSide(
                color: settings.darkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _saveAndExit(context, settings),
            icon: const Icon(Icons.check_rounded),
            label: const Text('ذخیره تغییرات'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
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
          backgroundColor: settings.darkMode ? const Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            textDirection: TextDirection.rtl,
            children: [
              const Icon(Icons.warning_rounded, color: Colors.orange),
              const SizedBox(width: 12),
              Text(
                'بازنشانی تنظیمات',
                style: TextStyle(
                  color: settings.darkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          content: Text(
            'آیا مطمئن هستید که می‌خواهید تمام تنظیمات را به حالت پیش‌فرض برگردانید؟',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              height: 1.5,
              color: settings.darkMode ? Colors.grey.shade300 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'انصراف',
                style: TextStyle(
                  color: settings.darkMode ? Colors.grey.shade400 : Colors.grey.shade700,
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
              ),
              child: const Text('بازنشانی'),
            ),
          ],
          actionsAlignment: MainAxisAlignment.start,
        ),
      ),
    );
  }

  void _resetToDefaults(BuildContext context, SettingsProvider settings) async {
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
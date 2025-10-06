import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // Settings values
  bool _darkMode = false;
  bool _autoSave = true;
  bool _showLineNumbers = true;
  bool _syntaxHighlight = true;
  bool _autoComplete = true;
  bool _notifications = true;
  double _fontSize = 14.0;
  String _editorTheme = 'default';
  String _language = 'fa';

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  bool _isLoading = false;

  // Getters
  bool get darkMode => _darkMode;
  bool get autoSave => _autoSave;
  bool get showLineNumbers => _showLineNumbers;
  bool get syntaxHighlight => _syntaxHighlight;
  bool get autoComplete => _autoComplete;
  bool get notifications => _notifications;
  double get fontSize => _fontSize;
  String get editorTheme => _editorTheme;
  String get language => _language;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;

  // Constants for validation
  static const double minFontSize = 10.0;
  static const double maxFontSize = 24.0;
  static const List<String> validThemes = ['default', 'monokai', 'dracula', 'solarized'];
  static const List<String> validLanguages = ['fa', 'en'];

  // Initialize and load settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      _prefs = await SharedPreferences.getInstance();
      await loadSettings();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing settings: $e');
      _isInitialized = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load settings from SharedPreferences
  Future<void> loadSettings() async {
    if (_prefs == null) return;

    try {
      _darkMode = _prefs!.getBool('darkMode') ?? false;
      _autoSave = _prefs!.getBool('autoSave') ?? true;
      _showLineNumbers = _prefs!.getBool('showLineNumbers') ?? true;
      _syntaxHighlight = _prefs!.getBool('syntaxHighlight') ?? true;
      _autoComplete = _prefs!.getBool('autoComplete') ?? true;
      _notifications = _prefs!.getBool('notifications') ?? true;

      // Validate fontSize
      final fontSize = _prefs!.getDouble('fontSize') ?? 14.0;
      _fontSize = fontSize.clamp(minFontSize, maxFontSize);

      // Validate theme
      final theme = _prefs!.getString('editorTheme') ?? 'default';
      _editorTheme = validThemes.contains(theme) ? theme : 'default';

      // Validate language
      final lang = _prefs!.getString('language') ?? 'fa';
      _language = validLanguages.contains(lang) ? lang : 'fa';

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  // Save all settings
  Future<bool> saveSettings() async {
    if (_prefs == null) return false;

    try {
      await Future.wait([
        _prefs!.setBool('darkMode', _darkMode),
        _prefs!.setBool('autoSave', _autoSave),
        _prefs!.setBool('showLineNumbers', _showLineNumbers),
        _prefs!.setBool('syntaxHighlight', _syntaxHighlight),
        _prefs!.setBool('autoComplete', _autoComplete),
        _prefs!.setBool('notifications', _notifications),
        _prefs!.setDouble('fontSize', _fontSize),
        _prefs!.setString('editorTheme', _editorTheme),
        _prefs!.setString('language', _language),
      ]);
      return true;
    } catch (e) {
      debugPrint('Error saving settings: $e');
      return false;
    }
  }

  // Individual setters with validation
  Future<void> setDarkMode(bool value) async {
    if (_darkMode == value) return;
    _darkMode = value;
    notifyListeners();
    if (_autoSave) await _prefs?.setBool('darkMode', value);
  }

  Future<void> setAutoSave(bool value) async {
    if (_autoSave == value) return;
    _autoSave = value;
    notifyListeners();
    await _prefs?.setBool('autoSave', value);
  }

  Future<void> setShowLineNumbers(bool value) async {
    if (_showLineNumbers == value) return;
    _showLineNumbers = value;
    notifyListeners();
    if (_autoSave) await _prefs?.setBool('showLineNumbers', value);
  }

  Future<void> setSyntaxHighlight(bool value) async {
    if (_syntaxHighlight == value) return;
    _syntaxHighlight = value;
    notifyListeners();
    if (_autoSave) await _prefs?.setBool('syntaxHighlight', value);
  }

  Future<void> setAutoComplete(bool value) async {
    if (_autoComplete == value) return;
    _autoComplete = value;
    notifyListeners();
    if (_autoSave) await _prefs?.setBool('autoComplete', value);
  }

  Future<void> setNotifications(bool value) async {
    if (_notifications == value) return;
    _notifications = value;
    notifyListeners();
    if (_autoSave) await _prefs?.setBool('notifications', value);
  }

  Future<void> setFontSize(double value) async {
    final clampedValue = value.clamp(minFontSize, maxFontSize);
    if ((_fontSize - clampedValue).abs() < 0.01) return;

    _fontSize = clampedValue;
    debugPrint('Font size changed to: $_fontSize');
    notifyListeners();

    if (_autoSave && _prefs != null) {
      await _prefs!.setDouble('fontSize', clampedValue);
      debugPrint('Font size saved: $clampedValue');
    }
  }

  Future<void> setEditorTheme(String value) async {
    if (!validThemes.contains(value) || _editorTheme == value) return;
    _editorTheme = value;
    notifyListeners();
    if (_autoSave) await _prefs?.setString('editorTheme', value);
  }

  Future<void> setLanguage(String value) async {
    if (!validLanguages.contains(value) || _language == value) return;
    _language = value;
    notifyListeners();
    if (_autoSave) await _prefs?.setString('language', value);
  }

  Future<void> updateSettings({
    bool? darkMode,
    bool? autoSave,
    bool? showLineNumbers,
    bool? syntaxHighlight,
    bool? autoComplete,
    bool? notifications,
    double? fontSize,
    String? editorTheme,
    String? language,
  }) async {
    bool hasChanged = false;

    if (darkMode != null && _darkMode != darkMode) {
      _darkMode = darkMode;
      hasChanged = true;
    }
    if (autoSave != null && _autoSave != autoSave) {
      _autoSave = autoSave;
      hasChanged = true;
    }
    if (showLineNumbers != null && _showLineNumbers != showLineNumbers) {
      _showLineNumbers = showLineNumbers;
      hasChanged = true;
    }
    if (syntaxHighlight != null && _syntaxHighlight != syntaxHighlight) {
      _syntaxHighlight = syntaxHighlight;
      hasChanged = true;
    }
    if (autoComplete != null && _autoComplete != autoComplete) {
      _autoComplete = autoComplete;
      hasChanged = true;
    }
    if (notifications != null && _notifications != notifications) {
      _notifications = notifications;
      hasChanged = true;
    }
    if (fontSize != null) {
      final clampedSize = fontSize.clamp(minFontSize, maxFontSize);
      if ((_fontSize - clampedSize).abs() >= 0.01) {
        _fontSize = clampedSize;
        hasChanged = true;
      }
    }
    if (editorTheme != null && validThemes.contains(editorTheme) && _editorTheme != editorTheme) {
      _editorTheme = editorTheme;
      hasChanged = true;
    }
    if (language != null && validLanguages.contains(language) && _language != language) {
      _language = language;
      hasChanged = true;
    }

    if (hasChanged) {
      notifyListeners();
      if (_autoSave) await saveSettings();
    }
  }

  Future<bool> resetToDefaults() async {
    _darkMode = false;
    _autoSave = true;
    _showLineNumbers = true;
    _syntaxHighlight = true;
    _autoComplete = true;
    _notifications = true;
    _fontSize = 14.0;
    _editorTheme = 'default';
    _language = 'fa';

    notifyListeners();
    return await saveSettings();
  }

  String getFormattedFontSize() {
    return '${_fontSize.round()} پیکسل';
  }

  double getFontSizePercentage() {
    return ((_fontSize - minFontSize) / (maxFontSize - minFontSize)) * 100;
  }

  ThemeData getThemeData() {
    if (_darkMode) {
      return ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
      );
    } else {
      return ThemeData.light().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
        ),
      );
    }
  }

  TextStyle getEditorTextStyle() {
    return TextStyle(
      fontSize: _fontSize,
      fontFamily: 'monospace',
      height: 1.5,
      color: _darkMode ? Colors.white : Colors.black,
    );
  }

  Map<String, Color> getEditorColorScheme() {
    switch (_editorTheme) {
      case 'monokai':
        return {
          'background': const Color(0xFF272822),
          'text': const Color(0xFFF8F8F2),
          'keyword': const Color(0xFFF92672),
          'string': const Color(0xFFE6DB74),
          'comment': const Color(0xFF75715E),
        };
      case 'dracula':
        return {
          'background': const Color(0xFF282A36),
          'text': const Color(0xFFF8F8F2),
          'keyword': const Color(0xFFFF79C6),
          'string': const Color(0xFFF1FA8C),
          'comment': const Color(0xFF6272A4),
        };
      case 'solarized':
        return {
          'background': const Color(0xFF002B36),
          'text': const Color(0xFF839496),
          'keyword': const Color(0xFF268BD2),
          'string': const Color(0xFF2AA198),
          'comment': const Color(0xFF586E75),
        };
      default:
        return {
          'background': Colors.white,
          'text': Colors.black,
          'keyword': Colors.blue,
          'string': Colors.green,
          'comment': Colors.grey,
        };
    }
  }

  // Export settings as Map
  Map<String, dynamic> exportSettings() {
    return {
      'darkMode': _darkMode,
      'autoSave': _autoSave,
      'showLineNumbers': _showLineNumbers,
      'syntaxHighlight': _syntaxHighlight,
      'autoComplete': _autoComplete,
      'notifications': _notifications,
      'fontSize': _fontSize,
      'editorTheme': _editorTheme,
      'language': _language,
    };
  }

  // Import settings from Map
  Future<bool> importSettings(Map<String, dynamic> settings) async {
    try {
      _darkMode = settings['darkMode'] ?? _darkMode;
      _autoSave = settings['autoSave'] ?? _autoSave;
      _showLineNumbers = settings['showLineNumbers'] ?? _showLineNumbers;
      _syntaxHighlight = settings['syntaxHighlight'] ?? _syntaxHighlight;
      _autoComplete = settings['autoComplete'] ?? _autoComplete;
      _notifications = settings['notifications'] ?? _notifications;

      final fontSize = settings['fontSize'];
      if (fontSize != null) {
        _fontSize = (fontSize is int ? fontSize.toDouble() : fontSize as double)
            .clamp(minFontSize, maxFontSize);
      }

      final theme = settings['editorTheme'] ?? _editorTheme;
      _editorTheme = validThemes.contains(theme) ? theme : _editorTheme;

      final lang = settings['language'] ?? _language;
      _language = validLanguages.contains(lang) ? lang : _language;

      notifyListeners();
      return await saveSettings();
    } catch (e) {
      debugPrint('Error importing settings: $e');
      return false;
    }
  }

  bool hasChangedFromDefaults() {
    return _darkMode != false ||
        _autoSave != true ||
        _showLineNumbers != true ||
        _syntaxHighlight != true ||
        _autoComplete != true ||
        _notifications != true ||
        (_fontSize - 14.0).abs() >= 0.01 ||
        _editorTheme != 'default' ||
        _language != 'fa';
  }
}
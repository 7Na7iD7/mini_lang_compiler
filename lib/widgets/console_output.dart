import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/compiler_provider.dart';

class ConsoleOutput extends StatefulWidget {
  const ConsoleOutput({super.key});

  @override
  State<ConsoleOutput> createState() => _ConsoleOutputState();
}

class _ConsoleOutputState extends State<ConsoleOutput>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _scrollController;
  late AnimationController _pulseController;
  late Animation<double> _blinkAnimation;
  late Animation<double> _pulseAnimation;

  final ScrollController _outputScrollController = ScrollController();
  bool _autoScroll = true;
  bool _isFullscreen = false;
  bool _wordWrap = true;
  bool _showLineNumbers = true;
  bool _isDarkTheme = true;
  double _fontSize = 11.0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<int> _searchMatches = [];
  int _currentMatchIndex = 0;

  // Theme configurations
  final Map<String, Color> _darkTheme = {
    'bg1': const Color(0xFF1a1a2e),
    'bg2': const Color(0xFF16213e),
    'text': Colors.greenAccent,
    'accent': Colors.cyanAccent,
  };

  final Map<String, Color> _lightTheme = {
    'bg1': const Color(0xFFf5f5f5),
    'bg2': const Color(0xFFe8e8e8),
    'text': const Color(0xFF2d3436),
    'accent': const Color(0xFF0984e3),
  };

  @override
  void initState() {
    super.initState();

    // Cursor blink animation
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);

    _blinkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // Scroll animation controller
    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Pulse animation for status indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listen to scroll position for auto-scroll toggle
    _outputScrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_outputScrollController.hasClients) {
      final isAtBottom = _outputScrollController.offset >=
          _outputScrollController.position.maxScrollExtent - 50;
      if (_autoScroll != isAtBottom) {
        setState(() => _autoScroll = isAtBottom);
      }
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _outputScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _outputScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_outputScrollController.hasClients) {
          _outputScrollController.animateTo(
            _outputScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _searchMatches.clear();
      _currentMatchIndex = 0;

      if (_searchQuery.isNotEmpty) {
        final provider = context.read<CompilerProvider>();
        final lines = provider.output.split('\n');
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].toLowerCase().contains(_searchQuery)) {
            _searchMatches.add(i);
          }
        }
      }
    });
  }

  void _navigateSearch(bool forward) {
    if (_searchMatches.isEmpty) return;

    setState(() {
      if (forward) {
        _currentMatchIndex = (_currentMatchIndex + 1) % _searchMatches.length;
      } else {
        _currentMatchIndex = (_currentMatchIndex - 1 + _searchMatches.length) %
            _searchMatches.length;
      }
    });

    // Scroll to matched line
    final lineHeight = 20.0;
    final targetOffset = _searchMatches[_currentMatchIndex] * lineHeight;
    _outputScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    HapticFeedback.selectionClick();
  }

  Color get _bgColor1 => _isDarkTheme ? _darkTheme['bg1']! : _lightTheme['bg1']!;
  Color get _bgColor2 => _isDarkTheme ? _darkTheme['bg2']! : _lightTheme['bg2']!;
  Color get _textColor =>
      _isDarkTheme ? _darkTheme['text']! : _lightTheme['text']!;
  Color get _accentColor =>
      _isDarkTheme ? _darkTheme['accent']! : _lightTheme['accent']!;

  @override
  Widget build(BuildContext context) {
    return Consumer<CompilerProvider>(
      builder: (context, provider, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return _isFullscreen
            ? _buildFullscreenConsole(provider)
            : _buildNormalConsole(provider);
      },
    );
  }

  Widget _buildNormalConsole(CompilerProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: constraints.maxHeight,
            maxWidth: constraints.maxWidth,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_bgColor1, _bgColor2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildConsoleHeader(provider),
              if (_isSearching) _buildSearchBar(),
              Expanded(
                child: _buildConsoleBody(provider),
              ),
              _buildConsoleFooter(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFullscreenConsole(CompilerProvider provider) {
    return Dialog.fullscreen(
      child: Container(
        color: _bgColor1,
        child: Column(
          children: [
            _buildConsoleHeader(provider, isFullscreen: true),
            if (_isSearching) _buildSearchBar(),
            Expanded(child: _buildConsoleBody(provider)),
            _buildConsoleFooter(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkTheme
            ? Colors.black.withOpacity(0.3)
            : Colors.white.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: _textColor.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: _textColor, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search in console...',
                hintStyle: TextStyle(
                  color: _textColor.withOpacity(0.5),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: _performSearch,
            ),
          ),
          if (_searchMatches.isNotEmpty) ...[
            Text(
              '${_currentMatchIndex + 1}/${_searchMatches.length}',
              style: TextStyle(
                color: _textColor.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              iconSize: 18,
              color: _textColor.withOpacity(0.7),
              onPressed: () => _navigateSearch(false),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              iconSize: 18,
              color: _textColor.withOpacity(0.7),
              onPressed: () => _navigateSearch(true),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 18,
            color: _textColor.withOpacity(0.7),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchQuery = '';
                _searchMatches.clear();
                _searchController.clear();
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleHeader(CompilerProvider provider,
      {bool isFullscreen = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2d3436).withOpacity(0.8),
            const Color(0xFF1e272e).withOpacity(0.8),
          ],
        ),
        borderRadius: isFullscreen
            ? null
            : const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Row(
            children: [
              _buildTrafficLight(Colors.red, onTap: isFullscreen ? null : () {
                setState(() => _isFullscreen = false);
              }),
              const SizedBox(width: 5),
              _buildTrafficLight(Colors.amber, onTap: () {
                _showSettingsMenu();
              }),
              const SizedBox(width: 5),
              _buildTrafficLight(Colors.green, onTap: () {
                setState(() => _isFullscreen = !_isFullscreen);
              }),
            ],
          ),
          const SizedBox(width: 10),
          // Console icon and title
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.terminal_rounded,
              size: 14,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Console Output',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          // Status indicator
          _buildStatusIndicator(provider),
          const SizedBox(width: 6),
          // Action buttons
          _buildActionButtons(provider, isFullscreen),
        ],
      ),
    );
  }

  Widget _buildTrafficLight(Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(0.8),
            width: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(CompilerProvider provider) {
    Color statusColor;
    String statusText;
    bool isAnimated = false;

    switch (provider.state) {
      case CompilerState.idle:
        statusColor = Colors.grey;
        statusText = 'Idle';
        break;
      case CompilerState.completed:
        statusColor = Colors.green;
        statusText = 'Done';
        break;
      case CompilerState.error:
        statusColor = Colors.red;
        statusText = 'Error';
        break;
      default:
        statusColor = Colors.blue;
        statusText = 'Running';
        isAnimated = true;
    }

    Widget statusDot = Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.5),
            blurRadius: 3,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );

    if (isAnimated) {
      statusDot = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _pulseAnimation.value,
            child: child,
          );
        },
        child: statusDot,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          statusDot,
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CompilerProvider provider, bool isFullscreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search button
        if (provider.output.isNotEmpty)
          _buildIconButton(
            icon: Icons.search,
            tooltip: 'Search',
            size: 14,
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              HapticFeedback.lightImpact();
            },
          ),
        const SizedBox(width: 3),
        // Auto-scroll toggle
        _buildIconButton(
          icon: _autoScroll ? Icons.arrow_downward : Icons.block_rounded,
          tooltip: _autoScroll ? 'Auto-scroll On' : 'Auto-scroll Off',
          color: _autoScroll ? Colors.greenAccent : Colors.grey,
          size: 14,
          onPressed: () {
            setState(() => _autoScroll = !_autoScroll);
            if (_autoScroll) _scrollToBottom();
            HapticFeedback.lightImpact();
          },
        ),
        const SizedBox(width: 3),
        // Copy button
        if (provider.output.isNotEmpty && provider.output != '(No output)')
          _buildIconButton(
            icon: Icons.content_copy_rounded,
            tooltip: 'Copy Output',
            size: 14,
            onPressed: () => _copyOutput(provider.output),
          ),
        const SizedBox(width: 3),
        // Export button
        if (provider.output.isNotEmpty)
          _buildIconButton(
            icon: Icons.download_rounded,
            tooltip: 'Export',
            size: 14,
            onPressed: () => _showExportMenu(provider),
          ),
        const SizedBox(width: 3),
        // Clear button
        _buildIconButton(
          icon: Icons.delete_sweep_rounded,
          tooltip: 'Clear Console',
          color: Colors.redAccent,
          size: 14,
          onPressed: provider.output.isEmpty
              ? null
              : () {
            HapticFeedback.mediumImpact();
            provider.clear();
            _showMessage('Console cleared', Icons.delete_sweep_rounded);
          },
        ),
        const SizedBox(width: 3),
        // Settings button
        _buildIconButton(
          icon: Icons.settings_rounded,
          tooltip: 'Settings',
          size: 14,
          onPressed: _showSettingsMenu,
        ),
        const SizedBox(width: 3),
        // Fullscreen toggle
        _buildIconButton(
          icon: isFullscreen
              ? Icons.fullscreen_exit_rounded
              : Icons.fullscreen_rounded,
          tooltip: isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
          size: 14,
          onPressed: () {
            setState(() => _isFullscreen = !_isFullscreen);
            HapticFeedback.lightImpact();
          },
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
    Color? color,
    double size = 14,
  }) {
    final isEnabled = onPressed != null;
    final buttonColor = color ?? Colors.white70;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isEnabled
                  ? buttonColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isEnabled
                    ? buttonColor.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Icon(
              icon,
              size: size,
              color: isEnabled ? buttonColor : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsoleBody(CompilerProvider provider) {
    if (provider.output.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: Scrollbar(
        controller: _outputScrollController,
        thumbVisibility: true,
        radius: const Radius.circular(6),
        thickness: 4,
        child: SingleChildScrollView(
          controller: _outputScrollController,
          padding: const EdgeInsets.only(right: 8),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOutputLines(provider),
              const SizedBox(height: 8),
              // Cursor
              if (provider.state == CompilerState.completed ||
                  provider.state == CompilerState.error)
                _buildCursor(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade700,
                        Colors.grey.shade800,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.terminal_rounded,
                    size: 30,
                    color: Colors.white38,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Console Ready',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Run your code to see the output',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          // Tips
          _buildTip(Icons.play_arrow, 'Press Run to execute'),
          const SizedBox(height: 8),
          _buildTip(Icons.search, 'Use search to find text'),
          const SizedBox(height: 8),
          _buildTip(Icons.content_copy, 'Copy output to clipboard'),
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildOutputLines(CompilerProvider provider) {
    final lines = provider.output.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines.length, (index) {
        final isMatch =
            _searchMatches.contains(index) && _searchQuery.isNotEmpty;
        final isCurrentMatch =
            isMatch && _currentMatchIndex < _searchMatches.length && _searchMatches[_currentMatchIndex] == index;
        return _buildOutputLine(lines[index], index, isMatch, isCurrentMatch);
      }),
    );
  }

  Widget _buildOutputLine(
      String line, int index, bool isMatch, bool isCurrentMatch) {
    Color lineColor = _textColor;
    FontWeight fontWeight = FontWeight.normal;
    IconData? prefixIcon;

    if (line.toLowerCase().contains('error')) {
      lineColor = Colors.redAccent;
      fontWeight = FontWeight.w600;
      prefixIcon = Icons.error_outline_rounded;
    } else if (line.toLowerCase().contains('warning')) {
      lineColor = Colors.orangeAccent;
      fontWeight = FontWeight.w600;
      prefixIcon = Icons.warning_amber_rounded;
    } else if (line.toLowerCase().contains('success')) {
      lineColor = Colors.lightGreenAccent;
      fontWeight = FontWeight.w600;
      prefixIcon = Icons.check_circle_outline_rounded;
    } else if (line.startsWith('>') || line.startsWith('')) {
      lineColor = _accentColor;
      fontWeight = FontWeight.w500;
    }

    Widget lineWidget = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line number
        if (_showLineNumbers)
          Container(
            width: 32,
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        // Prefix icon
        if (prefixIcon != null) ...[
          Icon(prefixIcon, size: 12, color: lineColor),
          const SizedBox(width: 4),
        ],
        // Line content
        Expanded(
          child: SelectableText(
            line,
            style: TextStyle(
              color: lineColor,
              fontFamily: 'monospace',
              fontSize: _fontSize,
              height: 1.4,
              fontWeight: fontWeight,
              backgroundColor: isMatch
                  ? (isCurrentMatch
                  ? Colors.orange.withOpacity(0.4)
                  : Colors.yellow.withOpacity(0.2))
                  : null,
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: _wordWrap ? lineWidget : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: lineWidget,
      ),
    );
  }

  Widget _buildCursor() {
    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, _) {
        return Row(
          children: [
            Text(
              '> ',
              style: TextStyle(
                color: _textColor.withOpacity(0.8),
                fontFamily: 'monospace',
                fontSize: _fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            Opacity(
              opacity: _blinkAnimation.value,
              child: Container(
                width: 6,
                height: 14,
                decoration: BoxDecoration(
                  color: _textColor,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConsoleFooter(CompilerProvider provider) {
    final lineCount =
    provider.output.isEmpty ? 0 : provider.output.split('\n').length;
    final charCount = provider.output.length;
    final wordCount = provider.output.isEmpty
        ? 0
        : provider.output.split(RegExp(r'\s+')).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1e272e).withOpacity(0.8),
            const Color(0xFF2d3436).withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildFooterInfo(
            icon: Icons.notes_rounded,
            label: 'Lines',
            value: lineCount.toString(),
          ),
          const SizedBox(width: 12),
          _buildFooterInfo(
            icon: Icons.text_fields_rounded,
            label: 'Chars',
            value: charCount.toString(),
          ),
          const SizedBox(width: 12),
          _buildFooterInfo(
            icon: Icons.space_bar_rounded,
            label: 'Words',
            value: wordCount.toString(),
          ),
          const Spacer(),
          // Theme indicator
          GestureDetector(
            onTap: () {
              setState(() => _isDarkTheme = !_isDarkTheme);
              HapticFeedback.lightImpact();
            },
            child: Icon(
              _isDarkTheme ? Icons.dark_mode : Icons.light_mode,
              size: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Terminal v2.0',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 9,
            color: _textColor,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  void _copyOutput(String output) {
    Clipboard.setData(ClipboardData(text: output));
    HapticFeedback.lightImpact();
    _showMessage('Output copied to clipboard', Icons.content_copy_rounded);
  }

  void _showMessage(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgColor1, _bgColor2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.settings, color: _textColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Console Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Settings options
              _buildSettingsTile(
                icon: Icons.wrap_text,
                title: 'Word Wrap',
                subtitle: 'Wrap long lines',
                value: _wordWrap,
                onChanged: (val) {
                  setState(() => _wordWrap = val);
                  HapticFeedback.selectionClick();
                },
              ),
              _buildSettingsTile(
                icon: Icons.format_list_numbered,
                title: 'Line Numbers',
                subtitle: 'Show line numbers',
                value: _showLineNumbers,
                onChanged: (val) {
                  setState(() => _showLineNumbers = val);
                  HapticFeedback.selectionClick();
                },
              ),
              _buildSettingsTile(
                icon: _isDarkTheme ? Icons.dark_mode : Icons.light_mode,
                title: 'Dark Theme',
                subtitle: 'Use dark color scheme',
                value: _isDarkTheme,
                onChanged: (val) {
                  setState(() => _isDarkTheme = val);
                  HapticFeedback.selectionClick();
                },
              ),
              // Font size slider
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.text_fields, color: _textColor, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Font Size: ${_fontSize.toInt()}px',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: _accentColor,
                        inactiveTrackColor: _accentColor.withOpacity(0.3),
                        thumbColor: _accentColor,
                        overlayColor: _accentColor.withOpacity(0.2),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _fontSize,
                        min: 9,
                        max: 16,
                        divisions: 7,
                        label: '${_fontSize.toInt()}px',
                        onChanged: (val) {
                          setState(() => _fontSize = val);
                          HapticFeedback.selectionClick();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: _textColor.withOpacity(0.8)),
      title: Text(
        title,
        style: TextStyle(
          color: _textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: _textColor.withOpacity(0.6),
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: _accentColor,
        activeTrackColor: _accentColor.withOpacity(0.5),
      ),
    );
  }

  void _showExportMenu(CompilerProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgColor1, _bgColor2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.download, color: _textColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Export Console Output',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Export options
              _buildExportOption(
                icon: Icons.text_snippet,
                title: 'Export as Text',
                subtitle: 'Plain text file (.txt)',
                onTap: () {
                  Navigator.pop(context);
                  _exportAsText(provider.output);
                },
              ),
              _buildExportOption(
                icon: Icons.code,
                title: 'Export as JSON',
                subtitle: 'Structured JSON file',
                onTap: () {
                  Navigator.pop(context);
                  _exportAsJson(provider.output);
                },
              ),
              _buildExportOption(
                icon: Icons.share,
                title: 'Share Output',
                subtitle: 'Share via system dialog',
                onTap: () {
                  Navigator.pop(context);
                  _shareOutput(provider.output);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _accentColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _accentColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: _textColor.withOpacity(0.6),
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: _textColor.withOpacity(0.5),
        size: 16,
      ),
      onTap: onTap,
    );
  }

  void _exportAsText(String output) {
    Clipboard.setData(ClipboardData(text: output));
    _showMessage('Output ready to save as .txt', Icons.text_snippet);
  }

  void _exportAsJson(String output) {
    final lines = output.split('\n');
    final jsonOutput = {
      'timestamp': DateTime.now().toIso8601String(),
      'lineCount': lines.length,
      'characterCount': output.length,
      'lines': lines,
    };
    Clipboard.setData(ClipboardData(text: jsonOutput.toString()));
    _showMessage('JSON output copied', Icons.code);
  }

  void _shareOutput(String output) {
    Clipboard.setData(ClipboardData(text: output));
    _showMessage('Output ready to share', Icons.share);
  }
}
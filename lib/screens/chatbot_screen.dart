import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../services/advanced_local_ai_chat_service.dart';
import '../services/offline_responses.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final AdvancedAIChatService _aiService = AdvancedAIChatService();

  bool _isLoading = false;
  bool _isTyping = false;
  late AnimationController _pulseController;
  late AnimationController _typingController;
  late AnimationController _shimmerController;
  bool _isConnected = true;

  double _lastConfidence = 0.0;
  String _lastProvider = '';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _addWelcomeMessage();
    _testConnection();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: OfflineResponses.welcome,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _testConnection() async {
    try {
      final connected = await _aiService.testConnection();
      setState(() {
        _isConnected = connected;
      });

      if (connected) {
        _showSnackBar('✅ موتور AI محلی آماده است!', Colors.green);
      }
    } catch (e) {
      setState(() {
        _isConnected = true;
      });
      _showSnackBar('✅ سیستم در حالت محلی فعال است', Colors.green);
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isLoading = true;
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final response = await _aiService.sendMessage(
        text,
        history: _messages.where((m) => !m.isError).toList(),
      );

      final botMessage = ChatMessage(
        text: response.text,
        isUser: false,
        timestamp: DateTime.now(),
        isError: !response.success,
      );

      setState(() {
        _messages.add(botMessage);
        _isLoading = false;
        _isTyping = false;
        _lastConfidence = response.confidence;
        _lastProvider = response.provider ?? 'Local AI';
      });

      if (response.provider != null) {
        final confidencePercent = (response.confidence * 100).toStringAsFixed(1);
        _showSnackBar(
          '🧠 ${response.provider} | اطمینان: $confidencePercent%',
          _getConfidenceColor(response.confidence),
        );
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: '❌ خطا در پردازش: $e\n\n💡 لطفاً دوباره تلاش کنید.',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.blue;
    if (confidence >= 0.4) return Colors.orange;
    return Colors.red;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => _buildGlassDialog(
        title: 'پاک کردن چت',
        icon: Icons.delete_sweep_rounded,
        iconColor: Colors.red,
        content: 'آیا مطمئن هستید که می‌خواهید تمام پیام‌ها را پاک کنید؟\n\n'
            '⚠️ تاریخچه یادگیری AI هم پاک خواهد شد.',
        actions: [
          _buildGlassButton(
            text: 'انصراف',
            onPressed: () => Navigator.pop(context),
            isPrimary: false,
          ),
          _buildGlassButton(
            text: 'پاک کردن',
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
                _aiService.reset();
                _lastConfidence = 0.0;
                _lastProvider = '';
              });
              Navigator.pop(context);
              _showSnackBar('✅ چت و حافظه AI پاک شد', Colors.green);
            },
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  void _showAIInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.4),
                          Colors.purple.withOpacity(0.3),
                          Colors.cyan.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue.withOpacity(0.6),
                                    Colors.purple.withOpacity(0.4),
                                  ],
                                  stops: [
                                    _shimmerController.value - 0.3,
                                    _shimmerController.value,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.4),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.psychology_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'اطلاعات موتور AI',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'سیستم هوش مصنوعی 4 لایه',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildAIStatCard(
                            icon: Icons.layers_rounded,
                            title: 'معماری سیستم',
                            subtitle: '4 لایه یکپارچه',
                            gradient: [Colors.purple, Colors.blue],
                          ),
                          const SizedBox(height: 12),
                          _buildAIStatCard(
                            icon: Icons.psychology_outlined,
                            title: 'موتور Casual Handler',
                            subtitle: '13+ Intent Detection',
                            gradient: [Colors.green, Colors.teal],
                          ),
                          const SizedBox(height: 12),
                          _buildAIStatCard(
                            icon: Icons.memory_rounded,
                            title: 'Base ML/NLP Engine',
                            subtitle: 'Word2Vec + Neural Net',
                            gradient: [Colors.orange, Colors.deepOrange],
                          ),
                          const SizedBox(height: 12),
                          _buildAIStatCard(
                            icon: Icons.auto_awesome_rounded,
                            title: 'Advanced Engine',
                            subtitle: 'Transformer + BERT',
                            gradient: [Colors.pink, Colors.purple],
                          ),
                          const SizedBox(height: 12),
                          _buildAIStatCard(
                            icon: Icons.hub_rounded,
                            title: 'Integration Bridge',
                            subtitle: 'Hybrid Analysis',
                            gradient: [Colors.cyan, Colors.blue],
                          ),
                          const SizedBox(height: 20),
                          // Features Grid
                          _buildFeaturesGrid(),
                          const SizedBox(height: 20),
                          // Stats
                          if (_lastConfidence > 0) _buildStatsRow(),
                        ],
                      ),
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.05),
                          Colors.white.withOpacity(0.02),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGlassButton(
                          text: 'بستن',
                          onPressed: () => Navigator.pop(context),
                          isPrimary: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradient[0].withOpacity(0.2),
                gradient[1].withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient.map((c) => c.withOpacity(0.6)).toList(),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                color: gradient[0],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    final features = [
      {'icon': '🎯', 'text': 'Intent Detection', 'color': Colors.purple},
      {'icon': '🔍', 'text': 'Semantic Analysis', 'color': Colors.blue},
      {'icon': '🧩', 'text': 'Context Aware', 'color': Colors.green},
      {'icon': '🔤', 'text': 'NLP Engine', 'color': Colors.orange},
      {'icon': '🎓', 'text': 'Deep Learning', 'color': Colors.pink},
      {'icon': '⚡', 'text': 'High Speed', 'color': Colors.cyan},
      {'icon': '🧠', 'text': 'Neural Net', 'color': Colors.indigo},
      {'icon': '📊', 'text': 'Analytics', 'color': Colors.teal},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'قابلیت‌های فعال',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: features.map((feature) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (feature['color'] as Color).withOpacity(0.3),
                        (feature['color'] as Color).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        feature['icon'] as String,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        feature['text'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'آمار جلسه فعلی',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildStatBox(
                icon: Icons.speed_rounded,
                title: 'اطمینان',
                value: '${(_lastConfidence * 100).toInt()}%',
                color: _getConfidenceColor(_lastConfidence),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                icon: Icons.chat_rounded,
                title: 'پیام‌ها',
                value: '${_messages.length}',
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.3),
                color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuggestionsDialog() {
    final suggestions = OfflineResponses.suggestedQuestions;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withOpacity(0.3),
                          Colors.orange.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.lightbulb_rounded,
                            color: Colors.amber,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'سوالات پیشنهادی',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // List
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = suggestions[index];
                        return _buildSuggestionCard(suggestion, context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, String> suggestion, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            _messageController.text = suggestion['query']!;
            _sendMessage(suggestion['query']!);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.2),
                  Colors.blue.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    suggestion['icon']!,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    suggestion['title']!,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDialog({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
    required List<Widget> actions,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        iconColor.withOpacity(0.3),
                        iconColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: iconColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    content,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.white70,
                    ),
                  ),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    textDirection: TextDirection.rtl,
                    children: actions,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required String text,
    required VoidCallback onPressed,
    Color? color,
    bool isPrimary = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? LinearGradient(
                colors: [
                  (color ?? Colors.purple).withOpacity(0.6),
                  (color ?? Colors.blue).withOpacity(0.4),
                ],
              )
                  : null,
              color: isPrimary ? null : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
              const Color(0xFF0f3460),
              Colors.purple.shade900,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildModernAppBar(),
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : _buildMessageList(),
            ),
            if (_isTyping) _buildTypingIndicator(),
            _buildModernInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 16,
            left: 16,
            right: 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
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
                            Colors.purple.withOpacity(0.6),
                            Colors.blue.withOpacity(0.4),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'دستیار هوش مصنوعی پیشرفته',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'موتور محلی فعال 🚀',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        if (_lastConfidence > 0) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getConfidenceColor(_lastConfidence).withOpacity(0.3),
                                  _getConfidenceColor(_lastConfidence).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getConfidenceColor(_lastConfidence).withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              '${(_lastConfidence * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: _getConfidenceColor(_lastConfidence),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.lightbulb_outline_rounded, color: Colors.white),
                onPressed: _showSuggestionsDialog,
                tooltip: 'سوالات پیشنهادی',
              ),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                onPressed: _showAIInfoDialog,
                tooltip: 'اطلاعات AI',
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
                onPressed: _clearChat,
                tooltip: 'پاک کردن چت',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.purple.shade400,
                          Colors.blue.shade400,
                          Colors.cyan.shade400,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Colors.purple.shade300,
                  Colors.blue.shade300,
                  Colors.cyan.shade300,
                ],
              ).createShader(bounds),
              child: const Text(
                'به دستیار هوش مصنوعی پیشرفته خوش آمدید!',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'پروژه درسی: اصول کامپایلر 🎓',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '🧠 موتور AI محلی با الگوریتم‌های پیشرفته\n'
                            '🎯 تحلیل هوشمند و یادگیری مستمر\n'
                            '⚡ پردازش سریع و دقیق',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildFeatureChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChips() {
    final features = [
      {'icon': '🎯', 'text': 'Intent Detection'},
      {'icon': '🔍', 'text': 'Semantic Analysis'},
      {'icon': '🧩', 'text': 'Context Aware'},
      {'icon': '🔤', 'text': 'NLP Engine'},
      {'icon': '🎓', 'text': 'Deep Learning'},
      {'icon': '⚡', 'text': 'سرعت بالا'},
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: features.map((feature) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(feature['icon']!, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    feature['text']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index], index);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          textDirection: message.isUser ? TextDirection.ltr : TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? LinearGradient(
                  colors: [Colors.blue.shade600, Colors.purple.shade600],
                )
                    : (message.isError
                    ? LinearGradient(
                  colors: [Colors.red.shade600, Colors.orange.shade600],
                )
                    : LinearGradient(
                  colors: [Colors.green.shade600, Colors.teal.shade600],
                )),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (message.isUser
                        ? Colors.blue
                        : (message.isError ? Colors.red : Colors.green))
                        .withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                message.isUser ? Icons.person_rounded : Icons.psychology_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Message Bubble
            Flexible(
              child: Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(24),
                      topRight: const Radius.circular(24),
                      bottomLeft: message.isUser
                          ? const Radius.circular(24)
                          : const Radius.circular(6),
                      bottomRight: message.isUser
                          ? const Radius.circular(6)
                          : const Radius.circular(24),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: message.isUser
                              ? LinearGradient(
                            colors: [
                              Colors.blue.shade600.withOpacity(0.8),
                              Colors.purple.shade600.withOpacity(0.8),
                            ],
                          )
                              : LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(24),
                            topRight: const Radius.circular(24),
                            bottomLeft: message.isUser
                                ? const Radius.circular(24)
                                : const Radius.circular(6),
                            bottomRight: message.isUser
                                ? const Radius.circular(6)
                                : const Radius.circular(24),
                          ),
                          border: Border.all(
                            color: message.isError
                                ? Colors.red.withOpacity(0.3)
                                : Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: message.isUser
                                  ? Colors.purple.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SelectableText(
                          message.text,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Timestamp
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Colors.white.withOpacity(0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.teal.shade600],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Typing Bubble
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.green.shade300,
                          Colors.teal.shade300,
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'در حال تحلیل',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedBuilder(
                      animation: _typingController,
                      builder: (context, child) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (index) {
                            final delay = index * 0.2;
                            final value =
                            (_typingController.value - delay).clamp(0.0, 1.0);
                            final offset = (0.5 - (value - 0.5).abs()) * 2;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Transform.translate(
                                offset: Offset(0, -8 * offset),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green.shade300,
                                        Colors.teal.shade300,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInputArea() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                // Input Field
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.purple.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _messageController,
                          textDirection: TextDirection.rtl,
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: _isLoading ? null : _sendMessage,
                          enabled: !_isLoading,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'پیام خود را بنویسید... 💬',
                            hintTextDirection: TextDirection.rtl,
                            hintStyle: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            suffixIcon: _messageController.text.isNotEmpty
                                ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() => _messageController.clear());
                              },
                            )
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Send Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading
                        ? null
                        : () => _sendMessage(_messageController.text),
                    borderRadius: BorderRadius.circular(28),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: _isLoading
                            ? LinearGradient(
                          colors: [
                            Colors.grey.shade600,
                            Colors.grey.shade700,
                          ],
                        )
                            : LinearGradient(
                          colors: [
                            Colors.purple.shade600,
                            Colors.blue.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isLoading ? Colors.grey : Colors.purple)
                                .withOpacity(0.5),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _typingController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }
}
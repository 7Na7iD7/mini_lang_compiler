import 'advanced_local_ai_chat_service.dart';
import 'casual_conversation_handler.dart';

enum ResponseType {
  casual,
  technical,
}

class UnifiedChatResponse {
  final String text;
  final ResponseType type;
  final double confidence;
  final Duration processingTime;
  final Map<String, dynamic> metadata;

  UnifiedChatResponse({
    required this.text,
    required this.type,
    required this.confidence,
    required this.processingTime,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'type': type.toString(),
    'confidence': confidence,
    'processing_time_ms': processingTime.inMilliseconds,
    'metadata': metadata,
  };

  @override
  String toString() {
    return '''
╔═══════════════════════════════════════════════════════════╗
║  📨 پاسخ یکپارچه                                          ║
╠═══════════════════════════════════════════════════════════╣
║  📝 متن: $text
║  🎯 نوع: $type
║  ⚡ اطمینان: ${(confidence * 100).toInt()}%
║  ⏱️  زمان: ${processingTime.inMilliseconds}ms
╚═══════════════════════════════════════════════════════════╝
''';
  }
}

class UnifiedChatService {
  static final UnifiedChatService _instance = UnifiedChatService._internal();
  factory UnifiedChatService() => _instance;
  UnifiedChatService._internal();

  late final AdvancedAIChatService _technicalService;
  late final AdvancedCasualConversationHandler _casualHandler;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    print('\n╔════════════════════════════════════════════════════════════╗');
    print('║   🎯 راه‌اندازی سیستم چت یکپارچه...                      ║');
    print('╚════════════════════════════════════════════════════════════╝\n');

    _technicalService = AdvancedAIChatService();
    _casualHandler = AdvancedCasualConversationHandler();

    _isInitialized = true;

    print('╔════════════════════════════════════════════════════════════╗');
    print('║   ✅ سیستم چت یکپارچه آماده است!                         ║');
    print('╠════════════════════════════════════════════════════════════╣');
    print('║                                                            ║');
    print('║   🔄 معماری دوگانه:                                       ║');
    print('║                                                            ║');
    print('║   ┌─────────────────────────────────────────────┐         ║');
    print('║   │  User Message                               │         ║');
    print('║   └──────────────┬──────────────────────────────┘         ║');
    print('║                  │                                         ║');
    print('║                  ▼                                         ║');
    print('║   ┌──────────────────────────────────────────────┐        ║');
    print('║   │  Intent Detection Layer                      │        ║');
    print('║   │  (Casual vs Technical)                       │        ║');
    print('║   └──────────┬──────────────────────┬────────────┘        ║');
    print('║              │                      │                     ║');
    print('║     Casual   │                      │   Technical         ║');
    print('║              ▼                      ▼                     ║');
    print('║   ┌─────────────────┐    ┌────────────────────┐          ║');
    print('║   │ 💬 Casual       │    │ 🧠 Technical       │          ║');
    print('║   │ Handler         │    │ ML/NLP Engine      │          ║');
    print('║   │                 │    │ (4-Layer System)   │          ║');
    print('║   └─────────────────┘    └────────────────────┘          ║');
    print('║                                                            ║');
    print('╚════════════════════════════════════════════════════════════╝\n');
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<UnifiedChatResponse> sendMessage(
      String message, {
        List<ChatMessage>? history,
      }) async {
    await _ensureInitialized();

    final startTime = DateTime.now();

    print('\n╔════════════════════════════════════════════════════════════╗');
    print('║   📨 پردازش پیام جدید...                                  ║');
    print('╚════════════════════════════════════════════════════════════╝');
    print('\n💬 پیام: "$message"\n');

    print('🔍 مرحله 1: تشخیص نوع پیام...');

    // handleMessage
    final casualResponse = await _casualHandler.handleMessage(
      message: message,
      conversationHistory: history?.map((m) => m.text).toList() ?? [],
    );

    if (casualResponse != null && casualResponse.isCasual) {
      print('   ✓ نوع: مکالمه غیرفنی (Casual)');
      print('   • Intent: ${casualResponse.intent.primaryIntent}');
      print('   • Emotion: ${casualResponse.emotion.primaryEmotion}');
      print('   • Confidence: ${(casualResponse.overallConfidence * 100).toInt()}%\n');

      final processingTime = DateTime.now().difference(startTime);

      return UnifiedChatResponse(
        text: casualResponse.responseText,
        type: ResponseType.casual,
        confidence: casualResponse.overallConfidence,
        processingTime: processingTime,
        metadata: {
          'intent': casualResponse.intent.primaryIntent.toString(),
          'sentiment': casualResponse.sentiment.label.toString(),
          'emotion': casualResponse.emotion.primaryEmotion.toString(),
          'handler': 'AdvancedCasualConversationHandler',
        },
      );
    } else {
      print('   ✓ نوع: سوال فنی (Technical)\n');
      print('🧠 مرحله 2: پردازش با موتور ML/NLP پیشرفته...\n');

      final technicalResponse = await _technicalService.sendMessage(
        message,
        history: history,
      );

      final processingTime = DateTime.now().difference(startTime);

      return UnifiedChatResponse(
        text: technicalResponse.text,
        type: ResponseType.technical,
        confidence: technicalResponse.confidence,
        processingTime: processingTime,
        metadata: {
          'provider': technicalResponse.provider,
          'handler': 'AdvancedAIChatService',
        },
      );
    }
  }

  Map<String, dynamic> getComprehensiveStats() {
    final casualStats = _casualHandler.getPerformanceMetrics();

    return {
      'technical_stats': _technicalService.getProvidersStatus(),
      'casual_stats': casualStats,
      'system_info': {
        'initialized': _isInitialized,
        'architecture': 'Dual-Engine (Casual + Technical)',
        'total_components': 2,
      },
    };
  }

  String getPerformanceReport() {
    final stats = getComprehensiveStats();

    return '''
╔════════════════════════════════════════════════════════════╗
║  📊 گزارش عملکرد سیستم یکپارچه                            ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  🎯 معماری: Dual-Engine (Casual + Technical)              ║
║  ✅ وضعیت: ${stats['system_info']['initialized'] ? 'فعال' : 'غیرفعال'}                                              ║
║  🔢 تعداد اجزا: ${stats['system_info']['total_components']}                                          ║
║                                                            ║
╠════════════════════════════════════════════════════════════╣
║  💬 آمار Casual Handler:                                   ║
║  ${stats['casual_stats']['total_interactions'] ?? 0} تعامل غیرفنی                                      ║
║                                                            ║
╠════════════════════════════════════════════════════════════╣
║  🧠 آمار Technical ML/NLP:                                 ║
║  در حال پردازش...                                         ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
''';
  }

  void reset() {
    _technicalService.reset();
    _casualHandler.reset();
    print('🔄 سیستم یکپارچه بازنشانی شد');
  }

  void recordFeedback({
    required String message,
    required String response,
    required bool wasHelpful,
    required ResponseType type,
  }) {
    if (type == ResponseType.technical) {
      _technicalService.recordUserFeedback(
        userMessage: message,
        assistantResponse: response,
        wasHelpful: wasHelpful,
      );
    }

    print('📝 بازخورد ثبت شد: ${wasHelpful ? "👍" : "👎"} (نوع: $type)');
  }

  Future<bool> testConnection() async {
    await _ensureInitialized();
    return await _technicalService.testConnection();
  }
}
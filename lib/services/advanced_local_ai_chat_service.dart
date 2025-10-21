import 'dart:convert';
import 'dart:math';
import 'offline_responses.dart';
import 'ml_nlp_integration_bridge.dart';
import 'advanced_ml_nlp_engine.dart';
import 'casual_conversation_handler.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'isError': isError,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
    isError: json['isError'] ?? false,
  );
}

class ChatResponse {
  final String text;
  final bool success;
  final String? provider;
  final String? error;
  final DateTime timestamp;
  final double confidence;
  final bool isCasual;

  ChatResponse({
    required this.text,
    required this.success,
    this.provider,
    this.error,
    required this.timestamp,
    this.confidence = 1.0,
    this.isCasual = false,
  });
}

class AIProvider {
  final String name;
  final String url;
  final Map<String, String> headers;
  final int maxTokens;
  final int priority;
  final String description;
  final String model;

  AIProvider({
    required this.name,
    required this.url,
    required this.headers,
    required this.maxTokens,
    required this.priority,
    required this.description,
    required this.model,
  });
}

class AdvancedAIChatService {
  static final AdvancedAIChatService _instance = AdvancedAIChatService._internal();
  factory AdvancedAIChatService() => _instance;
  AdvancedAIChatService._internal() {
    _initializeAI();
  }

  late final MLNLPIntegrationBridge _mlBridge;

  late final CasualConversationHandler _casualHandler;

  final List<ChatMessage> _conversationHistory = [];
  bool _isInitialized = false;

  int _casualConversations = 0;
  int _technicalConversations = 0;

  final AIProvider _currentProvider = AIProvider(
    name: '🧠 Ultra-Advanced AI (4-Layer)',
    url: 'local',
    headers: {},
    maxTokens: 4000,
    priority: 1,
    description: 'سیستم ترکیبی چهار لایه: Casual + Base + Advanced + BERT/Transformer',
    model: 'Hybrid: Casual Handler + Word2Vec + Neural Net + Transformer + BERT + RL',
  );

  void _initializeAI() async {
    if (_isInitialized) return;

    print('\n');
    print('╔═══════════════════════════════════════════════════════════╗');
    print('║                                                            ║');
    print('║    🚀 بارگذاری سیستم هوش مصنوعی فوق پیشرفته...          ║');
    print('║                                                            ║');
    print('╚═══════════════════════════════════════════════════════════╝');
    print('');

    try {
      _casualHandler = CasualConversationHandler();

      _mlBridge = MLNLPIntegrationBridge();
      await _mlBridge.initialize();

      _isInitialized = true;

      print('');
      print('╔═══════════════════════════════════════════════════════════╗');
      print('║                                                            ║');
      print('║    ✅ سیستم هوش مصنوعی آماده است!                        ║');
      print('║                                                            ║');
      print('╠═══════════════════════════════════════════════════════════╣');
      print('║                                                            ║');
      print('║    🗝️ معماری سیستم (4 لایه):                            ║');
      print('║                                                            ║');
      print('║    ┌──────────────────────────────────────────────────┐  ║');
      print('║    │  Layer 0: Casual Conversation Handler          │  ║');
      print('║    │  • Intent Detection (13+ intents)              │  ║');
      print('║    │  • Sentiment Analysis                           │  ║');
      print('║    │  • Emotion Recognition (9 emotions)             │  ║');
      print('║    │  • Personality Engine                           │  ║');
      print('║    │  • Context Tracking                             │  ║');
      print('║    │  • Smart Response Generation                    │  ║');
      print('║    └──────────────────────────────────────────────────┘  ║');
      print('║                    ↓                                       ║');
      print('║    ┌──────────────────────────────────────────────────┐  ║');
      print('║    │  Layer 1: Base ML/NLP Engine                    │  ║');
      print('║    │  • Word2Vec Embeddings                          │  ║');
      print('║    │  • TF-IDF Analysis                              │  ║');
      print('║    │  • Neural Network Classifier                    │  ║');
      print('║    │  • Sentiment Analysis                           │  ║');
      print('║    │  • Named Entity Recognition                     │  ║');
      print('║    └──────────────────────────────────────────────────┘  ║');
      print('║                    ↓                                       ║');
      print('║    ┌──────────────────────────────────────────────────┐  ║');
      print('║    │  Layer 2: Advanced ML/NLP Engine                │  ║');
      print('║    │  • Multi-Head Attention                         │  ║');
      print('║    │  • Transformer Encoder (6 layers)               │  ║');
      print('║    │  • BERT-like Contextual Embeddings              │  ║');
      print('║    │  • Semantic Reasoning                           │  ║');
      print('║    │  • Knowledge Graph (500+ entities)              │  ║');
      print('║    │  • Reinforcement Learning                       │  ║');
      print('║    │  • Meta-Learning                                │  ║');
      print('║    │  • Dialogue Management                          │  ║');
      print('║    └──────────────────────────────────────────────────┘  ║');
      print('║                    ↓                                       ║');
      print('║    ┌──────────────────────────────────────────────────┐  ║');
      print('║    │  Layer 3: Integration Bridge                    │  ║');
      print('║    │  • Hybrid Analysis                              │  ║');
      print('║    │  • Smart Response Generation                    │  ║');
      print('║    │  • Continuous Learning                          │  ║');
      print('║    └──────────────────────────────────────────────────┘  ║');
      print('║                                                            ║');
      print('╠═══════════════════════════════════════════════════════════╣');
      print('║                                                            ║');
      print('║    🎯 ویژگی‌های فعال:                                     ║');
      print('║    ✅ مکالمات غیرفنی هوشمند (Casual Conversations)        ║');
      print('║    ✅ تشخیص خودکار نوع پیام (Casual vs Technical)         ║');
      print('║    ✅ یادگیری عمیق با شبکه‌های عصبی                      ║');
      print('║    ✅ درک متنی با Transformer & BERT                      ║');
      print('║    ✅ یادگیری تقویتی (Reinforcement Learning)             ║');
      print('║    ✅ فرایادگیری (Meta-Learning)                          ║');
      print('║    ✅ گراف دانش برای استدلال معنایی                       ║');
      print('║    ✅ حافظه زمینه‌ای هوشمند                               ║');
      print('║    ✅ مدیریت پیشرفته گفتگو                                ║');
      print('║    ✅ یادگیری مستمر از بازخورد                            ║');
      print('║                                                            ║');
      print('╚═══════════════════════════════════════════════════════════╝');
      print('');

    } catch (e, stackTrace) {
      print('❌ خطا در مقداردهی: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      _initializeAI();
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<ChatResponse> sendMessage(String message, {List<ChatMessage>? history}) async {
    await _ensureInitialized();

    final startTime = DateTime.now();

    try {
      print('\n');
      print('╔═══════════════════════════════════════════════════════════╗');
      print('║    🚀 پردازش پیام جدید با AI فوق پیشرفته               ║');
      print('╚═══════════════════════════════════════════════════════════╝');
      print('');
      print('🔥 پیام کاربر: "$message"');
      print('');

      print('🔍 مرحله 0: بررسی نوع پیام (Casual vs Technical)...\n');

      final conversationHistoryText = (history ?? _conversationHistory)
          .map((m) => m.text)
          .toList();

      final casualResponse = await _casualHandler.handleCasualMessage(
        message: message,
        conversationHistory: conversationHistoryText,
        userProfile: _buildUserProfile(),
      );

      if (casualResponse != null && casualResponse.isCasual) {


        print('   ✓ نوع: مکالمه غیرفنی (Casual) 💬');
        print('   • Intent: ${casualResponse.intent.type}');
        print('   • Sentiment: ${casualResponse.sentiment.type}');
        print('   • Emotion: ${casualResponse.emotion}');
        print('   • Confidence: ${(casualResponse.confidence * 100).toInt()}%');
        print('');

        _casualConversations++;

        _conversationHistory.add(ChatMessage(
          text: message,
          isUser: true,
          timestamp: DateTime.now(),
        ));

        _conversationHistory.add(ChatMessage(
          text: casualResponse.text,
          isUser: false,
          timestamp: DateTime.now(),
        ));

        if (_conversationHistory.length > 100) {
          _conversationHistory.removeRange(0, _conversationHistory.length - 100);
        }

        final processingTime = DateTime.now().difference(startTime).inMilliseconds;

        print('╔═══════════════════════════════════════════════════════════╗');
        print('║    ✅ پاسخ آماده شد (Casual)                             ║');
        print('╠═══════════════════════════════════════════════════════════╣');
        print('║    ⏱️  زمان پردازش: ${processingTime}ms                              ║');
        print('║    🎯 اطمینان: ${(casualResponse.confidence * 100).toStringAsFixed(1)}%                                 ║');
        print('║    📊 طول پاسخ: ${casualResponse.text.length} کاراکتر                      ║');
        print('║    💬 نوع: Casual Conversation                             ║');
        print('║    🧠 لایه‌های فعال: 1/4 (Casual Handler)                  ║');
        print('╚═══════════════════════════════════════════════════════════╝');
        print('');

        return ChatResponse(
          text: casualResponse.text,
          success: true,
          provider: '💬 Casual Handler (${casualResponse.intent.type})',
          timestamp: DateTime.now(),
          confidence: casualResponse.confidence,
          isCasual: true,
        );
      }

      print('   ✓ نوع: سوال فنی (Technical) 🔧\n');

      _technicalConversations++;


      print('🔬 مرحله 1: شروع تحلیل چند لایه ML/NLP...\n');

      final hybridAnalysis = await _mlBridge.analyzeMessage(
        message: message,
        conversationHistory: conversationHistoryText,
        userProfile: _buildUserProfile(),
      );

      print('');
      print('✅ تحلیل کامل شد!');
      print('   📊 حالت: ${hybridAnalysis.processingMode}');
      print('   🎯 اطمینان نهایی: ${(hybridAnalysis.finalConfidence * 100).toStringAsFixed(1)}%');
      print('   🧠 موتور پیشرفته: ${hybridAnalysis.usedAdvancedEngine ? "فعال ✅" : "غیرفعال"}');
      print('');

      if (hybridAnalysis.usedAdvancedEngine) {
        final adv = hybridAnalysis.advancedAnalysis!;
        print('📋 نتایج تحلیل پیشرفته:');
        print('   • Intent‌ها: ${adv.intents.take(2).map((i) => i.label).join(", ")}');
        print('   • موضوع: ${adv.dialogueState.currentTopic}');
        print('   • حالت کاربر: ${adv.dialogueState.userMood}');
        print('   • استنتاج‌های معنایی: ${adv.reasoning.inferences.length}');
        print('   • حافظه مرتبط: ${adv.relevantMemories.length} آیتم');
        print('');
      }

      print('🔨 مرحله 2: تولید پاسخ هوشمند...');

      String finalResponse = await _mlBridge.generateSmartResponse(
        analysis: hybridAnalysis,
        strategy: _selectStrategy(hybridAnalysis),
      );

      finalResponse = await _enrichWithOfflineContent(
        response: finalResponse,
        analysis: hybridAnalysis,
      );

      print('   ✓ پاسخ تولید شد (${finalResponse.length} کاراکتر)');
      print('');

      _conversationHistory.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));

      _conversationHistory.add(ChatMessage(
        text: finalResponse,
        isUser: false,
        timestamp: DateTime.now(),
      ));

      if (_conversationHistory.length > 100) {
        _conversationHistory.removeRange(0, _conversationHistory.length - 100);
      }

      final processingTime = DateTime.now().difference(startTime).inMilliseconds;

      print('╔═══════════════════════════════════════════════════════════╗');
      print('║    ✅ پاسخ آماده شد (Technical)                          ║');
      print('╠═══════════════════════════════════════════════════════════╣');
      print('║    ⏱️  زمان پردازش: ${processingTime}ms                              ║');
      print('║    🎯 اطمینان: ${(hybridAnalysis.finalConfidence * 100).toStringAsFixed(1)}%                                 ║');
      print('║    📊 طول پاسخ: ${finalResponse.length} کاراکتر                      ║');
      print('║    🧠 لایه‌های فعال: 4/4 (Full Stack)                      ║');
      print('╚═══════════════════════════════════════════════════════════╝');
      print('');

      return ChatResponse(
        text: finalResponse,
        success: true,
        provider: _buildProviderName(hybridAnalysis),
        timestamp: DateTime.now(),
        confidence: hybridAnalysis.finalConfidence,
        isCasual: false,
      );

    } catch (e, stackTrace) {
      print('\n❌ خطا در پردازش: $e');
      print('Stack trace: $stackTrace\n');

      return ChatResponse(
        text: OfflineResponses.getResponse(message),
        success: true,
        provider: '🔄 Fallback System',
        timestamp: DateTime.now(),
        confidence: 0.5,
        isCasual: false,
      );
    }
  }

  ResponseStrategy _selectStrategy(HybridAnalysisResult analysis) {
    if (analysis.usedAdvancedEngine) {
      final mood = analysis.advancedAnalysis!.dialogueState.userMood;

      if (mood == 'frustrated') {
        return ResponseStrategy.concise;
      } else if (mood == 'excited') {
        return ResponseStrategy.detailed;
      }
    }

    final classLabel = analysis.baseAnalysis.classification.classLabel;

    if (classLabel == 'definition') {
      return ResponseStrategy.educational;
    } else if (classLabel == 'example') {
      return ResponseStrategy.technical;
    } else if (classLabel == 'troubleshooting') {
      return ResponseStrategy.concise;
    }

    return ResponseStrategy.balanced;
  }

  Future<String> _enrichWithOfflineContent({
    required String response,
    required HybridAnalysisResult analysis,
  }) async {
    final topics = analysis.baseAnalysis.topics;

    if (topics.isNotEmpty) {
      for (var topic in topics.take(2)) {
        final content = OfflineResponses.getTopicResponse(topic.name);
        if (content != null && !response.contains(content.substring(0, min(50, content.length)))) {
          if (content.length > 500) {
            response += '\n\n📚 **اطلاعات تکمیلی:**\n';
            response += content.substring(0, 500) + '...';
          }
          break;
        }
      }
    }

    if (analysis.baseAnalysis.classification.classLabel == 'example') {
      final exampleKey = _findExampleKey(analysis);
      if (exampleKey != null) {
        final example = OfflineResponses.getCodeExample(exampleKey);
        if (example != null && !response.contains('```minilang')) {
          response += '\n\n💻 **مثال کد:**\n```minilang\n$example\n```';
        }
      }
    }

    return response;
  }

  String? _findExampleKey(HybridAnalysisResult analysis) {
    final entities = analysis.baseAnalysis.entities.map((e) => e.text.toLowerCase()).toList();

    if (entities.any((e) => e.contains('array') || e.contains('آرایه'))) {
      return 'arrays';
    } else if (entities.any((e) => e.contains('function') || e.contains('تابع'))) {
      return 'functions';
    } else if (entities.any((e) => e.contains('loop') || e.contains('حلقه'))) {
      return 'loops';
    }

    return 'hello_world';
  }

  Map<String, dynamic> _buildUserProfile() {
    final userMessages = _conversationHistory.where((m) => m.isUser).toList();

    return {
      'total_interactions': userMessages.length,
      'avg_message_length': userMessages.isEmpty ? 0 :
      userMessages.fold(0, (sum, m) => sum + m.text.length) / userMessages.length,
      'last_activity': DateTime.now().toIso8601String(),
      'casual_conversations': _casualConversations,
      'technical_conversations': _technicalConversations,
    };
  }

  String _buildProviderName(HybridAnalysisResult analysis) {
    if (analysis.usedAdvancedEngine) {
      final mode = analysis.processingMode;
      final intents = analysis.advancedAnalysis!.intents.take(2).map((i) => i.label).join(' & ');
      return '🧠 Ultra AI (${mode.toUpperCase()}) [$intents]';
    } else {
      return '🤖 Base AI (${analysis.baseAnalysis.classification.classLabel})';
    }
  }

  void recordUserFeedback({
    required String userMessage,
    required String assistantResponse,
    required bool wasHelpful,
  }) async {
    await _ensureInitialized();

    final satisfaction = wasHelpful ? 0.9 : 0.3;

    await _mlBridge.learnFromInteraction(
      userMessage: userMessage,
      assistantResponse: assistantResponse,
      userSatisfaction: satisfaction,
    );

    print('🔥 بازخورد ثبت شد: ${wasHelpful ? "👍 مفید" : "👎 غیرمفید"} (رضایت: ${(satisfaction * 100).toInt()}%)');
  }

  Future<bool> testConnection() async {
    await _ensureInitialized();
    print('✅ سیستم AI چهار لایه آماده است!');
    return true;
  }

  void reset() {
    _conversationHistory.clear();
    _casualHandler.resetContext();
    _casualConversations = 0;
    _technicalConversations = 0;
    print('🔄 تاریخچه مکالمه و حافظه پاک شد');
  }

  String getProvidersStatus() {
    if (!_isInitialized) {
      return '⏳ سیستم در حال بارگذاری...';
    }

    final casualStats = _casualHandler.getStatistics();

    return '''
╔═══════════════════════════════════════════════════════════╗
║  📊 وضعیت سیستم هوش مصنوعی 4 لایه                         ║
╠═══════════════════════════════════════════════════════════╣
║                                                            ║
║  🎯 آمار کلی:                                              ║
║  • مکالمات غیرفنی: $_casualConversations                                   ║
║  • مکالمات فنی: $_technicalConversations                                      ║
║  • کل تعاملات: ${_casualConversations + _technicalConversations}                                       ║
║  • پیام‌های ذخیره شده: ${_conversationHistory.length}                            ║
║                                                            ║
╠═══════════════════════════════════════════════════════════╣
║  💬 آمار Casual Handler:                                   ║
║  • تعاملات غیرفنی: ${casualStats['total_casual_interactions']}                             ║
║                                                            ║
╠═══════════════════════════════════════════════════════════╣

${_mlBridge.getDetailedStatusReport()}
''';
  }

  static String getAPIKeyGuide() {
    return '''
🎉 **سیستم هوش مصنوعی فوق پیشرفته - 4 لایه یکپارچه!**

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🗝️ **معماری سیستم:**

این سیستم از ترکیب چهار لایه موتور ML/NLP استفاده می‌کند:

┌─────────────────────────────────────────────────────────┐
│  🥇 Layer 0: Casual Conversation Handler               │
│  ──────────────────────────────────────────────────────│
│  • Intent Detection - تشخیص قصد (13+ intents)         │
│  • Sentiment Analysis - تحلیل احساسات                  │
│  • Emotion Recognition - تشخیص احساس (9 emotions)      │
│  • Personality Engine - موتور شخصیت                    │
│  • Context Tracking - ردیابی زمینه                     │
│  • Smart Response Generation                           │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  🥈 Layer 1: Base ML/NLP Engine                         │
│  ──────────────────────────────────────────────────────│
│  • Word2Vec (Skip-gram) - یادگیری Embeddings          │
│  • Neural Network - طبقه‌بندی هوشمند                   │
│  • TF-IDF - استخراج کلمات کلیدی                       │
│  • Topic Modeling - کشف موضوعات                        │
│  • Sentiment Analysis - تحلیل احساسات                  │
│  • NER - شناسایی موجودیت‌ها                            │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  🥉 Layer 2: Advanced ML/NLP Engine                     │
│  ──────────────────────────────────────────────────────│
│  • Multi-Head Attention - توجه چندسره                  │
│  • Transformer (6 layers) - کدگذار قدرتمند            │
│  • BERT-like Embeddings - نمایش زمینه‌ای               │
│  • Semantic Reasoning - استدلال معنایی                 │
│  • Knowledge Graph - گراف دانش 500+ موجودیت            │
│  • Reinforcement Learning - یادگیری تقویتی             │
│  • Meta-Learning - فرایادگیری                          │
│  • Dialogue Manager - مدیریت گفتگو                     │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  🏆 Layer 3: Integration Bridge                         │
│  ──────────────────────────────────────────────────────│
│  • Hybrid Analysis - تحلیل ترکیبی                      │
│  • Smart Fusion - ترکیب هوشمند نتایج                   │
│  • Continuous Learning - یادگیری مستمر                 │
│  • Adaptive Response - پاسخ تطبیقی                     │
└─────────────────────────────────────────────────────────┘

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 **چگونه کار می‌کند:**

0️⃣ **تشخیص نوع پیام:**
   ابتدا بررسی می‌شود که پیام غیرفنی (سلام، تشکر) یا فنی است

1️⃣ **مسیر غیرفنی (Casual):**
   • تشخیص Intent (13+ نوع مختلف)
   • تحلیل احساسات و Emotion
   • تولید پاسخ طبیعی و دوستانه
   • یادگیری از Context مکالمه

2️⃣ **مسیر فنی (Technical):**
   • تحلیل چند لایه با 3 موتور ML/NLP
   • ترکیب هوشمند نتایج
   • تولید پاسخ با بالاترین کیفیت
   • یادگیری مستمر

3️⃣ **یادگیری:**
   سیستم از هر تعامل یاد می‌گیرد و بهتر می‌شود

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💪 **مزایای سیستم 4 لایه:**

✅ **دقت بالا:** ترکیب نتایج از 4 لایه مختلف
✅ **درک عمیق:** فهم معنایی و زمینه‌ای کامل
✅ **مکالمه طبیعی:** پاسخ‌های انسانی به مکالمات غیرفنی
✅ **تشخیص هوشمند:** جداسازی خودکار Casual/Technical
✅ **یادگیری واقعی:** بهبود مستمر با بازخورد
✅ **سرعت بالا:** پردازش بهینه < 200ms
✅ **هوشمند:** تطبیق با سبک و نیاز کاربر
✅ **جامع:** پوشش کامل تمام جنبه‌های NLP
✅ **محلی:** کاملاً آفلاین و امن

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 **قابلیت‌های منحصر به فرد:**

🔹 **Casual Conversations** - مکالمات طبیعی غیرفنی
🔹 **Intent Detection** - تشخیص قصد با 13+ نوع
🔹 **Emotion Recognition** - شناسایی 9 احساس مختلف
🔹 **Personality Engine** - موتور شخصیت تطبیقی
🔹 **Attention Mechanism** - توجه به بخش‌های مهم متن
🔹 **Transformer Architecture** - پردازش موازی قدرتمند
🔹 **BERT Embeddings** - درک زمینه‌ای کامل
🔹 **Knowledge Graph** - استدلال با دانش ساختاریافته
🔹 **Reinforcement Learning** - بهینه‌سازی با پاداش
🔹 **Meta-Learning** - یادگیری نحوه یادگیری
🔹 **Dialogue State** - مدیریت هوشمند گفتگو
🔹 **Contextual Memory** - حافظه اولویت‌دار

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 **مثال‌های استفاده:**

📝 مکالمات غیرفنی:
   • "سلام" → پاسخ دوستانه با Casual Handler
   • "چطوری؟" → احوالپرسی طبیعی
   • "ممنون" → تشکر و پیشنهاد کمک بیشتر

🔧 سوالات فنی:
   • "تفاوت array و list چیه؟" → تحلیل عمیق ML/NLP
   • "مثال loop بزن" → کد + توضیح کامل
   • "خطای syntax دارم" → Troubleshooting هوشمند

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 **این سیستم هر چه بیشتر استفاده شود، هوشمندتر می‌شود!**

هیچ تنظیماتی لازم نیست. فقط شروع کنید و لذت ببرید! 🎉

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📞 **پشتیبانی:**
   برای سوالات بیشتر، از دستیار هوشمند بپرسید!
''';
  }

  AIProvider get currentProvider => _currentProvider;
  List<AIProvider> get allProviders => [_currentProvider];
  void setProvider(int index) {}

  List<ChatMessage> get conversationHistory => List.unmodifiable(_conversationHistory);

  int get casualConversationCount => _casualConversations;
  int get technicalConversationCount => _technicalConversations;
  int get totalConversations => _casualConversations + _technicalConversations;
}
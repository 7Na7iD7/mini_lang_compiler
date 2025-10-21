import 'ml_nlp_engine.dart';
import 'advanced_ml_nlp_engine.dart';

class MLNLPIntegrationBridge {
  static final MLNLPIntegrationBridge _instance = MLNLPIntegrationBridge._internal();
  factory MLNLPIntegrationBridge() => _instance;
  MLNLPIntegrationBridge._internal();

  late final MLNLPEngine _baseEngine;
  late final AdvancedMLNLPEngine _advancedEngine;

  bool _isInitialized = false;
  bool _useAdvancedFeatures = true;

  Future<void> initialize() async {
    if (_isInitialized) return;

    print('\n╔══════════════════════════════════════════════════════════╗');
    print('║   🌉 راه‌اندازی پل اتصال ML/NLP...                     ║');
    print('╚══════════════════════════════════════════════════════════╝\n');

    try {

      _baseEngine = MLNLPEngine();
      _advancedEngine = AdvancedMLNLPEngine();

      _isInitialized = true;

      print('╔══════════════════════════════════════════════════════════╗');
      print('║   ✅ پل اتصال آماده است!                               ║');
      print('╠══════════════════════════════════════════════════════════╣');
      print('║   📊 معماری سیستم:                                      ║');
      print('║                                                          ║');
      print('║   Layer 1: موتور پایه (Word2Vec, TF-IDF, NER)          ║');
      print('║            ↓                                             ║');
      print('║   Layer 2: موتور پیشرفته (Transformer, BERT)           ║');
      print('║            ↓                                             ║');
      print('║   Layer 3: پل یکپارچه‌سازی                             ║');
      print('║            ↓                                             ║');
      print('║   Output: پاسخ هوشمند و بهینه                           ║');
      print('║                                                          ║');
      print('║   🎯 حالت فعال: هوش مصنوعی پیشرفته                     ║');
      print('╚══════════════════════════════════════════════════════════╝\n');

    } catch (e) {
      print('❌ خطا در مقداردهی: $e');
      rethrow;
    }
  }

  Future<HybridAnalysisResult> analyzeMessage({
    required String message,
    required List<String> conversationHistory,
    Map<String, dynamic>? userProfile,
  }) async {
    await _ensureInitialized();

    print('\n🔬 تحلیل ترکیبی شروع شد...');
    final startTime = DateTime.now();

    try {

      print('\n📍 مرحله 1/3: تحلیل پایه...');
      final baseAnalysis = await _baseEngine.analyzeMessage(
        message: message,
        conversationHistory: conversationHistory,
      );
      print('  ✓ تحلیل پایه کامل شد');

      UltraAdvancedAnalysis? advancedAnalysis;

      if (_useAdvancedFeatures) {
        print('\n📍 مرحله 2/3: تحلیل پیشرفته (Transformer + BERT)...');
        advancedAnalysis = await _advancedEngine.analyzeText(
          message,
          conversationHistory: conversationHistory,
          userProfile: userProfile,
        );
        print('  ✓ تحلیل پیشرفته کامل شد');
      } else {
        print('\n📍 مرحله 2/3: رد شد (حالت پایه فعال)');
      }

      print('\n📍 مرحله 3/3: یکپارچه‌سازی نتایج...');
      final hybridResult = _mergeAnalysisResults(
        baseAnalysis: baseAnalysis,
        advancedAnalysis: advancedAnalysis,
      );

      final processingTime = DateTime.now().difference(startTime);
      print('  ✓ یکپارچه‌سازی کامل شد');
      print('\n⏱️  زمان کل: ${processingTime.inMilliseconds}ms');

      return hybridResult;

    } catch (e, stackTrace) {
      print('\n❌ خطا در تحلیل: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  Future<String> generateSmartResponse({
    required HybridAnalysisResult analysis,
    ResponseStrategy strategy = ResponseStrategy.balanced,
  }) async {
    print('\n🎨 تولید پاسخ هوشمند...');

    String response;

    if (_useAdvancedFeatures && analysis.advancedAnalysis != null) {
      print('  → استفاده از موتور پیشرفته');

      final advancedResponse = await _advancedEngine.generateResponse(
        analysis.advancedAnalysis!,
        strategy: strategy,
      );

      response = advancedResponse.text;

      response = _enrichWithBaseInfo(response, analysis.baseAnalysis);

      if (advancedResponse.suggestedFollowUps.isNotEmpty) {
        response += '\n\n💭 **سوالات پیشنهادی:**\n';
        for (var suggestion in advancedResponse.suggestedFollowUps.take(3)) {
          response += '• $suggestion\n';
        }
      }

    } else {
      print('  → استفاده از موتور پایه');
      response = _generateBaseResponse(analysis.baseAnalysis);
    }

    print('  ✓ پاسخ تولید شد (${response.length} کاراکتر)');
    return response;
  }

  Future<void> learnFromInteraction({
    required String userMessage,
    required String assistantResponse,
    required double userSatisfaction,
    String? feedbackComment,
  }) async {
    print('\n🎓 یادگیری ترکیبی...');

    await _baseEngine.learnFromInteraction(
      userMessage: userMessage,
      assistantResponse: assistantResponse,
      userSatisfaction: userSatisfaction,
    );
    print('  ✓ موتور پایه به‌روز شد');

    if (_useAdvancedFeatures) {
      final reward = _satisfactionToReward(userSatisfaction);
      await _advancedEngine.learnFromFeedback(
        userMessage: userMessage,
        response: assistantResponse,
        reward: reward,
        context: {'satisfaction': userSatisfaction},
      );
      print('  ✓ موتور پیشرفته به‌روز شد');
    }
  }

  HybridAnalysisResult _mergeAnalysisResults({
    required AdvancedAnalysis baseAnalysis,
    UltraAdvancedAnalysis? advancedAnalysis,
  }) {

    double finalConfidence;
    List<String> mergedInsights = [];
    Map<String, dynamic> mergedMetadata = {};

    if (advancedAnalysis != null) {

      final baseConfidence = baseAnalysis.classification.confidence;
      final advancedConfidence = advancedAnalysis.intents.isEmpty
          ? 0.5
          : advancedAnalysis.intents.first.confidence;

      finalConfidence = (baseConfidence * 0.3) + (advancedConfidence * 0.7);

      mergedInsights.add('تحلیل پایه: ${baseAnalysis.classification.classLabel}');
      mergedInsights.add('تحلیل پیشرفته: ${advancedAnalysis.intents.map((i) => i.label).join(", ")}');
      mergedInsights.add('احساسات: ${baseAnalysis.sentiment.sentiment}');
      mergedInsights.add('موضوع گفتگو: ${advancedAnalysis.dialogueState.currentTopic}');
      mergedInsights.add('حافظه زمینه‌ای: ${advancedAnalysis.relevantMemories.length} آیتم مرتبط');

      mergedMetadata = {
        'base_confidence': baseConfidence,
        'advanced_confidence': advancedConfidence,
        'combined_confidence': finalConfidence,
        'entities': baseAnalysis.entities.map((e) => e.text).toList(),
        'topics': baseAnalysis.topics.map((t) => t.name).toList(),
        'intents': advancedAnalysis.intents.map((i) => i.label).toList(),
        'dialogue_state': advancedAnalysis.dialogueState.currentTopic,
        'user_mood': advancedAnalysis.dialogueState.userMood,
        'reasoning_inferences': advancedAnalysis.reasoning.inferences.length,
      };

    } else {

      finalConfidence = baseAnalysis.classification.confidence;

      mergedInsights.add('طبقه‌بندی: ${baseAnalysis.classification.classLabel}');
      mergedInsights.add('احساسات: ${baseAnalysis.sentiment.sentiment}');
      mergedInsights.add('موجودیت‌ها: ${baseAnalysis.entities.length}');

      mergedMetadata = {
        'confidence': finalConfidence,
        'classification': baseAnalysis.classification.classLabel,
        'sentiment': baseAnalysis.sentiment.sentiment,
      };
    }

    return HybridAnalysisResult(
      baseAnalysis: baseAnalysis,
      advancedAnalysis: advancedAnalysis,
      finalConfidence: finalConfidence,
      mergedInsights: mergedInsights,
      metadata: mergedMetadata,
      processingMode: _useAdvancedFeatures ? 'hybrid' : 'base_only',
    );
  }

  String _enrichWithBaseInfo(String advancedResponse, AdvancedAnalysis baseAnalysis) {
    var enriched = advancedResponse;

    if (baseAnalysis.entities.isNotEmpty && !enriched.contains('موجودیت')) {

      final entities = baseAnalysis.entities.take(3).map((e) => e.text).join('، ');
      enriched += '\n\n🏷️ **مفاهیم کلیدی شناسایی شده:** $entities';
    }

    // TF-IDF
    if (baseAnalysis.tfidfScores.isNotEmpty) {
      final topKeywords = baseAnalysis.tfidfScores.entries
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final keywords = topKeywords.take(5).map((e) => e.key).join('، ');
      enriched += '\n\n🔑 **کلمات کلیدی:** $keywords';
    }

    return enriched;
  }

  String _generateBaseResponse(AdvancedAnalysis baseAnalysis) {
    var response = '📚 بر اساس تحلیل:\n\n';

    response += '**نوع پرسش:** ${_translateClass(baseAnalysis.classification.classLabel)}\n';
    response += '**اطمینان:** ${(baseAnalysis.classification.confidence * 100).toStringAsFixed(0)}%\n\n';

    if (baseAnalysis.topics.isNotEmpty) {
      response += '**موضوعات مرتبط:**\n';
      for (var topic in baseAnalysis.topics.take(3)) {
        response += '• ${topic.keywords.join("، ")}\n';
      }
      response += '\n';
    }

    if (baseAnalysis.sentiment.sentiment != 'neutral') {
      response += '**تون کلی:** ${_translateSentiment(baseAnalysis.sentiment.sentiment)}\n\n';
    }

    return response;
  }

  String _translateClass(String classLabel) {
    const translations = {
      'definition': 'تعریف و مفهوم',
      'example': 'درخواست مثال',
      'explanation': 'توضیح و شرح',
      'comparison': 'مقایسه',
      'troubleshooting': 'رفع مشکل',
      'listing': 'فهرست‌سازی',
      'greeting': 'سلام و احوال‌پرسی',
    };
    return translations[classLabel] ?? classLabel;
  }

  String _translateSentiment(String sentiment) {
    const translations = {
      'positive': 'مثبت و خوشحال 😊',
      'negative': 'منفی یا ناامید 😟',
      'neutral': 'خنثی',
    };
    return translations[sentiment] ?? sentiment;
  }

  double _satisfactionToReward(double satisfaction) {
    return (satisfaction * 2) - 1;
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  void enableAdvancedFeatures(bool enable) {
    _useAdvancedFeatures = enable;
    print('🔧 حالت پیشرفته: ${enable ? "فعال ✅" : "غیرفعال ❌"}');
  }

  bool get isAdvancedMode => _useAdvancedFeatures;

  Map<String, dynamic> getSystemStats() {
    final baseStats = _baseEngine.getLearningStats();
    final advancedStats = _useAdvancedFeatures
        ? _advancedEngine.getAdvancedStats()
        : {};

    return {
      'initialized': _isInitialized,
      'advanced_mode': _useAdvancedFeatures,
      'base_engine': baseStats,
      'advanced_engine': advancedStats,
      'combined_capabilities': {
        'word2vec': true,
        'tfidf': true,
        'neural_network': true,
        'transformer': _useAdvancedFeatures,
        'bert_embeddings': _useAdvancedFeatures,
        'attention_mechanism': _useAdvancedFeatures,
        'reinforcement_learning': _useAdvancedFeatures,
        'meta_learning': _useAdvancedFeatures,
        'knowledge_graph': _useAdvancedFeatures,
      },
    };
  }

  String getDetailedStatusReport() {
    final stats = getSystemStats();

    return '''
╔══════════════════════════════════════════════════════════════╗
║          🧠 گزارش وضعیت سیستم ML/NLP ترکیبی                 ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  📊 وضعیت کلی:                                              ║
║  • حالت: ${_useAdvancedFeatures ? 'پیشرفته (Hybrid)' : 'پایه'}                                      ║
║  • آماده‌سازی: ${_isInitialized ? 'کامل ✅' : 'در انتظار ⏳'}                              ║
║                                                              ║
║  🔧 قابلیت‌های فعال:                                         ║
║  • Word2Vec Embeddings: ✅                                   ║
║  • TF-IDF Analysis: ✅                                       ║
║  • Neural Network: ✅                                        ║
║  • Transformer: ${_useAdvancedFeatures ? '✅' : '❌'}                                       ║
║  • BERT-like Encoder: ${_useAdvancedFeatures ? '✅' : '❌'}                                 ║
║  • Attention Mechanism: ${_useAdvancedFeatures ? '✅' : '❌'}                               ║
║  • Knowledge Graph: ${_useAdvancedFeatures ? '✅' : '❌'}                                   ║
║  • Reinforcement Learning: ${_useAdvancedFeatures ? '✅' : '❌'}                            ║
║  • Meta-Learning: ${_useAdvancedFeatures ? '✅' : '❌'}                                     ║
║                                                              ║
║  📈 آمار یادگیری:                                           ║
║  • حجم واژگان: ${stats['base_engine']['vocabulary_size']} کلمه                     ║
║  • نمونه‌های آموزشی: ${stats['base_engine']['training_examples']}                           ║
║  • دقت شبکه عصبی: ${(stats['base_engine']['neural_net_accuracy'] * 100).toStringAsFixed(1)}%                         ║
${_useAdvancedFeatures ? '''║  • اندازه Knowledge Graph: ${stats['advanced_engine']['knowledge_graph_size']} موجودیت             ║
║  • آیتم‌های حافظه: ${stats['advanced_engine']['memory_items']}                              ║
║  • لایه‌های Transformer: ${stats['advanced_engine']['transformer_layers']}                            ║''' : ''}
║                                                              ║
║  💡 عملکرد:                                                  ║
║  • میانگین رضایت: ${(stats['base_engine']['avg_satisfaction'] * 100).toStringAsFixed(1)}%                           ║
║  • موضوعات یادگرفته: ${stats['base_engine']['learned_topics']}                              ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  🚀 این سیستم ترکیبی بهترین الگوریتم‌های ML/NLP را          ║
║     برای ارائه پاسخ‌های هوشمند یکپارچه می‌کند.              ║
╚══════════════════════════════════════════════════════════════╝
''';
  }
}

class HybridAnalysisResult {
  final AdvancedAnalysis baseAnalysis;
  final UltraAdvancedAnalysis? advancedAnalysis;
  final double finalConfidence;
  final List<String> mergedInsights;
  final Map<String, dynamic> metadata;
  final String processingMode;

  HybridAnalysisResult({
    required this.baseAnalysis,
    this.advancedAnalysis,
    required this.finalConfidence,
    required this.mergedInsights,
    required this.metadata,
    required this.processingMode,
  });

  bool get usedAdvancedEngine => advancedAnalysis != null;

  String getSummary() {
    return '''
🔍 خلاصه تحلیل:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 حالت پردازش: $processingMode
🎯 اطمینان نهایی: ${(finalConfidence * 100).toStringAsFixed(1)}%

${usedAdvancedEngine ? '''
🧠 نتایج پیشرفته:
  • Intent‌ها: ${advancedAnalysis!.intents.map((i) => i.label).join(", ")}
  • موضوع گفتگو: ${advancedAnalysis!.dialogueState.currentTopic}
  • حالت کاربر: ${advancedAnalysis!.dialogueState.userMood}
  • استنتاج‌های معنایی: ${advancedAnalysis!.reasoning.inferences.length}
  • زنجیره‌های ارجاع: ${advancedAnalysis!.coreferences.chains.length}
''' : ''}
📚 نتایج پایه:
  • طبقه‌بندی: ${baseAnalysis.classification.classLabel}
  • احساسات: ${baseAnalysis.sentiment.sentiment}
  • موجودیت‌ها: ${baseAnalysis.entities.length}
  • موضوعات: ${baseAnalysis.topics.length}

💡 بینش‌ها:
${mergedInsights.map((i) => '  • $i').join('\n')}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }
}
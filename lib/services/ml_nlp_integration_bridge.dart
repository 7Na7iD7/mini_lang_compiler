import 'dart:math';
import 'ml_nlp_engine.dart';
import 'advanced_ml_nlp_engine.dart';
export 'advanced_ml_nlp_engine.dart' show ResponseStrategy;

/// This bridge integrates two engines:

/// 1. **Base Engine**: Classical NLP algorithms
///    - TF-IDF, Naive Bayes, VADER, etc.
///    - Fast and reliable for most queries

/// 2. **Advanced Engine**: Modern NLP techniques
///    - Skip-gram embeddings, Attention, MaxEnt
///    - More sophisticated analysis


class MLNLPIntegrationBridge {
  static final MLNLPIntegrationBridge _instance = MLNLPIntegrationBridge._internal();
  factory MLNLPIntegrationBridge() => _instance;

  MLNLPIntegrationBridge._internal();

  late final MLNLPEngine _baseEngine;
  late final AdvancedMLNLPEngine _advancedEngine;

  bool _isInitialized = false;
  bool _useAdvancedFeatures = true;

  // Performance tracking
  int _baseEngineUsage = 0;
  int _advancedEngineUsage = 0;
  int _hybridUsage = 0;

  Future<void> initialize() async {
    if (_isInitialized) return;

    print('\n╔═══════════════════════════════════════════════════════════╗');
    print('║  🌉 ML/NLP Integration Bridge Initialization             ║');
    print('╚═══════════════════════════════════════════════════════════╝\n');

    try {
      _baseEngine = MLNLPEngine();
      _advancedEngine = AdvancedMLNLPEngine();

      _isInitialized = true;

      print('╔═══════════════════════════════════════════════════════════╗');
      print('║  ✅ Integration Bridge Ready                              ║');
      print('╠═══════════════════════════════════════════════════════════╣');
      print('║                                                           ║');
      print('║  📊 Dual-Engine Architecture:                            ║');
      print('║                                                           ║');
      print('║  ┌────────────────────────────────────────────┐          ║');
      print('║  │  User Query                                │          ║');
      print('║  └──────────────┬─────────────────────────────┘          ║');
      print('║                 │                                         ║');
      print('║                 ▼                                         ║');
      print('║  ┌──────────────────────────────────────────────┐        ║');
      print('║  │  Query Analyzer (Complexity Detection)       │        ║');
      print('║  └──────────┬──────────────────────┬────────────┘        ║');
      print('║             │                      │                     ║');
      print('║    Simple   │                      │   Complex           ║');
      print('║             ▼                      ▼                     ║');
      print('║  ┌─────────────────┐    ┌────────────────────┐          ║');
      print('║  │ 🔬 Base Engine  │    │ 🧬 Advanced Engine │          ║');
      print('║  │                 │    │                    │          ║');
      print('║  │ • TF-IDF        │    │ • Skip-gram        │          ║');
      print('║  │ • Naive Bayes   │    │ • Attention        │          ║');
      print('║  │ • VADER         │    │ • MaxEnt           │          ║');
      print('║  │ • Rule NER      │    │ • PMI              │          ║');
      print('║  │                 │    │ • Dependency Parse │          ║');
      print('║  └─────────────────┘    └────────────────────┘          ║');
      print('║             │                      │                     ║');
      print('║             └──────────┬───────────┘                     ║');
      print('║                        ▼                                 ║');
      print('║             ┌──────────────────────┐                     ║');
      print('║             │  Result Fusion       │                     ║');
      print('║             └──────────────────────┘                     ║');
      print('║                                                           ║');
      print('╚═══════════════════════════════════════════════════════════╝\n');

    } catch (e) {
      print('❌ Initialization error: $e');
      rethrow;
    }
  }

  Future<HybridAnalysisResult> analyzeMessage({
    required String message,
    required List<String> conversationHistory,
    Map<String, dynamic>? userProfile,
  }) async {
    await _ensureInitialized();

    print('\n🔬 Hybrid Analysis Started...');
    final startTime = DateTime.now();

    try {

      // Step 1: Always run base engine (fast and reliable)
      print('\n📊 Stage 1/3: Base Engine Analysis...');
      final baseMLResult = await _baseEngine.analyzeMessage(
        message: message,
        conversationHistory: conversationHistory,
      );

      final baseAnalysis = AdvancedAnalysis(
        mlResult: baseMLResult,
        topics: baseMLResult.topics,
        entities: baseMLResult.entities,
        tfidfScores: baseMLResult.tfidfScores,
        classification: baseMLResult.classification,
        sentiment: baseMLResult.sentiment,
      );

      print('  ✓ Base analysis complete');

      // Step 2: Decide if advanced engine is needed

      final complexity = _assessQueryComplexity(message, baseAnalysis);
      print('\n📈 Query complexity: ${complexity.toStringAsFixed(2)}');

      UltraAdvancedAnalysis? advancedAnalysis;

      if (_useAdvancedFeatures && complexity > 0.5) {
        print('\n🧬 Stage 2/3: Advanced Engine Analysis...');

        final nlpResult = await _advancedEngine.analyzeText(
          message,
          conversationHistory: conversationHistory,
          userProfile: userProfile,
        );

        advancedAnalysis = UltraAdvancedAnalysis(
          intents: nlpResult.classification != null
              ? [Intent(
            label: nlpResult.classification.label,
            confidence: nlpResult.classification.confidence,
          )]
              : [],
          dialogueState: DialogueState(
            currentTopic: _inferTopic(baseMLResult),
            userMood: _inferMood(baseMLResult.sentiment),
            discussedTopics: conversationHistory.take(5).toList(),
            turnCount: conversationHistory.length,
          ),
          reasoning: SemanticReasoning(
            inferences: nlpResult.inferences,
            assumptions: [],
            confidence: nlpResult.confidence,
          ),
          coreferences: CoreferenceResolution(chains: []),
          relevantMemories: _retrieveMemories(baseMLResult),
        );

        print('  ✓ Advanced analysis complete');
        _advancedEngineUsage++;
      } else {
        print('\n⏭️  Stage 2/3: Skipped (using base engine only)');
        _baseEngineUsage++;
      }

      // Step 3: Merge results

      print('\n🔀 Stage 3/3: Merging results...');
      final hybridResult = _mergeAnalysisResults(
        baseAnalysis: baseAnalysis,
        advancedAnalysis: advancedAnalysis,
      );

      final processingTime = DateTime.now().difference(startTime);
      print('  ✓ Merge complete');
      print('\n⏱️  Total time: ${processingTime.inMilliseconds}ms');
      print('📊 Engine usage: ${advancedAnalysis != null ? "Hybrid" : "Base only"}\n');

      if (advancedAnalysis != null) {
        _hybridUsage++;
      }

      return hybridResult;

    } catch (e, stackTrace) {
      print('\n❌ Analysis error: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  double _assessQueryComplexity(String message, AdvancedAnalysis baseAnalysis) {
    double complexity = 0.0;

    // Length-based complexity
    final wordCount = message.split(RegExp(r'\s+')).length;
    if (wordCount > 15) complexity += 0.2;
    if (wordCount > 30) complexity += 0.2;

    // Entity-based complexity
    if (baseAnalysis.entities.length > 2) complexity += 0.2;

    // Classification-based complexity
    if (baseAnalysis.classification.classLabel == 'comparison') {
      complexity += 0.3;
    } else if (baseAnalysis.classification.classLabel == 'explanation') {
      complexity += 0.2;
    }

    // Question complexity
    if (message.contains('?') && message.split('?').length > 1) {
      complexity += 0.2;
    }

    return complexity.clamp(0.0, 1.0);
  }

  String _inferTopic(MLAnalysisResult result) {
    if (result.entities.isNotEmpty) {
      return result.entities.first.text;
    }
    if (result.topics.isNotEmpty) {
      return result.topics.first.name;
    }
    return result.classification.classLabel;
  }

  String _inferMood(SentimentScore sentiment) {
    if (sentiment.score > 0.5) return 'happy';
    if (sentiment.score < -0.5) return 'frustrated';
    return 'neutral';
  }

  List<Memory> _retrieveMemories(MLAnalysisResult result) {
    return result.similarMemories
        .map((m) => Memory(
      content: m.content,
      relevance: m.similarity,
      timestamp: m.timestamp,
    ))
        .toList();
  }

  Future<String> generateSmartResponse({
    required HybridAnalysisResult analysis,
    ResponseStrategy strategy = ResponseStrategy.balanced,
  }) async {
    print('\n🎨 Generating smart response...');

    String response;

    if (_useAdvancedFeatures && analysis.advancedAnalysis != null) {
      print('  → Using advanced engine for response');

      final advancedResponse = await _advancedEngine.generateResponse(
        NLPAnalysisResult(
          tokens: analysis.baseAnalysis.mlResult.tokens,
          embeddings: [],
          attentionWeights: [],
          attentionContext: [],
          dependencies: [],
          classification: MaxEntClassification(
            label: analysis.baseAnalysis.classification.classLabel,
            confidence: analysis.baseAnalysis.classification.confidence,
            labelIndex: 0,
            probabilities: {},
          ),
          bm25Scores: [],
          semanticPairs: [],
          knowledgeFacts: [],
          inferences: analysis.advancedAnalysis!.reasoning.inferences,
          processingTimeMs: 0,
          confidence: analysis.finalConfidence,
        ),
        strategy: strategy,
      );

      response = advancedResponse.text;
      response = _enrichWithBaseInfo(response, analysis.baseAnalysis);

      // Add follow-ups
      final followUps = _generateFollowUps(analysis);
      if (followUps.isNotEmpty) {
        response += '\n\n💭 **پیشنهادات:**\n';
        for (var suggestion in followUps.take(3)) {
          response += '• $suggestion\n';
        }
      }

    } else {
      print('  → Using base engine for response');
      response = _generateBaseResponse(analysis.baseAnalysis);
    }

    print('  ✓ Response generated (${response.length} chars)');
    return response;
  }

  String _enrichWithBaseInfo(String response, AdvancedAnalysis baseAnalysis) {
    var enriched = response;

    if (baseAnalysis.entities.isNotEmpty && !enriched.contains('موجودیت')) {
      final entities = baseAnalysis.entities.take(3).map((e) => e.text).join('، ');
      enriched += '\n\n🏷️ **مفاهیم کلیدی:** $entities';
    }

    if (baseAnalysis.tfidfScores.isNotEmpty) {
      final topKeywords = baseAnalysis.tfidfScores.entries.toList()
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
      'technical': 'فنی',
      'procedural': 'رویه‌ای',
      'general': 'عمومی',
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

  List<String> _generateFollowUps(HybridAnalysisResult analysis) {
    final followUps = <String>[];
    final classLabel = analysis.baseAnalysis.classification.classLabel;

    if (classLabel == 'definition') {
      followUps.add('می‌خوای مثالی ازش بزنم?');
      followUps.add('کاربردش کجاست?');
    } else if (classLabel == 'example') {
      followUps.add('می‌خوای توضیح بیشتری بدم?');
      followUps.add('مثال پیچیده‌تر می‌خوای?');
    } else if (classLabel == 'comparison') {
      followUps.add('می‌خوای جزئیات بیشتری بدم?');
      followUps.add('چه استفاده‌ای برات مناسب‌تره?');
    }

    return followUps;
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

      // Weighted combination
      finalConfidence = (baseConfidence * 0.4) + (advancedConfidence * 0.6);

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
      processingMode: _useAdvancedFeatures && advancedAnalysis != null ? 'hybrid' : 'base_only',
      usedAdvancedEngine: advancedAnalysis != null,
    );
  }

  Future<void> learnFromInteraction({
    required String userMessage,
    required String assistantResponse,
    required double userSatisfaction,
    String? feedbackComment,
  }) async {
    print('\n📚 Learning from interaction...');

    await _baseEngine.learnFromInteraction(
      userMessage: userMessage,
      assistantResponse: assistantResponse,
      userSatisfaction: userSatisfaction,
    );
    print('  ✓ Base engine updated');

    if (_useAdvancedFeatures) {
      final reward = (userSatisfaction * 2) - 1;
      // Scale to [-1, 1]
      await _advancedEngine.learnFromFeedback(
        input: userMessage,
        response: assistantResponse,
        reward: reward,
      );
      print('  ✓ Advanced engine updated');
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  void enableAdvancedFeatures(bool enable) {
    _useAdvancedFeatures = enable;
    print('🔧 Advanced mode: ${enable ? "ENABLED ✅" : "DISABLED ❌"}');
  }

  bool get isAdvancedMode => _useAdvancedFeatures;

  Map<String, dynamic> getSystemStats() {
    final baseStats = _baseEngine.getStatistics();
    final advancedStats = _advancedEngine.getStatistics();

    return {
      'initialized': _isInitialized,
      'advanced_mode': _useAdvancedFeatures,
      'usage_stats': {
        'base_only': _baseEngineUsage,
        'advanced_only': _advancedEngineUsage,
        'hybrid': _hybridUsage,
        'total': _baseEngineUsage + _advancedEngineUsage + _hybridUsage,
      },
      'base_engine': {
        'vocabulary_size': baseStats['vocab_size'],
        'training_examples': baseStats['training_examples'],
        'success_rate': baseStats['success_rate'],
        'avg_satisfaction': baseStats['avg_satisfaction'],
      },
      'advanced_engine': {
        'vocabulary_size': advancedStats['vocabulary_size'],
        'knowledge_facts': advancedStats['knowledge_facts'],
        'total_analyses': advancedStats['total_analyses'],
        'avg_confidence': advancedStats['avg_confidence'],
      },
    };
  }

  String getDetailedStatusReport() {
    final stats = getSystemStats();
    final usage = stats['usage_stats'];

    return '''
╔═══════════════════════════════════════════════════════════╗
║  🧠 ML/NLP Integration Bridge Status Report              ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  📊 System Status:                                        ║
║  • Mode: ${stats['advanced_mode'] ? 'Hybrid (Base + Advanced)' : 'Base Only'}                           ║
║  • Initialized: ${stats['initialized'] ? '✅' : '❌'}                                        ║
║                                                           ║
║  📈 Usage Statistics:                                     ║
║  • Base Only: ${usage['base_only']}                                             ║
║  • Hybrid: ${usage['hybrid']}                                                ║
║  • Total Queries: ${usage['total']}                                         ║
║                                                           ║
║  🔬 Base Engine:                                          ║
║  • Vocabulary: ${stats['base_engine']['vocabulary_size']} words                              ║
║  • Training Examples: ${stats['base_engine']['training_examples']}                           ║
║  • Success Rate: ${(stats['base_engine']['success_rate'] * 100).toStringAsFixed(1)}%                                ║
║  • Avg Satisfaction: ${(stats['base_engine']['avg_satisfaction'] * 100).toStringAsFixed(1)}%                          ║
║                                                           ║
║  🧬 Advanced Engine:                                      ║
║  • Vocabulary: ${stats['advanced_engine']['vocabulary_size']} words                              ║
║  • Knowledge Facts: ${stats['advanced_engine']['knowledge_facts']}                              ║
║  • Total Analyses: ${stats['advanced_engine']['total_analyses']}                                ║
║  • Avg Confidence: ${(stats['advanced_engine']['avg_confidence'] * 100).toStringAsFixed(1)}%                            ║
║                                                           ║
║  🎯 Algorithms in Use:                                    ║
║  Base: TF-IDF, Naive Bayes, VADER, Cosine Similarity     ║
║  Advanced: Skip-gram, Attention, MaxEnt, BM25, PMI        ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
''';
  }
}

class AdvancedAnalysis {
  final MLAnalysisResult mlResult;
  final List<Topic> topics;
  final List<NamedEntity> entities;
  final Map<String, double> tfidfScores;
  final ClassificationResult classification;
  final SentimentScore sentiment;

  AdvancedAnalysis({
    required this.mlResult,
    required this.topics,
    required this.entities,
    required this.tfidfScores,
    required this.classification,
    required this.sentiment,
  });
}

class UltraAdvancedAnalysis {
  final List<Intent> intents;
  final DialogueState dialogueState;
  final SemanticReasoning reasoning;
  final CoreferenceResolution coreferences;
  final List<Memory> relevantMemories;

  UltraAdvancedAnalysis({
    required this.intents,
    required this.dialogueState,
    required this.reasoning,
    required this.coreferences,
    required this.relevantMemories,
  });
}

class DialogueState {
  final String currentTopic;
  final String userMood;
  final List<String> discussedTopics;
  final int turnCount;

  DialogueState({
    required this.currentTopic,
    required this.userMood,
    required this.discussedTopics,
    required this.turnCount,
  });
}

class SemanticReasoning {
  final List<String> inferences;
  final List<String> assumptions;
  final double confidence;

  SemanticReasoning({
    required this.inferences,
    required this.assumptions,
    required this.confidence,
  });
}

class CoreferenceResolution {
  final List<CoreferenceChain> chains;

  CoreferenceResolution({required this.chains});
}

class CoreferenceChain {
  final List<String> mentions;
  final String representative;

  CoreferenceChain({
    required this.mentions,
    required this.representative,
  });
}

class Memory {
  final String content;
  final double relevance;
  final DateTime timestamp;

  Memory({
    required this.content,
    required this.relevance,
    required this.timestamp,
  });
}

class Intent {
  final String label;
  final double confidence;

  Intent({required this.label, required this.confidence});
}

class HybridAnalysisResult {
  final AdvancedAnalysis baseAnalysis;
  final UltraAdvancedAnalysis? advancedAnalysis;
  final double finalConfidence;
  final List<String> mergedInsights;
  final Map<String, dynamic> metadata;
  final String processingMode;
  final bool usedAdvancedEngine;

  HybridAnalysisResult({
    required this.baseAnalysis,
    this.advancedAnalysis,
    required this.finalConfidence,
    required this.mergedInsights,
    required this.metadata,
    required this.processingMode,
    required this.usedAdvancedEngine,
  });

  String getSummary() {
    return '''
📋 خلاصه تحلیل:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 حالت پردازش: $processingMode
🎯 اطمینان نهایی: ${(finalConfidence * 100).toStringAsFixed(1)}%

${usedAdvancedEngine ? '''
🧬 نتایج پیشرفته:
  • Intent‌ها: ${advancedAnalysis!.intents.map((i) => i.label).join(", ")}
  • موضوع گفتگو: ${advancedAnalysis!.dialogueState.currentTopic}
  • حالت کاربر: ${advancedAnalysis!.dialogueState.userMood}
  • استنتاج‌های معنایی: ${advancedAnalysis!.reasoning.inferences.length}
''' : ''}
📚 نتایج پایه:
  • طبقه‌بندی: ${baseAnalysis.classification.classLabel}
  • احساسات: ${baseAnalysis.sentiment.sentiment}
  • موجودیت‌ها: ${baseAnalysis.entities.length}
  • موضوعات: ${baseAnalysis.topics.length}

💡 بینش‌ها:
${mergedInsights.map((i) => '  • $i').join('\n')}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }
}
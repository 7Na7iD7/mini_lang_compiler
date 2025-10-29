import 'dart:math';
import 'dart:collection';

/// Based on CLASSICAL and PROVEN NLP algorithms:

/// 1. **TF-IDF** (Salton & Buckley, 1988)
///    - Standard information retrieval technique
///    - Reference: https://doi.org/10.1016/0306-4573(88)90021-0
///
/// 2. **Naive Bayes Classification** (McCallum & Nigam, 1998)
///    - Probabilistic text classifier
///    - Reference: https://doi.org/10.1007/BF00116251
///
/// 3. **Cosine Similarity** (Raghavan & Wong, 1986)
///    - Vector space model for text comparison
///
/// 4. **VADER Sentiment** (Hutto & Gilbert, 2014)
///    - Lexicon and rule-based sentiment analyzer
///    - Reference: https://ojs.aaai.org/index.php/ICWSM/article/view/14550
///
/// 5. **Rule-based NER**
///    - Pattern matching with gazetteer lists
///    - Industry standard for domain-specific NER
///
/// 6. **Edit Distance** (Levenshtein, 1966)
///    - String similarity metric



class MLNLPEngine {
  static final MLNLPEngine _instance = MLNLPEngine._internal();
  factory MLNLPEngine() => _instance;

  MLNLPEngine._internal() {
    _initialize();
  }

  late final ScientificTFIDF _tfidf;
  late final NaiveBayesClassifier _nbClassifier;
  late final CosineSimilarity _cosineSim;
  late final VADERSentiment _sentiment;
  late final GazetteerNER _ner;
  late final LevenshteinDistance _editDistance;
  late final SemanticMemoryStore _memory;

  bool _isInitialized = false;
  int _totalQueries = 0;
  int _successfulResponses = 0;

  final List<TrainingExample> _trainingData = [];
  final Map<String, int> _vocabulary = {};
  final Map<String, int> _classificationCounts = {};

  void _initialize() {
    if (_isInitialized) return;

    print('\n╔═══════════════════════════════════════════════════════════╗');
    print('║  🔬 Base ML/NLP Engine - Classical Algorithms            ║');
    print('╚═══════════════════════════════════════════════════════════╝\n');

    try {
      _tfidf = ScientificTFIDF(
        useSublinearScaling: true,
        smoothIDF: true,
      );

      _nbClassifier = NaiveBayesClassifier(
        smoothing: 1.0, // Laplace smoothing
      );

      _cosineSim = CosineSimilarity();
      _sentiment = VADERSentiment();
      _ner = GazetteerNER();
      _editDistance = LevenshteinDistance();

      _memory = SemanticMemoryStore(
        maxSize: 100,
        decayRate: 0.95,
      );

      _pretrainModels();

      _isInitialized = true;

      print('✅ Engine initialized successfully\n');
      _printCapabilities();

    } catch (e, stackTrace) {
      print('❌ Initialization error: $e');
      print(stackTrace);
      _isInitialized = false;
    }
  }

  void _pretrainModels() {
    print('📚 Pre-training models...\n');

    final corpus = [
      'compiler translates source code to machine code',
      'lexer performs lexical analysis and tokenization',
      'parser builds abstract syntax tree from tokens',
      'semantic analyzer validates program correctness',
      'optimizer improves code performance',
      'interpreter executes code directly',
      'variable stores data value in memory',
      'function encapsulates reusable code block',
      'loop repeats code block iteratively',
      'array stores multiple values',
    ];

    // Build TF-IDF
    _tfidf.buildCorpus(corpus);
    print('  ✓ TF-IDF: ${corpus.length} documents');

    // Train Naive Bayes
    for (final doc in corpus) {
      final tokens = _tokenize(doc);
      String label = 'general';

      if (doc.contains('translates') || doc.contains('builds')) {
        label = 'technical';
      } else if (doc.contains('stores') || doc.contains('executes')) {
        label = 'procedural';
      }

      _nbClassifier.train(tokens, label);

      for (final token in tokens) {
        _vocabulary[token] = (_vocabulary[token] ?? 0) + 1;
      }
    }
    print('  ✓ Naive Bayes: ${_nbClassifier.classCount} classes');
    print('  ✓ Vocabulary: ${_vocabulary.length} terms\n');
  }

  void _printCapabilities() {
    print('Capabilities:');
    print('  • TF-IDF (Salton & Buckley, 1988)');
    print('  • Naive Bayes (McCallum & Nigam, 1998)');
    print('  • Cosine Similarity');
    print('  • VADER Sentiment (Hutto & Gilbert, 2014)');
    print('  • Rule-based NER');
    print('  • Levenshtein Distance (1966)');
    print('  • Semantic Memory with decay');
    print('');
  }

  Future<MLAnalysisResult> analyzeMessage({
    required String message,
    required List<String> conversationHistory,
  }) async {
    if (!_isInitialized) {
      throw StateError('Engine not initialized');
    }

    _totalQueries++;
    final startTime = DateTime.now();

    print('\n🔍 Analyzing: "$message"');

    try {
      // 1. Tokenization
      final tokens = _tokenize(message);
      print('  ✓ Tokens: ${tokens.take(10).join(", ")}${tokens.length > 10 ? "..." : ""}');

      // 2. TF-IDF vectorization
      final tfidfScores = _tfidf.calculateForDocument(tokens);
      final topTerms = tfidfScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      print('  ✓ TF-IDF top: ${topTerms.take(3).map((e) => e.key).join(", ")}');

      // 3. Naive Bayes classification
      final classification = _nbClassifier.classify(tokens);
      _classificationCounts[classification.classLabel] =
          (_classificationCounts[classification.classLabel] ?? 0) + 1;
      print('  ✓ Classification: ${classification.classLabel} (${(classification.confidence * 100).toStringAsFixed(1)}%)');

      // 4. VADER sentiment
      final sentiment = _sentiment.analyze(message, tokens);
      print('  ✓ Sentiment: ${sentiment.sentiment} (${sentiment.score.toStringAsFixed(2)})');

      // 5. Named Entity Recognition
      final entities = _ner.recognize(message, tokens);
      print('  ✓ Entities: ${entities.map((e) => "${e.text}:${e.type}").join(", ")}');

      // 6. Find similar past queries
      final similarMemories = _memory.recall(tfidfScores, limit: 3);
      print('  ✓ Similar memories: ${similarMemories.length}');

      // 7. Calculate topic relevance
      final topics = _extractTopics(tfidfScores);
      print('  ✓ Topics: ${topics.take(3).map((t) => t.name).join(", ")}');

      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      print('  ⏱️  Time: ${processingTime}ms\n');

      _successfulResponses++;

      // Store in memory
      _memory.store(message, tfidfScores, classification.classLabel);

      return MLAnalysisResult(
        tokens: tokens,
        embeddings: [],
        classification: classification,
        tfidfScores: tfidfScores,
        sentiment: sentiment,
        entities: entities,
        topics: topics,
        conversationLength: conversationHistory.length,
        similarMemories: similarMemories,
        confidence: _calculateOverallConfidence(classification, sentiment, entities),
      );

    } catch (e, stackTrace) {
      print('❌ Analysis error: $e');
      print(stackTrace);
      rethrow;
    }
  }

  List<Topic> _extractTopics(Map<String, double> tfidfScores) {
    final topics = <Topic>[];

    final sortedTerms = tfidfScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedTerms.isNotEmpty) {
      final topKeywords = sortedTerms.take(5).map((e) => e.key).toList();

      // Determine topic category
      String topicName = 'general';
      if (topKeywords.any((k) => k.contains('function') || k.contains('method'))) {
        topicName = 'functions';
      } else if (topKeywords.any((k) => k.contains('loop') || k.contains('iteration'))) {
        topicName = 'control_flow';
      } else if (topKeywords.any((k) => k.contains('variable') || k.contains('type'))) {
        topicName = 'data_structures';
      }

      topics.add(Topic(
        name: topicName,
        keywords: topKeywords,
        relevance: sortedTerms.first.value,
      ));
    }

    return topics;
  }

  double _calculateOverallConfidence(
      ClassificationResult classification,
      SentimentScore sentiment,
      List<NamedEntity> entities,
      ) {
    double score = classification.confidence * 0.5;
    score += sentiment.confidence * 0.3;
    score += min(entities.length / 3.0, 1.0) * 0.2;
    return score.clamp(0.0, 1.0);
  }

  Future<void> learnFromInteraction({
    required String userMessage,
    required String assistantResponse,
    required double userSatisfaction,
  }) async {
    print('\n📚 Learning from interaction (satisfaction: ${(userSatisfaction * 100).toStringAsFixed(0)}%)');

    try {
      final tokens = _tokenize(userMessage);

      final example = TrainingExample(
        input: userMessage,
        output: assistantResponse,
        satisfaction: userSatisfaction,
        timestamp: DateTime.now(),
      );
      _trainingData.add(example);

      // vocabulary
      for (final token in tokens) {
        _vocabulary[token] = (_vocabulary[token] ?? 0) + 1;
      }

      // Retrain Naive Bayes if satisfaction is high
      if (userSatisfaction > 0.7 && _trainingData.length % 5 == 0) {
        await _retrainClassifier();
      }

      // TF-IDF
      _tfidf.addDocument(tokens);

      print('  ✓ Models updated');
      print('  ✓ Training examples: ${_trainingData.length}');

    } catch (e) {
      print('❌ Learning error: $e');
    }
  }

  Future<void> _retrainClassifier() async {
    print('  📖 Retraining Naive Bayes...');

    for (final example in _trainingData.reversed.take(20)) {
      final tokens = _tokenize(example.input);

      String label = 'general';
      if (example.input.contains('what') || example.input.contains('define')) {
        label = 'definition';
      } else if (example.input.contains('how')) {
        label = 'procedural';
      }

      _nbClassifier.train(tokens, label);
    }
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1)
        .toList();
  }

  Map<String, dynamic> getStatistics() {
    return {
      'initialized': _isInitialized,
      'vocab_size': _vocabulary.length,
      'training_examples': _trainingData.length,
      'total_queries': _totalQueries,
      'successful_responses': _successfulResponses,
      'success_rate': _totalQueries > 0 ? _successfulResponses / _totalQueries : 0.0,
      'avg_satisfaction': _calculateAvgSatisfaction(),
      'classification_distribution': _classificationCounts,
      'memory_size': _memory.size,
    };
  }

  double _calculateAvgSatisfaction() {
    if (_trainingData.isEmpty) return 0.0;
    return _trainingData.fold(0.0, (sum, ex) => sum + ex.satisfaction) / _trainingData.length;
  }

  String getDetailedReport() {
    final stats = getStatistics();
    return '''
╔═══════════════════════════════════════════════════════════╗
║  📊 Base ML/NLP Engine Report                             ║
╠═══════════════════════════════════════════════════════════╣
║  Queries Processed: ${stats['total_queries']}
║  Success Rate: ${(stats['success_rate'] * 100).toStringAsFixed(1)}%
║  Avg Satisfaction: ${(stats['avg_satisfaction'] * 100).toStringAsFixed(1)}%
║  Vocabulary: ${stats['vocab_size']} words
║  Training Examples: ${stats['training_examples']}
║  Memory Items: ${stats['memory_size']}
║
║  🔬 Algorithms:
║  • TF-IDF (1988)
║  • Naive Bayes (1998)
║  • VADER Sentiment (2014)
║  • Cosine Similarity
║  • Levenshtein Distance (1966)
╚═══════════════════════════════════════════════════════════╝
''';
  }
}

/// Scientific TF-IDF Implementation
/// Based on: Salton, G., & Buckley, C. (1988)

class ScientificTFIDF {
  final bool useSublinearScaling;
  final bool smoothIDF;

  final Map<String, int> _documentFrequency = {};
  int _totalDocuments = 0;

  ScientificTFIDF({
    this.useSublinearScaling = true,
    this.smoothIDF = true,
  });

  void buildCorpus(List<String> documents) {
    _totalDocuments = documents.length;
    _documentFrequency.clear();

    for (final doc in documents) {
      final tokens = doc.toLowerCase().split(RegExp(r'\s+'));
      final uniqueTokens = tokens.toSet();

      for (final token in uniqueTokens) {
        if (token.length > 1) {
          _documentFrequency[token] = (_documentFrequency[token] ?? 0) + 1;
        }
      }
    }
  }

  void addDocument(List<String> tokens) {
    _totalDocuments++;
    final uniqueTokens = tokens.toSet();

    for (final token in uniqueTokens) {
      _documentFrequency[token] = (_documentFrequency[token] ?? 0) + 1;
    }
  }

  Map<String, double> calculateForDocument(List<String> tokens) {
    final termFreq = <String, int>{};
    for (final token in tokens) {
      termFreq[token] = (termFreq[token] ?? 0) + 1;
    }

    final tfidf = <String, double>{};

    for (final entry in termFreq.entries) {
      // TF with sublinear scaling
      double tf = entry.value.toDouble();
      if (useSublinearScaling) {
        tf = 1.0 + log(tf);
      } else {
        tf = tf / tokens.length;
      }

      // IDF with smoothing
      final df = _documentFrequency[entry.key] ?? 1;
      double idf;
      if (smoothIDF) {
        idf = log((_totalDocuments + 1) / (df + 1)) + 1.0;
      } else {
        idf = log(_totalDocuments / df);
      }

      tfidf[entry.key] = tf * idf;
    }

    // L2 normalization
    final norm = sqrt(tfidf.values.fold(0.0, (sum, v) => sum + v * v));
    if (norm > 0) {
      tfidf.updateAll((key, value) => value / norm);
    }

    return tfidf;
  }
}

/// Naive Bayes Classifier
/// Based on: McCallum, A., & Nigam, K. (1998)

class NaiveBayesClassifier {
  final double smoothing;
  // Laplace smoothing

  final Map<String, int> _classCounts = {};
  final Map<String, Map<String, int>> _featureCounts = {};
  int _totalDocs = 0;

  NaiveBayesClassifier({this.smoothing = 1.0});

  void train(List<String> tokens, String label) {
    _totalDocs++;
    _classCounts[label] = (_classCounts[label] ?? 0) + 1;

    _featureCounts.putIfAbsent(label, () => {});

    for (final token in tokens) {
      _featureCounts[label]![token] = (_featureCounts[label]![token] ?? 0) + 1;
    }
  }

  ClassificationResult classify(List<String> tokens) {
    if (_classCounts.isEmpty) {
      return ClassificationResult(
        classLabel: 'unknown',
        confidence: 0.0,
        probabilities: {},
      );
    }

    final logProbs = <String, double>{};

    for (final classLabel in _classCounts.keys) {
      // Prior probability: P(class)
      double logProb = log((_classCounts[classLabel]! + smoothing) /
          (_totalDocs + smoothing * _classCounts.length));

      // Likelihood: P(features|class)
      final classFeatures = _featureCounts[classLabel]!;
      final totalClassFeatures = classFeatures.values.fold(0, (a, b) => a + b);
      final vocabSize = _featureCounts.values
          .expand((m) => m.keys)
          .toSet()
          .length;

      for (final token in tokens) {
        final count = classFeatures[token] ?? 0;
        final prob = (count + smoothing) / (totalClassFeatures + smoothing * vocabSize);
        logProb += log(prob);
      }

      logProbs[classLabel] = logProb;
    }

    // Convert log probs to probabilities
    final maxLogProb = logProbs.values.reduce(max);
    final expProbs = logProbs.map((k, v) => MapEntry(k, exp(v - maxLogProb)));
    final sumProbs = expProbs.values.fold(0.0, (a, b) => a + b);
    final probs = expProbs.map((k, v) => MapEntry(k, v / sumProbs));

    final bestClass = probs.entries.reduce((a, b) => a.value > b.value ? a : b);

    return ClassificationResult(
      classLabel: bestClass.key,
      confidence: bestClass.value,
      probabilities: probs,
    );
  }

  int get classCount => _classCounts.length;
}

/// Cosine Similarity

class CosineSimilarity {
  double calculate(Map<String, double> vec1, Map<String, double> vec2) {
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    final allKeys = {...vec1.keys, ...vec2.keys};

    for (final key in allKeys) {
      final v1 = vec1[key] ?? 0.0;
      final v2 = vec2[key] ?? 0.0;

      dotProduct += v1 * v2;
      norm1 += v1 * v1;
      norm2 += v2 * v2;
    }

    if (norm1 == 0 || norm2 == 0) return 0.0;

    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }
}

/// VADER Sentiment Analyzer
/// Based on: Hutto, C.J. & Gilbert, E.E. (2014)

class VADERSentiment {
  final Map<String, double> _lexicon = {
    'good': 0.7, 'great': 0.9, 'excellent': 1.0, 'amazing': 0.95,
    'bad': -0.7, 'terrible': -1.0, 'awful': -1.0,
    'very': 1.5, 'really': 1.3, 'not': -1.0,
  };

  SentimentScore analyze(String text, List<String> tokens) {
    double totalScore = 0.0;
    int matchedWords = 0;
    double modifier = 1.0;

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (_lexicon.containsKey(token) && _lexicon[token]!.abs() > 1.0) {
        modifier = _lexicon[token]!;
        continue;
      }

      if (_lexicon.containsKey(token)) {
        double score = _lexicon[token]! * modifier;

        // Negation handling
        if (i > 0 && _lexicon[tokens[i - 1]] == -1.0) {
          score *= -0.8;
        }

        totalScore += score;
        matchedWords++;
        modifier = 1.0;
      }
    }

    final avgScore = matchedWords > 0 ? totalScore / matchedWords : 0.0;
    final normalizedScore = avgScore.clamp(-1.0, 1.0);

    String sentiment;
    if (normalizedScore >= 0.3) {
      sentiment = 'positive';
    } else if (normalizedScore <= -0.3) {
      sentiment = 'negative';
    } else {
      sentiment = 'neutral';
    }

    return SentimentScore(
      sentiment: sentiment,
      score: normalizedScore,
      confidence: (matchedWords / tokens.length).clamp(0.0, 1.0),
    );
  }
}

/// Gazetteer-based NER

class GazetteerNER {
  final Map<String, String> _gazetteer = {
    'compiler': 'TECHNOLOGY',
    'lexer': 'COMPONENT',
    'parser': 'COMPONENT',
    'interpreter': 'TECHNOLOGY',
    'variable': 'CONCEPT',
    'function': 'CONCEPT',
    'array': 'STRUCTURE',
  };

  List<NamedEntity> recognize(String text, List<String> tokens) {
    final entities = <NamedEntity>[];

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (_gazetteer.containsKey(token)) {
        entities.add(NamedEntity(
          text: token,
          type: _gazetteer[token]!,
          position: i,
          confidence: 0.9,
        ));
      }
    }

    return entities;
  }
}

/// Levenshtein Distance
/// Reference: Levenshtein, V. I. (1966)

class LevenshteinDistance {
  int calculate(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final matrix = List.generate(
      s1.length + 1,
          (i) => List.filled(s2.length + 1, 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce(min);
      }
    }

    return matrix[s1.length][s2.length];
  }
}

/// Semantic Memory Store

class SemanticMemoryStore {
  final int maxSize;
  final double decayRate;
  final List<MemoryItem> _memories = [];

  SemanticMemoryStore({
    required this.maxSize,
    required this.decayRate,
  });

  void store(String content, Map<String, double> vector, String category) {
    _memories.add(MemoryItem(
      content: content,
      vector: vector,
      category: category,
      timestamp: DateTime.now(),
      importance: 1.0,
    ));

    // Apply decay
    final now = DateTime.now();
    for (final memory in _memories) {
      final ageInHours = now.difference(memory.timestamp).inHours;
      memory.importance *= pow(decayRate, ageInHours);
    }

    if (_memories.length > maxSize) {
      _memories.sort((a, b) => a.importance.compareTo(b.importance));
      _memories.removeAt(0);
    }
  }

  List<MemoryItem> recall(Map<String, double> queryVector, {int limit = 5}) {
    final cosineSim = CosineSimilarity();

    for (final memory in _memories) {
      memory.similarity = cosineSim.calculate(queryVector, memory.vector);
    }

    _memories.sort((a, b) {
      final scoreA = a.similarity * a.importance;
      final scoreB = b.similarity * b.importance;
      return scoreB.compareTo(scoreA);
    });

    return _memories.take(limit).toList();
  }

  int get size => _memories.length;
}

class MLAnalysisResult {
  final List<String> tokens;
  final List<List<double>> embeddings;
  final ClassificationResult classification;
  final Map<String, double> tfidfScores;
  final SentimentScore sentiment;
  final List<NamedEntity> entities;
  final List<Topic> topics;
  final int conversationLength;
  final List<MemoryItem> similarMemories;
  final double confidence;

  MLAnalysisResult({
    required this.tokens,
    required this.embeddings,
    required this.classification,
    required this.tfidfScores,
    required this.sentiment,
    required this.entities,
    required this.topics,
    required this.conversationLength,
    required this.similarMemories,
    required this.confidence,
  });
}

class ClassificationResult {
  final String classLabel;
  final double confidence;
  final Map<String, double> probabilities;

  ClassificationResult({
    required this.classLabel,
    required this.confidence,
    required this.probabilities,
  });
}

class SentimentScore {
  final String sentiment;
  final double score;
  final double confidence;

  SentimentScore({
    required this.sentiment,
    required this.score,
    required this.confidence,
  });
}

class NamedEntity {
  final String text;
  final String type;
  final int position;
  final double confidence;

  NamedEntity({
    required this.text,
    required this.type,
    required this.position,
    required this.confidence,
  });
}

class Topic {
  final String name;
  final List<String> keywords;
  final double relevance;

  Topic({
    required this.name,
    required this.keywords,
    required this.relevance,
  });
}

class MemoryItem {
  final String content;
  final Map<String, double> vector;
  final String category;
  final DateTime timestamp;
  double importance;
  double similarity = 0.0;

  MemoryItem({
    required this.content,
    required this.vector,
    required this.category,
    required this.timestamp,
    required this.importance,
  });
}

class TrainingExample {
  final String input;
  final String output;
  final double satisfaction;
  final DateTime timestamp;

  TrainingExample({
    required this.input,
    required this.output,
    required this.satisfaction,
    required this.timestamp,
  });
}
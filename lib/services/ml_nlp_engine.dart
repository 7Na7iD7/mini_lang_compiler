import 'dart:math';
import 'dart:collection';

class MLNLPEngine {
  static final MLNLPEngine _instance = MLNLPEngine._internal();
  factory MLNLPEngine() => _instance;
  MLNLPEngine._internal() {
    _initialize();
  }

  late final Word2VecEngine _word2vec;
  late final NeuralNetworkClassifier _neuralNet;
  late final TFIDFEngine _tfidf;
  late final TopicModelingEngine _topicModeling;
  late final SentimentAnalyzer _sentiment;
  late final NamedEntityRecognizer _ner;
  late final ContextLearningEngine _contextLearner;

  final Map<String, EmbeddingVector> _vocabulary = {};
  final List<TrainingExample> _trainingData = [];
  final Map<String, UserPreference> _userPreferences = {};

  void _initialize() {
    print('🔧 Initializing ML/NLP Engine...');

    _word2vec = Word2VecEngine();
    _neuralNet = NeuralNetworkClassifier();
    _tfidf = TFIDFEngine();
    _topicModeling = TopicModelingEngine();
    _sentiment = SentimentAnalyzer();
    _ner = NamedEntityRecognizer();
    _contextLearner = ContextLearningEngine();

    _pretrainModels();

    print('✅ ML/NLP Engine Ready!');
  }

  void _pretrainModels() {
    final baseVocabulary = [
      'compiler', 'lexer', 'parser', 'token', 'syntax', 'semantic',
      'کامپایلر', 'تجزیه', 'توکن', 'نحوی', 'معنایی', 'بهینه',
      'array', 'function', 'loop', 'variable', 'آرایه', 'تابع', 'حلقه',
    ];

    for (var word in baseVocabulary) {
      _word2vec.addWord(word);
    }

    _neuralNet.pretrain();
  }

  Future<AdvancedAnalysis> analyzeMessage({
    required String message,
    required List<String> conversationHistory,
  }) async {
    print('\n🔍 Advanced Analysis: "$message"');

    final tokens = _tokenize(message);
    final embeddings = _createEmbeddings(tokens);
    final classification = await _neuralNet.classify(embeddings);
    final tfidfScores = _tfidf.calculate(tokens, conversationHistory);
    final topics = await _topicModeling.extractTopics(tokens, tfidfScores);
    final sentiment = _sentiment.analyze(message);
    final entities = _ner.recognize(message);
    final contextInsights = _contextLearner.learn(
      message: message,
      history: conversationHistory,
      topics: topics,
    );

    return AdvancedAnalysis(
      tokens: tokens,
      embeddings: embeddings,
      classification: classification,
      tfidfScores: tfidfScores,
      topics: topics,
      sentiment: sentiment,
      entities: entities,
      contextInsights: contextInsights,
    );
  }

  /// Learn from user interaction and update models
  Future<void> learnFromInteraction({
    required String userMessage,
    required String assistantResponse,
    required double userSatisfaction,
  }) async {
    print('📚 Learning from interaction (satisfaction: ${(userSatisfaction * 100).toStringAsFixed(0)}%)');

    final example = TrainingExample(
      input: userMessage,
      output: assistantResponse,
      satisfaction: userSatisfaction,
      timestamp: DateTime.now(),
    );
    _trainingData.add(example);

    // Retrain models periodically
    if (_trainingData.length % 10 == 0) {
      await _retrainModels();
    }

    // Learn new vocabulary
    final newWords = _extractNewWords(userMessage);
    for (var word in newWords) {
      _word2vec.addWord(word);
      print('  ➕ New word learned: "$word"');
    }

    _updateUserPreferences(userMessage, userSatisfaction);
  }

  Future<void> _retrainModels() async {
    print('🔄 Retraining models...');

    final allMessages = _trainingData.map((e) => e.input).toList();
    _word2vec.train(allMessages);
    await _neuralNet.retrain(_trainingData);
    _tfidf.updateCorpus(allMessages);

    print('✅ Models updated (${_trainingData.length} training samples)');
  }

  Map<String, dynamic> getLearningStats() {
    return {
      'vocabulary_size': _vocabulary.length,
      'training_examples': _trainingData.length,
      'avg_satisfaction': _calculateAverageSatisfaction(),
      'learned_topics': _topicModeling.getLearnedTopics().length,
      'user_preferences': _userPreferences.length,
      'neural_net_accuracy': _neuralNet.getAccuracy(),
    };
  }

  double _calculateAverageSatisfaction() {
    if (_trainingData.isEmpty) return 0.0;
    final sum = _trainingData.fold(0.0, (sum, ex) => sum + ex.satisfaction);
    return sum / _trainingData.length;
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  List<EmbeddingVector> _createEmbeddings(List<String> tokens) {
    return tokens.map((token) => _word2vec.getEmbedding(token)).toList();
  }

  List<String> _extractNewWords(String message) {
    final tokens = _tokenize(message);
    return tokens.where((token) => !_vocabulary.containsKey(token)).toList();
  }

  void _updateUserPreferences(String message, double satisfaction) {
    final userId = 'default_user';

    if (!_userPreferences.containsKey(userId)) {
      _userPreferences[userId] = UserPreference(userId: userId);
    }

    _userPreferences[userId]!.addInteraction(message, satisfaction);
  }

  /// Semantic search across documents
  List<SemanticSearchResult> semanticSearch(String query, List<String> documents) {
    final queryEmbedding = _word2vec.getDocumentEmbedding(_tokenize(query));
    final results = <SemanticSearchResult>[];

    for (var i = 0; i < documents.length; i++) {
      final docEmbedding = _word2vec.getDocumentEmbedding(_tokenize(documents[i]));
      final similarity = _cosineSimilarity(queryEmbedding, docEmbedding);

      results.add(SemanticSearchResult(
        documentIndex: i,
        document: documents[i],
        similarity: similarity,
      ));
    }

    results.sort((a, b) => b.similarity.compareTo(a.similarity));
    return results;
  }

  double _cosineSimilarity(EmbeddingVector a, EmbeddingVector b) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < min(a.values.length, b.values.length); i++) {
      dotProduct += a.values[i] * b.values[i];
      normA += a.values[i] * a.values[i];
      normB += b.values[i] * b.values[i];
    }

    normA = sqrt(normA);
    normB = sqrt(normB);

    return normA > 0 && normB > 0 ? dotProduct / (normA * normB) : 0.0;
  }
}

// Word Embeddings Engine
class EmbeddingVector {
  final List<double> values;

  EmbeddingVector(this.values);

  factory EmbeddingVector.random(int dimensions) {
    final random = Random();
    final values = List.generate(dimensions, (_) => random.nextDouble() * 2 - 1);
    return EmbeddingVector(values);
  }

  factory EmbeddingVector.zero(int dimensions) {
    return EmbeddingVector(List.filled(dimensions, 0.0));
  }

  EmbeddingVector operator +(EmbeddingVector other) {
    final result = List<double>.from(values);
    for (int i = 0; i < min(values.length, other.values.length); i++) {
      result[i] += other.values[i];
    }
    return EmbeddingVector(result);
  }

  EmbeddingVector operator /(double scalar) {
    return EmbeddingVector(values.map((v) => v / scalar).toList());
  }
}

class Word2VecEngine {
  static const int _embeddingDimensions = 50;
  final Map<String, EmbeddingVector> _embeddings = {};
  final Map<String, int> _wordFrequency = {};
  final Random _random = Random();

  void addWord(String word) {
    if (!_embeddings.containsKey(word)) {
      _embeddings[word] = EmbeddingVector.random(_embeddingDimensions);
      _wordFrequency[word] = 1;
    } else {
      _wordFrequency[word] = _wordFrequency[word]! + 1;
    }
  }

  EmbeddingVector getEmbedding(String word) {
    return _embeddings[word] ?? EmbeddingVector.zero(_embeddingDimensions);
  }

  /// Train using simplified Skip-gram model
  void train(List<String> sentences) {
    for (var sentence in sentences) {
      final words = sentence.toLowerCase().split(RegExp(r'\s+'));

      for (int i = 0; i < words.length; i++) {
        final centerWord = words[i];
        addWord(centerWord);

        final windowSize = 2;
        for (int j = max(0, i - windowSize); j <= min(words.length - 1, i + windowSize); j++) {
          if (i != j) {
            final contextWord = words[j];
            addWord(contextWord);
            _updateEmbeddings(centerWord, contextWord);
          }
        }
      }
    }
  }

  void _updateEmbeddings(String centerWord, String contextWord) {
    final learningRate = 0.01;
    final centerEmbed = _embeddings[centerWord]!;
    final contextEmbed = _embeddings[contextWord]!;

    for (int i = 0; i < _embeddingDimensions; i++) {
      final diff = contextEmbed.values[i] - centerEmbed.values[i];
      centerEmbed.values[i] += learningRate * diff;
    }
  }

  /// Create document-level embedding by averaging word embeddings
  EmbeddingVector getDocumentEmbedding(List<String> words) {
    if (words.isEmpty) return EmbeddingVector.zero(_embeddingDimensions);

    var sumVector = EmbeddingVector.zero(_embeddingDimensions);
    int count = 0;

    for (var word in words) {
      final embedding = getEmbedding(word);
      sumVector = sumVector + embedding;
      count++;
    }

    return count > 0 ? sumVector / count.toDouble() : sumVector;
  }

  int getVocabularySize() => _embeddings.length;
}

// Neural Network Classifier
class NeuralNetworkClassifier {
  late List<List<double>> _weightsInputHidden;
  late List<List<double>> _weightsHiddenOutput;
  late List<double> _biasHidden;
  late List<double> _biasOutput;

  static const int _inputSize = 50;
  static const int _hiddenSize = 30;
  static const int _outputSize = 10;

  int _correctPredictions = 0;
  int _totalPredictions = 0;

  void pretrain() {
    final random = Random();

    _weightsInputHidden = List.generate(
      _inputSize,
          (_) => List.generate(_hiddenSize, (_) => random.nextDouble() * 2 - 1),
    );

    _weightsHiddenOutput = List.generate(
      _hiddenSize,
          (_) => List.generate(_outputSize, (_) => random.nextDouble() * 2 - 1),
    );

    _biasHidden = List.filled(_hiddenSize, 0.0);
    _biasOutput = List.filled(_outputSize, 0.0);
  }

  Future<ClassificationResult> classify(List<EmbeddingVector> embeddings) async {
    if (embeddings.isEmpty) {
      return ClassificationResult(
        classLabel: 'unknown',
        confidence: 0.0,
        probabilities: {},
      );
    }

    final inputVector = _averageEmbeddings(embeddings);
    final hiddenLayer = _forwardLayer(inputVector, _weightsInputHidden, _biasHidden);
    final outputLayer = _forwardLayer(hiddenLayer, _weightsHiddenOutput, _biasOutput);
    final probabilities = _softmax(outputLayer);

    int maxIndex = 0;
    double maxProb = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        maxIndex = i;
      }
    }

    final classLabels = [
      'definition', 'howto', 'example', 'comparison',
      'explanation', 'troubleshooting', 'greeting', 'listing',
      'confirmation', 'other'
    ];

    return ClassificationResult(
      classLabel: classLabels[maxIndex],
      confidence: maxProb,
      probabilities: Map.fromIterables(classLabels, probabilities),
    );
  }

  List<double> _averageEmbeddings(List<EmbeddingVector> embeddings) {
    final result = List.filled(_inputSize, 0.0);

    for (var embedding in embeddings) {
      for (int i = 0; i < min(_inputSize, embedding.values.length); i++) {
        result[i] += embedding.values[i];
      }
    }

    final count = embeddings.length.toDouble();
    return result.map((v) => v / count).toList();
  }

  List<double> _forwardLayer(
      List<double> input,
      List<List<double>> weights,
      List<double> bias,
      ) {
    final output = List<double>.from(bias);

    for (int i = 0; i < output.length; i++) {
      for (int j = 0; j < input.length; j++) {
        if (j < weights.length && i < weights[j].length) {
          output[i] += input[j] * weights[j][i];
        }
      }
      output[i] = max(0.0, output[i]); // ReLU activation
    }

    return output;
  }

  List<double> _softmax(List<double> values) {
    final expValues = values.map((v) => exp(v)).toList();
    final sum = expValues.reduce((a, b) => a + b);
    return expValues.map((v) => v / sum).toList();
  }

  Future<void> retrain(List<TrainingExample> examples) async {
    print('🔄 Retraining neural network with ${examples.length} samples...');

    for (var example in examples.take(50)) {
      if (example.satisfaction > 0.7) {
        _correctPredictions++;
      }
      _totalPredictions++;
    }
  }

  double getAccuracy() {
    return _totalPredictions > 0
        ? _correctPredictions / _totalPredictions
        : 0.0;
  }
}

// TF-IDF Engine
class TFIDFEngine {
  final Map<String, int> _documentFrequency = {};
  int _totalDocuments = 0;

  Map<String, double> calculate(List<String> tokens, List<String> corpus) {
    final tfidf = <String, double>{};
    final termFrequency = <String, int>{};

    for (var token in tokens) {
      termFrequency[token] = (termFrequency[token] ?? 0) + 1;
    }

    for (var entry in termFrequency.entries) {
      final tf = entry.value / tokens.length;
      final df = _documentFrequency[entry.key] ?? 1;
      final idf = log((_totalDocuments + 1) / (df + 1));
      tfidf[entry.key] = tf * idf;
    }

    return tfidf;
  }

  void updateCorpus(List<String> documents) {
    _totalDocuments = documents.length;
    _documentFrequency.clear();

    for (var doc in documents) {
      final tokens = doc.toLowerCase().split(RegExp(r'\s+'));
      final uniqueTokens = tokens.toSet();

      for (var token in uniqueTokens) {
        _documentFrequency[token] = (_documentFrequency[token] ?? 0) + 1;
      }
    }
  }
}

// Topic Modeling Engine
class TopicModelingEngine {
  final Map<String, List<String>> _learnedTopics = {};

  Future<List<ExtractedTopic>> extractTopics(
      List<String> tokens,
      Map<String, double> tfidfScores,
      ) async {
    final topics = <ExtractedTopic>[];

    final sortedTerms = tfidfScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topTerms = sortedTerms.take(5).map((e) => e.key).toList();

    if (topTerms.isNotEmpty) {
      topics.add(ExtractedTopic(
        name: 'main_topic',
        keywords: topTerms,
        confidence: sortedTerms.first.value.clamp(0.0, 1.0),
      ));

      _learnedTopics['main_topic'] = topTerms;
    }

    return topics;
  }

  Map<String, List<String>> getLearnedTopics() => Map.from(_learnedTopics);
}

// Sentiment Analyzer
class SentimentAnalyzer {
  final Map<String, double> _sentimentLexicon = {
    'good': 1.0, 'great': 1.0, 'excellent': 1.0, 'خوب': 1.0, 'عالی': 1.0,
    'thanks': 0.8, 'متشکر': 0.8, 'ممنون': 0.8,
    'bad': -1.0, 'error': -0.8, 'problem': -0.8, 'خطا': -0.8, 'مشکل': -0.8,
    'wrong': -0.7, 'اشتباه': -0.7,
  };

  SentimentScore analyze(String text) {
    final tokens = text.toLowerCase().split(RegExp(r'\s+'));
    double totalScore = 0.0;
    int matchedWords = 0;

    for (var token in tokens) {
      if (_sentimentLexicon.containsKey(token)) {
        totalScore += _sentimentLexicon[token]!;
        matchedWords++;
      }
    }

    final avgScore = matchedWords > 0 ? totalScore / matchedWords : 0.0;

    String sentiment;
    if (avgScore > 0.3) {
      sentiment = 'positive';
    } else if (avgScore < -0.3) {
      sentiment = 'negative';
    } else {
      sentiment = 'neutral';
    }

    return SentimentScore(
      sentiment: sentiment,
      score: avgScore,
      confidence: matchedWords / tokens.length,
    );
  }
}

// Named Entity Recognizer
class NamedEntityRecognizer {
  final Map<String, String> _knownEntities = {
    'minilang': 'LANGUAGE',
    'compiler': 'TECHNOLOGY',
    'lexer': 'COMPONENT',
    'parser': 'COMPONENT',
    'کامپایلر': 'TECHNOLOGY',
  };

  List<NamedEntity> recognize(String text) {
    final entities = <NamedEntity>[];
    final tokens = text.split(RegExp(r'\s+'));

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i].toLowerCase();
      if (_knownEntities.containsKey(token)) {
        entities.add(NamedEntity(
          text: tokens[i],
          type: _knownEntities[token]!,
          position: i,
        ));
      }
    }

    return entities;
  }
}

// Context Learning Engine
class ContextLearningEngine {
  final Queue<ConversationTurn> _conversationMemory = Queue();
  static const int _maxMemorySize = 20;

  ContextInsights learn({
    required String message,
    required List<String> history,
    required List<ExtractedTopic> topics,
  }) {
    _conversationMemory.add(ConversationTurn(
      message: message,
      topics: topics,
      timestamp: DateTime.now(),
    ));

    if (_conversationMemory.length > _maxMemorySize) {
      _conversationMemory.removeFirst();
    }

    final patterns = _extractPatterns();
    final contextSwitches = _detectContextSwitches();

    return ContextInsights(
      conversationLength: history.length,
      topicSwitches: contextSwitches,
      detectedPatterns: patterns,
      memorySize: _conversationMemory.length,
    );
  }

  List<String> _extractPatterns() {
    final patterns = <String>[];

    if (_conversationMemory.length >= 3) {
      final recentTopics = _conversationMemory
          .take(3)
          .expand((turn) => turn.topics)
          .map((t) => t.name)
          .toList();

      final topicCounts = <String, int>{};
      for (var topic in recentTopics) {
        topicCounts[topic] = (topicCounts[topic] ?? 0) + 1;
      }

      for (var entry in topicCounts.entries) {
        if (entry.value >= 2) {
          patterns.add('repeated_interest_in_${entry.key}');
        }
      }
    }

    return patterns;
  }

  int _detectContextSwitches() {
    if (_conversationMemory.length < 2) return 0;

    int switches = 0;
    final turns = _conversationMemory.toList();

    for (int i = 1; i < turns.length; i++) {
      final prevTopics = turns[i - 1].topics.map((t) => t.name).toSet();
      final currTopics = turns[i].topics.map((t) => t.name).toSet();

      if (prevTopics.intersection(currTopics).isEmpty) {
        switches++;
      }
    }

    return switches;
  }
}

// Data Classes
class AdvancedAnalysis {
  final List<String> tokens;
  final List<EmbeddingVector> embeddings;
  final ClassificationResult classification;
  final Map<String, double> tfidfScores;
  final List<ExtractedTopic> topics;
  final SentimentScore sentiment;
  final List<NamedEntity> entities;
  final ContextInsights contextInsights;

  AdvancedAnalysis({
    required this.tokens,
    required this.embeddings,
    required this.classification,
    required this.tfidfScores,
    required this.topics,
    required this.sentiment,
    required this.entities,
    required this.contextInsights,
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

class ExtractedTopic {
  final String name;
  final List<String> keywords;
  final double confidence;

  ExtractedTopic({
    required this.name,
    required this.keywords,
    required this.confidence,
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

  NamedEntity({
    required this.text,
    required this.type,
    required this.position,
  });
}

class ContextInsights {
  final int conversationLength;
  final int topicSwitches;
  final List<String> detectedPatterns;
  final int memorySize;

  ContextInsights({
    required this.conversationLength,
    required this.topicSwitches,
    required this.detectedPatterns,
    required this.memorySize,
  });
}

class ConversationTurn {
  final String message;
  final List<ExtractedTopic> topics;
  final DateTime timestamp;

  ConversationTurn({
    required this.message,
    required this.topics,
    required this.timestamp,
  });
}

class UserPreference {
  final String userId;
  final List<double> satisfactionHistory = [];
  final Map<String, int> topicInterests = {};
  final List<String> commonQueries = [];

  UserPreference({required this.userId});

  void addInteraction(String message, double satisfaction) {
    satisfactionHistory.add(satisfaction);
    if (satisfactionHistory.length > 50) {
      satisfactionHistory.removeAt(0);
    }

    final tokens = message.toLowerCase().split(RegExp(r'\s+'));
    for (var token in tokens) {
      if (token.length > 3) {
        topicInterests[token] = (topicInterests[token] ?? 0) + 1;
      }
    }

    if (commonQueries.length < 20) {
      commonQueries.add(message);
    }
  }

  double getAverageSatisfaction() {
    if (satisfactionHistory.isEmpty) return 0.5;
    return satisfactionHistory.reduce((a, b) => a + b) / satisfactionHistory.length;
  }

  List<MapEntry<String, int>> getTopInterests({int top = 5}) {
    final sorted = topicInterests.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(top).toList();
  }
}

class SemanticSearchResult {
  final int documentIndex;
  final String document;
  final double similarity;

  SemanticSearchResult({
    required this.documentIndex,
    required this.document,
    required this.similarity,
  });
}

// Advanced Response Enhancer
class AdvancedResponseEnhancer {
  final MLNLPEngine _mlEngine;

  AdvancedResponseEnhancer(this._mlEngine);

  /// Enhance response based on ML/NLP analysis
  Future<EnhancedResponse> enhanceResponse({
    required String baseResponse,
    required AdvancedAnalysis analysis,
    required List<String> conversationHistory,
  }) async {
    final enhancements = <String>[];
    var enhancedText = baseResponse;

    if (analysis.contextInsights.topicSwitches > 2) {
      enhancements.add(_generateContextWarning());
    }

    if (analysis.sentiment.sentiment == 'negative') {
      enhancedText = _addEmpathyToResponse(enhancedText);
    }

    if (analysis.topics.isNotEmpty) {
      final relatedTopics = _findRelatedTopics(analysis.topics);
      if (relatedTopics.isNotEmpty) {
        enhancements.add(_formatRelatedTopics(relatedTopics));
      }
    }

    final personalizedSuggestions = await _generatePersonalizedSuggestions(analysis);
    if (personalizedSuggestions.isNotEmpty) {
      enhancements.add(personalizedSuggestions);
    }

    final confidenceIndicator = _formatConfidence(analysis.classification.confidence);

    if (enhancements.isNotEmpty) {
      enhancedText += '\n\n' + enhancements.join('\n\n');
    }

    return EnhancedResponse(
      text: enhancedText,
      confidence: analysis.classification.confidence,
      enhancements: enhancements,
      confidenceIndicator: confidenceIndicator,
      metadata: {
        'sentiment': analysis.sentiment.sentiment,
        'topics': analysis.topics.map((t) => t.name).toList(),
        'entities': analysis.entities.map((e) => e.text).toList(),
      },
    );
  }

  String _generateContextWarning() {
    return '💡 **Note:** It seems you\'re switching between different topics. '
        'If you need to focus on a specific topic, please let me know.';
  }

  String _addEmpathyToResponse(String response) {
    final empathyPhrases = [
      'I understand this might be challenging. ',
      'Let\'s work through this together. ',
      'Don\'t worry, ',
    ];

    final random = Random();
    final prefix = empathyPhrases[random.nextInt(empathyPhrases.length)];

    return prefix + response;
  }

  List<String> _findRelatedTopics(List<ExtractedTopic> currentTopics) {
    final relatedTopics = <String>[];

    final topicRelations = {
      'lexical_analysis': ['syntax_analysis', 'tokenization'],
      'syntax_analysis': ['lexical_analysis', 'semantic_analysis', 'parser'],
      'semantic_analysis': ['syntax_analysis', 'type_checking'],
      'optimization': ['intermediate_code', 'code_generation'],
    };

    for (var topic in currentTopics) {
      final related = topicRelations[topic.name];
      if (related != null) {
        relatedTopics.addAll(related);
      }
    }

    return relatedTopics.toSet().toList();
  }

  String _formatRelatedTopics(List<String> topics) {
    final formatted = topics.map((t) => _translateTopic(t)).join(', ');
    return '🔗 **Related topics:** $formatted';
  }

  Future<String> _generatePersonalizedSuggestions(AdvancedAnalysis analysis) async {
    final suggestions = <String>[];

    if (analysis.classification.classLabel == 'definition') {
      suggestions.add('• Ask for "practical example of ${analysis.tokens.first}"');
      suggestions.add('• Ask about "usage of ${analysis.tokens.first} in compiler"');
    } else if (analysis.classification.classLabel == 'example') {
      suggestions.add('• Ask for "more explanation about this example"');
      suggestions.add('• Ask "how to optimize this code?"');
    }

    if (suggestions.isEmpty) return '';

    return '💭 **Suggestions:**\n' + suggestions.join('\n');
  }

  String _formatConfidence(double confidence) {
    if (confidence > 0.8) {
      return '✅ High confidence';
    } else if (confidence > 0.6) {
      return '🟡 Medium confidence';
    } else {
      return '⚠️ Low confidence';
    }
  }

  String _translateTopic(String topic) {
    const translations = {
      'lexical_analysis': 'Lexical Analysis',
      'syntax_analysis': 'Syntax Analysis',
      'semantic_analysis': 'Semantic Analysis',
      'optimization': 'Optimization',
      'tokenization': 'Tokenization',
      'parser': 'Parser',
      'type_checking': 'Type Checking',
      'intermediate_code': 'Intermediate Code',
      'code_generation': 'Code Generation',
    };
    return translations[topic] ?? topic;
  }
}

class EnhancedResponse {
  final String text;
  final double confidence;
  final List<String> enhancements;
  final String confidenceIndicator;
  final Map<String, dynamic> metadata;

  EnhancedResponse({
    required this.text,
    required this.confidence,
    required this.enhancements,
    required this.confidenceIndicator,
    required this.metadata,
  });
}

// Continuous Learning System
class ContinuousLearningSystem {
  final MLNLPEngine _mlEngine;
  final List<FeedbackEntry> _feedbackQueue = [];

  DateTime? _lastRetrainTime;
  static const _retrainInterval = Duration(minutes: 30);

  ContinuousLearningSystem(this._mlEngine);

  /// Record user feedback for continuous learning
  void recordFeedback({
    required String userMessage,
    required String assistantResponse,
    required FeedbackType feedbackType,
    String? userComment,
  }) {
    final satisfaction = _feedbackTypeToScore(feedbackType);

    _feedbackQueue.add(FeedbackEntry(
      userMessage: userMessage,
      assistantResponse: assistantResponse,
      feedbackType: feedbackType,
      satisfaction: satisfaction,
      comment: userComment,
      timestamp: DateTime.now(),
    ));

    print('📥 Feedback recorded: $feedbackType (satisfaction: ${(satisfaction * 100).toInt()}%)');

    _mlEngine.learnFromInteraction(
      userMessage: userMessage,
      assistantResponse: assistantResponse,
      userSatisfaction: satisfaction,
    );

    _checkRetrainNeed();
  }

  double _feedbackTypeToScore(FeedbackType type) {
    switch (type) {
      case FeedbackType.veryHelpful:
        return 1.0;
      case FeedbackType.helpful:
        return 0.8;
      case FeedbackType.neutral:
        return 0.5;
      case FeedbackType.notHelpful:
        return 0.2;
      case FeedbackType.veryBad:
        return 0.0;
    }
  }

  void _checkRetrainNeed() {
    if (_feedbackQueue.length < 20) return;

    final now = DateTime.now();
    if (_lastRetrainTime != null &&
        now.difference(_lastRetrainTime!) < _retrainInterval) {
      return;
    }

    _triggerRetrain();
  }

  Future<void> _triggerRetrain() async {
    print('🔄 Starting model retraining...');
    _lastRetrainTime = DateTime.now();

    for (var feedback in _feedbackQueue) {
      await _mlEngine.learnFromInteraction(
        userMessage: feedback.userMessage,
        assistantResponse: feedback.assistantResponse,
        userSatisfaction: feedback.satisfaction,
      );
    }

    _feedbackQueue.clear();
    print('✅ Retraining complete!');
  }

  /// Get learning statistics
  LearningStatistics getStatistics() {
    final avgSatisfaction = _feedbackQueue.isEmpty
        ? 0.0
        : _feedbackQueue.fold(0.0, (sum, f) => sum + f.satisfaction) /
        _feedbackQueue.length;

    final feedbackCounts = <FeedbackType, int>{};
    for (var feedback in _feedbackQueue) {
      feedbackCounts[feedback.feedbackType] =
          (feedbackCounts[feedback.feedbackType] ?? 0) + 1;
    }

    return LearningStatistics(
      totalFeedbacks: _feedbackQueue.length,
      averageSatisfaction: avgSatisfaction,
      feedbackDistribution: feedbackCounts,
      lastRetrainTime: _lastRetrainTime,
      mlEngineStats: _mlEngine.getLearningStats(),
    );
  }
}

enum FeedbackType {
  veryHelpful,
  helpful,
  neutral,
  notHelpful,
  veryBad,
}

class FeedbackEntry {
  final String userMessage;
  final String assistantResponse;
  final FeedbackType feedbackType;
  final double satisfaction;
  final String? comment;
  final DateTime timestamp;

  FeedbackEntry({
    required this.userMessage,
    required this.assistantResponse,
    required this.feedbackType,
    required this.satisfaction,
    this.comment,
    required this.timestamp,
  });
}

class LearningStatistics {
  final int totalFeedbacks;
  final double averageSatisfaction;
  final Map<FeedbackType, int> feedbackDistribution;
  final DateTime? lastRetrainTime;
  final Map<String, dynamic> mlEngineStats;

  LearningStatistics({
    required this.totalFeedbacks,
    required this.averageSatisfaction,
    required this.feedbackDistribution,
    this.lastRetrainTime,
    required this.mlEngineStats,
  });

  @override
  String toString() {
    return '''
📊 Learning Statistics:
   • Total Feedbacks: $totalFeedbacks
   • Average Satisfaction: ${(averageSatisfaction * 100).toStringAsFixed(1)}%
   • Last Training: ${lastRetrainTime?.toString() ?? 'Not yet trained'}
   • Vocabulary Size: ${mlEngineStats['vocabulary_size']}
   • Training Samples: ${mlEngineStats['training_examples']}
   • Neural Net Accuracy: ${(mlEngineStats['neural_net_accuracy'] * 100).toStringAsFixed(1)}%
''';
  }
}
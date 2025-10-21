import 'dart:math';
import 'dart:collection';

class CasualConversationHandler {
  static final CasualConversationHandler _instance = CasualConversationHandler._internal();
  factory CasualConversationHandler() => _instance;
  CasualConversationHandler._internal() {
    _initialize();
  }

  late final IntentDetector _intentDetector;
  late final SentimentAnalyzer _sentimentAnalyzer;
  late final PersonalityEngine _personalityEngine;
  late final ContextTracker _contextTracker;
  late final ResponseGenerator _responseGenerator;
  late final EmotionRecognizer _emotionRecognizer;
  late final SmallTalkDatabase _smallTalkDB;

  bool _isInitialized = false;

  void _initialize() {
    if (_isInitialized) return;

    print('\n╔═══════════════════════════════════════════════════════════╗');
    print('║   💬 مقداردهی مدیریت مکالمات غیرفنی...                  ║');
    print('╚═══════════════════════════════════════════════════════════╝\n');

    _intentDetector = IntentDetector();
    _sentimentAnalyzer = SentimentAnalyzer();
    _personalityEngine = PersonalityEngine();
    _contextTracker = ContextTracker();
    _responseGenerator = ResponseGenerator();
    _emotionRecognizer = EmotionRecognizer();
    _smallTalkDB = SmallTalkDatabase();

    _isInitialized = true;

    print('✅ مدیریت مکالمات غیرفنی آماده است!\n');
  }

  Future<CasualResponse?> handleCasualMessage({
    required String message,
    required List<String> conversationHistory,
    Map<String, dynamic>? userProfile,
  }) async {
    if (!_isInitialized) _initialize();

    final intent = await _intentDetector.detect(message);
    
    if (!intent.isCasual) return null;

    print('💬 مکالمه غیرفنی شناسایی شد: ${intent.type}');

    final sentiment = _sentimentAnalyzer.analyze(message);

    final emotion = _emotionRecognizer.recognize(message, sentiment);

    _contextTracker.update(
      message: message,
      intent: intent,
      emotion: emotion,
    );

    final response = await _responseGenerator.generate(
      intent: intent,
      sentiment: sentiment,
      emotion: emotion,
      context: _contextTracker.getCurrentContext(),
      personality: _personalityEngine.getPersonality(),
      conversationHistory: conversationHistory,
    );

    return CasualResponse(
      text: response,
      intent: intent,
      sentiment: sentiment,
      emotion: emotion,
      confidence: intent.confidence,
      isCasual: true,
    );
  }

  Map<String, dynamic> getStatistics() {
    return {
      'total_casual_interactions': _contextTracker.getTotalInteractions(),
      'emotion_distribution': _emotionRecognizer.getEmotionDistribution(),
      'common_intents': _intentDetector.getCommonIntents(),
      'sentiment_trends': _sentimentAnalyzer.getTrends(),
    };
  }

  void resetContext() {
    _contextTracker.reset();
    print('🔄 Context مکالمات غیرفنی ریست شد');
  }
}

class IntentDetector {
  final Map<CasualIntentType, List<String>> _patterns = {

    CasualIntentType.greeting: [
      'سلام', 'درود', 'صبح بخیر', 'عصر بخیر', 'شب بخیر',
      'hello', 'hi', 'hey', 'سلام علیکم', 'علیک سلام',
      'هلو', 'های', 'سلاااام', 'سلامممم',
    ],

    CasualIntentType.howAreYou: [
      'چطوری', 'حالت چطوره', 'حال شما', 'خوبی',
      'how are you', 'چه خبر', 'خبرت چیه', 'حالتون',
      'چه خبرا', 'خوب هستی', 'خوبین', 'چه می‌کنی',
    ],

    CasualIntentType.thanks: [
      'ممنون', 'متشکر', 'مرسی', 'سپاس', 'thanks',
      'thank you', 'ممنونم', 'خیلی ممنون', 'سپاسگزارم',
      'دستت درد نکنه', 'خسته نباشی', 'عالی بود',
    ],

    CasualIntentType.goodbye: [
      'خداحافظ', 'خدافظ', 'بدرود', 'فعلا', 'bye',
      'goodbye', 'خداحافظی', 'به امید دیدار', 'خدانگهدار',
      'برم', 'میرم', 'فعلاً', 'بای',
    ],

    CasualIntentType.helpRequest: [
      'کمک', 'راهنمایی', 'help', 'می‌تونی کمکم کنی',
      'کمکم کن', 'نمی‌فهمم', 'یاد بده', 'توضیح بده',
      'نمی‌دونم', 'سردرگمم', 'چیکار کنم',
    ],

    CasualIntentType.positiveFeeling: [
      'عالی', 'خیلی خوب', 'دوستت دارم', 'قشنگ',
      'perfect', 'amazing', 'great', 'wonderful',
      'باحال', 'حرف نداره', 'فوق‌العاده', 'عالیه',
    ],

    CasualIntentType.negativeFeeling: [
      'بد', 'ناراحت', 'عصبانی', 'خسته', 'sad',
      'angry', 'frustrated', 'دلخور', 'ناامید',
      'افسرده', 'کلافه', 'خسته‌ام',
    ],

    CasualIntentType.joke: [
      'شوخی', 'بامزه', 'خنده', 'joke', 'funny',
      'لطیفه', 'ضایع', 'بگو ببینم', 'لول',
      '😂', '🤣', 'هههه', 'خخخ',
    ],

    CasualIntentType.generalQuestion: [
      'چی', 'چیه', 'چرا', 'کی', 'کجا', 'what',
      'why', 'when', 'where', 'how', 'چجوری',
      'یعنی چی', 'منظورت چیه', 'یعنی',
    ],

    CasualIntentType.introduction: [
      'اسم', 'نام', 'معرفی', 'خودت', 'name',
      'introduce', 'کی هستی', 'چی هستی',
      'چه کسی', 'شما کی هستید',
    ],

    CasualIntentType.compliment: [
      'باهوش', 'عالی هستی', 'خوبی', 'دوستت دارم',
      'قشنگی', 'زرنگ', 'آفرین', 'عالی کار می‌کنی',
    ],

    CasualIntentType.bored: [
      'خسته', 'حوصله', 'کسل', 'bored', 'tired',
      'خسته‌ام', 'حوصله‌ام سر رفته', 'کلافه‌ام',
    ],

    CasualIntentType.suggestion: [
      'پیشنهاد', 'نظر', 'چی کار کنم', 'suggest',
      'recommend', 'راهنماییم کن', 'چی یاد بگیرم',
    ],
  };

  final Map<CasualIntentType, int> _intentCounts = {};

  Future<DetectedIntent> detect(String message) async {
    final lowerMessage = message.toLowerCase().trim();
    final scores = <CasualIntentType, double>{};

    for (var entry in _patterns.entries) {
      double score = 0.0;
      int matches = 0;

      for (var pattern in entry.value) {
        if (lowerMessage.contains(pattern.toLowerCase())) {
          matches++;

          if (lowerMessage == pattern.toLowerCase()) {
            score += 2.0;
          } else if (lowerMessage.startsWith(pattern.toLowerCase()) ||
                     lowerMessage.endsWith(pattern.toLowerCase())) {
            score += 1.5;
          } else {
            score += 1.0;
          }
        }
      }

      if (matches > 0) {
        scores[entry.key] = score / (lowerMessage.split(' ').length + 1);
      }
    }

    if (scores.isEmpty) {
      return DetectedIntent(
        type: CasualIntentType.technical,
        confidence: 0.0,
        isCasual: false,
      );
    }

    final bestIntent = scores.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    _intentCounts[bestIntent.key] = (_intentCounts[bestIntent.key] ?? 0) + 1;

    final isCasual = bestIntent.value >= 0.3;

    return DetectedIntent(
      type: bestIntent.key,
      confidence: bestIntent.value.clamp(0.0, 1.0),
      isCasual: isCasual,
      alternativeIntents: scores.entries
          .where((e) => e.key != bestIntent.key)
          .map((e) => e.key)
          .take(2)
          .toList(),
    );
  }

  List<MapEntry<CasualIntentType, int>> getCommonIntents() {
    final sorted = _intentCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }
}

class SentimentAnalyzer {
  final Map<String, double> _sentimentLexicon = {

    'عالی': 1.0, 'خوب': 0.8, 'دوست': 0.9, 'ممنون': 0.8,
    'عشق': 1.0, 'قشنگ': 0.9, 'باحال': 0.8, 'حرف نداره': 1.0,
    'فوق‌العاده': 1.0, 'perfect': 1.0, 'great': 0.9, 'love': 1.0,
    'amazing': 1.0, 'wonderful': 1.0, 'excellent': 1.0,
    'آفرین': 0.9, 'برو': 0.7, 'شاد': 0.9, 'خوشحال': 0.9,

    'بد': -0.8, 'ناراحت': -0.8, 'عصبانی': -1.0, 'دلخور': -0.7,
    'افسرده': -1.0, 'خسته': -0.6, 'کلافه': -0.8, 'ناامید': -0.9,
    'غمگین': -0.8, 'sad': -0.8, 'angry': -1.0, 'bad': -0.8,
    'terrible': -1.0, 'awful': -1.0, 'hate': -1.0,
    'ضایع': -0.7, 'مزخرف': -0.9, 'چرت': -0.7,

    'خوبه': 0.6, 'نه بد': 0.5, 'قابل قبول': 0.5,
    'ok': 0.4, 'okay': 0.4, 'fine': 0.5,
  };

  final Queue<SentimentScore> _history = Queue();

  SentimentScore analyze(String text) {
    final tokens = text.toLowerCase().split(RegExp(r'\s+'));
    double totalScore = 0.0;
    int matchedWords = 0;
    final matchedTerms = <String>[];

    for (var token in tokens) {
      if (_sentimentLexicon.containsKey(token)) {
        totalScore += _sentimentLexicon[token]!;
        matchedWords++;
        matchedTerms.add(token);
      }
    }

    final avgScore = matchedWords > 0 ? totalScore / matchedWords : 0.0;

    SentimentType type;
    if (avgScore > 0.4) {
      type = SentimentType.positive;
    } else if (avgScore < -0.4) {
      type = SentimentType.negative;
    } else {
      type = SentimentType.neutral;
    }

    final result = SentimentScore(
      type: type,
      score: avgScore,
      confidence: matchedWords / max(tokens.length, 1),
      matchedTerms: matchedTerms,
    );

    _history.add(result);
    if (_history.length > 50) _history.removeFirst();

    return result;
  }

  Map<SentimentType, int> getTrends() {
    final trends = <SentimentType, int>{};
    for (var score in _history) {
      trends[score.type] = (trends[score.type] ?? 0) + 1;
    }
    return trends;
  }
}

class EmotionRecognizer {
  final Map<EmotionType, List<String>> _emotionPatterns = {

    EmotionType.happy: ['😊', '😄', '😁', '🎉', '❤️', 'خوشحال', 'شاد'],
    EmotionType.sad: ['😢', '😭', '💔', '😞', 'غمگین', 'ناراحت'],
    EmotionType.angry: ['😠', '😡', '💢', 'عصبانی', 'عصبی'],
    EmotionType.excited: ['🔥', '🚀', '⚡', 'هیجان', 'هیجان‌زده'],
    EmotionType.confused: ['🤔', '😕', '❓', 'سردرگم', 'گیج'],
    EmotionType.grateful: ['🙏', '❤️', 'ممنون', 'متشکر', 'سپاس'],
    EmotionType.bored: ['😴', '🥱', 'حوصله', 'خسته', 'کسل'],
    EmotionType.surprised: ['😮', '😲', '🤯', 'واو', 'جدی'],
  };

  final Map<EmotionType, int> _emotionCounts = {};

  EmotionType recognize(String message, SentimentScore sentiment) {
    for (var entry in _emotionPatterns.entries) {
      for (var pattern in entry.value) {
        if (message.contains(pattern)) {
          _emotionCounts[entry.key] = (_emotionCounts[entry.key] ?? 0) + 1;
          return entry.key;
        }
      }
    }

    if (sentiment.score > 0.6) {
      _emotionCounts[EmotionType.happy] = (_emotionCounts[EmotionType.happy] ?? 0) + 1;
      return EmotionType.happy;
    } else if (sentiment.score < -0.6) {
      _emotionCounts[EmotionType.sad] = (_emotionCounts[EmotionType.sad] ?? 0) + 1;
      return EmotionType.sad;
    }

    _emotionCounts[EmotionType.neutral] = (_emotionCounts[EmotionType.neutral] ?? 0) + 1;
    return EmotionType.neutral;
  }

  Map<EmotionType, int> getEmotionDistribution() => Map.from(_emotionCounts);
}

class PersonalityEngine {
  final AssistantPersonality _personality = AssistantPersonality(
    name: 'دستیار هوشمند',
    traits: {
      'friendliness': 0.9,
      'professionalism': 0.8,
      'humor': 0.6,
      'empathy': 0.9,
      'patience': 0.95,
    },
    emotionalIntelligence: 0.85,
    communicationStyle: CommunicationStyle.friendly,
  );

  AssistantPersonality getPersonality() => _personality;

  CommunicationStyle adjustStyle(ConversationContext context) {
    if (context.userMood == EmotionType.sad ||
        context.userMood == EmotionType.angry) {
      return CommunicationStyle.empathetic;
    } else if (context.interactionCount > 10) {
      return CommunicationStyle.casual;
    }
    return CommunicationStyle.friendly;
  }
}

class ContextTracker {
  final Queue<ConversationTurn> _history = Queue();
  int _totalInteractions = 0;
  EmotionType _currentMood = EmotionType.neutral;
  DateTime? _lastInteractionTime;

  void update({
    required String message,
    required DetectedIntent intent,
    required EmotionType emotion,
  }) {
    _history.add(ConversationTurn(
      message: message,
      intent: intent.type,
      emotion: emotion,
      timestamp: DateTime.now(),
    ));

    if (_history.length > 20) _history.removeFirst();

    _totalInteractions++;
    _currentMood = emotion;
    _lastInteractionTime = DateTime.now();
  }

  ConversationContext getCurrentContext() {
    final recentIntents = _history.map((t) => t.intent).toList();
    final moodChanges = _detectMoodChanges();

    return ConversationContext(
      recentIntents: recentIntents,
      userMood: _currentMood,
      interactionCount: _totalInteractions,
      sessionDuration: _getSessionDuration(),
      moodChanges: moodChanges,
      lastInteractionTime: _lastInteractionTime,
    );
  }

  int _detectMoodChanges() {
    if (_history.length < 2) return 0;

    int changes = 0;
    final turns = _history.toList();

    for (int i = 1; i < turns.length; i++) {
      if (turns[i].emotion != turns[i - 1].emotion) {
        changes++;
      }
    }

    return changes;
  }

  Duration _getSessionDuration() {
    if (_history.isEmpty) return Duration.zero;
    final first = _history.first.timestamp;
    final last = _history.last.timestamp;
    return last.difference(first);
  }

  int getTotalInteractions() => _totalInteractions;

  void reset() {
    _history.clear();
    _totalInteractions = 0;
    _currentMood = EmotionType.neutral;
    _lastInteractionTime = null;
  }
}

class ResponseGenerator {
  final SmallTalkDatabase _database = SmallTalkDatabase();
  final Random _random = Random();

  Future<String> generate({
    required DetectedIntent intent,
    required SentimentScore sentiment,
    required EmotionType emotion,
    required ConversationContext context,
    required AssistantPersonality personality,
    required List<String> conversationHistory,
  }) async {

    String baseResponse = _selectBaseResponse(intent.type, context);

    baseResponse = _personalizeForEmotion(baseResponse, emotion, sentiment);

    baseResponse = _addEmoji(baseResponse, emotion);

    if (_shouldAddSuggestion(context)) {
      baseResponse += '\n\n' + _generateSuggestion(intent.type);
    }

    return baseResponse;
  }

  String _selectBaseResponse(CasualIntentType intent, ConversationContext context) {
    final responses = _database.getResponses(intent);

    if (context.interactionCount > 5) {
      return responses[_random.nextInt(responses.length)];
    }

    return responses[0];
  }

  String _personalizeForEmotion(
    String response,
    EmotionType emotion,
    SentimentScore sentiment,
  ) {
    if (emotion == EmotionType.sad || emotion == EmotionType.angry) {
      final empathy = [
        'متوجه‌م. ',
        'درکت می‌کنم. ',
        'می‌فهمم چه حسی داری. ',
      ];
      response = empathy[_random.nextInt(empathy.length)] + response;
    }

    if (emotion == EmotionType.happy || emotion == EmotionType.excited) {
      response = response.replaceAll('.', '!');
    }

    return response;
  }

  String _addEmoji(String response, EmotionType emotion) {
    final emojiMap = {
      EmotionType.happy: ['😊', '😄', '🎉'],
      EmotionType.sad: ['🤗', '💙'],
      EmotionType.excited: ['🔥', '⚡', '🚀'],
      EmotionType.grateful: ['❤️', '🙏'],
      EmotionType.confused: ['🤔', '💡'],
    };

    if (emojiMap.containsKey(emotion)) {
      final emojis = emojiMap[emotion]!;
      if (_random.nextDouble() > 0.5) {
        response += ' ' + emojis[_random.nextInt(emojis.length)];
      }
    }

    return response;
  }

  bool _shouldAddSuggestion(ConversationContext context) {

    return context.interactionCount > 0 &&
           context.interactionCount % 3 == 0;
  }

  String _generateSuggestion(CasualIntentType intent) {
    final suggestions = {
      CasualIntentType.greeting: 'می‌خوای راجع به چی صحبت کنیم؟',
      CasualIntentType.howAreYou: 'اگر سوالی داری، بپرس!',
      CasualIntentType.thanks: 'سوال دیگه‌ای داری؟',
      CasualIntentType.helpRequest: 'موضوع خاصی هست که کمکت کنم؟',
    };

    return suggestions[intent] ?? 'چطور می‌تونم کمکت کنم؟';
  }
}

class SmallTalkDatabase {
  final Map<CasualIntentType, List<String>> _responses = {
    CasualIntentType.greeting: [
      'سلام! چطور می‌تونم کمکت کنم؟',
      'درود! خوشحالم که اینجایی 😊',
      'سلام عزیز! چه خبر؟',
      'هی! خوش اومدی 👋',
      'سلام! آماده‌ام تا کمکت کنم',
    ],

    CasualIntentType.howAreYou: [
      'من یه دستیار هوشمندم، همیشه آماده کمک! تو چطوری؟',
      'خوبم ممنون! امیدوارم تو هم حالت خوب باشه 😊',
      'عالیم! تو چطوری؟ چیکار می‌تونم برات انجام بدم؟',
      'خوبم! خوشحالم که می‌بینمت. چه کمکی می‌تونم بکنم؟',
      'حالم فوق‌العادست! امروز چه کاری داری؟',
    ],

    CasualIntentType.thanks: [
      'خواهش می‌کنم! خوشحالم که تونستم کمک کنم 😊',
      'قابلی نداره! هر وقت نیاز داشتی بگو',
      'هیچی نگو! همیشه اینجام برای کمک',
      'خیلی خوشحالم که مفید بودم! ❤️',
      'وظیفه‌س! موفق باشی',
    ],

    CasualIntentType.goodbye: [
      'خداحافظ! موفق باشی 👋',
      'به امید دیدار! مراقب خودت باش',
      'فعلا! هر وقت خواستی برگرد',
      'خدانگهدار! همیشه خوشحالم که کمکت کنم',
      'بای! روز خوبی داشته باشی',
    ],

    CasualIntentType.helpRequest: [
      'حتما! بگو چه کمکی می‌تونم بکنم',
      'البته! من اینجام تا کمکت کنم. موضوع چیه؟',
      'خوشحال می‌شم کمکت کنم! چیکار می‌خوای انجام بدی؟',
      'بله عزیز! سوالت رو بپرس',
      'آره حتما! بگو چی نیاز داری',
    ],

    CasualIntentType.positiveFeeling: [
      'وای چقدر خوشحالم! 🎉',
      'عالیه! خیلی خوشحالم که راضی هستی',
      'آره! خیلی باحاله 😄',
      'واقعا خوشحالم که اینطور فکر می‌کنی!',
      'ممنونم! تو هم فوق‌العاده‌ای ❤️',
    ],

    CasualIntentType.negativeFeeling: [
      'متاسفم که ناراحت شدی. چه اتفاقی افتاده؟',
      'خیلی ببخشید. بگو چطور می‌تونم کمکت کنم',
      'نگران نباش، با هم حلش می‌کنیم 💙',
      'درکت می‌کنم. بیا باهم یه راه حل پیدا کنیم',
      'ناراحت نباش، من اینجام تا کمکت کنم 🤗',
    ],

    CasualIntentType.joke: [
      'هههه، خنده دار بود! 😄',
      'لول! باحال بود 🤣',
      'دهنت سرویس! 😂',
      'خخخ، عالی بود!',
      'خیلی بامزه بود! من هم یکی می‌گم؟',
    ],

    CasualIntentType.generalQuestion: [
      'سوال جالبیه! بذار فکر کنم...',
      'خب، راجع به این موضوع...',
      'سوال خوبیه! بگم چی؟',
      'جالبه که پرسیدی! خب...',
      'اوه، این یه سوال عمیقه! 🤔',
    ],

    CasualIntentType.introduction: [
      'من یه دستیار هوشمند مبتنی بر ML/NLP هستم که برای کمک به شما ساخته شدم! 🤖',
      'اسم من دستیار هوشمند اصول کامپایلره. من با الگوریتم‌های پیشرفته ML یاد می‌گیرم',
      'من یه AI Assistant هستم که با سیستم 3 لایه ML/NLP کار می‌کنم. می‌تونم کمکت کنم!',
      'من دستیار هوشمند پروژه MiniLang هستم. برنامه‌نویسی و آموزش تخصصمه! 😊',
      'من یه هوش مصنوعی یادگیرندم که اینجام تا بهترین کمک رو بهت بکنم',
    ],

    CasualIntentType.compliment: [
      'ممنونم! تو هم خیلی مهربونی ❤️',
      'وای خجالت می‌کشم! تو عالی‌تری 😊',
      'ممنون از محبتت! خوشحالم که دوستم داری',
      'آخ دلم! خیلی مهربونی 🤗',
      'ای بابا! شرمنده‌ام، تو هم فوق‌العاده‌ای',
    ],

    CasualIntentType.bored: [
      'بیا یه چیز جالب یاد بگیریم! 🚀',
      'حوصله‌ت سر رفته؟ بیا یه مفهوم جدید یاد بگیریم',
      'خسته شدی؟ بذار یه موضوع باحال بهت نشون بدم',
      'اوکی، بیا یه چیز هیجان‌انگیز کار کنیم! ⚡',
      'حوصله نداری؟ چیکار دوست داری انجام بدی؟',
    ],

    CasualIntentType.suggestion: [
      'خب، بذار ببینم چه پیشنهادی دارم...',
      'نظرم اینه که...',
      'به نظرم بهتره که...',
      'پیشنهاد من اینه: ...',
      'یه راه خوب اینه که...',
    ],
  };

  List<String> getResponses(CasualIntentType intent) {
    return _responses[intent] ?? ['چطور می‌تونم کمکت کنم؟'];
  }
}

enum CasualIntentType {
  greeting,
  howAreYou,
  thanks,
  goodbye,
  helpRequest,
  positiveFeeling,
  negativeFeeling,
  joke,
  generalQuestion,
  introduction,
  compliment,
  bored,
  suggestion,
  technical,
}

class DetectedIntent {
  final CasualIntentType type;
  final double confidence;
  final bool isCasual;
  final List<CasualIntentType> alternativeIntents;

  DetectedIntent({
    required this.type,
    required this.confidence,
    required this.isCasual,
    this.alternativeIntents = const [],
  });

  @override
  String toString() => 'Intent: $type (${(confidence * 100).toInt()}%)';
}

enum SentimentType {
  positive,
  negative,
  neutral,
}

class SentimentScore {
  final SentimentType type;
  final double score;
  final double confidence;
  final List<String> matchedTerms;

  SentimentScore({
    required this.type,
    required this.score,
    required this.confidence,
    required this.matchedTerms,
  });

  @override
  String toString() => 'Sentiment: $type (${score.toStringAsFixed(2)})';
}

enum EmotionType {
  happy,
  sad,
  angry,
  excited,
  confused,
  grateful,
  bored,
  surprised,
  neutral,
}

enum CommunicationStyle {
  formal,
  friendly,
  casual,
  empathetic,
  professional,
}

class AssistantPersonality {
  final String name;
  final Map<String, double> traits;
  final double emotionalIntelligence;
  final CommunicationStyle communicationStyle;

  AssistantPersonality({
    required this.name,
    required this.traits,
    required this.emotionalIntelligence,
    required this.communicationStyle,
  });
}

class ConversationTurn {
  final String message;
  final CasualIntentType intent;
  final EmotionType emotion;
  final DateTime timestamp;

  ConversationTurn({
    required this.message,
    required this.intent,
    required this.emotion,
    required this.timestamp,
  });
}

class ConversationContext {
  final List<CasualIntentType> recentIntents;
  final EmotionType userMood;
  final int interactionCount;
  final Duration sessionDuration;
  final int moodChanges;
  final DateTime? lastInteractionTime;

  ConversationContext({
    required this.recentIntents,
    required this.userMood,
    required this.interactionCount,
    required this.sessionDuration,
    required this.moodChanges,
    this.lastInteractionTime,
  });

  bool get isLongSession => sessionDuration.inMinutes > 10;
  bool get isFrequentUser => interactionCount > 20;
  bool get hasRecentActivity =>
      lastInteractionTime != null &&
      DateTime.now().difference(lastInteractionTime!).inMinutes < 5;
}

class CasualResponse {
  final String text;
  final DetectedIntent intent;
  final SentimentScore sentiment;
  final EmotionType emotion;
  final double confidence;
  final bool isCasual;

  CasualResponse({
    required this.text,
    required this.intent,
    required this.sentiment,
    required this.emotion,
    required this.confidence,
    required this.isCasual,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'intent': intent.type.toString(),
        'sentiment': sentiment.type.toString(),
        'emotion': emotion.toString(),
        'confidence': confidence,
        'is_casual': isCasual,
      };

  @override
  String toString() {
    return '''
╔═══════════════════════════════════════════════════════════╗
║  💬 پاسخ مکالمه غیرفنی                                    ║
╠═══════════════════════════════════════════════════════════╣
║  📝 پاسخ: $text
║  🎯 Intent: ${intent.type}
║  😊 Sentiment: ${sentiment.type}
║  🎭 Emotion: $emotion
║  ⚡ اطمینان: ${(confidence * 100).toInt()}%
╚═══════════════════════════════════════════════════════════╝
''';
  }
}

/*
void main() async {
  final handler = CasualConversationHandler();

  // تست سناریوهای مختلف
  final testMessages = [
    'سلام',
    'چطوری؟',
    'خیلی ممنون از کمکت',
    'ناراحتم 😢',
    'عالی هستی! ❤️',
    'حوصله‌م سر رفته',
    'خداحافظ',
  ];

  for (var message in testMessages) {
    print('\n📨 پیام کاربر: "$message"');
    
    final response = await handler.handleCasualMessage(
      message: message,
      conversationHistory: [],
    );

    if (response != null) {
      print(response);
    } else {
      print('⚙️ پیام فنی شناسایی شد - ارسال به موتور ML/NLP اصلی');
    }
  }

  // نمایش آمار
  print('\n📊 آمار مکالمات:');
  print(handler.getStatistics());
}
*/

extension CasualConversationExtension on Object {

  static Future<CasualResponse?> checkCasualMessage({
    required String message,
    required List<String> conversationHistory,
    Map<String, dynamic>? userProfile,
  }) async {
    final handler = CasualConversationHandler();
    
    return await handler.handleCasualMessage(
      message: message,
      conversationHistory: conversationHistory,
      userProfile: userProfile,
    );
  }
}

class CasualConversationAnalytics {
  static String generateReport(CasualConversationHandler handler) {
    final stats = handler.getStatistics();
    
    return '''
╔═══════════════════════════════════════════════════════════╗
║  📊 گزارش مکالمات غیرفنی                                  ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  📈 تعداد کل مکالمات: ${stats['total_casual_interactions']}                          ║
║                                                           ║
║  🎭 توزیع احساسات:                                        ║
${_formatEmotionDistribution(stats['emotion_distribution'])}
║                                                           ║
║  🎯 Intent‌های پرتکرار:                                   ║
${_formatCommonIntents(stats['common_intents'])}
║                                                           ║
║  😊 روند Sentiment:                                       ║
${_formatSentimentTrends(stats['sentiment_trends'])}
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
''';
  }

  static String _formatEmotionDistribution(Map<EmotionType, int> emotions) {
    if (emotions.isEmpty) return '║  (هنوز داده‌ای ثبت نشده)                              ║';
    
    final lines = <String>[];
    final sorted = emotions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (var entry in sorted.take(5)) {
      final emoji = _getEmotionEmoji(entry.key);
      lines.add('║  $emoji ${_translateEmotion(entry.key)}: ${entry.value}                                ║');
    }
    
    return lines.join('\n');
  }

  static String _formatCommonIntents(List<MapEntry<CasualIntentType, int>> intents) {
    if (intents.isEmpty) return '║  (هنوز داده‌ای ثبت نشده)                              ║';
    
    final lines = <String>[];
    for (var entry in intents.take(5)) {
      lines.add('║  • ${_translateIntent(entry.key)}: ${entry.value}                           ║');
    }
    
    return lines.join('\n');
  }

  static String _formatSentimentTrends(Map<SentimentType, int> trends) {
    if (trends.isEmpty) return '║  (هنوز داده‌ای ثبت نشده)                              ║';
    
    final total = trends.values.fold(0, (a, b) => a + b);
    final lines = <String>[];
    
    for (var entry in trends.entries) {
      final percentage = ((entry.value / total) * 100).toInt();
      lines.add('║  ${_getSentimentEmoji(entry.key)} ${_translateSentiment(entry.key)}: $percentage%                         ║');
    }
    
    return lines.join('\n');
  }

  static String _getEmotionEmoji(EmotionType emotion) {
    const emojis = {
      EmotionType.happy: '😊',
      EmotionType.sad: '😢',
      EmotionType.angry: '😠',
      EmotionType.excited: '🔥',
      EmotionType.confused: '🤔',
      EmotionType.grateful: '🙏',
      EmotionType.bored: '😴',
      EmotionType.surprised: '😮',
      EmotionType.neutral: '😐',
    };
    return emojis[emotion] ?? '😐';
  }

  static String _getSentimentEmoji(SentimentType sentiment) {
    const emojis = {
      SentimentType.positive: '😊',
      SentimentType.negative: '😞',
      SentimentType.neutral: '😐',
    };
    return emojis[sentiment] ?? '😐';
  }

  static String _translateEmotion(EmotionType emotion) {
    const translations = {
      EmotionType.happy: 'خوشحال',
      EmotionType.sad: 'غمگین',
      EmotionType.angry: 'عصبانی',
      EmotionType.excited: 'هیجان‌زده',
      EmotionType.confused: 'گیج',
      EmotionType.grateful: 'سپاسگزار',
      EmotionType.bored: 'خسته',
      EmotionType.surprised: 'متعجب',
      EmotionType.neutral: 'خنثی',
    };
    return translations[emotion] ?? 'نامشخص';
  }

  static String _translateIntent(CasualIntentType intent) {
    const translations = {
      CasualIntentType.greeting: 'سلام',
      CasualIntentType.howAreYou: 'احوالپرسی',
      CasualIntentType.thanks: 'تشکر',
      CasualIntentType.goodbye: 'خداحافظی',
      CasualIntentType.helpRequest: 'درخواست کمک',
      CasualIntentType.positiveFeeling: 'احساس مثبت',
      CasualIntentType.negativeFeeling: 'احساس منفی',
      CasualIntentType.joke: 'شوخی',
      CasualIntentType.generalQuestion: 'سوال عمومی',
      CasualIntentType.introduction: 'معرفی',
      CasualIntentType.compliment: 'تعارف',
      CasualIntentType.bored: 'خستگی',
      CasualIntentType.suggestion: 'پیشنهاد',
    };
    return translations[intent] ?? 'نامشخص';
  }

  static String _translateSentiment(SentimentType sentiment) {
    const translations = {
      SentimentType.positive: 'مثبت',
      SentimentType.negative: 'منفی',
      SentimentType.neutral: 'خنثی',
    };
    return translations[sentiment] ?? 'نامشخص';
  }
}
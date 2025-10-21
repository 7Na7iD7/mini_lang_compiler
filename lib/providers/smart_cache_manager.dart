import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ast_nodes.dart';
import '../models/token_types.dart';

class CachedCompilationResult {
  final String sourceCodeHash;
  final List<Token> tokens;
  final Program? ast;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic> statistics;
  final DateTime cachedAt;
  final String compilerVersion;

  CachedCompilationResult({
    required this.sourceCodeHash,
    required this.tokens,
    required this.ast,
    required this.errors,
    required this.warnings,
    required this.statistics,
    required this.cachedAt,
    required this.compilerVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'sourceCodeHash': sourceCodeHash,
      'tokens': tokens.map((t) => {
        'type': t.type.toString(),
        'value': t.value,
        'line': t.line,
        'column': t.column,
      }).toList(),
      'ast': ast?.toJson(),
      'errors': errors,
      'warnings': warnings,
      'statistics': statistics,
      'cachedAt': cachedAt.millisecondsSinceEpoch,
      'compilerVersion': compilerVersion,
    };
  }

  factory CachedCompilationResult.fromJson(Map<String, dynamic> json) {
    return CachedCompilationResult(
      sourceCodeHash: json['sourceCodeHash'],
      tokens: (json['tokens'] as List).map((t) => Token(
        type: TokenType.values.firstWhere((type) => type.toString() == t['type']),
        value: t['value'],
        line: t['line'] ?? 0,
        column: t['column'] ?? 0,
      )).toList(),
      ast: json['ast'] != null ? Program.fromJson(json['ast']) : null,
      errors: List<String>.from(json['errors']),
      warnings: List<String>.from(json['warnings']),
      statistics: Map<String, dynamic>.from(json['statistics']),
      cachedAt: DateTime.fromMillisecondsSinceEpoch(json['cachedAt']),
      compilerVersion: json['compilerVersion'],
    );
  }

  bool isValid() {
    final now = DateTime.now();
    final maxAge = Duration(hours: 1);
    return now.difference(cachedAt) < maxAge &&
        compilerVersion == getCurrentCompilerVersion();
  }
}

class SmartCacheManager {
  static const String CACHE_KEY_PREFIX = 'compiler_cache_';
  static const String STATS_KEY = 'cache_statistics';
  static const int MAX_CACHE_ENTRIES = 50;

  SharedPreferences? _prefs;
  Map<String, CachedCompilationResult> _memoryCache = {};

  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCacheStatistics();
    await _cleanupExpiredEntries();
  }

  String _generateHash(String sourceCode) {
    final bytes = utf8.encode(sourceCode.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<CachedCompilationResult?> getCachedResult(String sourceCode) async {
    if (_prefs == null) await initialize();

    final hash = _generateHash(sourceCode);

    if (_memoryCache.containsKey(hash)) {
      final cached = _memoryCache[hash]!;
      if (cached.isValid()) {
        _hits++;
        await _updateCacheStatistics();
        return cached;
      } else {
        _memoryCache.remove(hash);
      }
    }

    final cacheKey = CACHE_KEY_PREFIX + hash;
    final cachedJson = _prefs!.getString(cacheKey);

    if (cachedJson != null) {
      try {
        final cachedResult = CachedCompilationResult.fromJson(jsonDecode(cachedJson));
        if (cachedResult.isValid()) {
          _memoryCache[hash] = cachedResult;
          _hits++;
          await _updateCacheStatistics();
          return cachedResult;
        } else {
          await _prefs!.remove(cacheKey);
        }
      } catch (e) {
        await _prefs!.remove(cacheKey);
      }
    }

    _misses++;
    await _updateCacheStatistics();
    return null;
  }

  Future<void> cacheResult(
      String sourceCode,
      List<Token> tokens,
      Program? ast,
      List<String> errors,
      List<String> warnings,
      Map<String, dynamic> statistics,
      ) async {
    if (_prefs == null) await initialize();

    final hash = _generateHash(sourceCode);
    final cachedResult = CachedCompilationResult(
      sourceCodeHash: hash,
      tokens: tokens,
      ast: ast,
      errors: errors,
      warnings: warnings,
      statistics: statistics,
      cachedAt: DateTime.now(),
      compilerVersion: getCurrentCompilerVersion(),
    );

    _memoryCache[hash] = cachedResult;

    final cacheKey = CACHE_KEY_PREFIX + hash;
    final jsonString = jsonEncode(cachedResult.toJson());
    await _prefs!.setString(cacheKey, jsonString);

    await _manageCacheSize();
  }

  Future<void> _manageCacheSize() async {
    final keys = _prefs!.getKeys().where((k) => k.startsWith(CACHE_KEY_PREFIX)).toList();

    if (keys.length > MAX_CACHE_ENTRIES) {
      final entries = <String, DateTime>{};

      for (final key in keys) {
        final cachedJson = _prefs!.getString(key);
        if (cachedJson != null) {
          try {
            final cached = CachedCompilationResult.fromJson(jsonDecode(cachedJson));
            entries[key] = cached.cachedAt;
          } catch (e) {
            await _prefs!.remove(key);
          }
        }
      }

      final sortedEntries = entries.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final entriesToRemove = sortedEntries.length - MAX_CACHE_ENTRIES;
      for (int i = 0; i < entriesToRemove; i++) {
        await _prefs!.remove(sortedEntries[i].key);
        _evictions++;
      }
    }

    if (_memoryCache.length > MAX_CACHE_ENTRIES) {
      final sortedEntries = _memoryCache.entries.toList()
        ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));

      final entriesToRemove = _memoryCache.length - MAX_CACHE_ENTRIES;
      for (int i = 0; i < entriesToRemove; i++) {
        _memoryCache.remove(sortedEntries[i].key);
      }
    }
  }

  Future<void> _cleanupExpiredEntries() async {
    if (_prefs == null) return;

    final keys = _prefs!.getKeys().where((k) => k.startsWith(CACHE_KEY_PREFIX)).toList();

    for (final key in keys) {
      final cachedJson = _prefs!.getString(key);
      if (cachedJson != null) {
        try {
          final cached = CachedCompilationResult.fromJson(jsonDecode(cachedJson));
          if (!cached.isValid()) {
            await _prefs!.remove(key);
          }
        } catch (e) {
          await _prefs!.remove(key);
        }
      }
    }

    _memoryCache.removeWhere((key, value) => !value.isValid());
  }

  Future<void> _loadCacheStatistics() async {
    if (_prefs == null) return;

    final statsJson = _prefs!.getString(STATS_KEY);
    if (statsJson != null) {
      try {
        final stats = jsonDecode(statsJson);
        _hits = stats['hits'] ?? 0;
        _misses = stats['misses'] ?? 0;
        _evictions = stats['evictions'] ?? 0;
      } catch (e) {
        _hits = _misses = _evictions = 0;
      }
    }
  }

  Future<void> _updateCacheStatistics() async {
    if (_prefs == null) return;

    final stats = {
      'hits': _hits,
      'misses': _misses,
      'evictions': _evictions,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };

    await _prefs!.setString(STATS_KEY, jsonEncode(stats));
  }

  Future<void> clearCache() async {
    if (_prefs == null) return;

    final keys = _prefs!.getKeys().where((k) => k.startsWith(CACHE_KEY_PREFIX)).toList();
    for (final key in keys) {
      await _prefs!.remove(key);
    }

    _memoryCache.clear();
    _hits = _misses = _evictions = 0;
    await _updateCacheStatistics();
  }

  Map<String, dynamic> getCacheStatistics() {
    final totalRequests = _hits + _misses;
    final hitRate = totalRequests > 0 ? (_hits / totalRequests * 100).toStringAsFixed(2) : '0.00';

    return {
      'hits': _hits,
      'misses': _misses,
      'evictions': _evictions,
      'hitRate': '$hitRate%',
      'memoryCacheSize': _memoryCache.length,
      'totalRequests': totalRequests,
    };
  }

  Future<void> preloadExamples() async {
    final examples = [
      '''int function fibonacci(int n) {
    if (n <= 1) {
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}''',
      '''int numbers[5];
numbers[0] = 10;
numbers[1] = 20;''',
      '''string message = "Hello World";
print(message);''',
    ];

    for (final example in examples) {
    }
  }

  Future<void> optimizeCache() async {
    await _cleanupExpiredEntries();
    await _manageCacheSize();
  }
}

String getCurrentCompilerVersion() {
  return '1.0.0';
}

mixin CacheableMixin {
  static final SmartCacheManager _cacheManager = SmartCacheManager();

  SmartCacheManager get cacheManager => _cacheManager;

  Future<void> initializeCache() async {
    await _cacheManager.initialize();
  }

  Future<CachedCompilationResult?> getCachedCompilation(String sourceCode) async {
    return await _cacheManager.getCachedResult(sourceCode);
  }

  Future<void> cacheCompilationResult(
      String sourceCode,
      List<Token> tokens,
      Program? ast,
      List<String> errors,
      List<String> warnings,
      Map<String, dynamic> statistics,
      ) async {
    await _cacheManager.cacheResult(
        sourceCode, tokens, ast, errors, warnings, statistics
    );
  }

  Map<String, dynamic> getCacheStats() {
    return _cacheManager.getCacheStatistics();
  }

  Future<void> clearCompilerCache() async {
    await _cacheManager.clearCache();
  }
}
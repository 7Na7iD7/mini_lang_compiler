import 'dart:async';
import 'dart:math' as math;

class CompilerPerformanceAnalyzer {
  final List<PerformanceMetric> _metrics = [];
  final Map<String, List<int>> _phaseDurations = {};
  final Map<String, CacheStatistics> _cacheStats = {};

  static const int warmupIterations = 3;
  static const int benchmarkIterations = 10;
  static const double confidenceLevel = 0.95;

  void recordMetric(PerformanceMetric metric) {
    _metrics.add(metric);

    for (var phase in metric.phases) {
      _phaseDurations.putIfAbsent(phase.name, () => []);
      _phaseDurations[phase.name]!.add(phase.duration.inMicroseconds);
    }

    if (metric.cacheHit) {
      _cacheStats.putIfAbsent('cache', () => CacheStatistics());
      _cacheStats['cache']!.recordHit();
    } else {
      _cacheStats.putIfAbsent('cache', () => CacheStatistics());
      _cacheStats['cache']!.recordMiss();
    }
  }

  PerformanceStatistics calculateStatistics() {
    if (_metrics.isEmpty) {
      throw StateError('No metrics recorded');
    }

    return PerformanceStatistics(
      totalCompilations: _metrics.length,
      overallStats: _calculateOverallStatistics(),
      phaseStats: _calculatePhaseStatistics(),
      cacheEfficiency: _calculateCacheEfficiency(),
      temporalAnalysis: _performTemporalAnalysis(),
      complexityAnalysis: _analyzeComplexity(),
      outlierDetection: _detectOutliers(),
      performanceRegression: _detectPerformanceRegression(),
    );
  }

  StatisticalSummary _calculateOverallStatistics() {
    final durations = _metrics.map((m) => m.totalDuration.inMicroseconds).toList();
    return _computeStatistics(durations, 'Overall Compilation');
  }

  Map<String, StatisticalSummary> _calculatePhaseStatistics() {
    final Map<String, StatisticalSummary> stats = {};

    for (var entry in _phaseDurations.entries) {
      stats[entry.key] = _computeStatistics(entry.value, entry.key);
    }

    return stats;
  }

  StatisticalSummary _computeStatistics(List<int> data, String label) {
    if (data.isEmpty) {
      return StatisticalSummary.empty(label);
    }

    final sorted = List<int>.from(data)..sort();
    final n = data.length;

    final mean = data.reduce((a, b) => a + b) / n;

    final variance = data.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / n;
    final stdDev = math.sqrt(variance);

    final median = n.isOdd
        ? sorted[n ~/ 2].toDouble()
        : (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2.0;

    final q1 = _calculatePercentile(sorted, 25);
    final q3 = _calculatePercentile(sorted, 75);
    final iqr = q3 - q1;

    final p5 = _calculatePercentile(sorted, 5);
    final p95 = _calculatePercentile(sorted, 95);
    final p99 = _calculatePercentile(sorted, 99);

    final cv = mean > 0 ? (stdDev / mean) * 100 : 0.0;

    final skewness = _calculateSkewness(data, mean, stdDev);

    final kurtosis = _calculateKurtosis(data, mean, stdDev);

    final ci95 = _calculateConfidenceInterval(mean, stdDev, n, confidenceLevel);

    return StatisticalSummary(
      label: label,
      count: n,
      mean: mean,
      median: median,
      stdDev: stdDev,
      min: sorted.first.toDouble(),
      max: sorted.last.toDouble(),
      q1: q1,
      q3: q3,
      iqr: iqr,
      p5: p5,
      p95: p95,
      p99: p99,
      cv: cv,
      skewness: skewness,
      kurtosis: kurtosis,
      ci95Lower: ci95.$1,
      ci95Upper: ci95.$2,
    );
  }

  double _calculatePercentile(List<int> sorted, int percentile) {
    final index = (percentile / 100.0) * (sorted.length - 1);
    final lower = index.floor();
    final upper = index.ceil();
    final weight = index - lower;

    if (lower == upper) {
      return sorted[lower].toDouble();
    }

    return sorted[lower] * (1 - weight) + sorted[upper] * weight;
  }

  double _calculateSkewness(List<int> data, double mean, double stdDev) {
    if (stdDev == 0 || data.length < 3) return 0.0;

    final n = data.length;
    final sum = data.map((x) => math.pow((x - mean) / stdDev, 3)).reduce((a, b) => a + b);

    return (n / ((n - 1) * (n - 2))) * sum;
  }

  double _calculateKurtosis(List<int> data, double mean, double stdDev) {
    if (stdDev == 0 || data.length < 4) return 0.0;

    final n = data.length;
    final sum = data.map((x) => math.pow((x - mean) / stdDev, 4)).reduce((a, b) => a + b);

    final term1 = ((n * (n + 1)) / ((n - 1) * (n - 2) * (n - 3))) * sum;
    final term2 = (3 * math.pow(n - 1, 2)) / ((n - 2) * (n - 3));

    return term1 - term2;
  }

  (double, double) _calculateConfidenceInterval(
      double mean,
      double stdDev,
      int n,
      double confidence
      ) {
    if (n < 2) return (mean, mean);

    final alpha = 1 - confidence;
    final degreesOfFreedom = n - 1;

    double tCritical;
    if (degreesOfFreedom > 30) {
      tCritical = _normalInverseCDF(1 - alpha / 2);
    } else {
      tCritical = _getTCriticalValue(degreesOfFreedom, alpha / 2);
    }

    final marginOfError = tCritical * (stdDev / math.sqrt(n));

    return (mean - marginOfError, mean + marginOfError);
  }

  double _getTCriticalValue(int df, double alpha) {
    const tTable = {
      1: 12.706, 2: 4.303, 3: 3.182, 4: 2.776, 5: 2.571,
      6: 2.447, 7: 2.365, 8: 2.306, 9: 2.262, 10: 2.228,
      15: 2.131, 20: 2.086, 25: 2.060, 30: 2.042
    };

    if (tTable.containsKey(df)) {
      return tTable[df]!;
    }

    final keys = tTable.keys.where((k) => k <= df).toList()..sort();
    if (keys.isEmpty) return tTable[1]!;

    final lower = keys.last;
    final upper = tTable.keys.where((k) => k > df).toList()..sort();

    if (upper.isEmpty) return tTable[30]!;

    final lowerVal = tTable[lower]!;
    final upperVal = tTable[upper.first]!;
    final ratio = (df - lower) / (upper.first - lower);

    return lowerVal + ratio * (upperVal - lowerVal);
  }

  double _normalInverseCDF(double p) {
    final a = [2.50662823884, -18.61500062529, 41.39119773534, -25.44106049637];
    final b = [-8.47351093090, 23.08336743743, -21.06224101826, 3.13082909833];
    final c = [0.3374754822726147, 0.9761690190917186, 0.1607979714918209,
      0.0276438810333863, 0.0038405729373609, 0.0003951896511919,
      0.0000321767881768, 0.0000002888167364, 0.0000003960315187];

    if (p <= 0 || p >= 1) throw ArgumentError('p must be between 0 and 1');

    final y = p - 0.5;

    if (y.abs() < 0.42) {
      final r = y * y;
      var x = y * (((a[3] * r + a[2]) * r + a[1]) * r + a[0]);
      x /= ((((b[3] * r + b[2]) * r + b[1]) * r + b[0]) * r + 1);
      return x;
    }

    var r = p < 0.5 ? p : 1 - p;
    r = math.sqrt(-math.log(r));

    var x = c[8];
    for (var i = 7; i >= 0; i--) {
      x = x * r + c[i];
    }

    return p < 0.5 ? -x : x;
  }

  CacheEfficiencyMetrics _calculateCacheEfficiency() {
    final cacheStats = _cacheStats['cache'] ?? CacheStatistics();

    final totalAccess = cacheStats.hits + cacheStats.misses;
    if (totalAccess == 0) {
      return CacheEfficiencyMetrics.empty();
    }

    final hitRate = cacheStats.hits / totalAccess;
    final missRate = 1 - hitRate;

    final cachedMetrics = _metrics.where((m) => m.cacheHit).toList();
    final uncachedMetrics = _metrics.where((m) => !m.cacheHit).toList();

    final avgCachedTime = cachedMetrics.isEmpty
        ? 0.0
        : cachedMetrics.map((m) => m.totalDuration.inMicroseconds).reduce((a, b) => a + b) / cachedMetrics.length;

    final avgUncachedTime = uncachedMetrics.isEmpty
        ? 0.0
        : uncachedMetrics.map((m) => m.totalDuration.inMicroseconds).reduce((a, b) => a + b) / uncachedMetrics.length;

    final timeSaved = (avgUncachedTime - avgCachedTime) * cacheStats.hits;
    final speedup = avgCachedTime > 0 ? avgUncachedTime / avgCachedTime : 1.0;
    final effectiveness = avgUncachedTime > 0 ? hitRate * (1 - avgCachedTime / avgUncachedTime) : 0.0;

    return CacheEfficiencyMetrics(
      hitRate: hitRate,
      missRate: missRate,
      totalHits: cacheStats.hits,
      totalMisses: cacheStats.misses,
      avgCachedTime: avgCachedTime,
      avgUncachedTime: avgUncachedTime,
      timeSavedMicroseconds: timeSaved,
      speedupFactor: speedup,
      effectiveness: effectiveness,
    );
  }

  TemporalAnalysisResult _performTemporalAnalysis() {
    if (_metrics.length < 2) {
      return TemporalAnalysisResult.insufficient();
    }

    final trend = _calculateLinearTrend();
    final autocorrelation = _calculateAutocorrelation();
    final cyclicalPatterns = _detectCyclicalPatterns();
    final movingVariance = _calculateMovingVariance();

    return TemporalAnalysisResult(
      trend: trend,
      autocorrelation: autocorrelation,
      cyclicalPatterns: cyclicalPatterns,
      movingVariance: movingVariance,
    );
  }

  TrendAnalysis _calculateLinearTrend() {
    final n = _metrics.length;
    final x = List.generate(n, (i) => i.toDouble());
    final y = _metrics.map((m) => m.totalDuration.inMicroseconds.toDouble()).toList();

    final xMean = x.reduce((a, b) => a + b) / n;
    final yMean = y.reduce((a, b) => a + b) / n;

    var numerator = 0.0;
    var denominator = 0.0;

    for (var i = 0; i < n; i++) {
      numerator += (x[i] - xMean) * (y[i] - yMean);
      denominator += math.pow(x[i] - xMean, 2);
    }

    final slope = denominator != 0 ? numerator / denominator : 0.0;
    final intercept = yMean - slope * xMean;

    var ssRes = 0.0;
    var ssTot = 0.0;

    for (var i = 0; i < n; i++) {
      final predicted = intercept + slope * x[i];
      ssRes += math.pow(y[i] - predicted, 2);
      ssTot += math.pow(y[i] - yMean, 2);
    }

    final rSquared = ssTot != 0 ? 1 - (ssRes / ssTot) : 0.0;

    String interpretation;
    if (slope.abs() < 0.01) {
      interpretation = 'Stable: No significant trend detected';
    } else if (slope > 0) {
      interpretation = 'Degrading: Performance is decreasing over time';
    } else {
      interpretation = 'Improving: Performance is increasing over time';
    }

    return TrendAnalysis(
      slope: slope,
      intercept: intercept,
      rSquared: rSquared,
      interpretation: interpretation,
    );
  }

  List<double> _calculateAutocorrelation({int maxLag = 10}) {
    final durations = _metrics.map((m) => m.totalDuration.inMicroseconds.toDouble()).toList();
    final n = durations.length;

    if (n < maxLag + 1) return [];

    final mean = durations.reduce((a, b) => a + b) / n;
    final variance = durations.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b);

    if (variance == 0) return List.filled(maxLag, 0.0);

    final autocorr = <double>[];

    for (var lag = 1; lag <= maxLag; lag++) {
      var covariance = 0.0;

      for (var i = 0; i < n - lag; i++) {
        covariance += (durations[i] - mean) * (durations[i + lag] - mean);
      }

      autocorr.add(covariance / variance);
    }

    return autocorr;
  }

  CyclicalPatternAnalysis _detectCyclicalPatterns() {
    final durations = _metrics.map((m) => m.totalDuration.inMicroseconds.toDouble()).toList();
    final n = durations.length;

    if (n < 4) {
      return CyclicalPatternAnalysis(detected: false);
    }

    final mean = durations.reduce((a, b) => a + b) / n;
    final centered = durations.map((d) => d - mean).toList();

    final frequencies = <double>[];
    final magnitudes = <double>[];

    for (var k = 1; k < n ~/ 2; k++) {
      var real = 0.0;
      var imag = 0.0;

      for (var t = 0; t < n; t++) {
        final angle = 2 * math.pi * k * t / n;
        real += centered[t] * math.cos(angle);
        imag += centered[t] * math.sin(angle);
      }

      frequencies.add(k / n.toDouble());
      magnitudes.add(math.sqrt(real * real + imag * imag) * 2 / n);
    }

    if (magnitudes.isEmpty) {
      return CyclicalPatternAnalysis(detected: false);
    }

    var maxMagnitude = 0.0;
    var dominantFrequency = 0.0;

    for (var i = 0; i < magnitudes.length; i++) {
      if (magnitudes[i] > maxMagnitude) {
        maxMagnitude = magnitudes[i];
        dominantFrequency = frequencies[i];
      }
    }

    final avgMagnitude = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final stdMagnitude = math.sqrt(
        magnitudes.map((m) => math.pow(m - avgMagnitude, 2)).reduce((a, b) => a + b) / magnitudes.length
    );
    final threshold = avgMagnitude + 2 * stdMagnitude;

    return CyclicalPatternAnalysis(
      detected: maxMagnitude > threshold,
      dominantFrequency: dominantFrequency,
      period: dominantFrequency > 0 ? 1 / dominantFrequency : 0,
      strength: maxMagnitude,
    );
  }

  List<double> _calculateMovingVariance({int windowSize = 5}) {
    final durations = _metrics.map((m) => m.totalDuration.inMicroseconds.toDouble()).toList();
    final n = durations.length;

    if (n < windowSize) return [];

    final movingVar = <double>[];

    for (var i = 0; i <= n - windowSize; i++) {
      final window = durations.sublist(i, i + windowSize);
      final mean = window.reduce((a, b) => a + b) / windowSize;
      final variance = window.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / windowSize;
      movingVar.add(variance);
    }

    return movingVar;
  }

  ComplexityAnalysisResult _analyzeComplexity() {
    if (_metrics.length < 3) {
      return ComplexityAnalysisResult(
        estimatedComplexity: 'Insufficient data',
        linearFit: PolynomialFit(degree: 1, coefficients: [], rSquared: 0),
        quadraticFit: PolynomialFit(degree: 2, coefficients: [], rSquared: 0),
        bestModel: PolynomialFit(degree: 1, coefficients: [], rSquared: 0),
        confidence: 0,
      );
    }

    final sizeVsTime = _metrics.map((m) => (m.codeSize, m.totalDuration.inMicroseconds)).toList();

    final linearFit = _fitPolynomial(sizeVsTime, 1);
    final quadraticFit = _fitPolynomial(sizeVsTime, 2);

    final linearAIC = _calculateAIC(linearFit.rSquared, sizeVsTime.length, 2);
    final quadraticAIC = _calculateAIC(quadraticFit.rSquared, sizeVsTime.length, 3);

    final bestModel = linearAIC < quadraticAIC ? linearFit : quadraticFit;

    String complexityClass;
    if (bestModel.degree == 1) {
      complexityClass = 'O(n) - Linear';
    } else if (bestModel.degree == 2) {
      complexityClass = 'O(n²) - Quadratic';
    } else {
      complexityClass = 'O(n^${bestModel.degree})';
    }

    return ComplexityAnalysisResult(
      estimatedComplexity: complexityClass,
      linearFit: linearFit,
      quadraticFit: quadraticFit,
      bestModel: bestModel,
      confidence: bestModel.rSquared,
    );
  }

  PolynomialFit _fitPolynomial(List<(int, int)> data, int degree) {
    if (data.isEmpty || data.length < degree + 1) {
      return PolynomialFit(degree: degree, coefficients: [], rSquared: 0);
    }

    if (degree == 1) {
      return _linearRegression(data);
    } else if (degree == 2) {
      return _quadraticRegression(data);
    }

    return PolynomialFit(degree: degree, coefficients: [], rSquared: 0);
  }

  PolynomialFit _linearRegression(List<(int, int)> data) {
    final n = data.length;
    final x = data.map((d) => d.$1.toDouble()).toList();
    final y = data.map((d) => d.$2.toDouble()).toList();

    final xMean = x.reduce((a, b) => a + b) / n;
    final yMean = y.reduce((a, b) => a + b) / n;

    var numerator = 0.0;
    var denominator = 0.0;

    for (var i = 0; i < n; i++) {
      numerator += (x[i] - xMean) * (y[i] - yMean);
      denominator += math.pow(x[i] - xMean, 2);
    }

    final b1 = denominator != 0 ? numerator / denominator : 0.0;
    final b0 = yMean - b1 * xMean;

    var ssRes = 0.0;
    var ssTot = 0.0;

    for (var i = 0; i < n; i++) {
      final predicted = b0 + b1 * x[i];
      ssRes += math.pow(y[i] - predicted, 2);
      ssTot += math.pow(y[i] - yMean, 2);
    }

    final rSquared = ssTot != 0 ? 1 - (ssRes / ssTot) : 0.0;

    return PolynomialFit(degree: 1, coefficients: [b0, b1], rSquared: rSquared);
  }

  PolynomialFit _quadraticRegression(List<(int, int)> data) {
    final n = data.length;

    if (n < 3) {
      return PolynomialFit(degree: 2, coefficients: [], rSquared: 0);
    }

    var sumX = 0.0, sumX2 = 0.0, sumX3 = 0.0, sumX4 = 0.0;
    var sumY = 0.0, sumXY = 0.0, sumX2Y = 0.0;

    for (var point in data) {
      final x = point.$1.toDouble();
      final y = point.$2.toDouble();
      final x2 = x * x;
      final x3 = x2 * x;
      final x4 = x2 * x2;

      sumX += x;
      sumX2 += x2;
      sumX3 += x3;
      sumX4 += x4;
      sumY += y;
      sumXY += x * y;
      sumX2Y += x2 * y;
    }

    final det = n * (sumX2 * sumX4 - sumX3 * sumX3) -
        sumX * (sumX * sumX4 - sumX3 * sumX2) +
        sumX2 * (sumX * sumX3 - sumX2 * sumX2);

    if (det.abs() < 1e-10) {
      return _linearRegression(data);
    }

    final b0 = (sumY * (sumX2 * sumX4 - sumX3 * sumX3) -
        sumXY * (sumX * sumX4 - sumX3 * sumX2) +
        sumX2Y * (sumX * sumX3 - sumX2 * sumX2)) / det;

    final b1 = (n * (sumXY * sumX4 - sumX2Y * sumX3) -
        sumY * (sumX * sumX4 - sumX3 * sumX2) +
        sumX2 * (sumX * sumX2Y - sumXY * sumX2)) / det;

    final b2 = (n * (sumX2 * sumX2Y - sumX3 * sumXY) -
        sumX * (sumX * sumX2Y - sumX2 * sumXY) +
        sumY * (sumX * sumX3 - sumX2 * sumX2)) / det;

    final yMean = sumY / n;
    var ssRes = 0.0;
    var ssTot = 0.0;

    for (var point in data) {
      final x = point.$1.toDouble();
      final y = point.$2.toDouble();
      final predicted = b0 + b1 * x + b2 * x * x;
      ssRes += math.pow(y - predicted, 2);
      ssTot += math.pow(y - yMean, 2);
    }

    final rSquared = ssTot != 0 ? 1 - (ssRes / ssTot) : 0.0;

    return PolynomialFit(degree: 2, coefficients: [b0, b1, b2], rSquared: rSquared);
  }

  double _calculateAIC(double rSquared, int n, int k) {
    if (rSquared >= 1.0 || n <= k) return double.infinity;

    final rss = (1 - rSquared) * n;
    return n * math.log(rss / n) + 2 * k;
  }

  OutlierDetectionResult _detectOutliers() {
    final durations = _metrics.map((m) => m.totalDuration.inMicroseconds.toDouble()).toList();

    if (durations.length < 4) {
      return OutlierDetectionResult(outliers: []);
    }

    final sorted = List<double>.from(durations)..sort();
    final n = durations.length;

    final q1 = _calculatePercentile(sorted.map((e) => e.toInt()).toList(), 25);
    final q3 = _calculatePercentile(sorted.map((e) => e.toInt()).toList(), 75);
    final iqr = q3 - q1;

    final lowerBound = q1 - 1.5 * iqr;
    final upperBound = q3 + 1.5 * iqr;

    final iqrOutliers = <OutlierInfo>[];
    for (var i = 0; i < _metrics.length; i++) {
      final value = durations[i];
      if (value < lowerBound || value > upperBound) {
        iqrOutliers.add(OutlierInfo(
          index: i,
          value: value,
          method: 'IQR',
          severity: _calculateOutlierSeverity(value, lowerBound, upperBound),
        ));
      }
    }

    final mean = durations.reduce((a, b) => a + b) / n;
    final stdDev = math.sqrt(
        durations.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / n
    );

    final zScoreOutliers = <OutlierInfo>[];
    if (stdDev > 0) {
      for (var i = 0; i < _metrics.length; i++) {
        final zScore = (durations[i] - mean) / stdDev;
        if (zScore.abs() > 3) {
          zScoreOutliers.add(OutlierInfo(
            index: i,
            value: durations[i],
            method: 'Z-Score',
            severity: zScore.abs() / 3,
          ));
        }
      }
    }

    final median = sorted[n ~/ 2];
    final mad = _calculateMAD(durations, median);

    final madOutliers = <OutlierInfo>[];
    if (mad > 0) {
      for (var i = 0; i < _metrics.length; i++) {
        final modifiedZScore = 0.6745 * (durations[i] - median) / mad;
        if (modifiedZScore.abs() > 3.5) {
          madOutliers.add(OutlierInfo(
            index: i,
            value: durations[i],
            method: 'MAD',
            severity: modifiedZScore.abs() / 3.5,
          ));
        }
      }
    }

    final allOutliers = <int, OutlierInfo>{};

    for (var outlier in [...iqrOutliers, ...zScoreOutliers, ...madOutliers]) {
      if (allOutliers.containsKey(outlier.index)) {
        allOutliers[outlier.index]!.methods.add(outlier.method);
        allOutliers[outlier.index]!.severity =
            math.max(allOutliers[outlier.index]!.severity, outlier.severity);
      } else {
        allOutliers[outlier.index] = outlier;
      }
    }

    return OutlierDetectionResult(
      outliers: allOutliers.values.toList()..sort((a, b) => b.severity.compareTo(a.severity)),
      iqrCount: iqrOutliers.length,
      zScoreCount: zScoreOutliers.length,
      madCount: madOutliers.length,
    );
  }

  double _calculateOutlierSeverity(double value, double lower, double upper) {
    if (value < lower) {
      return lower > 0 ? (lower - value) / lower : 1.0;
    } else {
      return upper > 0 ? (value - upper) / upper : 1.0;
    }
  }

  double _calculateMAD(List<double> data, double median) {
    final deviations = data.map((x) => (x - median).abs()).toList()..sort();
    return deviations[deviations.length ~/ 2];
  }

  PerformanceRegressionResult _detectPerformanceRegression() {
    if (_metrics.length < 10) {
      return PerformanceRegressionResult(detected: false);
    }

    final midPoint = _metrics.length ~/ 2;
    final firstHalf = _metrics.sublist(0, midPoint);
    final secondHalf = _metrics.sublist(midPoint);

    final firstHalfDurations = firstHalf.map((m) => m.totalDuration.inMicroseconds).toList();
    final secondHalfDurations = secondHalf.map((m) => m.totalDuration.inMicroseconds).toList();

    final firstStats = _computeStatistics(firstHalfDurations, 'First Half');
    final secondStats = _computeStatistics(secondHalfDurations, 'Second Half');

    final tTestResult = _performTTest(firstHalfDurations, secondHalfDurations);

    final cohensD = _calculateCohensD(
      firstStats.mean,
      secondStats.mean,
      firstStats.stdDev,
      secondStats.stdDev,
      firstHalf.length,
      secondHalf.length,
    );

    final meanIncrease = firstStats.mean > 0
        ? ((secondStats.mean - firstStats.mean) / firstStats.mean) * 100
        : 0.0;
    final detected = tTestResult.pValue < 0.05 && meanIncrease > 5;

    String severity;
    if (!detected) {
      severity = 'None';
    } else if (meanIncrease < 10) {
      severity = 'Minor';
    } else if (meanIncrease < 20) {
      severity = 'Moderate';
    } else {
      severity = 'Severe';
    }

    return PerformanceRegressionResult(
      detected: detected,
      firstHalfMean: firstStats.mean,
      secondHalfMean: secondStats.mean,
      percentageIncrease: meanIncrease,
      tStatistic: tTestResult.tStatistic,
      pValue: tTestResult.pValue,
      cohensD: cohensD,
      severity: severity,
      interpretation: _interpretRegression(detected, meanIncrease, cohensD),
    );
  }

  TTestResult _performTTest(List<int> sample1, List<int> sample2) {
    final n1 = sample1.length;
    final n2 = sample2.length;

    if (n1 < 2 || n2 < 2) {
      return TTestResult(tStatistic: 0, degreesOfFreedom: 0, pValue: 1.0);
    }

    final mean1 = sample1.reduce((a, b) => a + b) / n1;
    final mean2 = sample2.reduce((a, b) => a + b) / n2;

    final var1 = sample1.map((x) => math.pow(x - mean1, 2)).reduce((a, b) => a + b) / (n1 - 1);
    final var2 = sample2.map((x) => math.pow(x - mean2, 2)).reduce((a, b) => a + b) / (n2 - 1);

    if (var1 == 0 && var2 == 0) {
      return TTestResult(
          tStatistic: 0,
          degreesOfFreedom: n1 + n2 - 2,
          pValue: 1.0
      );
    }

    final pooledVar = ((n1 - 1) * var1 + (n2 - 1) * var2) / (n1 + n2 - 2);

    if (pooledVar == 0) {
      return TTestResult(
          tStatistic: 0,
          degreesOfFreedom: n1 + n2 - 2,
          pValue: 1.0
      );
    }

    final tStatistic = (mean1 - mean2) / math.sqrt(pooledVar * (1/n1 + 1/n2));
    final df = n1 + n2 - 2;
    final pValue = _calculateTTestPValue(tStatistic.abs(), df);

    return TTestResult(
      tStatistic: tStatistic,
      degreesOfFreedom: df,
      pValue: pValue,
    );
  }

  double _calculateTTestPValue(double t, int df) {
    if (df <= 0) return 1.0;

    if (df > 30) {
      return 2 * (1 - _normalCDF(t.abs()));
    }

    final x = df / (df + t * t);
    final betaValue = _betaIncomplete(df / 2.0, 0.5, x);

    return betaValue.clamp(0.0, 1.0);
  }

  double _normalCDF(double x) {
    return 0.5 * (1 + _erf(x / math.sqrt(2)));
  }

  double _erf(double x) {
    final sign = x < 0 ? -1 : 1;
    x = x.abs();

    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;

    final t = 1.0 / (1.0 + p * x);
    final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);

    return sign * y;
  }

  double _betaIncomplete(double a, double b, double x) {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;

    const maxIterations = 200;
    const epsilon = 1e-10;

    final logBeta = _logGamma(a) + _logGamma(b) - _logGamma(a + b);
    final front = math.exp(math.log(x) * a + math.log(1 - x) * b - logBeta) / a;

    var f = 1.0;
    var c = 1.0;
    var d = 0.0;

    for (var m = 0; m <= maxIterations; m++) {
      final m2 = 2 * m;

      var aa = m * (b - m) * x / ((a + m2 - 1) * (a + m2));
      d = 1 + aa * d;
      if (d.abs() < epsilon) d = epsilon;
      c = 1 + aa / c;
      if (c.abs() < epsilon) c = epsilon;
      d = 1 / d;
      f *= d * c;

      aa = -(a + m) * (a + b + m) * x / ((a + m2) * (a + m2 + 1));
      d = 1 + aa * d;
      if (d.abs() < epsilon) d = epsilon;
      c = 1 + aa / c;
      if (c.abs() < epsilon) c = epsilon;
      d = 1 / d;
      final delta = d * c;
      f *= delta;

      if ((delta - 1).abs() < epsilon) break;
    }

    return front * f;
  }

  double _logGamma(double x) {
    if (x < 12) {
      var product = 1.0;
      while (x < 12) {
        product *= x;
        x += 1;
      }
      return _logGamma(x) - math.log(product);
    }

    const c0 = 0.918938533204672741780329736406;
    const c1 = 1.0 / 12.0;
    const c2 = 1.0 / 360.0;
    const c3 = 1.0 / 1260.0;

    final z = 1 / (x * x);
    final series = c1 - z * (c2 - z * c3);

    return c0 + (x - 0.5) * math.log(x) - x + series / x;
  }

  double _calculateCohensD(double mean1, double mean2, double sd1, double sd2, int n1, int n2) {
    if (n1 < 2 || n2 < 2) return 0.0;

    final pooledSD = math.sqrt(((n1 - 1) * sd1 * sd1 + (n2 - 1) * sd2 * sd2) / (n1 + n2 - 2));
    return pooledSD > 0 ? (mean1 - mean2) / pooledSD : 0.0;
  }

  String _interpretRegression(bool detected, double increase, double cohensD) {
    if (!detected) {
      return 'No significant performance regression detected';
    }

    String effectSize;
    final absCohensD = cohensD.abs();
    if (absCohensD < 0.2) {
      effectSize = 'negligible';
    } else if (absCohensD < 0.5) {
      effectSize = 'small';
    } else if (absCohensD < 0.8) {
      effectSize = 'medium';
    } else {
      effectSize = 'large';
    }

    return 'Performance degraded by ${increase.toStringAsFixed(1)}% with $effectSize effect size. '
        'This suggests ${absCohensD > 0.5 ? "significant" : "minor"} regression requiring attention.';
  }

  String generateComprehensiveReport() {
    final stats = calculateStatistics();
    final buffer = StringBuffer();

    buffer.writeln('╔═══════════════════════════════════════════════════════════╗');
    buffer.writeln('║        MiniLang Compiler Performance Analysis Report          ║');
    buffer.writeln('║              Based on Scientific Algorithms                    ║');
    buffer.writeln('╚═══════════════════════════════════════════════════════════╝');
    buffer.writeln();

    buffer.writeln('📊 OVERALL STATISTICS');
    buffer.writeln('─────────────────────────────────────────────────────────');
    _writeStatisticalSummary(buffer, stats.overallStats);
    buffer.writeln();

    buffer.writeln('⚙️ PHASE-BY-PHASE BREAKDOWN');
    buffer.writeln('─────────────────────────────────────────────────────────');
    for (var entry in stats.phaseStats.entries) {
      buffer.writeln('  ${entry.key}:');
      _writeStatisticalSummary(buffer, entry.value, indent: '    ');
      buffer.writeln();
    }

    buffer.writeln('💾 CACHE EFFICIENCY');
    buffer.writeln('─────────────────────────────────────────────────────────');
    _writeCacheEfficiency(buffer, stats.cacheEfficiency);
    buffer.writeln();

    buffer.writeln('📈 TEMPORAL ANALYSIS');
    buffer.writeln('─────────────────────────────────────────────────────────');
    _writeTemporalAnalysis(buffer, stats.temporalAnalysis);
    buffer.writeln();

    buffer.writeln('🔬 COMPLEXITY ANALYSIS');
    buffer.writeln('─────────────────────────────────────────────────────────');
    _writeComplexityAnalysis(buffer, stats.complexityAnalysis);
    buffer.writeln();

    if (stats.outlierDetection.outliers.isNotEmpty) {
      buffer.writeln('⚠️ OUTLIER DETECTION');
      buffer.writeln('─────────────────────────────────────────────────────────');
      _writeOutlierDetection(buffer, stats.outlierDetection);
      buffer.writeln();
    }

    if (stats.performanceRegression.detected) {
      buffer.writeln('🚨 PERFORMANCE REGRESSION DETECTED');
      buffer.writeln('─────────────────────────────────────────────────────────');
      _writeRegressionAnalysis(buffer, stats.performanceRegression);
      buffer.writeln();
    }

    buffer.writeln('╔═══════════════════════════════════════════════════════════╗');
    buffer.writeln('║                    End of Report                               ║');
    buffer.writeln('╚═══════════════════════════════════════════════════════════╝');

    return buffer.toString();
  }

  void _writeStatisticalSummary(StringBuffer buffer, StatisticalSummary stats, {String indent = '  '}) {
    buffer.writeln('${indent}Count: ${stats.count}');
    buffer.writeln('${indent}Mean: ${_formatMicroseconds(stats.mean)}');
    buffer.writeln('${indent}Median: ${_formatMicroseconds(stats.median)}');
    buffer.writeln('${indent}Std Dev: ${_formatMicroseconds(stats.stdDev)}');
    buffer.writeln('${indent}Min: ${_formatMicroseconds(stats.min)}');
    buffer.writeln('${indent}Max: ${_formatMicroseconds(stats.max)}');
    buffer.writeln('${indent}Q1: ${_formatMicroseconds(stats.q1)}');
    buffer.writeln('${indent}Q3: ${_formatMicroseconds(stats.q3)}');
    buffer.writeln('${indent}IQR: ${_formatMicroseconds(stats.iqr)}');
    buffer.writeln('${indent}P95: ${_formatMicroseconds(stats.p95)}');
    buffer.writeln('${indent}P99: ${_formatMicroseconds(stats.p99)}');
    buffer.writeln('${indent}CV: ${stats.cv.toStringAsFixed(2)}%');
    buffer.writeln('${indent}Skewness: ${stats.skewness.toStringAsFixed(3)}');
    buffer.writeln('${indent}Kurtosis: ${stats.kurtosis.toStringAsFixed(3)}');
    buffer.writeln('${indent}95% CI: [${_formatMicroseconds(stats.ci95Lower)}, ${_formatMicroseconds(stats.ci95Upper)}]');
  }

  void _writeCacheEfficiency(StringBuffer buffer, CacheEfficiencyMetrics cache) {
    buffer.writeln('  Hit Rate: ${(cache.hitRate * 100).toStringAsFixed(2)}%');
    buffer.writeln('  Miss Rate: ${(cache.missRate * 100).toStringAsFixed(2)}%');
    buffer.writeln('  Total Hits: ${cache.totalHits}');
    buffer.writeln('  Total Misses: ${cache.totalMisses}');
    buffer.writeln('  Avg Cached Time: ${_formatMicroseconds(cache.avgCachedTime)}');
    buffer.writeln('  Avg Uncached Time: ${_formatMicroseconds(cache.avgUncachedTime)}');
    buffer.writeln('  Time Saved: ${_formatMicroseconds(cache.timeSavedMicroseconds)}');
    buffer.writeln('  Speedup Factor: ${cache.speedupFactor.toStringAsFixed(2)}x');
    buffer.writeln('  Effectiveness: ${(cache.effectiveness * 100).toStringAsFixed(2)}%');
  }

  void _writeTemporalAnalysis(StringBuffer buffer, TemporalAnalysisResult temporal) {
    buffer.writeln('  Trend: ${temporal.trend.interpretation}');
    buffer.writeln('  Slope: ${temporal.trend.slope.toStringAsFixed(6)} μs/compilation');
    buffer.writeln('  R²: ${temporal.trend.rSquared.toStringAsFixed(4)}');

    if (temporal.cyclicalPatterns.detected) {
      buffer.writeln('  Cyclical Pattern Detected:');
      buffer.writeln('    Period: ${temporal.cyclicalPatterns.period.toStringAsFixed(2)} compilations');
      buffer.writeln('    Strength: ${temporal.cyclicalPatterns.strength.toStringAsFixed(2)}');
    }
  }

  void _writeComplexityAnalysis(StringBuffer buffer, ComplexityAnalysisResult complexity) {
    buffer.writeln('  Estimated Complexity: ${complexity.estimatedComplexity}');
    buffer.writeln('  Confidence: ${(complexity.confidence * 100).toStringAsFixed(2)}%');
    buffer.writeln('  Best Model: Degree ${complexity.bestModel.degree}');
    buffer.writeln('  R²: ${complexity.bestModel.rSquared.toStringAsFixed(4)}');
  }

  void _writeOutlierDetection(StringBuffer buffer, OutlierDetectionResult outliers) {
    buffer.writeln('  Total Outliers: ${outliers.outliers.length}');
    buffer.writeln('  IQR Method: ${outliers.iqrCount}');
    buffer.writeln('  Z-Score Method: ${outliers.zScoreCount}');
    buffer.writeln('  MAD Method: ${outliers.madCount}');

    if (outliers.outliers.isNotEmpty) {
      buffer.writeln('  Top 5 Outliers:');
      for (var i = 0; i < math.min(5, outliers.outliers.length); i++) {
        final outlier = outliers.outliers[i];
        buffer.writeln('    ${i + 1}. Index ${outlier.index}: ${_formatMicroseconds(outlier.value)} '
            '(severity: ${outlier.severity.toStringAsFixed(2)}, methods: ${outlier.methods.join(", ")})');
      }
    }
  }

  void _writeRegressionAnalysis(StringBuffer buffer, PerformanceRegressionResult regression) {
    buffer.writeln('  Severity: ${regression.severity}');
    buffer.writeln('  First Half Mean: ${_formatMicroseconds(regression.firstHalfMean)}');
    buffer.writeln('  Second Half Mean: ${_formatMicroseconds(regression.secondHalfMean)}');
    buffer.writeln('  Increase: ${regression.percentageIncrease.toStringAsFixed(2)}%');
    buffer.writeln('  t-statistic: ${regression.tStatistic.toStringAsFixed(4)}');
    buffer.writeln('  p-value: ${regression.pValue.toStringAsFixed(6)}');
    buffer.writeln('  Cohen\'s d: ${regression.cohensD.toStringAsFixed(4)}');
    buffer.writeln('  Interpretation: ${regression.interpretation}');
  }

  String _formatMicroseconds(double microseconds) {
    if (microseconds < 1000) {
      return '${microseconds.toStringAsFixed(0)}μs';
    } else if (microseconds < 1000000) {
      return '${(microseconds / 1000).toStringAsFixed(2)}ms';
    } else {
      return '${(microseconds / 1000000).toStringAsFixed(2)}s';
    }
  }

  void clear() {
    _metrics.clear();
    _phaseDurations.clear();
    _cacheStats.clear();
  }
}

class PerformanceMetric {
  final Duration totalDuration;
  final List<PhaseMetric> phases;
  final bool cacheHit;
  final int codeSize;
  final DateTime timestamp;

  PerformanceMetric({
    required this.totalDuration,
    required this.phases,
    required this.cacheHit,
    required this.codeSize,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class PhaseMetric {
  final String name;
  final Duration duration;
  final bool successful;

  PhaseMetric({
    required this.name,
    required this.duration,
    required this.successful,
  });
}

class CacheStatistics {
  int hits = 0;
  int misses = 0;

  void recordHit() => hits++;
  void recordMiss() => misses++;
}

class PerformanceStatistics {
  final int totalCompilations;
  final StatisticalSummary overallStats;
  final Map<String, StatisticalSummary> phaseStats;
  final CacheEfficiencyMetrics cacheEfficiency;
  final TemporalAnalysisResult temporalAnalysis;
  final ComplexityAnalysisResult complexityAnalysis;
  final OutlierDetectionResult outlierDetection;
  final PerformanceRegressionResult performanceRegression;

  PerformanceStatistics({
    required this.totalCompilations,
    required this.overallStats,
    required this.phaseStats,
    required this.cacheEfficiency,
    required this.temporalAnalysis,
    required this.complexityAnalysis,
    required this.outlierDetection,
    required this.performanceRegression,
  });
}

class StatisticalSummary {
  final String label;
  final int count;
  final double mean;
  final double median;
  final double stdDev;
  final double min;
  final double max;
  final double q1;
  final double q3;
  final double iqr;
  final double p5;
  final double p95;
  final double p99;
  final double cv;
  final double skewness;
  final double kurtosis;
  final double ci95Lower;
  final double ci95Upper;

  StatisticalSummary({
    required this.label,
    required this.count,
    required this.mean,
    required this.median,
    required this.stdDev,
    required this.min,
    required this.max,
    required this.q1,
    required this.q3,
    required this.iqr,
    required this.p5,
    required this.p95,
    required this.p99,
    required this.cv,
    required this.skewness,
    required this.kurtosis,
    required this.ci95Lower,
    required this.ci95Upper,
  });

  factory StatisticalSummary.empty(String label) {
    return StatisticalSummary(
      label: label, count: 0, mean: 0, median: 0, stdDev: 0,
      min: 0, max: 0, q1: 0, q3: 0, iqr: 0, p5: 0, p95: 0, p99: 0,
      cv: 0, skewness: 0, kurtosis: 0, ci95Lower: 0, ci95Upper: 0,
    );
  }
}

class CacheEfficiencyMetrics {
  final double hitRate;
  final double missRate;
  final int totalHits;
  final int totalMisses;
  final double avgCachedTime;
  final double avgUncachedTime;
  final double timeSavedMicroseconds;
  final double speedupFactor;
  final double effectiveness;

  CacheEfficiencyMetrics({
    required this.hitRate, required this.missRate,
    required this.totalHits, required this.totalMisses,
    required this.avgCachedTime, required this.avgUncachedTime,
    required this.timeSavedMicroseconds, required this.speedupFactor,
    required this.effectiveness,
  });

  factory CacheEfficiencyMetrics.empty() {
    return CacheEfficiencyMetrics(
      hitRate: 0, missRate: 0, totalHits: 0, totalMisses: 0,
      avgCachedTime: 0, avgUncachedTime: 0, timeSavedMicroseconds: 0,
      speedupFactor: 1, effectiveness: 0,
    );
  }
}

class TemporalAnalysisResult {
  final TrendAnalysis trend;
  final List<double> autocorrelation;
  final CyclicalPatternAnalysis cyclicalPatterns;
  final List<double> movingVariance;

  TemporalAnalysisResult({
    required this.trend, required this.autocorrelation,
    required this.cyclicalPatterns, required this.movingVariance,
  });

  factory TemporalAnalysisResult.insufficient() {
    return TemporalAnalysisResult(
      trend: TrendAnalysis(slope: 0, intercept: 0, rSquared: 0, interpretation: 'Insufficient data'),
      autocorrelation: [],
      cyclicalPatterns: CyclicalPatternAnalysis(detected: false),
      movingVariance: [],
    );
  }
}

class TrendAnalysis {
  final double slope;
  final double intercept;
  final double rSquared;
  final String interpretation;

  TrendAnalysis({
    required this.slope,
    required this.intercept,
    required this.rSquared,
    required this.interpretation,
  });
}

class CyclicalPatternAnalysis {
  final bool detected;
  final double dominantFrequency;
  final double period;
  final double strength;

  CyclicalPatternAnalysis({
    required this.detected,
    this.dominantFrequency = 0,
    this.period = 0,
    this.strength = 0,
  });
}

class ComplexityAnalysisResult {
  final String estimatedComplexity;
  final PolynomialFit linearFit;
  final PolynomialFit quadraticFit;
  final PolynomialFit bestModel;
  final double confidence;

  ComplexityAnalysisResult({
    required this.estimatedComplexity,
    required this.linearFit,
    required this.quadraticFit,
    required this.bestModel,
    required this.confidence,
  });
}

class PolynomialFit {
  final int degree;
  final List<double> coefficients;
  final double rSquared;

  PolynomialFit({
    required this.degree,
    required this.coefficients,
    required this.rSquared,
  });
}

class OutlierDetectionResult {
  final List<OutlierInfo> outliers;
  final int iqrCount;
  final int zScoreCount;
  final int madCount;

  OutlierDetectionResult({
    required this.outliers,
    this.iqrCount = 0,
    this.zScoreCount = 0,
    this.madCount = 0,
  });
}

class OutlierInfo {
  final int index;
  final double value;
  final String method;
  double severity;
  final List<String> methods = [];

  OutlierInfo({
    required this.index,
    required this.value,
    required this.method,
    required this.severity,
  }) {
    methods.add(method);
  }
}

class PerformanceRegressionResult {
  final bool detected;
  final double firstHalfMean;
  final double secondHalfMean;
  final double percentageIncrease;
  final double tStatistic;
  final double pValue;
  final double cohensD;
  final String severity;
  final String interpretation;

  PerformanceRegressionResult({
    required this.detected,
    this.firstHalfMean = 0,
    this.secondHalfMean = 0,
    this.percentageIncrease = 0,
    this.tStatistic = 0,
    this.pValue = 1,
    this.cohensD = 0,
    this.severity = 'None',
    this.interpretation = 'No regression detected',
  });
}

class TTestResult {
  final double tStatistic;
  final int degreesOfFreedom;
  final double pValue;

  TTestResult({
    required this.tStatistic,
    required this.degreesOfFreedom,
    required this.pValue,
  });
}
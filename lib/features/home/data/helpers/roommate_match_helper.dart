// Tính % độ phù hợp giữa 2 người tìm phòng:
// Tiêu chí 45% + Thói quen 25% + Ngân sách 15% + Địa điểm 15%, trừ thêm điểm phạt nếu có xung đột
int calculateRoommateMatchPercentage({
  required List<String> currentHabits,
  required List<String> currentCriteria,
  required List<String> targetHabits,
  required List<String> targetCriteria,
  String currentBudgetRange = '',
  String targetBudgetRange = '',
  String currentAddress = '',
  String targetAddress = '',
}) {
  final currentHabitSet = _normalizedSet(currentHabits);
  final currentCriteriaSet = _normalizedSet(currentCriteria);
  final targetHabitSet = _normalizedSet(targetHabits);
  final targetCriteriaSet = _normalizedSet(targetCriteria);

  final currentSignals = {...currentHabitSet, ...currentCriteriaSet};
  final targetSignals = {...targetHabitSet, ...targetCriteriaSet};

  final components = <_MatchComponent>[];

  final criteriaScore = _calculateCriteriaCompatibilityScore(
    currentCriteria: currentCriteriaSet,
    currentSignals: currentSignals,
    targetCriteria: targetCriteriaSet,
    targetSignals: targetSignals,
  );
  if (criteriaScore != null) {
    components.add(
      const _MatchComponent(weight: 45, score: 0).copyWith(score: criteriaScore),
    );
  }

  final habitScore = _calculateSetOverlapScore(currentHabitSet, targetHabitSet);
  if (habitScore != null) {
    components.add(
      const _MatchComponent(weight: 25, score: 0).copyWith(score: habitScore),
    );
  }

  final budgetScore = _calculateBudgetCompatibilityScore(
    currentBudgetRange,
    targetBudgetRange,
  );
  if (budgetScore != null) {
    components.add(
      const _MatchComponent(weight: 15, score: 0).copyWith(score: budgetScore),
    );
  }

  final locationScore = _calculateLocationCompatibilityScore(
    currentAddress,
    targetAddress,
  );
  if (locationScore != null) {
    components.add(
      const _MatchComponent(weight: 15, score: 0).copyWith(score: locationScore),
    );
  }

  if (components.isEmpty) {
    return 0;
  }

  final totalWeight = components.fold<int>(
    0,
    (sum, component) => sum + component.weight,
  );
  final weightedScore = components.fold<double>(
        0,
        (sum, component) => sum + (component.score * component.weight),
      ) /
      totalWeight;

  final penalty = _calculateConflictPenalty(
    currentHabits: currentHabitSet,
    currentCriteria: currentCriteriaSet,
    targetHabits: targetHabitSet,
    targetCriteria: targetCriteriaSet,
  );

  return (weightedScore - penalty).round().clamp(0, 100);
}

Set<String> _normalizedSet(List<String> values) {
  return values
      .map(_normalizeText)
      .where((value) => value.isNotEmpty)
      .toSet();
}

// Tính điểm tương thích tiêu chí roommate theo 2 chiều: tôi → họ và họ → tôi, lấy trung bình
int? _calculateCriteriaCompatibilityScore({
  required Set<String> currentCriteria,
  required Set<String> currentSignals,
  required Set<String> targetCriteria,
  required Set<String> targetSignals,
}) {
  if (currentCriteria.isEmpty && targetCriteria.isEmpty) {
    return null;
  }

  int calculateDirectionalScore(Set<String> needs, Set<String> signals) {
    if (needs.isEmpty) return 100;
    final matched = needs.where(signals.contains).length;
    return ((matched / needs.length) * 100).round();
  }

  final currentToTarget = calculateDirectionalScore(currentCriteria, targetSignals);
  final targetToCurrent = calculateDirectionalScore(targetCriteria, currentSignals);
  return ((currentToTarget + targetToCurrent) / 2).round();
}

int? _calculateSetOverlapScore(Set<String> left, Set<String> right) {
  if (left.isEmpty && right.isEmpty) {
    return null;
  }

  final union = left.union(right);
  if (union.isEmpty) {
    return 0;
  }

  final overlap = left.intersection(right).length;
  return ((overlap / union.length) * 100).round();
}

// Tính điểm tương thích ngân sách: 100 nếu khoảng chồng nhau, giảm dần theo khoảng cách
int? _calculateBudgetCompatibilityScore(String currentBudgetRange, String targetBudgetRange) {
  final currentRange = _parseBudgetRange(currentBudgetRange);
  final targetRange = _parseBudgetRange(targetBudgetRange);

  if (currentRange == null || targetRange == null) {
    return null;
  }

  final overlapMin = currentRange.start > targetRange.start
      ? currentRange.start
      : targetRange.start;
  final overlapMax =
      currentRange.end < targetRange.end ? currentRange.end : targetRange.end;

  if (overlapMin <= overlapMax) {
    return 100;
  }

  final gap = overlapMin - overlapMax;
  final reference = [
    currentRange.end,
    targetRange.end,
    currentRange.start,
    targetRange.start,
  ].reduce((a, b) => a > b ? a : b);
  if (reference <= 0) {
    return 0;
  }

  final distanceRatio = gap / reference;
  if (distanceRatio <= 0.10) return 80;
  if (distanceRatio <= 0.20) return 60;
  if (distanceRatio <= 0.35) return 40;
  return 20;
}

_NumericRange? _parseBudgetRange(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return null;
  }

  final matches = RegExp(r'\d[\d\.,]*')
      .allMatches(normalized)
      .map((match) => match.group(0) ?? '')
      .map((raw) => raw.replaceAll(RegExp(r'[^0-9]'), ''))
      .where((raw) => raw.isNotEmpty)
      .map(int.tryParse)
      .whereType<int>()
      .toList();

  if (matches.isEmpty) {
    return null;
  }

  if (matches.length == 1) {
    return _NumericRange(matches.first, matches.first);
  }

  final start = matches.first < matches.last ? matches.first : matches.last;
  final end = matches.first > matches.last ? matches.first : matches.last;
  return _NumericRange(start, end);
}

// Tính điểm tương thích địa điểm bằng cách so sánh các token địa chỉ (bỏ stop words)
int? _calculateLocationCompatibilityScore(String currentAddress, String targetAddress) {
  final currentTokens = _extractAddressTokens(currentAddress);
  final targetTokens = _extractAddressTokens(targetAddress);

  if (currentTokens.isEmpty || targetTokens.isEmpty) {
    return null;
  }

  final normalizedCurrent = currentTokens.join(' ');
  final normalizedTarget = targetTokens.join(' ');
  if (normalizedCurrent == normalizedTarget) {
    return 100;
  }

  final overlap = currentTokens.intersection(targetTokens).length;
  if (overlap == 0) {
    return 20;
  }

  final base = currentTokens.length > targetTokens.length
      ? currentTokens.length
      : targetTokens.length;
  final ratio = overlap / base;
  if (ratio >= 0.75) return 90;
  if (ratio >= 0.5) return 75;
  if (ratio >= 0.3) return 60;
  return 45;
}

Set<String> _extractAddressTokens(String value) {
  final normalized = _normalizeText(value)
      .replaceAll(RegExp(r'[,\-_/]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((token) => token.length >= 2)
      .where((token) => !_addressStopWords.contains(token))
      .toSet();
  return normalized;
}

// Tính điểm phạt khi có xung đột thói quen/tiêu chí (VD: ngủ sớm vs thức khuya), tối đa -30 điểm
int _calculateConflictPenalty({
  required Set<String> currentHabits,
  required Set<String> currentCriteria,
  required Set<String> targetHabits,
  required Set<String> targetCriteria,
}) {
  var penalty = 0;

  penalty += _calculateDirectionalConflictPenalty(
    criteria: currentCriteria,
    habits: targetHabits,
  );
  penalty += _calculateDirectionalConflictPenalty(
    criteria: targetCriteria,
    habits: currentHabits,
  );

  if (currentHabits.contains('sleep_early') && targetHabits.contains('stay_up_late')) {
    penalty += 10;
  }
  if (targetHabits.contains('sleep_early') && currentHabits.contains('stay_up_late')) {
    penalty += 10;
  }
  if (_prefersQuiet(currentHabits) && targetHabits.contains('like_gathering')) {
    penalty += 10;
  }
  if (_prefersQuiet(targetHabits) && currentHabits.contains('like_gathering')) {
    penalty += 10;
  }

  return penalty.clamp(0, 30);
}

int _calculateDirectionalConflictPenalty({
  required Set<String> criteria,
  required Set<String> habits,
}) {
  var penalty = 0;

  if (_containsAny(criteria, _quietCriteria) && habits.contains('like_gathering')) {
    penalty += 12;
  }
  if (_containsAny(criteria, _stableScheduleCriteria) &&
      habits.contains('stay_up_late')) {
    penalty += 10;
  }
  if (_containsAny(criteria, _noCookingCriteria) && habits.contains('cook_at_home')) {
    penalty += 8;
  }

  return penalty;
}

bool _prefersQuiet(Set<String> habits) {
  return habits.contains('prefer_quiet') || habits.contains('less_partying');
}

bool _containsAny(Set<String> values, Set<String> expected) {
  for (final value in values) {
    if (expected.contains(value)) {
      return true;
    }
  }
  return false;
}

String _normalizeText(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

const Set<String> _quietCriteria = {
  'ưu tiên không gian yên tĩnh',
  'không ồn ào, hạn chế tiệc tùng',
};

const Set<String> _stableScheduleCriteria = {
  'lịch sinh hoạt ổn định',
};

const Set<String> _noCookingCriteria = {
  'không phụ thuộc vào nhu cầu nấu ăn chung',
};

const Set<String> _addressStopWords = {
  'duong',
  'phuong',
  'quan',
  'huyen',
  'tinh',
  'thanh',
  'pho',
  'so',
  'nha',
  'đường',
  'phường',
  'quận',
  'huyện',
  'tỉnh',
  'thành',
  'phố',
  'số',
  'nhà',
};

class _MatchComponent {
  final int weight;
  final int score;

  const _MatchComponent({
    required this.weight,
    required this.score,
  });

  _MatchComponent copyWith({
    int? weight,
    int? score,
  }) {
    return _MatchComponent(
      weight: weight ?? this.weight,
      score: score ?? this.score,
    );
  }
}

class _NumericRange {
  final int start;
  final int end;

  const _NumericRange(this.start, this.end);
}

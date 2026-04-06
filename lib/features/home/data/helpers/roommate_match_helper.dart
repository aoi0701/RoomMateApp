int calculateRoommateMatchPercentage({
  required List<String> currentHabits,
  required List<String> currentCriteria,
  required List<String> targetHabits,
  required List<String> targetCriteria,
}) {
  final currentSignals = {
    ...currentHabits.map((item) => item.trim()).where((item) => item.isNotEmpty),
    ...currentCriteria.map((item) => item.trim()).where((item) => item.isNotEmpty),
  };

  final targetSignals = {
    ...targetHabits.map((item) => item.trim()).where((item) => item.isNotEmpty),
    ...targetCriteria.map((item) => item.trim()).where((item) => item.isNotEmpty),
  };

  final currentNeeds = currentCriteria
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet();
  final targetNeeds = targetCriteria
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet();

  if (currentSignals.isEmpty && targetSignals.isEmpty) {
    return 0;
  }

  int calculateScore(Set<String> sourceNeeds, Set<String> comparedSignals) {
    if (sourceNeeds.isEmpty) return 100;
    final matched = sourceNeeds.where(comparedSignals.contains).length;
    return ((matched / sourceNeeds.length) * 100).round();
  }

  final currentToTarget = calculateScore(currentNeeds, targetSignals);
  final targetToCurrent = calculateScore(targetNeeds, currentSignals);

  if (currentNeeds.isEmpty && targetNeeds.isEmpty) {
    final overlap = currentSignals.where(targetSignals.contains).length;
    final base = currentSignals.union(targetSignals).length;
    if (base == 0) return 0;
    return ((overlap / base) * 100).round();
  }

  return ((currentToTarget + targetToCurrent) / 2).round();
}

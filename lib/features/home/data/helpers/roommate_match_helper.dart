import '../../../profile/data/models/profile_habit_model.dart';

class MatchResult {
  final int score;
  final List<String> matchedReasons;
  final List<String> conflictReasons;

  const MatchResult({
    required this.score,
    required this.matchedReasons,
    required this.conflictReasons,
  });
}

MatchResult calculateRoommateMatch({
  required List<String> currentHabits,
  required List<String> targetHabits,
}) {
  if (currentHabits.isEmpty && targetHabits.isEmpty) {
    return const MatchResult(score: 0, matchedReasons: [], conflictReasons: []);
  }

  final currentSet = currentHabits.toSet();
  final targetSet = targetHabits.toSet();

  final matchedReasons = <String>[];
  final conflictReasons = <String>[];

  // Detect conflicts: habit của A xung đột với habit của B
  for (final habitId in currentSet) {
    final habit = ProfileHabitCatalog.findById(habitId);
    if (habit == null) continue;
    for (final conflictId in habit.conflictsWith) {
      if (targetSet.contains(conflictId)) {
        final conflictHabit = ProfileHabitCatalog.findById(conflictId);
        if (conflictHabit != null) {
          conflictReasons.add('${habit.label} ↔ ${conflictHabit.label}');
        }
      }
    }
  }

  // Weighted score: dựa trên habits chung của cả 2
  double totalWeight = 0;
  double matchedWeight = 0;

  final allHabitIds = currentSet.union(targetSet);

  for (final habitId in allHabitIds) {
    final habit = ProfileHabitCatalog.findById(habitId);
    if (habit == null) continue;
    totalWeight += habit.weight;
    if (currentSet.contains(habitId) && targetSet.contains(habitId)) {
      matchedWeight += habit.weight;
      matchedReasons.add(habit.label);
    }
  }

  if (totalWeight == 0) {
    return const MatchResult(score: 0, matchedReasons: [], conflictReasons: []);
  }

  final rawScore = (matchedWeight / totalWeight * 100).round();
  final penalty = conflictReasons.length * 20;
  final finalScore = (rawScore - penalty).clamp(0, 100);

  return MatchResult(
    score: finalScore,
    matchedReasons: matchedReasons,
    conflictReasons: conflictReasons,
  );
}

// Backward-compatible wrapper trả về int
int calculateRoommateMatchPercentage({
  required List<String> currentHabits,
  required List<String> currentCriteria,
  required List<String> targetHabits,
  required List<String> targetCriteria,
}) {
  return calculateRoommateMatch(
    currentHabits: currentHabits,
    targetHabits: targetHabits,
  ).score;
}

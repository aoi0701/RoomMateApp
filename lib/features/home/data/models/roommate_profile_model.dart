class RoommateProfileModel {
  final String userId;
  final String fullName;
  final String displayName;
  final String avatarUrl;
  final String address;
  final String budgetRange;
  final List<String> habits;
  final List<String> roommateCriteria;
  final String bio;
  final String gender;
  final int? age;
  final String occupation;
  final int matchPercentage;
  final List<String> matchedReasons;
  final List<String> conflictReasons;

  const RoommateProfileModel({
    required this.userId,
    required this.fullName,
    required this.displayName,
    required this.avatarUrl,
    required this.address,
    required this.budgetRange,
    required this.habits,
    required this.roommateCriteria,
    required this.bio,
    required this.gender,
    required this.age,
    required this.occupation,
    required this.matchPercentage,
    this.matchedReasons = const [],
    this.conflictReasons = const [],
  });
}

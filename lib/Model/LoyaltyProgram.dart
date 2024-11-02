class LoyaltyProgram {
  final String level;
  final int bonusPoints;
  final int pointsToNextLevel;
  final String dataEndBonus;

  LoyaltyProgram({
    required this.level,
    required this.bonusPoints,
    required this.pointsToNextLevel,
    required this.dataEndBonus
  });

  factory LoyaltyProgram.fromJson(Map<String, dynamic> json) {
    return LoyaltyProgram(
      level: json['level'],
      bonusPoints: json['bonusPoints'],
      pointsToNextLevel: json['pointsToNextLevel'],
      dataEndBonus: json['dataEndBonus']
    );
  }
}
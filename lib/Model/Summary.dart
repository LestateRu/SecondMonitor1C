class Summary {
  final int totalItems;
  final int discountAmount;
  final int bonusForPurchase;
  final int totalAmount;

  Summary({
    required this.totalItems,
    required this.discountAmount,
    required this.bonusForPurchase,
    required this.totalAmount,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      totalItems: json['totalItems'] as int,
      discountAmount: json['discountAmount'] as int,
      bonusForPurchase: json['bonusForPurchase'] as int,
      totalAmount: json['totalAmount'] as int,
    );
  }
}
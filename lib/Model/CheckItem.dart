class CheckItem {
  final String name;
  final String article;
  final String size;
  final int quantity;
  final int amount;

  CheckItem({
    required this.name,
    required this.article,
    required this.size,
    required this.quantity,
    required this.amount,
  });

  factory CheckItem.fromJson(Map<String, dynamic> json) {
    return CheckItem(
      name: json['name'] as String,
      article: json['article'] as String,
      size: json['size'] as String,
      quantity: json['quantity'] as int,
      amount: json['amount'] as int,
    );
  }
}
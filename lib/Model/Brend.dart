class Brend {
  final String brendName;

  Brend({
    required this.brendName,
  });

  factory Brend.fromJson(Map<String, dynamic> json) {
    return Brend(
      brendName: json['brendName'] as String? ?? '',
    );
  }
}
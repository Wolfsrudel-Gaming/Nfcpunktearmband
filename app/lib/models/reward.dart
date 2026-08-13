class Reward {
  final String id;
  final String name;
  final String? description;
  final int cost;
  final int? stock;
  final int redeemed;
  final String? category;
  final int? limitPerParticipant;
  final bool available;

  const Reward({
    required this.id,
    required this.name,
    this.description,
    required this.cost,
    this.stock,
    required this.redeemed,
    this.category,
    this.limitPerParticipant,
    required this.available,
  });

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        cost: json['cost'] as int,
        stock: json['stock'] as int?,
        redeemed: json['redeemed'] as int? ?? 0,
        category: json['category'] as String?,
        limitPerParticipant: json['limitPerParticipant'] as int?,
        available: json['available'] as bool? ?? true,
      );

  int? get remaining => stock != null ? stock! - redeemed : null;
  bool get inStock => stock == null || remaining! > 0;
}

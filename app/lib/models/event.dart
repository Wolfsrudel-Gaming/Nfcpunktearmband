class Event {
  final String id;
  final String name;
  final String? description;
  final String status;
  final String? startDate;
  final String? endDate;
  final String? location;
  final String joinCode;
  final Map<String, dynamic>? config;
  final int participantCount;

  const Event({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.startDate,
    this.endDate,
    this.location,
    required this.joinCode,
    this.config,
    this.participantCount = 0,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        status: json['status'] as String,
        startDate: json['startDate'] as String?,
        endDate: json['endDate'] as String?,
        location: json['location'] as String?,
        joinCode: json['joinCode'] as String,
        config: json['config'] as Map<String, dynamic>?,
        participantCount:
            (json['participants'] as List?)?.length ?? json['participantCount'] as int? ?? 0,
      );

  List<int> get quickSelectValues {
    final vals = config?['quickSelectValues'];
    if (vals is List) return vals.cast<int>();
    return const [1, 2, 5, 10];
  }
}

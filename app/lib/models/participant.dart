class Participant {
  final String id;
  final String displayName;
  final String? firstName;
  final String? lastName;
  final int? age;
  final String? group;
  final int balance;
  final bool active;
  final String? nfcTagUid;
  final String eventId;

  const Participant({
    required this.id,
    required this.displayName,
    this.firstName,
    this.lastName,
    this.age,
    this.group,
    required this.balance,
    required this.active,
    this.nfcTagUid,
    required this.eventId,
  });

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        age: json['age'] as int?,
        group: json['group'] as String?,
        balance: json['balance'] as int? ?? 0,
        active: json['active'] as bool? ?? true,
        nfcTagUid: (json['nfcTag'] as Map<String, dynamic>?)?['tagUid'] as String?,
        eventId: json['eventId'] as String? ?? json['event']?['id'] as String? ?? '',
      );

  String get fullName {
    final parts = [firstName, lastName].where((s) => s != null && s.isNotEmpty);
    return parts.isEmpty ? displayName : parts.join(' ');
  }
}

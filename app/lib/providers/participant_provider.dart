import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/participant.dart';
import '../services/api_client.dart';

final scannedParticipantProvider = StateProvider<Participant?>((ref) => null);

final participantsProvider = FutureProvider.family<List<Participant>, String>(
  (ref, eventId) async {
    final data = await ApiClient()
        .get<List<dynamic>>('/api/participants/event/$eventId');
    return data
        .map((e) => Participant.fromJson(e as Map<String, dynamic>))
        .toList();
  },
);

final leaderboardProvider = FutureProvider.family<List<Participant>, String>(
  (ref, eventId) async {
    final data = await ApiClient()
        .get<List<dynamic>>('/api/points/leaderboard/$eventId');
    return data
        .map((e) => Participant.fromJson(e as Map<String, dynamic>))
        .toList();
  },
);

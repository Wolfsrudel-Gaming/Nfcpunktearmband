import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/participant.dart';
import '../services/api_client.dart';
import '../services/demo_service.dart';
import '../services/socket_service.dart';
import 'demo_provider.dart';

final scannedParticipantProvider = StateProvider<Participant?>((ref) => null);

final participantsProvider = FutureProvider.family<List<Participant>, String>(
  (ref, eventId) async {
    if (ref.read(demoModeProvider)) {
      return DemoService().getParticipants(eventId);
    }
    final data = await ApiClient()
        .get<List<dynamic>>('/api/participants/event/$eventId');
    return data
        .map((e) => Participant.fromJson(e as Map<String, dynamic>))
        .toList();
  },
);

final leaderboardProvider = FutureProvider.family<List<Participant>, String>(
  (ref, eventId) async {
    if (ref.read(demoModeProvider)) {
      return DemoService().getLeaderboard(eventId);
    }
    final data = await ApiClient()
        .get<List<dynamic>>('/api/points/leaderboard/$eventId');
    return data
        .map((e) => Participant.fromJson(e as Map<String, dynamic>))
        .toList();
  },
);

final socketListenerProvider = Provider<void>((ref) {
  void onUpdate(Map<String, dynamic> data) {
    final eventId = data['eventId'] as String?;
    if (eventId != null) {
      ref.invalidate(participantsProvider(eventId));
      ref.invalidate(leaderboardProvider(eventId));
    }
  }

  SocketService().onPointsUpdate(onUpdate);
  ref.onDispose(() => SocketService().removePointsListener(onUpdate));
});

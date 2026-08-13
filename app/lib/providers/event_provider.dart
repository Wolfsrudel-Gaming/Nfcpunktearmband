import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../services/api_client.dart';

final eventsProvider =
    AsyncNotifierProvider<EventsNotifier, List<Event>>(EventsNotifier.new);

final selectedEventProvider = StateProvider<Event?>((ref) => null);

class EventsNotifier extends AsyncNotifier<List<Event>> {
  @override
  Future<List<Event>> build() async {
    final data = await ApiClient().get<List<dynamic>>('/api/events');
    return data.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/event_provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_participants_screen.dart';
import 'admin_rewards_screen.dart';
import 'admin_event_config_screen.dart';
import 'admin_activity_screen.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(selectedEventProvider);
    if (event == null) {
      return const Center(child: Text('Kein Event gewählt'));
    }

    final screens = [
      AdminDashboardScreen(eventId: event.id),
      AdminParticipantsScreen(eventId: event.id),
      AdminActivityScreen(eventId: event.id),
      AdminRewardsScreen(eventId: event.id),
      AdminEventConfigScreen(eventId: event.id),
    ];

    return Column(
      children: [
        Expanded(child: screens[_currentIndex]),
        NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Teilnehmer',
            ),
            NavigationDestination(
              icon: Icon(Icons.timeline_outlined),
              selectedIcon: Icon(Icons.timeline),
              label: 'Aktivität',
            ),
            NavigationDestination(
              icon: Icon(Icons.card_giftcard_outlined),
              selectedIcon: Icon(Icons.card_giftcard),
              label: 'Prämien',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Event',
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/demo_provider.dart';
import '../../providers/event_provider.dart';
import '../../services/demo_service.dart';
import '../../models/participant.dart';
import 'tn_dashboard_screen.dart';
import 'tn_shop_screen.dart';
import 'tn_leaderboard_screen.dart';
import 'tn_profile_screen.dart';

class TnHomeScreen extends ConsumerStatefulWidget {
  const TnHomeScreen({super.key});

  @override
  ConsumerState<TnHomeScreen> createState() => _TnHomeScreenState();
}

class _TnHomeScreenState extends ConsumerState<TnHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final participantId = ref.watch(demoActiveParticipantIdProvider);
    final event = ref.watch(selectedEventProvider);

    if (participantId == null || event == null) {
      return _buildParticipantPicker();
    }

    final participant = DemoService().getParticipant(participantId);
    if (participant == null) return _buildParticipantPicker();

    final screens = [
      TnDashboardScreen(participant: participant),
      TnShopScreen(participant: participant, eventId: event.id),
      TnLeaderboardScreen(eventId: event.id, myId: participant.id),
      TnProfileScreen(participant: participant),
    ];

    return Column(
      children: [
        Expanded(child: screens[_currentIndex]),
        NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Start',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Shop',
            ),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events),
              label: 'Rangliste',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParticipantPicker() {
    final event = ref.watch(selectedEventProvider);
    if (event == null) {
      return const Center(child: Text('Kein Event gewählt'));
    }
    final participants = DemoService().getParticipants(event.id);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 56,
              color: AppTheme.violet.withAlpha(120)),
          const SizedBox(height: 16),
          Text(
            'Wer bist du?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wähle einen Teilnehmer um die App aus deren Sicht zu erleben',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: participants.length,
              itemBuilder: (_, i) {
                final p = participants[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.violet.withAlpha(30),
                      child: Text(
                        p.displayName[0].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.violet,
                        ),
                      ),
                    ),
                    title: Text(p.displayName),
                    subtitle: Text('${p.group ?? "—"} · ${p.balance} P'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ref.read(demoActiveParticipantIdProvider.notifier)
                          .state = p.id;
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

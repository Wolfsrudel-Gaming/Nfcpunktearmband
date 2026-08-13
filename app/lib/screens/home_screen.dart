import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../providers/demo_provider.dart';
import '../providers/participant_provider.dart';
import '../services/demo_service.dart';
import '../widgets/role_switcher.dart';
import 'scan_screen.dart';
import 'points_screen.dart';
import 'rewards_screen.dart';
import 'leaderboard_screen.dart';
import 'teilnehmer/tn_home_screen.dart';
import 'eltern/eltern_home_screen.dart';
import 'admin/admin_home_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final _betreuerScreens = const [
    ScanScreen(),
    PointsScreen(),
    RewardsScreen(),
    LeaderboardScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectDemoEvent();
    });
  }

  void _autoSelectDemoEvent() {
    final isDemo = ref.read(demoModeProvider);
    if (!isDemo) return;
    final events = ref.read(eventsProvider).valueOrNull;
    if (events != null && events.isNotEmpty) {
      ref.read(selectedEventProvider.notifier).state = events.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = ref.watch(demoModeProvider);
    final demoRole = ref.watch(demoRoleProvider);
    final selectedEvent = ref.watch(selectedEventProvider);
    final events = ref.watch(eventsProvider);

    if (isDemo && selectedEvent == null) {
      events.whenData((list) {
        if (list.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedEventProvider.notifier).state = list.first;
          });
        }
      });
    }

    final showOwnNav = !isDemo ||
        demoRole == DemoRole.betreuer;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showEventPicker(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedEvent?.name ?? 'Event wählen',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 24),
            ],
          ),
        ),
        actions: [
          if (isDemo)
            IconButton(
              icon: const Icon(Icons.restart_alt),
              onPressed: () async {
                await DemoService().reset();
                ref.invalidate(eventsProvider);
                ref.invalidate(participantsProvider);
                ref.invalidate(leaderboardProvider);
                ref.read(demoActiveParticipantIdProvider.notifier).state = null;
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demo zurückgesetzt')),
                  );
                }
              },
              tooltip: 'Demo zurücksetzen',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(selectedEventProvider.notifier).state = null;
              ref.read(authProvider.notifier).logout();
            },
            tooltip: 'Abmelden',
          ),
        ],
      ),
      body: Column(
        children: [
          if (isDemo) const RoleSwitcher(),
          Expanded(
            child: selectedEvent == null
                ? _buildNoEvent(context)
                : _buildRoleContent(isDemo, demoRole),
          ),
        ],
      ),
      bottomNavigationBar:
          selectedEvent != null && showOwnNav ? _buildBetreuerNav() : null,
    );
  }

  Widget _buildNoEvent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Bitte ein Event wählen',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showEventPicker(context),
            icon: const Icon(Icons.list),
            label: const Text('Event auswählen'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleContent(bool isDemo, DemoRole demoRole) {
    if (!isDemo || demoRole == DemoRole.betreuer) {
      return _betreuerScreens[_currentIndex];
    }
    switch (demoRole) {
      case DemoRole.teilnehmer:
        return const TnHomeScreen();
      case DemoRole.eltern:
        return const ElternHomeScreen();
      case DemoRole.admin:
        return const AdminHomeScreen();
      case DemoRole.betreuer:
        return _betreuerScreens[_currentIndex];
    }
  }

  NavigationBar _buildBetreuerNav() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (i) => setState(() => _currentIndex = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.nfc_outlined),
          selectedIcon: Icon(Icons.nfc),
          label: 'Scan',
        ),
        NavigationDestination(
          icon: Icon(Icons.stars_outlined),
          selectedIcon: Icon(Icons.stars),
          label: 'Punkte',
        ),
        NavigationDestination(
          icon: Icon(Icons.card_giftcard_outlined),
          selectedIcon: Icon(Icons.card_giftcard),
          label: 'Prämien',
        ),
        NavigationDestination(
          icon: Icon(Icons.leaderboard_outlined),
          selectedIcon: Icon(Icons.leaderboard),
          label: 'Rangliste',
        ),
      ],
    );
  }

  void _showEventPicker(BuildContext context) {
    final events = ref.read(eventsProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Event auswählen',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            ...events.when(
              data: (list) => list
                  .where((e) => e.status == 'active')
                  .map((event) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.brand.withAlpha(30),
                          child: Icon(Icons.event, color: AppTheme.brand),
                        ),
                        title: Text(event.name),
                        subtitle: event.location != null
                            ? Text(event.location!,
                                style: const TextStyle(fontSize: 12))
                            : null,
                        trailing:
                            ref.read(selectedEventProvider)?.id == event.id
                                ? Icon(Icons.check_circle,
                                    color: AppTheme.brand)
                                : null,
                        onTap: () {
                          ref.read(selectedEventProvider.notifier).state =
                              event;
                          Navigator.pop(ctx);
                        },
                      ))
                  .toList(),
              loading: () => [
                const Center(child: CircularProgressIndicator())
              ],
              error: (_, __) => [
                const ListTile(title: Text('Fehler beim Laden'))
              ],
            ),
          ],
        ),
      ),
    );
  }
}

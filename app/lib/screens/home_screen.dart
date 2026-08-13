import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import 'scan_screen.dart';
import 'points_screen.dart';
import 'rewards_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    ScanScreen(),
    PointsScreen(),
    RewardsScreen(),
    LeaderboardScreen(),
  ];

  @override
  void initState() {
    super.initState();
    ref.listenManual(eventsProvider, (_, __) {});
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final selectedEvent = ref.watch(selectedEventProvider);
    final events = ref.watch(eventsProvider);

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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
            tooltip: 'Abmelden',
          ),
        ],
      ),
      body: selectedEvent == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event, size: 64,
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
            )
          : _screens[_currentIndex],
      bottomNavigationBar: selectedEvent != null
          ? NavigationBar(
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
            )
          : null,
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
                        trailing: ref.read(selectedEventProvider)?.id == event.id
                            ? Icon(Icons.check_circle, color: AppTheme.brand)
                            : null,
                        onTap: () {
                          ref.read(selectedEventProvider.notifier).state = event;
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

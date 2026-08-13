import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/event_provider.dart';
import '../../services/demo_service.dart';
import '../../models/participant.dart';
import 'eltern_overview_screen.dart';
import 'eltern_activity_screen.dart';
import 'eltern_contact_screen.dart';

class ElternHomeScreen extends ConsumerStatefulWidget {
  const ElternHomeScreen({super.key});

  @override
  ConsumerState<ElternHomeScreen> createState() => _ElternHomeScreenState();
}

class _ElternHomeScreenState extends ConsumerState<ElternHomeScreen> {
  int _currentIndex = 0;
  final Set<String> _selectedChildIds = {};

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(selectedEventProvider);
    if (event == null) {
      return const Center(child: Text('Kein Event gewählt'));
    }

    final participants = DemoService().getParticipants(event.id);

    if (_selectedChildIds.isEmpty) {
      return _buildChildPicker(participants);
    }

    final children = participants
        .where((p) => _selectedChildIds.contains(p.id))
        .toList();

    final screens = [
      ElternOverviewScreen(children: children),
      ElternActivityScreen(children: children),
      ElternContactScreen(eventName: event.name),
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
              label: 'Übersicht',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Aktivitäten',
            ),
            NavigationDestination(
              icon: Icon(Icons.mail_outline),
              selectedIcon: Icon(Icons.mail),
              label: 'Kontakt',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChildPicker(List<Participant> participants) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.family_restroom, size: 56,
              color: AppTheme.success.withAlpha(120)),
          const SizedBox(height: 16),
          Text(
            'Eltern-Ansicht',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wähle deine Kinder aus, um deren Fortschritt zu sehen',
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
                final selected = _selectedChildIds.contains(p.id);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: CheckboxListTile(
                    value: selected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedChildIds.add(p.id);
                        } else {
                          _selectedChildIds.remove(p.id);
                        }
                      });
                    },
                    secondary: CircleAvatar(
                      backgroundColor: AppTheme.success.withAlpha(30),
                      child: Text(
                        p.displayName[0].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.success,
                        ),
                      ),
                    ),
                    title: Text(p.displayName),
                    subtitle: Text('${p.group ?? "—"} · ${p.age ?? "?"} Jahre'),
                    activeColor: AppTheme.success,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _selectedChildIds.isEmpty
                ? null
                : () => setState(() {}),
            icon: const Icon(Icons.check),
            label: Text(
              _selectedChildIds.isEmpty
                  ? 'Bitte Kind(er) auswählen'
                  : '${_selectedChildIds.length} Kind(er) anzeigen',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.success,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}

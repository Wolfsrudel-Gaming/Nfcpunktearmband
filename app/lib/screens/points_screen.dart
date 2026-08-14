import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/event_provider.dart';
import '../providers/participant_provider.dart';
import '../models/participant.dart';
import '../widgets/shimmer_loading.dart';
import 'book_points_screen.dart';

class PointsScreen extends ConsumerStatefulWidget {
  const PointsScreen({super.key});

  @override
  ConsumerState<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends ConsumerState<PointsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(selectedEventProvider);
    if (event == null) return const SizedBox.shrink();

    final participantsAsync = ref.watch(participantsProvider(event.id));

    return participantsAsync.when(
      loading: () => const ShimmerList(),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (participants) {
        var sorted = [...participants]
          ..sort((a, b) => a.displayName.compareTo(b.displayName));
        if (_search.isNotEmpty) {
          final lower = _search.toLowerCase();
          sorted = sorted
              .where((p) =>
                  p.displayName.toLowerCase().contains(lower) ||
                  (p.group?.toLowerCase().contains(lower) ?? false))
              .toList();
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Teilnehmer suchen...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setState(() => _search = ''),
                        )
                      : null,
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${sorted.length} Teilnehmer',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  return _ParticipantTile(
                    participant: sorted[index],
                    eventId: event.id,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final Participant participant;
  final String eventId;

  const _ParticipantTile({required this.participant, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.brand.withAlpha(30),
          child: Text(
            participant.displayName[0].toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.brand,
            ),
          ),
        ),
        title: Text(
          participant.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: participant.group != null ? Text(participant.group!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${participant.balance} P',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.brand,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookPointsScreen(
                participant: participant,
                eventId: eventId,
              ),
            ),
          );
        },
      ),
    );
  }
}

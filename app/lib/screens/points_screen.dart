import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/event_provider.dart';
import '../providers/participant_provider.dart';
import '../models/participant.dart';
import 'book_points_screen.dart';

class PointsScreen extends ConsumerWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(selectedEventProvider);
    if (event == null) return const SizedBox.shrink();

    final participantsAsync = ref.watch(participantsProvider(event.id));

    return participantsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (participants) {
        final sorted = [...participants]
          ..sort((a, b) => a.displayName.compareTo(b.displayName));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: sorted.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Teilnehmer wählen',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              );
            }
            final p = sorted[index - 1];
            return _ParticipantTile(participant: p, eventId: event.id);
          },
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

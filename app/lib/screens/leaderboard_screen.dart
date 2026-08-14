import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/event_provider.dart';
import '../providers/participant_provider.dart';
import '../widgets/shimmer_loading.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(selectedEventProvider);
    if (event == null) return const SizedBox.shrink();

    final leaderboardAsync = ref.watch(leaderboardProvider(event.id));

    return leaderboardAsync.when(
      loading: () => const ShimmerList(itemCount: 8),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (participants) {
        if (participants.isEmpty) {
          return const Center(
            child: Text('Keine Daten', style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: participants.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildPodium(context, participants);
            }
            final rank = index;
            if (rank > participants.length) return const SizedBox.shrink();
            final p = participants[rank - 1];
            if (rank <= 3) return const SizedBox.shrink();
            return _buildRow(context, rank, p);
          },
        );
      },
    );
  }

  Widget _buildPodium(BuildContext context, List participants) {
    final top = participants.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top.length > 1) _podiumItem(context, top[1], 2, 80),
          if (top.isNotEmpty) _podiumItem(context, top[0], 1, 110),
          if (top.length > 2) _podiumItem(context, top[2], 3, 60),
        ],
      ),
    );
  }

  Widget _podiumItem(BuildContext context, dynamic p, int rank, double height) {
    final colors = [AppTheme.brand, Colors.grey.shade400, Colors.brown.shade300];
    final icons = ['🥇', '🥈', '🥉'];
    final color = colors[rank - 1];

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icons[rank - 1], style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          CircleAvatar(
            radius: rank == 1 ? 32 : 24,
            backgroundColor: color.withAlpha(40),
            child: Text(
              p.displayName[0].toUpperCase(),
              style: TextStyle(
                fontSize: rank == 1 ? 24 : 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            p.displayName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${p.balance} P',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.brand,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, int rank, dynamic p) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: SizedBox(
          width: 32,
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        title: Text(
          p.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: p.group != null ? Text(p.group!) : null,
        trailing: Text(
          '${p.balance} P',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppTheme.brand,
          ),
        ),
      ),
    );
  }
}

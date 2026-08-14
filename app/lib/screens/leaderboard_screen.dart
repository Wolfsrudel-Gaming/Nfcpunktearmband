import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../providers/event_provider.dart';
import '../providers/participant_provider.dart';
import '../widgets/shimmer_loading.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String? _selectedGroup;

  @override
  Widget build(BuildContext context) {
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

        final groups = participants
            .where((p) => p.group != null)
            .map((p) => p.group!)
            .toSet()
            .toList()
          ..sort();

        final filtered = _selectedGroup == null
            ? participants
            : participants.where((p) => p.group == _selectedGroup).toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(leaderboardProvider(event.id));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildGroupFilter(context, groups);
              }
              if (index == 1) {
                return _buildPodium(context, filtered)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.1, end: 0, duration: 500.ms);
              }
              final rank = index - 1;
              if (rank > filtered.length) return const SizedBox.shrink();
              final p = filtered[rank - 1];
              if (rank <= 3) return const SizedBox.shrink();
              return _buildRow(context, rank, p);
            },
          ),
        );
      },
    );
  }

  Widget _buildGroupFilter(BuildContext context, List<String> groups) {
    if (groups.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _filterChip(context, 'Alle', null),
            ...groups.map((g) => _filterChip(context, g, g)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, String? group) {
    final selected = _selectedGroup == group;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
        selected: selected,
        selectedColor: AppTheme.violet,
        checkmarkColor: Colors.white,
        onSelected: (_) => setState(() => _selectedGroup = group),
      ),
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
    final icons = ['\u{1F947}', '\u{1F948}', '\u{1F949}'];
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

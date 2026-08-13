import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/demo_service.dart';

class TnLeaderboardScreen extends StatelessWidget {
  final String eventId;
  final String myId;

  const TnLeaderboardScreen({
    super.key,
    required this.eventId,
    required this.myId,
  });

  @override
  Widget build(BuildContext context) {
    final leaderboard = DemoService().getLeaderboard(eventId);

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: leaderboard.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          final myRank = leaderboard.indexWhere((p) => p.id == myId) + 1;
          final myP = leaderboard.where((p) => p.id == myId).firstOrNull;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.violet, AppTheme.brand],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#$myRank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dein Platz',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '${myP?.balance ?? 0} Punkte',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final rank = index;
        final p = leaderboard[rank - 1];
        final isMe = p.id == myId;
        final medal = rank <= 3
            ? ['', '🥇', '🥈', '🥉'][rank]
            : '';

        return Card(
          color: isMe
              ? AppTheme.violet.withAlpha(15)
              : null,
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: ListTile(
            leading: SizedBox(
              width: 36,
              child: Center(
                child: medal.isNotEmpty
                    ? Text(medal, style: const TextStyle(fontSize: 20))
                    : Text(
                        '$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            title: Text(
              isMe ? '${p.displayName} (Du)' : p.displayName,
              style: TextStyle(
                fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                color: isMe ? AppTheme.violet : null,
              ),
            ),
            subtitle: p.group != null
                ? Text(p.group!, style: const TextStyle(fontSize: 12))
                : null,
            trailing: Text(
              '${p.balance} P',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isMe ? AppTheme.violet : AppTheme.brand,
              ),
            ),
          ),
        );
      },
    );
  }
}

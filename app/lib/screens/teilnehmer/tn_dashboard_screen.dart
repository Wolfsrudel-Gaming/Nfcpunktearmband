import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/participant.dart';
import '../../models/point_transaction.dart';
import '../../services/demo_service.dart';

class TnDashboardScreen extends StatelessWidget {
  final Participant participant;

  const TnDashboardScreen({super.key, required this.participant});

  @override
  Widget build(BuildContext context) {
    final p = DemoService().getParticipant(participant.id) ?? participant;
    final transactions = DemoService().getTransactions(p.id);
    final leaderboard = DemoService().getLeaderboard(p.eventId);
    final rank = leaderboard.indexWhere((x) => x.id == p.id) + 1;
    final recent = transactions.take(10).toList();

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPointsCard(context, p, rank, leaderboard.length)
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.15, end: 0, duration: 500.ms),
          const SizedBox(height: 16),
          _buildStatsRow(context, p, transactions)
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 200.ms),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Letzte Aktivitäten',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Text(
                '${transactions.length} gesamt',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Noch keine Aktivitäten',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...recent.map((tx) => _txTile(context, tx)),
        ],
      ),
    );
  }

  Widget _buildPointsCard(
      BuildContext context, Participant p, int rank, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.violet, AppTheme.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Deine Punkte',
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${p.balance}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  p.group ?? p.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (rank > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Platz $rank/$total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
      BuildContext context, Participant p, List<PointTransaction> txs) {
    final earned =
        txs.where((t) => t.amount > 0).fold<int>(0, (s, t) => s + t.amount);
    final spent = txs
        .where((t) => t.amount < 0)
        .fold<int>(0, (s, t) => s + t.amount.abs());
    return Row(
      children: [
        _statCard(context, 'Verdient', '+$earned', AppTheme.success),
        const SizedBox(width: 8),
        _statCard(context, 'Ausgegeben', '-$spent', AppTheme.danger),
        const SizedBox(width: 8),
        _statCard(context, 'Buchungen', '${txs.length}', AppTheme.violet),
      ],
    );
  }

  Widget _statCard(
      BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _txTile(BuildContext context, PointTransaction tx) {
    final pos = tx.amount >= 0;
    final dt = DateTime.tryParse(tx.createdAt);
    final time = dt != null
        ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : '';

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor:
            (pos ? AppTheme.success : AppTheme.danger).withAlpha(25),
        child: Icon(
          pos ? Icons.arrow_upward : Icons.arrow_downward,
          size: 18,
          color: pos ? AppTheme.success : AppTheme.danger,
        ),
      ),
      title: Text(
        '${pos ? '+' : ''}${tx.amount} Punkte',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: pos ? AppTheme.success : AppTheme.danger,
        ),
      ),
      subtitle:
          Text(tx.note ?? tx.reason, style: const TextStyle(fontSize: 12)),
      trailing: Text(
        time,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

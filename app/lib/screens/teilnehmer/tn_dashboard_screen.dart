import 'package:flutter/material.dart';
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
    final recent = transactions.take(5).toList();

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPointsCard(context, p),
          const SizedBox(height: 16),
          _buildStatsRow(context, p, transactions),
          const SizedBox(height: 20),
          Text(
            'Letzte Aktivitäten',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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

  Widget _buildPointsCard(BuildContext context, Participant p) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
        ],
      ),
    );
  }

  Widget _buildStatsRow(
      BuildContext context, Participant p, List<PointTransaction> txs) {
    final earned = txs.where((t) => t.amount > 0).fold<int>(0, (s, t) => s + t.amount);
    final spent = txs.where((t) => t.amount < 0).fold<int>(0, (s, t) => s + t.amount.abs());
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

  Widget _statCard(BuildContext context, String label, String value, Color color) {
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
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: (pos ? AppTheme.success : AppTheme.danger).withAlpha(25),
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
      subtitle: Text(tx.note ?? tx.reason, style: const TextStyle(fontSize: 12)),
    );
  }
}

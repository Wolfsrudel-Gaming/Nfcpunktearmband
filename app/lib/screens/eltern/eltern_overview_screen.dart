import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/participant.dart';
import '../../services/demo_service.dart';

class ElternOverviewScreen extends StatelessWidget {
  final List<Participant> children;

  const ElternOverviewScreen({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(context),
        const SizedBox(height: 16),
        ...children.map((child) => _buildChildCard(context, child)),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final totalPoints = children.fold<int>(0, (s, c) {
      final p = DemoService().getParticipant(c.id) ?? c;
      return s + p.balance;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.success, const Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.family_restroom, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            '${children.length} ${children.length == 1 ? 'Kind' : 'Kinder'}',
            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '$totalPoints Punkte gesamt',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, Participant child) {
    final p = DemoService().getParticipant(child.id) ?? child;
    final txs = DemoService().getTransactions(p.id);
    final earned = txs.where((t) => t.amount > 0).fold<int>(0, (s, t) => s + t.amount);
    final redeemed = txs.where((t) => t.reason == 'redemption').length;
    final lastTx = txs.isNotEmpty ? txs.first : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.success.withAlpha(30),
                  child: Text(
                    p.displayName[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${p.group ?? "—"} · ${p.age ?? "?"} Jahre',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.violet.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${p.balance} P',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.violet,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _miniStat(context, Icons.arrow_upward, '+$earned', 'Verdient',
                    AppTheme.success),
                const SizedBox(width: 16),
                _miniStat(context, Icons.card_giftcard, '$redeemed',
                    'Eingelöst', AppTheme.brand),
                const SizedBox(width: 16),
                _miniStat(
                  context,
                  p.nfcTagUid != null ? Icons.nfc : Icons.nfc_outlined,
                  p.nfcTagUid != null ? 'Ja' : 'Nein',
                  'Armband',
                  p.nfcTagUid != null ? AppTheme.success : Colors.grey,
                ),
              ],
            ),
            if (lastTx != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Letzte Buchung: ${lastTx.amount >= 0 ? '+' : ''}${lastTx.amount} P — ${lastTx.note ?? lastTx.reason}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStat(BuildContext context, IconData icon, String value,
      String label, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13, color: color)),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

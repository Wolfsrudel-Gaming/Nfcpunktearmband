import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/demo_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  final String eventId;

  const AdminDashboardScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final event = DemoService().getEvent(eventId);
    final participants = DemoService().getParticipants(eventId);
    final txs = DemoService().getEventTransactions(eventId);
    final rewards = DemoService().getRewards(eventId);

    final totalPoints =
        participants.fold<int>(0, (s, p) => s + p.balance);
    final totalEarned = txs
        .where((t) => t.amount > 0)
        .fold<int>(0, (s, t) => s + t.amount);
    final totalSpent = txs
        .where((t) => t.amount < 0)
        .fold<int>(0, (s, t) => s + t.amount.abs());
    final redemptions = txs.where((t) => t.reason == 'redemption').length;
    final withNfc = participants.where((p) => p.nfcTagUid != null).length;

    final groups = <String, int>{};
    for (final p in participants) {
      final g = p.group ?? 'Ohne Gruppe';
      groups[g] = (groups[g] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (event != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.danger, const Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.admin_panel_settings,
                    color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Text(
                  event.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.location ?? "—"} · ${event.startDate ?? ""} – ${event.endDate ?? ""}',
                  style: TextStyle(
                      color: Colors.white.withAlpha(200), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            _statCard(context, '${participants.length}', 'Teilnehmer',
                Icons.people, AppTheme.violet),
            const SizedBox(width: 8),
            _statCard(context, '$totalPoints', 'Punkte Gesamt',
                Icons.stars, AppTheme.brand),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _statCard(context, '+$totalEarned', 'Vergeben',
                Icons.arrow_upward, AppTheme.success),
            const SizedBox(width: 8),
            _statCard(context, '-$totalSpent', 'Eingelöst',
                Icons.arrow_downward, AppTheme.danger),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _statCard(context, '${txs.length}', 'Buchungen',
                Icons.receipt_long, AppTheme.violet),
            const SizedBox(width: 8),
            _statCard(context, '$redemptions', 'Einlösungen',
                Icons.card_giftcard, AppTheme.brand),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _statCard(context, '$withNfc', 'NFC verbunden', Icons.nfc,
                AppTheme.success),
            const SizedBox(width: 8),
            _statCard(context, '${rewards.length}', 'Prämien',
                Icons.inventory_2, AppTheme.danger),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Gruppen',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...groups.entries.map((e) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.violet.withAlpha(20),
                  child: Text(
                    '${e.value}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.violet,
                    ),
                  ),
                ),
                title: Text(e.key,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Text('${e.value} TN',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            )),
        const SizedBox(height: 20),
        Text(
          'Letzte Buchungen',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...txs.take(10).map((tx) {
          final pos = tx.amount >= 0;
          final pName = participants
                  .where((p) => p.id == tx.participantId)
                  .firstOrNull
                  ?.displayName ??
              '?';
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor:
                  (pos ? AppTheme.success : AppTheme.danger).withAlpha(25),
              child: Icon(
                pos ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: pos ? AppTheme.success : AppTheme.danger,
              ),
            ),
            title: Text(
              '$pName: ${pos ? "+" : ""}${tx.amount} P',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            subtitle: Text(tx.note ?? tx.reason,
                style: const TextStyle(fontSize: 11)),
          );
        }),
      ],
    );
  }

  Widget _statCard(BuildContext context, String value, String label,
      IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(label,
                      style: TextStyle(fontSize: 11, color: color),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

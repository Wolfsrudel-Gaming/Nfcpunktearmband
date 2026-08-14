import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/point_transaction.dart';
import '../../services/demo_service.dart';

class AdminActivityScreen extends StatefulWidget {
  final String eventId;

  const AdminActivityScreen({super.key, required this.eventId});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final participants = DemoService().getParticipants(widget.eventId);
    var txs = DemoService().getEventTransactions(widget.eventId);

    if (_filter == 'earned') {
      txs = txs.where((t) => t.amount > 0).toList();
    } else if (_filter == 'spent') {
      txs = txs.where((t) => t.amount < 0).toList();
    } else if (_filter == 'redemption') {
      txs = txs.where((t) => t.reason == 'redemption').toList();
    }

    final nameMap = <String, String>{};
    for (final p in participants) {
      nameMap[p.id] = p.displayName;
    }

    final grouped = <String, List<PointTransaction>>{};
    for (final tx in txs) {
      final dt = DateTime.tryParse(tx.createdAt);
      final key = dt != null
          ? '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}'
          : 'Unbekannt';
      (grouped[key] ??= []).add(tx);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip('Alle', 'all'),
                _chip('Verdient', 'earned'),
                _chip('Ausgegeben', 'spent'),
                _chip('Einlösungen', 'redemption'),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${txs.length} Buchungen',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: txs.isEmpty
              ? const Center(
                  child:
                      Text('Keine Buchungen', style: TextStyle(color: Colors.grey)),
                )
              : RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: grouped.length,
                    itemBuilder: (context, i) {
                      final entry = grouped.entries.elementAt(i);
                      return _buildDaySection(context, entry.key, entry.value, nameMap, i);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
        selected: selected,
        selectedColor: AppTheme.violet,
        checkmarkColor: Colors.white,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  Widget _buildDaySection(BuildContext context, String date,
      List<PointTransaction> txs, Map<String, String> nameMap, int sectionIdx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
          child: Text(
            date,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ...txs.asMap().entries.map((e) {
          final tx = e.value;
          final idx = e.key;
          return _txTile(context, tx, nameMap)
              .animate()
              .fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: 50 * (idx > 5 ? 5 : idx)),
              );
        }),
      ],
    );
  }

  Widget _txTile(
      BuildContext context, PointTransaction tx, Map<String, String> nameMap) {
    final pos = tx.amount >= 0;
    final name = nameMap[tx.participantId] ?? '?';
    final dt = DateTime.tryParse(tx.createdAt);
    final time = dt != null
        ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
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
          '$name: ${pos ? "+" : ""}${tx.amount} P',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: pos ? AppTheme.success : AppTheme.danger,
          ),
        ),
        subtitle: Text(
          tx.note ?? tx.reason,
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${tx.balanceAfter} P',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/participant.dart';
import '../../models/point_transaction.dart';
import '../../services/demo_service.dart';

class ElternActivityScreen extends StatelessWidget {
  final List<Participant> children;

  const ElternActivityScreen({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final allTxs = <_ChildTx>[];
    for (final child in children) {
      final p = DemoService().getParticipant(child.id) ?? child;
      final txs = DemoService().getTransactions(p.id);
      for (final tx in txs) {
        allTxs.add(_ChildTx(child: p, tx: tx));
      }
    }
    allTxs.sort((a, b) => b.tx.createdAt.compareTo(a.tx.createdAt));

    return allTxs.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 48,
                    color: Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: 12),
                Text(
                  'Noch keine Aktivitäten',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: allTxs.length,
            itemBuilder: (context, index) {
              final item = allTxs[index];
              final pos = item.tx.amount >= 0;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
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
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${pos ? '+' : ''}${item.tx.amount} Punkte',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: pos ? AppTheme.success : AppTheme.danger,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.child.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    item.tx.note ?? item.tx.reason,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          );
  }
}

class _ChildTx {
  final Participant child;
  final PointTransaction tx;
  const _ChildTx({required this.child, required this.tx});
}

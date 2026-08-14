import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/reward.dart';
import '../../services/demo_service.dart';

class AdminRewardsScreen extends StatefulWidget {
  final String eventId;

  const AdminRewardsScreen({super.key, required this.eventId});

  @override
  State<AdminRewardsScreen> createState() => _AdminRewardsScreenState();
}

class _AdminRewardsScreenState extends State<AdminRewardsScreen> {
  @override
  Widget build(BuildContext context) {
    final rewards = DemoService().getRewards(widget.eventId);
    final totalRedeemed = rewards.fold<int>(0, (s, r) => s + r.redeemed);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${rewards.length} Prämien',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Neue Prämie'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$totalRedeemed Einlösungen gesamt',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...rewards.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          return _rewardCard(context, r)
              .animate()
              .fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: 60 * (i > 5 ? 5 : i)),
              );
        }),
      ],
    );
  }

  Widget _rewardCard(BuildContext context, Reward r) {
    final stockText =
        r.stock != null ? '${r.remaining}/${r.stock} übrig' : 'Unbegrenzt';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRewardDetail(context, r),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.brand.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(Icons.card_giftcard, color: AppTheme.brand),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        if (r.description != null)
                          Text(r.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              )),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${r.cost} P',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brand,
                              fontSize: 16)),
                      if (r.category != null)
                        Text(r.category!,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  _tag(context, Icons.inventory_2_outlined, stockText,
                      r.inStock ? AppTheme.success : AppTheme.danger),
                  const SizedBox(width: 8),
                  _tag(context, Icons.shopping_bag_outlined,
                      '${r.redeemed}x eingelöst', AppTheme.violet),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          (r.available ? AppTheme.success : AppTheme.danger)
                              .withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      r.available ? 'Aktiv' : 'Inaktiv',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: r.available
                            ? AppTheme.success
                            : AppTheme.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(
      BuildContext context, IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  void _showRewardDetail(BuildContext context, Reward r) {
    final participants = DemoService().getParticipants(widget.eventId);
    final txs = DemoService().getEventTransactions(widget.eventId);
    final redemptions = txs
        .where((t) => t.reason == 'redemption' && t.note == r.name)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.brand.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.card_giftcard,
                        color: AppTheme.brand, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        if (r.description != null)
                          Text(r.description!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _detailStat('Kosten', '${r.cost} P', AppTheme.brand),
                  const SizedBox(width: 8),
                  _detailStat(
                      'Bestand',
                      r.stock != null
                          ? '${r.remaining}/${r.stock}'
                          : '∞',
                      r.inStock ? AppTheme.success : AppTheme.danger),
                  const SizedBox(width: 8),
                  _detailStat(
                      'Eingelöst', '${r.redeemed}x', AppTheme.violet),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Einlösungen',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              if (redemptions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('Noch keine Einlösungen',
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...redemptions.map((tx) {
                  final pName = participants
                          .where((p) => p.id == tx.participantId)
                          .firstOrNull
                          ?.displayName ??
                      '?';
                  final dt = DateTime.tryParse(tx.createdAt);
                  final time = dt != null
                      ? '${dt.day}.${dt.month}. ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'
                      : '';
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.violet.withAlpha(20),
                      child: Text(
                        pName[0].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.violet,
                        ),
                      ),
                    ),
                    title: Text(pName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(time,
                        style: const TextStyle(fontSize: 11)),
                    trailing: Text('-${tx.amount.abs()} P',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.danger,
                          fontSize: 13,
                        )),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
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

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    String? category;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Prämie erstellen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kosten (Punkte)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bestand (leer = unbegrenzt)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Kategorie',
                  border: OutlineInputBorder(),
                ),
                items: ['Essen', 'Privilegien', 'Erlebnisse', 'Spezial']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => category = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final cost = int.tryParse(costCtrl.text);
              if (cost == null || cost <= 0) return;

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${nameCtrl.text} erstellt (Demo)'),
                  backgroundColor: AppTheme.success,
                ),
              );
              setState(() {});
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }
}

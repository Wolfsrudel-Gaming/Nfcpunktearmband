import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/demo_service.dart';

class AdminRewardsScreen extends StatelessWidget {
  final String eventId;

  const AdminRewardsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final rewards = DemoService().getRewards(eventId);

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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Prämien-Erstellung: Im Live-Modus über Dashboard')),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Neue Prämie'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...rewards.map((r) {
          final stockText = r.stock != null
              ? '${r.remaining}/${r.stock} übrig'
              : 'Unbegrenzt';
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
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
                        child: Icon(Icons.card_giftcard,
                            color: AppTheme.brand),
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
                          color: (r.available
                                  ? AppTheme.success
                                  : AppTheme.danger)
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
          );
        }),
      ],
    );
  }

  Widget _tag(
      BuildContext context, IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

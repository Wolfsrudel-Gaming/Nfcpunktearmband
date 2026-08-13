import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../models/participant.dart';
import '../../models/reward.dart';
import '../../services/demo_service.dart';

class TnShopScreen extends StatefulWidget {
  final Participant participant;
  final String eventId;

  const TnShopScreen({
    super.key,
    required this.participant,
    required this.eventId,
  });

  @override
  State<TnShopScreen> createState() => _TnShopScreenState();
}

class _TnShopScreenState extends State<TnShopScreen> {
  late List<Reward> _rewards;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _rewards = DemoService().getRewards(widget.eventId);
    });
  }

  Participant get _currentP =>
      DemoService().getParticipant(widget.participant.id) ?? widget.participant;

  Future<void> _redeem(Reward reward) async {
    final p = _currentP;
    if (p.balance < reward.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Du brauchst ${reward.cost - p.balance} Punkte mehr'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(reward.name),
        content: Text(
          '${reward.cost} Punkte einlösen?\n\nDein Kontostand danach: ${p.balance - reward.cost} P',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Einlösen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await DemoService().redeemReward(
        rewardId: reward.id,
        participantId: widget.participant.id,
        eventId: widget.eventId,
      );
      HapticFeedback.heavyImpact();
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${reward.name} eingelöst! Neuer Stand: ${result['balance']} P',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _currentP;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.violet.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  color: AppTheme.violet, size: 20),
              const SizedBox(width: 8),
              Text(
                'Dein Guthaben: ',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${p.balance} Punkte',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.violet,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._rewards.map((r) => _buildRewardCard(context, r, p)),
      ],
    );
  }

  Widget _buildRewardCard(BuildContext context, Reward reward, Participant p) {
    final canAfford = p.balance >= reward.cost;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: canAfford
                    ? AppTheme.brand.withAlpha(20)
                    : Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.card_giftcard,
                color: canAfford ? AppTheme.brand : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (reward.description != null)
                    Text(
                      reward.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${reward.cost} P',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: canAfford ? AppTheme.brand : Colors.grey,
                        ),
                      ),
                      if (reward.remaining != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Noch ${reward.remaining}x',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (reward.available && reward.inStock)
              FilledButton.tonal(
                onPressed: canAfford ? () => _redeem(reward) : null,
                child: Text(canAfford ? 'Holen' : 'Zu wenig'),
              ),
            if (!reward.inStock)
              const Chip(
                label: Text('Weg', style: TextStyle(fontSize: 11)),
                backgroundColor: Colors.transparent,
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/reward.dart';
import '../models/participant.dart';
import '../providers/event_provider.dart';
import '../providers/participant_provider.dart';
import '../services/api_client.dart';

final _rewardsProvider = FutureProvider.family<List<Reward>, String>(
  (ref, eventId) async {
    final data =
        await ApiClient().get<List<dynamic>>('/api/rewards/event/$eventId');
    return data
        .map((e) => Reward.fromJson(e as Map<String, dynamic>))
        .toList();
  },
);

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(selectedEventProvider);
    if (event == null) return const SizedBox.shrink();

    final rewardsAsync = ref.watch(_rewardsProvider(event.id));

    return rewardsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (rewards) {
        if (rewards.isEmpty) {
          return const Center(
            child: Text(
              'Keine Prämien konfiguriert',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: rewards.length,
          itemBuilder: (_, i) =>
              _RewardCard(reward: rewards[i], eventId: event.id),
        );
      },
    );
  }
}

class _RewardCard extends ConsumerWidget {
  final Reward reward;
  final String eventId;

  const _RewardCard({required this.reward, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reward.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.brand.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${reward.cost} P',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brand,
                    ),
                  ),
                ),
              ],
            ),
            if (reward.description != null) ...[
              const SizedBox(height: 6),
              Text(
                reward.description!,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (reward.remaining != null)
                  _chip(Icons.inventory_2_outlined,
                      '${reward.remaining}/${reward.stock}'),
                if (reward.category != null)
                  _chip(Icons.label_outline, reward.category!),
                if (reward.limitPerParticipant != null)
                  _chip(Icons.person_outline,
                      'Max ${reward.limitPerParticipant}x'),
                const Spacer(),
                if (reward.available && reward.inStock)
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        _showRedeemDialog(context, ref),
                    icon: const Icon(Icons.redeem, size: 18),
                    label: const Text('Einlösen'),
                  ),
                if (!reward.available || !reward.inStock)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      !reward.inStock ? 'Ausverkauft' : 'Deaktiviert',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showRedeemDialog(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.read(participantsProvider(eventId));
    final eligible = participantsAsync.valueOrNull
            ?.where((p) => p.balance >= reward.cost)
            .toList() ??
        [];

    if (eligible.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kein Teilnehmer hat genug Punkte')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RedeemSheet(
        reward: reward,
        participants: eligible,
        eventId: eventId,
      ),
    );
  }
}

class _RedeemSheet extends StatefulWidget {
  final Reward reward;
  final List<Participant> participants;
  final String eventId;

  const _RedeemSheet({
    required this.reward,
    required this.participants,
    required this.eventId,
  });

  @override
  State<_RedeemSheet> createState() => _RedeemSheetState();
}

class _RedeemSheetState extends State<_RedeemSheet> {
  bool _loading = false;

  Future<void> _redeem(Participant participant) async {
    setState(() => _loading = true);
    try {
      final result =
          await ApiClient().post<Map<String, dynamic>>('/api/rewards/redeem', data: {
        'rewardId': widget.reward.id,
        'participantId': participant.id,
        'eventId': widget.eventId,
      });
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.reward.name} eingelöst! Stand: ${result['balance']} P',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${widget.reward.name} einlösen',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Kosten: ${widget.reward.cost} Punkte',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            ...widget.participants.map((p) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.brand.withAlpha(30),
                    child: Text(
                      p.displayName[0].toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brand,
                      ),
                    ),
                  ),
                  title: Text(p.displayName),
                  trailing: Text(
                    '${p.balance} P',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brand,
                    ),
                  ),
                  onTap: () => _redeem(p),
                )),
        ],
      ),
    );
  }
}

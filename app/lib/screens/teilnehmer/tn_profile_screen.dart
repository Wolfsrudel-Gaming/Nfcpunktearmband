import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/participant.dart';
import '../../services/demo_service.dart';

class TnProfileScreen extends StatelessWidget {
  final Participant participant;

  const TnProfileScreen({super.key, required this.participant});

  @override
  Widget build(BuildContext context) {
    final p = DemoService().getParticipant(participant.id) ?? participant;
    final txs = DemoService().getTransactions(p.id);
    final redeemed = txs.where((t) => t.reason == 'redemption').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: AppTheme.violet.withAlpha(30),
            child: Text(
              p.displayName[0].toUpperCase(),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.violet,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            p.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (p.group != null)
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.violet.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                p.group!,
                style: TextStyle(color: AppTheme.violet, fontSize: 13),
              ),
            ),
          ),
        const SizedBox(height: 24),
        _infoRow(context, Icons.stars, 'Punkte', '${p.balance}'),
        _infoRow(context, Icons.receipt_long, 'Buchungen', '${txs.length}'),
        _infoRow(context, Icons.card_giftcard, 'Eingelöst',
            '${redeemed.length} Prämien'),
        _infoRow(context, Icons.cake_outlined, 'Alter',
            p.age != null ? '${p.age} Jahre' : '—'),
        _infoRow(
          context,
          p.nfcTagUid != null ? Icons.nfc : Icons.nfc_outlined,
          'NFC-Armband',
          p.nfcTagUid != null ? 'Verbunden' : 'Nicht zugewiesen',
        ),
        if (redeemed.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Eingelöste Prämien',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...redeemed.map((tx) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.success.withAlpha(25),
                  child: Icon(Icons.check, size: 16, color: AppTheme.success),
                ),
                title: Text(tx.note ?? 'Prämie'),
                subtitle: Text('−${tx.amount.abs()} P',
                    style: const TextStyle(fontSize: 12)),
              )),
        ],
      ],
    );
  }

  Widget _infoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.violet),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

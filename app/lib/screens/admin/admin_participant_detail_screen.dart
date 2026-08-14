import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/participant.dart';
import '../../models/point_transaction.dart';
import '../../services/demo_service.dart';

class AdminParticipantDetailScreen extends StatefulWidget {
  final Participant participant;
  final String eventId;

  const AdminParticipantDetailScreen({
    super.key,
    required this.participant,
    required this.eventId,
  });

  @override
  State<AdminParticipantDetailScreen> createState() =>
      _AdminParticipantDetailScreenState();
}

class _AdminParticipantDetailScreenState
    extends State<AdminParticipantDetailScreen> {
  late Participant _participant;
  List<PointTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final p = DemoService().getParticipant(widget.participant.id);
    final txs = DemoService().getTransactions(widget.participant.id);
    setState(() {
      _participant = p ?? widget.participant;
      _transactions = txs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final earned = _transactions
        .where((t) => t.amount > 0)
        .fold<int>(0, (s, t) => s + t.amount);
    final spent = _transactions
        .where((t) => t.amount < 0)
        .fold<int>(0, (s, t) => s + t.amount.abs());

    return Scaffold(
      appBar: AppBar(
        title: Text(_participant.displayName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'toggle':
                  _toggleActive();
                case 'reset':
                  _resetPoints();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      _participant.active
                          ? Icons.block
                          : Icons.check_circle_outline,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(_participant.active ? 'Deaktivieren' : 'Aktivieren'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt, size: 20),
                    SizedBox(width: 8),
                    Text('Punkte zurücksetzen'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoCard(context)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0, duration: 400.ms),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard('Verdient', '+$earned', AppTheme.success),
                const SizedBox(width: 8),
                _statCard('Ausgegeben', '-$spent', AppTheme.danger),
                const SizedBox(width: 8),
                _statCard('Buchungen', '${_transactions.length}', AppTheme.violet),
              ],
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 150.ms),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Transaktionen',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${_transactions.length} gesamt',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('Keine Buchungen',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ..._transactions.map((tx) => _txTile(context, tx)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.violet.withAlpha(30),
              child: Text(
                _participant.displayName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.violet,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _participant.displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_participant.group != null)
                  _chipTag(Icons.group, _participant.group!, AppTheme.violet),
                if (_participant.age != null) ...[
                  const SizedBox(width: 8),
                  _chipTag(
                      Icons.cake, '${_participant.age} Jahre', AppTheme.brand),
                ],
                const SizedBox(width: 8),
                _chipTag(
                  _participant.nfcTagUid != null ? Icons.nfc : Icons.nfc_outlined,
                  _participant.nfcTagUid != null ? 'NFC aktiv' : 'Kein NFC',
                  _participant.nfcTagUid != null
                      ? AppTheme.success
                      : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.brand.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_participant.balance}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brand,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Punkte',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (_participant.nfcTagUid != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: _participant.nfcTagUid!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tag-UID kopiert')),
                  );
                },
                child: Text(
                  'Tag: ${_participant.nfcTagUid}',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            if (!_participant.active) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Deaktiviert',
                  style: TextStyle(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chipTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
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

  Widget _txTile(BuildContext context, PointTransaction tx) {
    final pos = tx.amount >= 0;
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
        '${pos ? "+" : ""}${tx.amount} Punkte',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: pos ? AppTheme.success : AppTheme.danger,
        ),
      ),
      subtitle: Text(tx.note ?? tx.reason,
          style: const TextStyle(fontSize: 11)),
      trailing: Text('${tx.balanceAfter} P',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
    );
  }

  void _toggleActive() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_participant.active
            ? 'Teilnehmer deaktiviert (Demo)'
            : 'Teilnehmer aktiviert (Demo)'),
        backgroundColor: _participant.active ? AppTheme.danger : AppTheme.success,
      ),
    );
  }

  void _resetPoints() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Punkte zurücksetzen?'),
        content: Text(
            'Alle ${_participant.balance} Punkte von ${_participant.displayName} auf 0 setzen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Punkte zurückgesetzt (Demo)'),
                ),
              );
            },
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );
  }
}

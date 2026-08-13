import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/participant.dart';
import '../models/point_transaction.dart';
import '../services/api_client.dart';
import '../providers/event_provider.dart';
import 'book_points_screen.dart';

class ParticipantProfileScreen extends ConsumerStatefulWidget {
  final Participant participant;

  const ParticipantProfileScreen({super.key, required this.participant});

  @override
  ConsumerState<ParticipantProfileScreen> createState() =>
      _ParticipantProfileScreenState();
}

class _ParticipantProfileScreenState
    extends ConsumerState<ParticipantProfileScreen> {
  late Participant _participant;
  List<PointTransaction> _transactions = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _participant = widget.participant;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await ApiClient().get<List<dynamic>>(
        '/api/points/participant/${_participant.id}',
      );
      setState(() {
        _transactions = data
            .map((e) => PointTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
        _loadingHistory = false;
      });
    } catch (_) {
      setState(() => _loadingHistory = false);
    }
  }

  Future<void> _refreshParticipant() async {
    try {
      final data = await ApiClient().get<Map<String, dynamic>>(
        '/api/participants/${_participant.id}',
      );
      setState(() => _participant = Participant.fromJson(data));
      _loadHistory();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_participant.displayName)),
      body: RefreshIndicator(
        onRefresh: _refreshParticipant,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 24),
            Text(
              'Letzte Buchungen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _buildHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.brand.withAlpha(30),
              child: Text(
                _participant.displayName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brand,
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
            if (_participant.group != null) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.violet.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _participant.group!,
                  style: TextStyle(
                    color: AppTheme.violet,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.brand.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '${_participant.balance}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brand,
                    ),
                  ),
                  const Text(
                    'Punkte',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _infoChip(Icons.cake_outlined,
                    _participant.age != null ? '${_participant.age} J.' : '—'),
                const SizedBox(width: 12),
                _infoChip(
                  _participant.nfcTagUid != null
                      ? Icons.nfc
                      : Icons.nfc_outlined,
                  _participant.nfcTagUid != null ? 'NFC aktiv' : 'Kein NFC',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final event = ref.read(selectedEventProvider);
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => BookPointsScreen(
                    participant: _participant,
                    eventId: event!.id,
                  ),
                ),
              );
              if (result == true) _refreshParticipant();
            },
            icon: const Icon(Icons.add),
            label: const Text('Punkte buchen'),
          ),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Noch keine Buchungen',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return Column(
      children: _transactions.take(20).map((tx) {
        final isPositive = tx.amount >= 0;
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: isPositive
                ? AppTheme.success.withAlpha(25)
                : AppTheme.danger.withAlpha(25),
            child: Icon(
              isPositive ? Icons.add : Icons.remove,
              size: 18,
              color: isPositive ? AppTheme.success : AppTheme.danger,
            ),
          ),
          title: Text(
            '${isPositive ? '+' : ''}${tx.amount} Punkte',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isPositive ? AppTheme.success : AppTheme.danger,
            ),
          ),
          subtitle: Text(
            tx.note ?? tx.reason,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Text(
            '${tx.balanceAfter} P',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        );
      }).toList(),
    );
  }
}

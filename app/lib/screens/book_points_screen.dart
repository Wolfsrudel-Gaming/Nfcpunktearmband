import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/participant.dart';
import '../services/api_client.dart';
import '../services/offline_queue.dart';

class BookPointsScreen extends StatefulWidget {
  final Participant participant;
  final String eventId;

  const BookPointsScreen({
    super.key,
    required this.participant,
    required this.eventId,
  });

  @override
  State<BookPointsScreen> createState() => _BookPointsScreenState();
}

class _BookPointsScreenState extends State<BookPointsScreen> {
  int? _selectedAmount;
  final _customController = TextEditingController();
  String _reason = 'manual';
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _customController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? get _amount {
    if (_selectedAmount != null) return _selectedAmount;
    final text = _customController.text;
    if (text.isNotEmpty) return int.tryParse(text);
    return null;
  }

  Future<void> _book() async {
    final amount = _amount;
    if (amount == null || amount == 0) return;

    setState(() => _loading = true);

    final body = {
      'participantId': widget.participant.id,
      'eventId': widget.eventId,
      'amount': amount,
      'reason': _reason,
      'note': _noteController.text.isEmpty ? null : _noteController.text,
    };

    try {
      final result =
          await ApiClient().post<Map<String, dynamic>>('/api/points', data: body);
      if (!mounted) return;
      final balance = result['balance'] as int;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${amount > 0 ? '+' : ''}$amount Punkte gebucht. Stand: $balance',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      await OfflineQueue().enqueue('POST', '/api/points', data: body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Offline gespeichert — wird synchronisiert'),
          backgroundColor: AppTheme.warning,
        ),
      );
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Punkte buchen')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.brand.withAlpha(30),
                    child: Text(
                      widget.participant.displayName[0].toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brand,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.participant.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${widget.participant.balance} Punkte',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Schnellwahl',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.quickSelectValues
                .map((v) => _quickButton(v))
                .toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Oder manuell eingeben',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customController,
            keyboardType:
                const TextInputType.numberWithOptions(signed: true),
            decoration: const InputDecoration(
              hintText: 'Anzahl (negativ = Abzug)',
              prefixIcon: Icon(Icons.edit),
            ),
            onChanged: (_) {
              setState(() => _selectedAmount = null);
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Grund',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _reason,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'manual', child: Text('Manuell')),
              DropdownMenuItem(
                  value: 'quick_select', child: Text('Schnellwahl')),
              DropdownMenuItem(value: 'quest', child: Text('Quest')),
              DropdownMenuItem(value: 'badge', child: Text('Badge')),
            ],
            onChanged: (v) => setState(() => _reason = v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText: 'Notiz (optional)',
              prefixIcon: Icon(Icons.note_outlined),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading || _amount == null ? null : _book,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _amount != null
                          ? '${_amount! > 0 ? '+' : ''}${_amount!} Punkte buchen'
                          : 'Punkte buchen',
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickButton(int value) {
    final selected = _selectedAmount == value;
    return SizedBox(
      width: 72,
      height: 52,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _selectedAmount = value;
            _customController.clear();
            _reason = 'quick_select';
          });
          HapticFeedback.selectionClick();
        },
        style: OutlinedButton.styleFrom(
          backgroundColor:
              selected ? AppTheme.brand.withAlpha(25) : null,
          side: BorderSide(
            color: selected ? AppTheme.brand : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          '+$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: selected ? AppTheme.brand : null,
          ),
        ),
      ),
    );
  }
}

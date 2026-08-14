import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/participant.dart';
import '../services/api_client.dart';
import '../services/demo_service.dart';
import '../services/offline_queue.dart';
import '../providers/connectivity_provider.dart';
import '../providers/demo_provider.dart';

class BookPointsScreen extends ConsumerStatefulWidget {
  final Participant participant;
  final String eventId;

  const BookPointsScreen({
    super.key,
    required this.participant,
    required this.eventId,
  });

  @override
  ConsumerState<BookPointsScreen> createState() => _BookPointsScreenState();
}

class _BookPointsScreenState extends ConsumerState<BookPointsScreen> {
  int? _selectedAmount;
  final _customController = TextEditingController();
  String _reason = 'manual';
  final _noteController = TextEditingController();
  bool _loading = false;
  bool _showSuccess = false;
  int? _resultBalance;

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
    final isDemo = ref.read(demoModeProvider);

    try {
      int balance;
      if (isDemo) {
        final result = await DemoService().bookPoints(
          participantId: widget.participant.id,
          eventId: widget.eventId,
          amount: amount,
          reason: _reason,
          note: _noteController.text.isEmpty ? null : _noteController.text,
        );
        balance = result['balance'] as int;
      } else {
        final body = {
          'participantId': widget.participant.id,
          'eventId': widget.eventId,
          'amount': amount,
          'reason': _reason,
          'note': _noteController.text.isEmpty ? null : _noteController.text,
        };
        try {
          final result = await ApiClient()
              .post<Map<String, dynamic>>('/api/points', data: body);
          balance = result['balance'] as int;
        } catch (e) {
          await OfflineQueue().enqueue('POST', '/api/points', data: body);
          ref.read(connectivityProvider.notifier).refreshPendingCount();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Offline gespeichert — wird synchronisiert'),
              backgroundColor: AppTheme.warning,
            ),
          );
          Navigator.pop(context, true);
          return;
        }
      }

      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _showSuccess = true;
        _resultBalance = balance;
        _loading = false;
      });

      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 80, color: AppTheme.success)
                  .animate()
                  .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1, 1),
                      duration: 400.ms,
                      curve: Curves.elasticOut),
              const SizedBox(height: 16),
              Text(
                '${_amount! > 0 ? '+' : ''}${_amount!} Punkte',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _amount! > 0 ? AppTheme.success : AppTheme.danger,
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
              const SizedBox(height: 8),
              Text(
                'Neuer Stand: $_resultBalance P',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 350.ms),
            ],
          ),
        ),
      );
    }

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
            'Punkte vergeben',
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
                .map((v) => _quickButton(v, positive: true))
                .toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Punkte abziehen',
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
                .map((v) => _quickButton(-v, positive: false))
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
              DropdownMenuItem(value: 'penalty', child: Text('Strafe')),
              DropdownMenuItem(value: 'correction', child: Text('Korrektur')),
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
              style: _amount != null && _amount! < 0
                  ? ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                    )
                  : null,
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

  Widget _quickButton(int value, {required bool positive}) {
    final selected = _selectedAmount == value;
    final color = positive ? AppTheme.brand : AppTheme.danger;
    return SizedBox(
      width: 72,
      height: 52,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _selectedAmount = value;
            _customController.clear();
            _reason = positive ? 'quick_select' : 'penalty';
          });
          HapticFeedback.selectionClick();
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? color.withAlpha(25) : null,
          side: BorderSide(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          '${positive ? '+' : ''}$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: selected ? color : null,
          ),
        ),
      ),
    );
  }
}

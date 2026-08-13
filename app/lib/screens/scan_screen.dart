import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/event_provider.dart';
import '../providers/participant_provider.dart';
import '../providers/demo_provider.dart';
import '../services/nfc_service.dart';
import '../services/demo_service.dart';
import '../models/participant.dart';
import 'participant_profile_screen.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with SingleTickerProviderStateMixin {
  bool _scanning = false;
  String? _error;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    NfcService().stopScan();
    super.dispose();
  }

  void _openProfile(Participant participant) {
    ref.read(scannedParticipantProvider.notifier).state = participant;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParticipantProfileScreen(participant: participant),
      ),
    );
  }

  void _startScan() {
    final event = ref.read(selectedEventProvider);
    if (event == null) return;

    setState(() {
      _scanning = true;
      _error = null;
    });
    _pulseController.repeat();

    Participant? demoLookup(String tagUid) {
      if (!ref.read(demoModeProvider)) return null;
      return DemoService().getParticipantByTag(tagUid);
    }

    NfcService().startScan(
      eventId: event.id,
      localLookup: demoLookup,
      onSuccess: (participant) {
        if (!mounted) return;
        setState(() => _scanning = false);
        _pulseController.stop();
        _pulseController.reset();
        _openProfile(participant);
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _scanning = false;
          _error = error;
        });
        _pulseController.stop();
        _pulseController.reset();
      },
    );
  }

  void _showDemoParticipantPicker() {
    final event = ref.read(selectedEventProvider);
    if (event == null) return;

    final participants = DemoService().getParticipants(event.id);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Teilnehmer simulieren',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Wähle einen Teilnehmer (simuliert NFC-Scan)',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: participants.length,
                itemBuilder: (_, i) {
                  final p = participants[i];
                  return ListTile(
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
                    subtitle: Text(
                      '${p.group ?? "—"} · ${p.balance} P',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openProfile(p);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = ref.watch(demoModeProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = _scanning
                    ? 1.0 + (_pulseController.value * 0.15)
                    : 1.0;
                final opacity = _scanning
                    ? 0.5 + (_pulseController.value * 0.5)
                    : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Opacity(opacity: opacity, child: child),
                );
              },
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _scanning
                      ? AppTheme.brand.withAlpha(30)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  Icons.nfc_rounded,
                  size: 80,
                  color: _scanning
                      ? AppTheme.brand
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _scanning ? 'Armband scannen...' : 'Bereit zum Scannen',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _scanning
                  ? 'Halte das NFC-Armband an die Rückseite des Geräts'
                  : isDemo
                      ? 'Scanne ein NFC-Armband oder wähle einen Teilnehmer'
                      : 'Tippe auf den Button um ein Armband zu scannen',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        color: AppTheme.danger, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _error!,
                        style:
                            TextStyle(color: AppTheme.danger, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _scanning ? null : _startScan,
                icon: Icon(_scanning ? Icons.hourglass_top : Icons.nfc),
                label: Text(_scanning ? 'Scanne...' : 'Scannen'),
              ),
            ),
            if (isDemo) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _showDemoParticipantPicker,
                  icon: const Icon(Icons.person_search, size: 20),
                  label: const Text('Teilnehmer wählen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.violet,
                    side: BorderSide(color: AppTheme.violet.withAlpha(120)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

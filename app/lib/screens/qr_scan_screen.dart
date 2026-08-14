import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../config/theme.dart';
import '../models/participant.dart';
import '../providers/demo_provider.dart';
import '../providers/event_provider.dart';
import '../providers/participant_provider.dart';
import '../services/demo_service.dart';
import 'participant_profile_screen.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  MobileScannerController? _controller;
  bool _scanned = false;
  String? _error;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final codes = capture.barcodes;
    if (codes.isEmpty) return;

    final code = codes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _scanned = true);
    _controller?.stop();

    _resolveParticipant(code);
  }

  void _resolveParticipant(String code) {
    final event = ref.read(selectedEventProvider);
    if (event == null) {
      _showError('Kein Event ausgewählt');
      return;
    }

    final isDemo = ref.read(demoModeProvider);

    if (isDemo) {
      final participant = DemoService().getParticipant(code);
      if (participant != null) {
        _openProfile(participant);
        return;
      }
      final participants = DemoService().getParticipants(event.id);
      final byName = participants.where(
        (p) => p.displayName.toLowerCase() == code.toLowerCase(),
      );
      if (byName.isNotEmpty) {
        _openProfile(byName.first);
        return;
      }
    }

    _showError('Teilnehmer nicht gefunden: $code');
  }

  void _openProfile(Participant participant) {
    ref.read(scannedParticipantProvider.notifier).state = participant;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ParticipantProfileScreen(participant: participant),
      ),
    );
  }

  void _showError(String msg) {
    setState(() => _error = msg);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _scanned = false;
        _error = null;
      });
      _controller?.start();
    });
  }

  void _toggleTorch() {
    _controller?.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  void _switchCamera() {
    _controller?.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = ref.watch(demoModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR-Code scannen'),
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null)
            MobileScanner(
              controller: _controller!,
              onDetect: _onDetect,
            ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _scanned
                      ? (_error != null ? AppTheme.danger : AppTheme.success)
                      : Colors.white.withAlpha(180),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(180),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withAlpha(200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    _scanned
                        ? 'Verarbeite...'
                        : 'Richte die Kamera auf einen QR-Code',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  if (isDemo) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _showDemoParticipantPicker,
                      icon: const Icon(Icons.person_search,
                          size: 18, color: Colors.white),
                      label: const Text('Demo: Teilnehmer wählen',
                          style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
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
                'Wähle einen Teilnehmer (simuliert QR-Scan)',
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
}

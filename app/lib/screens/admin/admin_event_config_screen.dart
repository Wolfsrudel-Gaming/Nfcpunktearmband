import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/demo_service.dart';

class AdminEventConfigScreen extends StatelessWidget {
  final String eventId;

  const AdminEventConfigScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final event = DemoService().getEvent(eventId);
    if (event == null) {
      return const Center(child: Text('Event nicht gefunden'));
    }

    final participants = DemoService().getParticipants(eventId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Event-Konfiguration',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _configCard(context, [
          _configRow(context, 'Name', event.name, Icons.event),
          _configRow(context, 'Status', event.status.toUpperCase(), Icons.circle,
              valueColor: event.status == 'active'
                  ? AppTheme.success
                  : AppTheme.danger),
          _configRow(context, 'Ort', event.location ?? '—', Icons.location_on),
          _configRow(context, 'Beginn', event.startDate ?? '—',
              Icons.calendar_today),
          _configRow(
              context, 'Ende', event.endDate ?? '—', Icons.calendar_today),
          _configRow(context, 'Join-Code', event.joinCode, Icons.qr_code),
        ]),
        const SizedBox(height: 16),
        Text(
          'Punkte-System',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _configCard(context, [
          _configRow(
              context,
              'Schnellwahl',
              event.quickSelectValues.join(', '),
              Icons.touch_app),
          _configRow(
              context,
              'P2P erlaubt',
              event.config?['allowP2P'] == true ? 'Ja' : 'Nein',
              Icons.swap_horiz),
        ]),
        const SizedBox(height: 16),
        Text(
          'Statistik',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _configCard(context, [
          _configRow(context, 'Teilnehmer', '${participants.length}',
              Icons.people),
          _configRow(
              context,
              'NFC zugewiesen',
              '${participants.where((p) => p.nfcTagUid != null).length}',
              Icons.nfc),
          _configRow(
              context,
              'Gruppen',
              '${participants.map((p) => p.group).toSet().where((g) => g != null).length}',
              Icons.groups),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.violet.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.violet.withAlpha(30)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppTheme.violet),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Im Demo-Modus können Events nur eingeschränkt konfiguriert werden. Volle Konfiguration im Live-Modus über das Web-Dashboard.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.violet,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _configCard(BuildContext context, List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: rows),
      ),
    );
  }

  Widget _configRow(
      BuildContext context, String label, String value, IconData icon,
      {Color? valueColor}) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: AppTheme.violet),
      title: Text(label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          )),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: valueColor,
        ),
      ),
    );
  }
}

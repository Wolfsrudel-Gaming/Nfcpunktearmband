import 'package:flutter/material.dart';
import '../../config/theme.dart';

class ElternContactScreen extends StatelessWidget {
  final String eventName;

  const ElternContactScreen({super.key, required this.eventName});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.success.withAlpha(15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.success.withAlpha(40)),
          ),
          child: Column(
            children: [
              Icon(Icons.verified_user,
                  size: 40, color: AppTheme.success),
              const SizedBox(height: 12),
              Text(
                eventName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ihr Kind nimmt an diesem Event teil',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Kontaktmöglichkeiten',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _contactCard(
          context,
          icon: Icons.phone,
          title: 'Notfall-Telefon',
          subtitle: 'Betreuer-Team erreichen',
          detail: '+49 170 1234567',
          color: AppTheme.danger,
        ),
        _contactCard(
          context,
          icon: Icons.mail_outline,
          title: 'E-Mail',
          subtitle: 'Allgemeine Anfragen',
          detail: 'betreuer@camp-demo.de',
          color: AppTheme.brand,
        ),
        _contactCard(
          context,
          icon: Icons.schedule,
          title: 'Sprechzeiten',
          subtitle: 'Für Eltern-Gespräche',
          detail: 'Mo-Fr 18:00-19:00 Uhr',
          color: AppTheme.violet,
        ),
        const SizedBox(height: 24),
        Text(
          'Hinweise',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        _infoTile(
          context,
          Icons.info_outline,
          'Demo-Modus',
          'In der Demo werden Kontaktdaten simuliert. Im Live-Betrieb werden hier die echten Kontaktdaten des Betreuer-Teams angezeigt.',
        ),
        _infoTile(
          context,
          Icons.notifications_outlined,
          'Benachrichtigungen',
          'Im Live-Betrieb erhalten Sie Push-Benachrichtigungen bei wichtigen Ereignissen.',
        ),
        _infoTile(
          context,
          Icons.shield_outlined,
          'Datenschutz',
          'Alle Daten werden verschlüsselt übertragen. Nur autorisierte Betreuer haben Zugriff.',
        ),
      ],
    );
  }

  Widget _contactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String detail,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(20),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              detail,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(
      BuildContext context, IconData icon, String title, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

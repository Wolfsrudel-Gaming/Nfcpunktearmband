import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/participant.dart';
import '../../services/demo_service.dart';

class AdminParticipantsScreen extends StatefulWidget {
  final String eventId;

  const AdminParticipantsScreen({super.key, required this.eventId});

  @override
  State<AdminParticipantsScreen> createState() =>
      _AdminParticipantsScreenState();
}

class _AdminParticipantsScreenState extends State<AdminParticipantsScreen> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    var participants = DemoService().getParticipants(widget.eventId);
    if (_filter.isNotEmpty) {
      final lower = _filter.toLowerCase();
      participants = participants
          .where((p) =>
              p.displayName.toLowerCase().contains(lower) ||
              (p.group?.toLowerCase().contains(lower) ?? false))
          .toList();
    }
    participants.sort((a, b) => a.displayName.compareTo(b.displayName));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Suchen...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Neu'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${participants.length} Teilnehmer',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: participants.length,
            itemBuilder: (context, i) {
              final p = participants[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.violet.withAlpha(30),
                    child: Text(
                      p.displayName[0].toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.violet,
                      ),
                    ),
                  ),
                  title: Text(p.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Row(
                    children: [
                      if (p.group != null) ...[
                        Text(p.group!,
                            style: const TextStyle(fontSize: 12)),
                        const Text(' · ',
                            style: TextStyle(fontSize: 12)),
                      ],
                      Text('${p.balance} P',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.brand)),
                      if (p.nfcTagUid != null) ...[
                        const Text(' · ',
                            style: TextStyle(fontSize: 12)),
                        Icon(Icons.nfc, size: 12,
                            color: AppTheme.success),
                      ],
                    ],
                  ),
                  trailing: Text(
                    '${p.age ?? "?"} J.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    String? group;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Teilnehmer hinzufügen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Alter',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Gruppe',
                border: OutlineInputBorder(),
              ),
              items: ['Adler', 'Bären', 'Delfine']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => group = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await DemoService().registerParticipant(
                eventId: widget.eventId,
                displayName: nameCtrl.text.trim(),
                firstName: nameCtrl.text.trim(),
                age: int.tryParse(ageCtrl.text),
                group: group,
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/demo_provider.dart';

class RoleSwitcher extends ConsumerWidget {
  const RoleSwitcher({super.key});

  static const _roleInfo = {
    DemoRole.admin: ('Admin', Icons.admin_panel_settings, Color(0xFFEF4444)),
    DemoRole.betreuer: ('Betreuer', Icons.supervisor_account, Color(0xFFFF6B35)),
    DemoRole.teilnehmer: ('Teilnehmer', Icons.person, Color(0xFF7C3AED)),
    DemoRole.eltern: ('Eltern', Icons.family_restroom, Color(0xFF10B981)),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(demoRoleProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined,
                  size: 14, color: AppTheme.violet),
              const SizedBox(width: 6),
              Text(
                'Demo — Rolle wechseln:',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: DemoRole.values.map((role) {
              final (label, icon, color) = _roleInfo[role]!;
              final active = currentRole == role;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _RoleChip(
                    label: label,
                    icon: icon,
                    color: color,
                    active: active,
                    onTap: () {
                      ref.read(demoRoleProvider.notifier).state = role;
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color : Colors.transparent,
            width: active ? 1.5 : 0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: active ? color : Colors.grey),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

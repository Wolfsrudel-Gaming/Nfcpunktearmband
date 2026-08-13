import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DemoRole { admin, betreuer, teilnehmer, eltern }

final demoModeProvider = StateProvider<bool>((ref) => false);

final demoRoleProvider = StateProvider<DemoRole>((ref) => DemoRole.betreuer);

final demoActiveParticipantIdProvider = StateProvider<String?>((ref) => null);

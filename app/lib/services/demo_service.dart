import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import '../models/event.dart';
import '../models/participant.dart';
import '../models/reward.dart';
import '../models/point_transaction.dart';
import '../models/user.dart';

class DemoService {
  static final DemoService _instance = DemoService._();
  factory DemoService() => _instance;
  DemoService._();

  static const _uuid = Uuid();
  static const _storageKey = 'demo_data';

  bool _initialized = false;
  late _DemoState _state;

  bool get isInitialized => _initialized;

  final Map<String, String> _nfcTagMap = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      _state = _DemoState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } else {
      _state = _createSeedData();
      await _persist();
    }
    for (final p in _state.participants) {
      if (p['nfcTagUid'] != null) {
        _nfcTagMap[p['nfcTagUid'] as String] = p['id'] as String;
      }
    }
    _initialized = true;
  }

  Future<void> reset() async {
    _state = _createSeedData();
    _nfcTagMap.clear();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_state.toJson()));
  }

  // Auth
  User login() => User(
        id: 'demo-admin',
        name: 'Demo Betreuer',
        email: 'demo@questband.app',
        role: 'admin',
        active: true,
      );

  // Events
  List<Event> getEvents() => _state.events
      .map((e) => Event.fromJson(e))
      .toList();

  Event? getEvent(String id) {
    final e = _state.events.where((e) => e['id'] == id).firstOrNull;
    return e != null ? Event.fromJson(e) : null;
  }

  // Participants
  List<Participant> getParticipants(String eventId) => _state.participants
      .where((p) => p['eventId'] == eventId)
      .map((p) => Participant.fromJson(p))
      .toList();

  Participant? getParticipant(String id) {
    final p = _state.participants.where((p) => p['id'] == id).firstOrNull;
    return p != null ? Participant.fromJson(p) : null;
  }

  Participant? getParticipantByTag(String tagUid) {
    final pid = _nfcTagMap[tagUid];
    if (pid == null) return null;
    return getParticipant(pid);
  }

  Future<Participant> registerParticipant({
    required String eventId,
    required String displayName,
    String? firstName,
    String? lastName,
    int? age,
    String? group,
  }) async {
    final data = <String, dynamic>{
      'id': _uuid.v4(),
      'eventId': eventId,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'group': group,
      'balance': 0,
      'active': true,
      'nfcTagUid': null,
    };
    _state.participants.add(data);
    await _persist();
    return Participant.fromJson(data);
  }

  Future<void> assignNfcTag(String participantId, String tagUid) async {
    final idx = _state.participants
        .indexWhere((p) => p['id'] == participantId);
    if (idx < 0) throw Exception('Teilnehmer nicht gefunden');
    _state.participants[idx]['nfcTagUid'] = tagUid;
    _state.participants[idx]['nfcTag'] = {'tagUid': tagUid};
    _nfcTagMap[tagUid] = participantId;
    await _persist();
  }

  // Points
  Future<Map<String, dynamic>> bookPoints({
    required String participantId,
    required String eventId,
    required int amount,
    String reason = 'manual',
    String? note,
  }) async {
    final idx = _state.participants
        .indexWhere((p) => p['id'] == participantId);
    if (idx < 0) throw Exception('Teilnehmer nicht gefunden');

    final oldBalance = _state.participants[idx]['balance'] as int;
    final newBalance = oldBalance + amount;
    _state.participants[idx]['balance'] = newBalance;

    final sig = sha256
        .convert(utf8.encode('$participantId:$amount:$newBalance:$reason'))
        .toString()
        .substring(0, 16);

    final tx = <String, dynamic>{
      'id': _uuid.v4(),
      'participantId': participantId,
      'eventId': eventId,
      'amount': amount,
      'balanceAfter': newBalance,
      'reason': reason,
      'note': note,
      'signature': sig,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _state.transactions.add(tx);
    await _persist();

    return {'transaction': tx, 'balance': newBalance};
  }

  List<PointTransaction> getTransactions(String participantId) => _state
      .transactions
      .where((t) => t['participantId'] == participantId)
      .map((t) => PointTransaction.fromJson(t))
      .toList()
      .reversed
      .toList();

  List<PointTransaction> getEventTransactions(String eventId) => _state
      .transactions
      .where((t) => t['eventId'] == eventId)
      .map((t) => PointTransaction.fromJson(t))
      .toList()
      .reversed
      .toList();

  List<Participant> getLeaderboard(String eventId) {
    final list = getParticipants(eventId);
    list.sort((a, b) => b.balance.compareTo(a.balance));
    return list;
  }

  // Rewards
  List<Reward> getRewards(String eventId) => _state.rewards
      .where((r) => r['eventId'] == eventId)
      .map((r) => Reward.fromJson(r))
      .toList();

  Future<Map<String, dynamic>> redeemReward({
    required String rewardId,
    required String participantId,
    required String eventId,
  }) async {
    final rIdx = _state.rewards.indexWhere((r) => r['id'] == rewardId);
    if (rIdx < 0) throw Exception('Prämie nicht gefunden');
    final reward = _state.rewards[rIdx];

    final pIdx = _state.participants
        .indexWhere((p) => p['id'] == participantId);
    if (pIdx < 0) throw Exception('Teilnehmer nicht gefunden');

    final cost = reward['cost'] as int;
    final balance = _state.participants[pIdx]['balance'] as int;
    if (balance < cost) throw Exception('Nicht genug Punkte');

    final stock = reward['stock'] as int?;
    final redeemed = reward['redeemed'] as int;
    if (stock != null && redeemed >= stock) throw Exception('Ausverkauft');

    _state.rewards[rIdx]['redeemed'] = redeemed + 1;

    final result = await bookPoints(
      participantId: participantId,
      eventId: eventId,
      amount: -cost,
      reason: 'redemption',
      note: reward['name'] as String,
    );

    await _persist();
    return result;
  }

  // Seed data
  _DemoState _createSeedData() {
    final eventId = _uuid.v4();
    final groups = ['Adler', 'Bären', 'Delfine'];
    final names = [
      ('Luna', 'Adler', 12),
      ('Max', 'Adler', 11),
      ('Mia', 'Adler', 13),
      ('Leon', 'Adler', 12),
      ('Emma', 'Bären', 11),
      ('Noah', 'Bären', 14),
      ('Sophia', 'Bären', 12),
      ('Finn', 'Bären', 13),
      ('Lina', 'Delfine', 11),
      ('Paul', 'Delfine', 12),
      ('Hannah', 'Delfine', 13),
      ('Ben', 'Delfine', 14),
      ('Ella', 'Delfine', 11),
      ('Tim', 'Adler', 13),
      ('Marie', 'Bären', 12),
    ];

    final participants = <Map<String, dynamic>>[];
    final transactions = <Map<String, dynamic>>[];

    for (final (name, group, age) in names) {
      final pid = _uuid.v4();
      final startBalance = (age * 2) + (group.hashCode % 10).abs();
      participants.add({
        'id': pid,
        'eventId': eventId,
        'displayName': name,
        'firstName': name,
        'lastName': 'Demo',
        'age': age,
        'group': group,
        'balance': startBalance,
        'active': true,
        'nfcTagUid': null,
      });
      transactions.add({
        'id': _uuid.v4(),
        'participantId': pid,
        'eventId': eventId,
        'amount': startBalance,
        'balanceAfter': startBalance,
        'reason': 'manual',
        'note': 'Startpunkte',
        'createdAt': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
      });
    }

    final rewards = [
      {
        'id': _uuid.v4(),
        'eventId': eventId,
        'name': 'Extra Dessert',
        'description': 'Wähle ein zusätzliches Dessert beim Abendessen',
        'cost': 15,
        'stock': 10,
        'redeemed': 0,
        'category': 'Essen',
        'available': true,
      },
      {
        'id': _uuid.v4(),
        'eventId': eventId,
        'name': 'Freie Aktivität',
        'description': '30 Min freie Aktivitätswahl',
        'cost': 25,
        'stock': null,
        'redeemed': 0,
        'category': 'Privilegien',
        'available': true,
      },
      {
        'id': _uuid.v4(),
        'eventId': eventId,
        'name': 'Lagerfeuer-DJ',
        'description': 'Wähle 3 Songs für das Lagerfeuer',
        'cost': 30,
        'stock': 3,
        'redeemed': 0,
        'category': 'Erlebnisse',
        'available': true,
      },
      {
        'id': _uuid.v4(),
        'eventId': eventId,
        'name': 'Team-Captain',
        'description': 'Werde Captain für die nächste Team-Challenge',
        'cost': 40,
        'stock': 3,
        'redeemed': 0,
        'category': 'Privilegien',
        'available': true,
      },
      {
        'id': _uuid.v4(),
        'eventId': eventId,
        'name': 'Mystery-Box',
        'description': 'Überraschungspreis!',
        'cost': 50,
        'stock': 5,
        'redeemed': 0,
        'category': 'Spezial',
        'available': true,
      },
    ];

    final events = [
      {
        'id': eventId,
        'name': 'Sommercamp 2026',
        'description': 'Demo-Event für QuestBand',
        'status': 'active',
        'startDate': '2026-08-01',
        'endDate': '2026-08-14',
        'location': 'Schwarzwald',
        'joinCode': 'DEMO42',
        'config': {
          'quickSelectValues': [1, 2, 5, 10],
          'allowP2P': false,
        },
        'participantCount': participants.length,
      },
    ];

    return _DemoState(
      events: events,
      participants: participants,
      rewards: rewards,
      transactions: transactions,
    );
  }
}

class _DemoState {
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> participants;
  final List<Map<String, dynamic>> rewards;
  final List<Map<String, dynamic>> transactions;

  _DemoState({
    required this.events,
    required this.participants,
    required this.rewards,
    required this.transactions,
  });

  Map<String, dynamic> toJson() => {
        'events': events,
        'participants': participants,
        'rewards': rewards,
        'transactions': transactions,
      };

  factory _DemoState.fromJson(Map<String, dynamic> json) => _DemoState(
        events: (json['events'] as List).cast<Map<String, dynamic>>(),
        participants:
            (json['participants'] as List).cast<Map<String, dynamic>>(),
        rewards: (json['rewards'] as List).cast<Map<String, dynamic>>(),
        transactions:
            (json['transactions'] as List).cast<Map<String, dynamic>>(),
      );
}

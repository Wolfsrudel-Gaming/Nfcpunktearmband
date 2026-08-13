import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/constants.dart';
import 'api_client.dart';

class QueuedAction {
  final String id;
  final String method;
  final String path;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  QueuedAction({
    required this.id,
    required this.method,
    required this.path,
    this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'path': path,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QueuedAction.fromJson(Map<String, dynamic> json) => QueuedAction(
        id: json['id'] as String,
        method: json['method'] as String,
        path: json['path'] as String,
        data: json['data'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class OfflineQueue {
  static final OfflineQueue _instance = OfflineQueue._();
  factory OfflineQueue() => _instance;
  OfflineQueue._();

  static const _storageKey = 'offline_queue';
  final List<QueuedAction> _queue = [];
  bool _processing = false;

  List<QueuedAction> get pending => List.unmodifiable(_queue);
  int get length => _queue.length;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    _queue.clear();
    for (final item in raw) {
      _queue.add(QueuedAction.fromJson(jsonDecode(item)));
    }
    _listenConnectivity();
  }

  void _listenConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) processQueue();
    });
  }

  Future<void> enqueue(String method, String path,
      {Map<String, dynamic>? data}) async {
    if (_queue.length >= AppConstants.maxOfflineQueueSize) return;
    _queue.add(QueuedAction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      method: method,
      path: path,
      data: data,
      createdAt: DateTime.now(),
    ));
    await _persist();
  }

  Future<void> processQueue() async {
    if (_processing || _queue.isEmpty) return;
    _processing = true;

    final api = ApiClient();
    final toRemove = <QueuedAction>[];

    for (final action in List.of(_queue)) {
      try {
        switch (action.method) {
          case 'POST':
            await api.post(action.path, data: action.data);
          case 'PATCH':
            await api.patch(action.path, data: action.data);
          case 'DELETE':
            await api.delete(action.path);
        }
        toRemove.add(action);
      } catch (_) {
        break;
      }
    }

    _queue.removeWhere(toRemove.contains);
    await _persist();
    _processing = false;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _queue.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }
}

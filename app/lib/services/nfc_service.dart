import 'dart:convert';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'api_client.dart';
import '../models/participant.dart';

class NfcTagData {
  final String participantId;
  final String eventId;
  final String serverToken;
  final String? displayName;

  const NfcTagData({
    required this.participantId,
    required this.eventId,
    required this.serverToken,
    this.displayName,
  });

  Map<String, dynamic> toJson() => {
        'pid': participantId,
        'eid': eventId,
        'tok': serverToken,
        if (displayName != null) 'name': displayName,
      };

  factory NfcTagData.fromJson(Map<String, dynamic> json) => NfcTagData(
        participantId: json['pid'] as String,
        eventId: json['eid'] as String,
        serverToken: json['tok'] as String,
        displayName: json['name'] as String?,
      );
}

class NfcService {
  static final NfcService _instance = NfcService._();
  factory NfcService() => _instance;
  NfcService._();

  Future<bool> get isAvailable => NfcManager.instance.isAvailable();

  String _extractUid(NfcTag tag) {
    final nfca = NfcA.from(tag);
    if (nfca != null) {
      return nfca.identifier
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(':');
    }
    final nfcb = NfcB.from(tag);
    if (nfcb != null) {
      return nfcb.identifier
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(':');
    }
    final isoDep = IsoDep.from(tag);
    if (isoDep != null) {
      return isoDep.identifier
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(':');
    }
    throw Exception('Tag-UID nicht lesbar');
  }

  Future<void> startScan({
    required String eventId,
    required void Function(Participant participant) onSuccess,
    required void Function(String error) onError,
    Participant? Function(String tagUid)? localLookup,
  }) async {
    final available = await isAvailable;
    if (!available) {
      onError('NFC nicht verfügbar');
      return;
    }

    NfcManager.instance.startSession(
      alertMessage: 'Armband an das Gerät halten',
      onDiscovered: (NfcTag tag) async {
        try {
          final tagUid = _extractUid(tag);

          if (localLookup != null) {
            final p = localLookup(tagUid);
            if (p != null) {
              onSuccess(p);
              NfcManager.instance.stopSession();
              return;
            }
          }

          final ndef = Ndef.from(tag);
          if (ndef != null && ndef.cachedMessage != null) {
            for (final record in ndef.cachedMessage!.records) {
              if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
                final payload = String.fromCharCodes(record.payload.skip(1));
                if (payload.startsWith('questband:')) {
                  try {
                    final jsonStr = payload.substring('questband:'.length);
                    final data = NfcTagData.fromJson(
                        jsonDecode(jsonStr) as Map<String, dynamic>);
                    if (localLookup != null) {
                      final p = localLookup(tagUid);
                      if (p != null) {
                        onSuccess(p);
                        NfcManager.instance.stopSession();
                        return;
                      }
                    }
                  } catch (_) {}
                }
              }
            }
          }

          final api = ApiClient();
          final responseData = await api.get<Map<String, dynamic>>(
            '/api/participants/tag/$tagUid',
          );
          final participant = Participant.fromJson(responseData);
          onSuccess(participant);
        } catch (e) {
          onError(e.toString().contains('404')
              ? 'Armband nicht registriert'
              : 'Fehler: $e');
        }
        NfcManager.instance.stopSession();
      },
      onError: (error) async {
        onError(error.message);
        NfcManager.instance.stopSession();
      },
    );
  }

  Future<void> writeTag({
    required String participantId,
    required String eventId,
    required String displayName,
    required void Function(String tagUid) onSuccess,
    required void Function(String error) onError,
  }) async {
    final available = await isAvailable;
    if (!available) {
      onError('NFC nicht verfügbar');
      return;
    }

    final serverToken = sha256
        .convert(utf8.encode('${const Uuid().v4()}:$participantId:$eventId'))
        .toString()
        .substring(0, 32);

    final tagData = NfcTagData(
      participantId: participantId,
      eventId: eventId,
      serverToken: serverToken,
      displayName: displayName,
    );

    final payload = 'questband:${jsonEncode(tagData.toJson())}';

    NfcManager.instance.startSession(
      alertMessage: 'Armband zum Beschreiben an das Gerät halten',
      onDiscovered: (NfcTag tag) async {
        try {
          final tagUid = _extractUid(tag);
          final ndef = Ndef.from(tag);

          if (ndef == null) {
            onError('Tag unterstützt kein NDEF');
            NfcManager.instance.stopSession();
            return;
          }

          if (!ndef.isWritable) {
            onError('Tag ist schreibgeschützt');
            NfcManager.instance.stopSession();
            return;
          }

          final record = NdefRecord.createUri(Uri.parse(payload));
          final message = NdefMessage([record]);

          final messageSize = message.byteLength;
          if (messageSize > (ndef.maxSize)) {
            onError('Daten zu gross für diesen Tag '
                '($messageSize/${ndef.maxSize} Bytes)');
            NfcManager.instance.stopSession();
            return;
          }

          await ndef.write(message);

          try {
            await ApiClient().post('/api/participants/$participantId/nfc',
                data: {
                  'tagUid': tagUid,
                  'serverToken': serverToken,
                  'eventId': eventId,
                });
          } catch (_) {}

          onSuccess(tagUid);
        } catch (e) {
          onError('Schreibfehler: $e');
        }
        NfcManager.instance.stopSession();
      },
      onError: (error) async {
        onError(error.message);
        NfcManager.instance.stopSession();
      },
    );
  }

  Future<NfcTagData?> readTagData() async {
    final available = await isAvailable;
    if (!available) return null;

    NfcTagData? result;
    NfcManager.instance.startSession(
      alertMessage: 'Tag zum Lesen an das Gerät halten',
      onDiscovered: (NfcTag tag) async {
        final ndef = Ndef.from(tag);
        if (ndef?.cachedMessage != null) {
          for (final record in ndef!.cachedMessage!.records) {
            final payload = String.fromCharCodes(record.payload.skip(1));
            if (payload.startsWith('questband:')) {
              try {
                final jsonStr = payload.substring('questband:'.length);
                result = NfcTagData.fromJson(
                    jsonDecode(jsonStr) as Map<String, dynamic>);
              } catch (_) {}
            }
          }
        }
        NfcManager.instance.stopSession();
      },
      onError: (error) async {
        NfcManager.instance.stopSession();
      },
    );
    return result;
  }

  void stopScan() {
    NfcManager.instance.stopSession();
  }
}

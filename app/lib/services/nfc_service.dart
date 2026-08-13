import 'package:nfc_manager/nfc_manager.dart';
import 'api_client.dart';
import '../models/participant.dart';

class NfcService {
  static final NfcService _instance = NfcService._();
  factory NfcService() => _instance;
  NfcService._();

  Future<bool> get isAvailable => NfcManager.instance.isAvailable();

  Future<void> startScan({
    required String eventId,
    required void Function(Participant participant) onSuccess,
    required void Function(String error) onError,
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
          final nfca = NfcA.from(tag);
          final nfcb = NfcB.from(tag);
          final isoDep = IsoDep.from(tag);

          String? tagUid;
          if (nfca != null) {
            tagUid = nfca.identifier
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join(':');
          } else if (nfcb != null) {
            tagUid = nfcb.identifier
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join(':');
          } else if (isoDep != null) {
            tagUid = isoDep.identifier
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join(':');
          }

          if (tagUid == null) {
            onError('Tag konnte nicht gelesen werden');
            NfcManager.instance.stopSession();
            return;
          }

          final api = ApiClient();
          final data = await api.get<Map<String, dynamic>>(
            '/api/participants/tag/$tagUid',
          );
          final participant = Participant.fromJson(data);
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

  void stopScan() {
    NfcManager.instance.stopSession();
  }
}

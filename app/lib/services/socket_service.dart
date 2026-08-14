import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/constants.dart';
import 'api_client.dart';

typedef PointsUpdateCallback = void Function(Map<String, dynamic> data);

class SocketService {
  static final SocketService _instance = SocketService._();
  factory SocketService() => _instance;
  SocketService._();

  io.Socket? _socket;
  final List<PointsUpdateCallback> _listeners = [];

  void connect() {
    final token = ApiClient().token;
    if (token == null) return;

    final baseUrl = ApiClient().baseUrl;
    final uri = Uri.parse(baseUrl);
    final socketUrl =
        '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    final socketPath = uri.path.isEmpty || uri.path == '/'
        ? '/socket.io'
        : '${uri.path}/socket.io';

    _socket?.disconnect();
    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath(socketPath)
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionDelay(
              AppConstants.socketReconnectDelay.inMilliseconds)
          .build(),
    );

    _socket!.on('points:update', (data) {
      if (data is Map<String, dynamic>) {
        for (final cb in _listeners) {
          cb(data);
        }
      }
    });

    _socket!.connect();
  }

  void joinEvent(String eventId) {
    _socket?.emit('join:event', eventId);
  }

  void leaveEvent(String eventId) {
    _socket?.emit('leave:event', eventId);
  }

  void onPointsUpdate(PointsUpdateCallback callback) {
    _listeners.add(callback);
  }

  void removePointsListener(PointsUpdateCallback callback) {
    _listeners.remove(callback);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _listeners.clear();
  }
}

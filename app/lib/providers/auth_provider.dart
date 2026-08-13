import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/demo_service.dart';
import '../services/socket_service.dart';
import 'demo_provider.dart';

final authProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    if (ref.read(demoModeProvider)) {
      final demo = DemoService();
      if (demo.isInitialized) return demo.login();
      return null;
    }
    final api = ApiClient();
    await api.init();
    if (!api.isAuthenticated) return null;
    return _decodeToken(api.token!);
  }

  Future<void> loginDemo() async {
    state = const AsyncLoading();
    ref.read(demoModeProvider.notifier).state = true;
    final demo = DemoService();
    await demo.init();
    state = AsyncData(demo.login());
  }

  Future<void> login(String email, String pin) async {
    state = const AsyncLoading();
    try {
      final api = ApiClient();
      final result = await api.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': email, 'pin': pin},
      );
      final token = result['token'] as String;
      await api.setToken(token);
      SocketService().connect();
      state = AsyncData(_decodeToken(token));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> logout() async {
    final isDemo = ref.read(demoModeProvider);
    if (isDemo) {
      ref.read(demoModeProvider.notifier).state = false;
    } else {
      SocketService().disconnect();
      await ApiClient().clearToken();
    }
    state = const AsyncData(null);
  }

  User? _decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final exp = data['exp'] as int?;
      if (exp != null &&
          DateTime.fromMillisecondsSinceEpoch(exp * 1000)
              .isBefore(DateTime.now())) {
        ApiClient().clearToken();
        return null;
      }
      return User(
        id: data['userId'] as String,
        name: data['name'] as String? ?? '',
        email: data['email'] as String?,
        role: data['role'] as String,
        active: true,
      );
    } catch (_) {
      return null;
    }
  }
}

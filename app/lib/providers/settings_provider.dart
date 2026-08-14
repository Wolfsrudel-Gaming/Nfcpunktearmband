import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class AppSettings {
  final String serverUrl;

  const AppSettings({required this.serverUrl});
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _keyServerUrl = 'settings_server_url';

  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      serverUrl:
          prefs.getString(_keyServerUrl) ?? AppConstants.apiBaseUrl,
    );
  }

  Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, url);
    state = AsyncData(AppSettings(serverUrl: url));
  }
}

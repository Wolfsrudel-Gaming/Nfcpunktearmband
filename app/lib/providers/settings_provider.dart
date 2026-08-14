import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../services/api_client.dart';

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
    final url =
        prefs.getString(_keyServerUrl) ?? AppConstants.apiBaseUrl;
    ApiClient().updateBaseUrl(url);
    return AppSettings(serverUrl: url);
  }

  Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, url);
    ApiClient().updateBaseUrl(url);
    state = AsyncData(AppSettings(serverUrl: url));
  }
}

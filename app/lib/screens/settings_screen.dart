import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/connectivity_provider.dart';
import '../providers/settings_provider.dart';
import '../services/offline_queue.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _packageInfo = info);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(context, 'Verbindung'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    connectivity.isOnline ? Icons.cloud_done : Icons.cloud_off,
                    color:
                        connectivity.isOnline ? AppTheme.success : AppTheme.danger,
                  ),
                  title: Text(
                      connectivity.isOnline ? 'Online' : 'Offline'),
                  subtitle: Text(connectivity.isOnline
                      ? 'Verbunden mit dem Server'
                      : 'Keine Internetverbindung'),
                ),
                if (connectivity.pendingActions > 0)
                  ListTile(
                    leading: Icon(Icons.sync, color: AppTheme.warning),
                    title: Text(
                        '${connectivity.pendingActions} ausstehende Aktionen'),
                    subtitle: const Text('Werden synchronisiert sobald online'),
                    trailing: connectivity.isOnline
                        ? IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () async {
                              await OfflineQueue().processQueue();
                              ref
                                  .read(connectivityProvider.notifier)
                                  .refreshPendingCount();
                            },
                          )
                        : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionHeader(context, 'Server'),
          Card(
            child: settings.when(
              data: (s) => ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: const Text('Server-URL'),
                subtitle: Text(s.serverUrl),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () => _editServerUrl(s.serverUrl),
              ),
              loading: () =>
                  const ListTile(title: Text('Lade Einstellungen...')),
              error: (_, __) =>
                  const ListTile(title: Text('Fehler beim Laden')),
            ),
          ),
          const SizedBox(height: 20),
          _sectionHeader(context, 'App-Info'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.nfc_rounded, color: AppTheme.brand),
                  title: const Text(AppConstants.appName),
                  subtitle: Text(_packageInfo != null
                      ? 'Version ${_packageInfo!.version} (${_packageInfo!.buildNumber})'
                      : 'Version wird geladen...'),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Paket'),
                  subtitle: Text(
                      _packageInfo?.packageName ?? 'app.questband.nfcpunktearmband'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionHeader(context, 'Offline-Warteschlange'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.queue),
                  title: const Text('Ausstehend'),
                  trailing: Text(
                    '${OfflineQueue().length}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('Max. Warteschlange'),
                  trailing: const Text(
                    '${AppConstants.maxOfflineQueueSize}',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  void _editServerUrl(String currentUrl) {
    final controller = TextEditingController(text: currentUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Server-URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'https://api.example.com',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  controller.text = AppConstants.apiBaseUrl;
                },
                child: const Text('Standard wiederherstellen'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                ref.read(settingsProvider.notifier).setServerUrl(url);
                HapticFeedback.lightImpact();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}

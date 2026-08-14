import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'providers/auth_provider.dart';
import 'services/offline_queue.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await OfflineQueue().init();
  runApp(const ProviderScope(child: QuestBandApp()));
}

class QuestBandApp extends ConsumerWidget {
  const QuestBandApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: authState.when(
        data: (user) => user != null
            ? const HomeScreen()
            : const LoginScreen(),
        loading: () => const _SplashScreen(),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brand.withAlpha(20),
              ),
              child: Icon(
                Icons.nfc_rounded,
                size: 56,
                color: AppTheme.brand,
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1500.ms, color: AppTheme.brand.withAlpha(40)),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn(duration: 600.ms),
            const SizedBox(height: 8),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.brand.withAlpha(120),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
          ],
        ),
      ),
    );
  }
}

// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'bloc/app_provider.dart';
import 'services/storage_service.dart';
import 'services/telegram_service.dart';
import 'screens/home_screen.dart';
import 'screens/pin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  final storage = StorageService();
  await storage.init();

  final provider = AppProvider(
    storage: storage,
    telegram: TelegramService(),
  );
  await provider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const SkladInventarApp(),
    ),
  );
}

class SkladInventarApp extends StatelessWidget {
  const SkladInventarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkladScan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.isPinEnabled && !provider.isAuthenticated) {
          return const PinScreen();
        }
        return const HomeScreen();
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/chat_provider.dart';
import 'providers/health_log_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/health_log_screen.dart';
import 'screens/home_shell.dart';
import 'screens/log_grooming_screen.dart';
import 'screens/log_medicine_screen.dart';
import 'screens/log_photo_screen.dart';
import 'screens/log_weight_screen.dart';
import 'services/storage_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();
  runApp(PawprintApp(storage: storage));
}

class PawprintApp extends StatelessWidget {
  final StorageService storage;
  const PawprintApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storage),
        ),
        ChangeNotifierProvider(
          create: (_) => PetProvider(storage),
        ),
        ChangeNotifierProvider(
          create: (_) => HealthLogProvider(storage),
        ),
        ChangeNotifierProvider(
          create: (_) => ReminderProvider(storage),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, ChatProvider>(
          create: (ctx) =>
              ChatProvider(storage, ctx.read<SettingsProvider>()),
          // Reuse the existing ChatProvider so chat history is preserved when
          // settings change. The provider reads the latest settings from the
          // passed-in SettingsProvider on every send.
          update: (_, __, previous) => previous!,
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'PawPrint',
            debugShowCheckedModeBanner: false,
            theme: PawprintTheme.light(),
            darkTheme: PawprintTheme.dark(),
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: '/',
            onGenerateRoute: _onGenerateRoute,
            home: const HomeShell(),
          );
        },
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/log/weight':
        return MaterialPageRoute(
            builder: (_) => const LogWeightScreen(), settings: settings);
      case '/log/medicine':
        return MaterialPageRoute(
            builder: (_) => const LogMedicineScreen(), settings: settings);
      case '/log/photo':
        return MaterialPageRoute(
            builder: (_) => const LogPhotoScreen(), settings: settings);
      case '/log/grooming':
        return MaterialPageRoute(
            builder: (_) => const LogGroomingScreen(), settings: settings);
      case '/history':
        return MaterialPageRoute(
            builder: (_) => const HealthLogScreen(), settings: settings);
      default:
        return null;
    }
  }
}

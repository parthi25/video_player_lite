import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'services/theme_service.dart';
import 'screens/next_player_main_screen.dart';
import 'screens/launch_screen.dart';
import 'screens/vault_auth_screen.dart';
import 'screens/vault_setup_screen.dart';
import 'screens/vault_screen.dart';
import 'screens/vault_forgot_screen.dart';
import 'screens/vault_security_setup_screen.dart';
import 'screens/file_browser_screen.dart';
import 'screens/next_file_browser_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const ProviderScope(child: NextPlayerApp()));
}

class NextPlayerApp extends ConsumerWidget {
  const NextPlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'NEXT PLAYER',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.red,
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        cardColor: Colors.grey[100],
        dividerColor: Colors.grey[300],
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        cardColor: const Color(0xFF1E1E1E),
        dividerColor: const Color(0xFF2A2A2A),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LaunchScreen(),
        '/main': (context) => const NextPlayerMainScreen(),
        '/vault-auth': (context) => const VaultAuthScreen(),
        '/vault-setup': (context) => const VaultSetupScreen(),
        '/vault': (context) => const VaultScreen(),
        '/vault-forgot': (context) => const VaultForgotScreen(),
        '/vault-security-setup': (context) => const VaultSecuritySetupScreen(),
        '/file-browser': (context) => const FileBrowserScreen(),
        '/next-browser': (context) => const NextFileBrowserScreen(),
      },
    );
  }
}

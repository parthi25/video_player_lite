import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/next_player_main_screen.dart';
import 'screens/launch_screen.dart';
import 'screens/vault_auth_screen.dart';
import 'screens/vault_setup_screen.dart';
import 'screens/vault_screen.dart';
import 'screens/vault_forgot_screen.dart';
import 'screens/vault_security_setup_screen.dart';

void main() {
  runApp(const ProviderScope(child: NextPlayerApp()));
}

class NextPlayerApp extends StatelessWidget {
  const NextPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEXT PLAYER',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
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
        listTileTheme: const ListTileThemeData(
          tileColor: Color(0xFF1E1E1E),
          iconColor: Colors.grey,
          textColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        useMaterial3: false,
      ),
      home: const LaunchScreen(),
      routes: {
        '/main': (context) => const NextPlayerMainScreen(),
        '/vault-auth': (context) => const VaultAuthScreen(),
        '/vault-setup': (context) => const VaultSetupScreen(),
        '/vault': (context) => const VaultScreen(),
        '/vault-forgot': (context) => const VaultForgotScreen(),
        '/vault-security-setup': (context) => const VaultSecuritySetupScreen(),
      },
    );
  }
}

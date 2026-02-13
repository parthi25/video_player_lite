import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter/services.dart';
import 'services/theme_service.dart';
import 'services/vault_service.dart';
import 'screens/parthi_play_main_screen.dart';
import 'screens/launch_screen.dart';
import 'screens/vault_auth_screen.dart';
import 'screens/vault_setup_screen.dart';
import 'screens/vault_screen.dart';
import 'screens/vault_forgot_screen.dart';
import 'screens/vault_security_setup_screen.dart';
import 'screens/file_browser_screen.dart';
import 'screens/next_file_browser_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    // MediaKit.ensureInitialized() is synchronous, wrap in try-catch
    MediaKit.ensureInitialized();
    debugPrint('MediaKit initialized successfully');
  } catch (e) {
    debugPrint('MediaKit initialization failed: $e');
  }

  // Cleanup any lingering vault playback temp files on app start.
  VaultService.cleanupPlaybackTempFiles();

  runApp(const ProviderScope(child: ParthiPlayApp()));
}

class ParthiPlayApp extends ConsumerStatefulWidget {
  const ParthiPlayApp({super.key});

  @override
  ConsumerState<ParthiPlayApp> createState() => _ParthiPlayAppState();
}

class _ParthiPlayAppState extends ConsumerState<ParthiPlayApp>
    with WidgetsBindingObserver {
  DateTime? _lastVaultCleanupAt;
  static const Duration _vaultCleanupCooldown = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_lastVaultCleanupAt == null ||
          now.difference(_lastVaultCleanupAt!) > _vaultCleanupCooldown) {
        VaultService.cleanupPlaybackTempFiles();
        _lastVaultCleanupAt = now;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Parthi Play',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
          primary: Colors.red.shade600,
          secondary: Colors.orange.shade600,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black87,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        dividerColor: Colors.grey[300],
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
          primary: Colors.red.shade600,
          secondary: Colors.orange.shade600,
          surface: const Color(0xFF1A1A1A),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          elevation: 0,
          foregroundColor: Colors.white,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A1A),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        dividerColor: const Color(0xFF2A2A2A),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LaunchScreen(),
        '/main': (context) => const ParthiPlayMainScreen(),
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

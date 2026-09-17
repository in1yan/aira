import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';

void main() => runApp(const SmartFlashCardsApp());

class MyApp extends SmartFlashCardsApp {
  const MyApp({super.key});
}

class SmartFlashCardsApp extends StatelessWidget {
  const SmartFlashCardsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Aira',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4CAF50),
              primary: const Color(0xFF4CAF50),
              secondary: const Color(0xFF2196F3),
              surface: Colors.white),
          useMaterial3: true,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF212121)),
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                  elevation: 2,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600))),
          cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
        ),
        home: const _AuthGate(),
      );
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late Future<bool> _session;
  @override
  void initState() {
    super.initState();
    _session = _restore();
  }

  Future<bool> _restore() async {
    await apiClient.restoreSession();
    try {
      await apiClient.me();
      return true;
    } catch (_) {
      await apiClient.logout();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
        future: _session,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          return snapshot.data! ? const HomeScreen() : const LoginScreen();
        },
      );
}

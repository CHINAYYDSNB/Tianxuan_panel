import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/settings_provider.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const ProviderScope(child: OnePanelApp()));
}

class OnePanelApp extends StatelessWidget {
  const OnePanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tianxuan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/init',
      routes: {
        '/init': (context) => const InitPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

class InitPage extends ConsumerStatefulWidget {
  const InitPage({super.key});

  @override
  ConsumerState<InitPage> createState() => _InitPageState();
}

class _InitPageState extends ConsumerState<InitPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _checkConfig());
  }

  Future<void> _checkConfig() async {
    final settings = ref.read(settingsProvider.notifier);
    await settings.init();
    if (!mounted) return;
    if (ref.read(settingsProvider).isConnected) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

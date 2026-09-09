import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

Future<void> main() async {
  await GetStorage.init();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final GetStorage _box = GetStorage();

  bool get _isDark => _box.read<bool>('darkmode') ?? false;

  Future<void> _changeTheme(bool value) async {
    await _box.write('darkmode', value);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(title: const Text('Get Storage')),
        body: Center(
          child: SwitchListTile(
            value: _isDark,
            title: const Text('Use dark theme'),
            onChanged: _changeTheme,
          ),
        ),
      ),
    );
  }
}

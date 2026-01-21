import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/data_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PocketIdApp());
}

class PocketIdApp extends StatelessWidget {
  const PocketIdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Pocket ID',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}

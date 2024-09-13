import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/sounds_screen.dart';
import 'screens/pomodoro_screen.dart';
import 'screens/settings_screen.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database; // Initialize the database
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class AppState extends ChangeNotifier {
  int _currentIndex = 0;
  bool _isDarkMode = true;

  int get currentIndex => _currentIndex;
  bool get isDarkMode => _isDarkMode;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return MaterialApp(
          title: 'OpenHarmoni',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
              surface: const Color(0xFFD9D9D9),
            ),
            scaffoldBackgroundColor: const Color(0xFFD9D9D9),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
              surface: const Color(0xFF1C1919),
            ),
            scaffoldBackgroundColor: const Color(0xFF1C1919),
          ),
          themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          body: IndexedStack(
            index: appState.currentIndex,
            children: const [
              SoundsScreen(),
              PomodoroScreen(),
              SettingsScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: appState.currentIndex,
            onTap: (index) => appState.setIndex(index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.music_note),
                label: 'Sounds',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.timer),
                label: 'Pomodoro',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}

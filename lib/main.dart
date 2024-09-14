import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/sounds_screen.dart';
import 'screens/pomodoro_screen.dart';
import 'screens/settings_screen.dart';
import 'database/database_helper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Add this extension
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

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
  String _language = 'English';

  int get currentIndex => _currentIndex;
  bool get isDarkMode => _isDarkMode;
  String get language => _language;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  Locale get locale {
    switch (_language) {
      case 'Persian':
        return const Locale('fa');
      case 'Turkish':
        return const Locale('tr');
      case 'Azerbaijani':
        return const Locale('az');
      case 'Russian':
        return const Locale('ru');
      case 'Chinese':
        return const Locale('zh');
      case 'Arabic':
        return const Locale('ar');
      case 'Spanish':
        return const Locale('es');
      default:
        return const Locale('en');
    }
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
            fontFamily: 'Kavivanar', // Apply the font here
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
              surface: const Color(0xFFD9D9D9),
            ),
            scaffoldBackgroundColor: const Color(0xFFD9D9D9),
          ),
          darkTheme: ThemeData(
            fontFamily: 'Kavivanar', // Apply the font here
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
              surface: const Color(0xFF1C1919),
            ),
            scaffoldBackgroundColor: const Color(0xFF1C1919),
          ),
          themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: appState.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('fa'), // Persian
            Locale('tr'), // Turkish
            Locale('az'), // Azerbaijani
            Locale('ru'), // Russian
            Locale('zh'), // Chinese
            Locale('ar'), // Arabic
            Locale('es'), // Spanish
          ],
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
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.music_note),
                label: context.l10n.sounds,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.timer),
                label: context.l10n.pomodoro,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings),
                label: context.l10n.settings,
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
// Remove this line if not needed
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle), // Use localized string
      ),
      body: const _SettingsContent(),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            context.l10n.appearance, // Use localized string
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SwitchListTile(
          title: Text(context.l10n.darkMode), // Use localized string
          value: appState.isDarkMode,
          onChanged: (bool value) {
            appState.toggleDarkMode();
          },
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            context.l10n.language, // Use localized string
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          title: Text(context.l10n.appLanguage), // Use localized string
          trailing: DropdownButton<String>(
            value: appState.language,
            onChanged: (String? newValue) {
              if (newValue != null) {
                appState.setLanguage(newValue);
              }
            },
            items: [
              'English',
              'Persian',
              'Turkish',
              'Azerbaijani',
              'Russian',
              'Chinese',
              'Arabic',
              'Spanish',
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
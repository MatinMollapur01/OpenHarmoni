import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class PomodoroState extends ChangeNotifier {
  int workDuration = 25 * 60;
  int breakDuration = 5 * 60;
  int remainingTime = 25 * 60;
  bool isWorking = true;
  bool isRunning = false;
  Timer? timer;
  int completedPomodoros = 0;
  int totalWorkTime = 0;
  int totalBreakTime = 0;
  String selectedWorkSound = 'bell.mp3';
  String selectedBreakSound = 'chime.mp3';
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  PomodoroState() {
    _initNotifications();
    _loadTodayStats();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    final InitializationSettings initializationSettings = const InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadTodayStats() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final stats = await DatabaseHelper.instance.getPomodoroStatsByDate(today);
    if (stats.isNotEmpty) {
      completedPomodoros = stats['completed_pomodoros'];
      totalWorkTime = stats['total_work_time'];
      totalBreakTime = stats['total_break_time'];
    }
    notifyListeners();
  }

  void startTimer() {
    if (!isRunning) {
      isRunning = true;
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (remainingTime > 0) {
          remainingTime--;
          if (isWorking) {
            totalWorkTime++;
          } else {
            totalBreakTime++;
          }
        } else {
          if (isWorking) {
            completedPomodoros++;
          }
          isWorking = !isWorking;
          remainingTime = isWorking ? workDuration : breakDuration;
          _playNotificationSound();
          _showNotification();
        }
        _saveTodayStats();
        notifyListeners();
      });
    }
  }

  void pauseTimer() {
    if (isRunning) {
      isRunning = false;
      timer?.cancel();
      notifyListeners();
    }
  }

  void resetTimer() {
    isRunning = false;
    isWorking = true;
    remainingTime = workDuration;
    timer?.cancel();
    notifyListeners();
  }

  void setWorkDuration(int minutes) {
    workDuration = minutes * 60;
    if (isWorking) remainingTime = workDuration;
    notifyListeners();
  }

  void setBreakDuration(int minutes) {
    breakDuration = minutes * 60;
    if (!isWorking) remainingTime = breakDuration;
    notifyListeners();
  }

  void setNotificationSound(String sound, bool isWorkSound) {
    if (isWorkSound) {
      selectedWorkSound = sound;
    } else {
      selectedBreakSound = sound;
    }
    notifyListeners();
  }

  Future<void> _playNotificationSound() async {
    final sound = isWorking ? selectedBreakSound : selectedWorkSound;
    await _audioPlayer.play(AssetSource('notification_sounds/$sound'));
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pomodoro_channel', 'Pomodoro Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      isWorking ? 'Break Time!' : 'Work Time!',
      isWorking ? 'Time to take a break.' : 'Time to focus on your work.',
      platformChannelSpecifics,
    );
  }

  Future<void> _saveTodayStats() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await DatabaseHelper.instance.updatePomodoroStats(today, completedPomodoros, totalWorkTime, totalBreakTime);
  }

  String get timeString {
    final minutes = (remainingTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingTime % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PomodoroState(),
      child: const _PomodoroScreenContent(),
    );
  }
}

class _PomodoroScreenContent extends StatelessWidget {
  const _PomodoroScreenContent();

  @override
  Widget build(BuildContext context) {
    final pomodoroState = Provider.of<PomodoroState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                pomodoroState.isWorking ? 'Work Time' : 'Break Time',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1 - (pomodoroState.remainingTime / (pomodoroState.isWorking ? pomodoroState.workDuration : pomodoroState.breakDuration)),
                      strokeWidth: 10,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        pomodoroState.isWorking ? Colors.red : Colors.green,
                      ),
                    ),
                    Center(
                      child: Text(
                        pomodoroState.timeString,
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: pomodoroState.isRunning
                        ? pomodoroState.pauseTimer
                        : pomodoroState.startTimer,
                    child: Text(pomodoroState.isRunning ? 'Pause' : 'Start'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: pomodoroState.resetTimer,
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text('Work Duration'),
                      DropdownButton<int>(
                        value: pomodoroState.workDuration ~/ 60,
                        items: [15, 25, 30, 45, 60]
                            .map((int value) => DropdownMenuItem<int>(
                                  value: value,
                                  child: Text('$value min'),
                                ))
                            .toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            pomodoroState.setWorkDuration(newValue);
                          }
                        },
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Break Duration'),
                      DropdownButton<int>(
                        value: pomodoroState.breakDuration ~/ 60,
                        items: [5, 10, 15, 20]
                            .map((int value) => DropdownMenuItem<int>(
                                  value: value,
                                  child: Text('$value min'),
                                ))
                            .toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            pomodoroState.setBreakDuration(newValue);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Notification Sounds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text('Work End'),
                      DropdownButton<String>(
                        value: pomodoroState.selectedWorkSound,
                        items: ['bell.mp3', 'chime.mp3', 'gong.mp3']
                            .map((String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value.split('.').first),
                                ))
                            .toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            pomodoroState.setNotificationSound(newValue, true);
                          }
                        },
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Break End'),
                      DropdownButton<String>(
                        value: pomodoroState.selectedBreakSound,
                        items: ['bell.mp3', 'chime.mp3', 'gong.mp3']
                            .map((String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value.split('.').first),
                                ))
                            .toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            pomodoroState.setNotificationSound(newValue, false);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Today\'s Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Completed Pomodoros: ${pomodoroState.completedPomodoros}'),
              Text('Total Work Time: ${(pomodoroState.totalWorkTime / 60).toStringAsFixed(1)} minutes'),
              Text('Total Break Time: ${(pomodoroState.totalBreakTime / 60).toStringAsFixed(1)} minutes'),
            ],
          ),
        ),
      ),
    );
  }
}
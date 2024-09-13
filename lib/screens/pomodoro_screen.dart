import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';

class PomodoroState extends ChangeNotifier {
  int workDuration = 25 * 60;
  int breakDuration = 5 * 60;
  int remainingTime = 25 * 60;
  bool isWorking = true;
  bool isRunning = false;
  Timer? timer;

  void startTimer() {
    if (!isRunning) {
      isRunning = true;
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          isWorking = !isWorking;
          remainingTime = isWorking ? workDuration : breakDuration;
        }
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              pomodoroState.isWorking ? 'Work Time' : 'Break Time',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text(
              pomodoroState.timeString,
              style: Theme.of(context).textTheme.displayLarge,
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
          ],
        ),
      ),
    );
  }
}
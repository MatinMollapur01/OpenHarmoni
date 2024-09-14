import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../database/database_helper.dart';
import '../main.dart'; // Import the file where the extension is defined

class SoundCategory {
  final String name;
  final List<String> sounds;

  SoundCategory(this.name, this.sounds);
}

class SoundMix {
  final String name;
  final Map<String, double> soundVolumes;

  SoundMix(this.name, this.soundVolumes);
}

class Equalizer {
  double bass;
  double mid;
  double treble;

  Equalizer({this.bass = 0.5, this.mid = 0.5, this.treble = 0.5});
}

class SoundState extends ChangeNotifier {
  final List<SoundCategory> categories = [
    SoundCategory('Nature', ['birds', 'forest', 'ocean', 'rain', 'stream', 'wind']),
    SoundCategory('Ambient', ['fire']),
    SoundCategory('White Noise', ['brown-noise', 'pink-noise', 'white-noise']),
  ];
  final Map<String, AudioPlayer> players = {};
  final Map<String, double> volumes = {};
  final Map<String, PlayerState> playerStates = {};
  final List<SoundMix> savedMixes = [];
  Timer? fadeOutTimer;
  final Map<String, Equalizer> equalizers = {};
  List<String> lastPlayedSounds = [];

  SoundState() {
    for (var category in categories) {
      for (var sound in category.sounds) {
        players[sound] = AudioPlayer();
        volumes[sound] = 0.5;
        playerStates[sound] = PlayerState.stopped;
        equalizers[sound] = Equalizer();
        players[sound]!.setReleaseMode(ReleaseMode.loop); // Set to loop mode
        players[sound]!.onPlayerStateChanged.listen((state) {
          playerStates[sound] = state;
          notifyListeners();
        });
      }
    }
  }

  Future<void> toggleSound(String sound) async {
    try {
      if (playerStates[sound] == PlayerState.playing) {
        await players[sound]!.pause();
      } else {
        await players[sound]!.setSource(AssetSource('sounds/$sound.mp3'));
        await players[sound]!.setVolume(volumes[sound]!);
        await players[sound]!.resume();
      }
    } catch (e) {
      print('Error playing sound $sound: $e');
    }
    notifyListeners();
  }

  void setVolume(String sound, double volume) {
    volumes[sound] = volume;
    players[sound]!.setVolume(volume);
    notifyListeners();
  }

  void stopAllSounds() {
    lastPlayedSounds = players.keys.where((sound) => playerStates[sound] == PlayerState.playing).toList();
    for (var player in players.values) {
      player.stop();
    }
    notifyListeners();
  }

  void continuePlayingSounds() {
    for (var sound in lastPlayedSounds) {
      toggleSound(sound);
    }
  }

  void setEqualizer(String sound, String band, double value) {
    switch (band) {
      case 'bass':
        equalizers[sound]!.bass = value;
        break;
      case 'mid':
        equalizers[sound]!.mid = value;
        break;
      case 'treble':
        equalizers[sound]!.treble = value;
        break;
    }
    // In a real implementation, you would apply the equalizer settings to the audio player here
    notifyListeners();
  }

  void startFadeOut(int durationInSeconds) {
    const stepDuration = Duration(milliseconds: 100);
    final steps = durationInSeconds * 10;
    var currentStep = 0;

    fadeOutTimer = Timer.periodic(stepDuration, (timer) {
      currentStep++;
      for (var sound in players.keys) {
        if (playerStates[sound] == PlayerState.playing) {
          final newVolume = volumes[sound]! * (1 - currentStep / steps);
          setVolume(sound, newVolume);
        }
      }

      if (currentStep >= steps) {
        stopAllSounds();
        timer.cancel();
      }
    });
  }

  Future<void> loadSavedMixes() async {
    try {
      final mixes = await DatabaseHelper.instance.getSoundMixes();
      savedMixes.clear();
      for (var mix in mixes) {
        final soundVolumes = Map<String, double>.from(json.decode(mix['mix_data']));
        savedMixes.add(SoundMix(mix['name'], soundVolumes));
      }
      print('Loaded ${savedMixes.length} mixes'); // Debug print
      notifyListeners();
    } catch (e) {
      print('Error loading saved mixes: $e');
    }
  }

  Future<void> saveMix(String name) async {
    try {
      final activeSounds = Map<String, double>.fromEntries(
        volumes.entries.where((entry) => playerStates[entry.key] == PlayerState.playing)
      );
      if (activeSounds.isNotEmpty) {
        final mix = SoundMix(name, activeSounds);
        savedMixes.add(mix);
        await DatabaseHelper.instance.insertSoundMix(name, json.encode(activeSounds));
        print('Saved mix: $name with ${activeSounds.length} sounds'); // Debug print
        notifyListeners();
      } else {
        print('No active sounds to save');
      }
    } catch (e) {
      print('Error saving mix: $e');
    }
  }

  Future<void> deleteMix(SoundMix mix) async {
    savedMixes.remove(mix);
    // Assuming the mix id is its index in the list + 1
    await DatabaseHelper.instance.deleteSoundMix(savedMixes.indexOf(mix) + 1);
    notifyListeners();
  }

  void loadMix(SoundMix mix) {
    stopAllSounds();
    for (var entry in mix.soundVolumes.entries) {
      setVolume(entry.key, entry.value);
      toggleSound(entry.key);
    }
  }
}

class SoundsScreen extends StatelessWidget {
  const SoundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final state = SoundState();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          state.loadSavedMixes();
        });
        return state;
      },
      child: const _SoundsScreenContent(),
    );
  }
}

class _SoundsScreenContent extends StatelessWidget {
  const _SoundsScreenContent();

  @override
  Widget build(BuildContext context) {
    final soundState = Provider.of<SoundState>(context);
    return DefaultTabController(
      length: soundState.categories.length + 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.relaxingSounds), // Use the l10n extension method
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              ...soundState.categories.map((category) => Tab(text: _getCategoryName(context, category.name))), // Use the correct category name
              Tab(text: context.l10n.savedMixes), // Use the l10n extension method
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ...soundState.categories.map((category) => SoundCategoryView(category: category)),
            const SavedMixesView(),
          ],
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: soundState.continuePlayingSounds,
              child: const Icon(Icons.play_arrow),
            ),
            const SizedBox(width: 16),
            FloatingActionButton(
              onPressed: soundState.stopAllSounds,
              child: const Icon(Icons.stop),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(BuildContext context, String categoryName) {
    switch (categoryName) {
      case 'Nature':
        return context.l10n.nature;
      case 'Ambient':
        return context.l10n.ambient;
      case 'White Noise':
        return context.l10n.whiteNoise;
      default:
        return categoryName;
    }
  }
}

class SoundCategoryView extends StatelessWidget {
  final SoundCategory category;

  const SoundCategoryView({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8, // Adjust this value as needed
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: category.sounds.length,
      itemBuilder: (context, index) {
        final sound = category.sounds[index];
        return SoundTile(sound: sound);
      },
    );
  }
}

class SoundTile extends StatelessWidget {
  final String sound;

  const SoundTile({super.key, required this.sound});

  @override
  Widget build(BuildContext context) {
    final soundState = Provider.of<SoundState>(context);
    final isPlaying = soundState.playerStates[sound] == PlayerState.playing;

    return Card(
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _getSoundName(context, sound), // Use the localized sound name
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () => soundState.toggleSound(sound),
          ),
          Slider(
            value: soundState.volumes[sound]!,
            onChanged: (value) => soundState.setVolume(sound, value),
          ),
          SoundVisualization(sound: sound),
          ExpansionTile(
            title: Text(context.l10n.equalizer), // Use the l10n extension method
            children: [
              EqualizerControls(sound: sound),
            ],
          ),
        ],
      ),
    );
  }

  String _getSoundName(BuildContext context, String sound) {
    switch (sound) {
      case 'birds':
        return context.l10n.birds;
      case 'forest':
        return context.l10n.forest;
      case 'ocean':
        return context.l10n.ocean;
      case 'rain':
        return context.l10n.rain;
      case 'stream':
        return context.l10n.stream;
      case 'wind':
        return context.l10n.wind;
      case 'fire':
        return context.l10n.fire;
      case 'brown-noise':
        return context.l10n.brownNoise;
      case 'pink-noise':
        return context.l10n.pinkNoise;
      case 'white-noise':
        return context.l10n.whiteNoise;
      default:
        return sound;
    }
  }
}

class EqualizerControls extends StatelessWidget {
  final String sound;

  const EqualizerControls({super.key, required this.sound});

  @override
  Widget build(BuildContext context) {
    final soundState = Provider.of<SoundState>(context);
    final equalizer = soundState.equalizers[sound]!;

    return Column(
      children: [
        _buildEqualizerSlider(context.l10n.bass, equalizer.bass, (value) => soundState.setEqualizer(sound, 'bass', value)), // Use the l10n extension method
        _buildEqualizerSlider(context.l10n.mid, equalizer.mid, (value) => soundState.setEqualizer(sound, 'mid', value)), // Use the l10n extension method
        _buildEqualizerSlider(context.l10n.treble, equalizer.treble, (value) => soundState.setEqualizer(sound, 'treble', value)), // Use the l10n extension method
      ],
    );
  }

  Widget _buildEqualizerSlider(String label, double value, Function(double) onChanged) {
    return Row(
      children: [
        SizedBox(width: 50, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class SoundVisualization extends StatefulWidget {
  final String sound;

  const SoundVisualization({super.key, required this.sound});

  @override
  _SoundVisualizationState createState() => _SoundVisualizationState();
}

class _SoundVisualizationState extends State<SoundVisualization> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final soundState = Provider.of<SoundState>(context);
    final isPlaying = soundState.playerStates[widget.sound] == PlayerState.playing;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(50, 20),
          painter: WaveformPainter(
            animation: _controller,
            isPlaying: isPlaying,
          ),
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isPlaying;

  WaveformPainter({required this.animation, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isPlaying ? Colors.blue : Colors.grey
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final width = size.width;
    final height = size.height;

    for (double i = 0; i < width; i++) {
      final x = i;
      final y = height / 2 + sin((x / width + animation.value) * 2 * pi) * height / 4 * (isPlaying ? 1 : 0.2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SavedMixesView extends StatelessWidget {
  const SavedMixesView({super.key});

  @override
  Widget build(BuildContext context) {
    final soundState = Provider.of<SoundState>(context);

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => SaveMixDialog(soundState: soundState),
            );
          },
          child: Text(context.l10n.saveCurrentMix), // Use the l10n extension method
        ),
        Expanded(
          child: ListView.builder(
            itemCount: soundState.savedMixes.length,
            itemBuilder: (context, index) {
              final mix = soundState.savedMixes[index];
              return ListTile(
                title: Text(mix.name),
                onTap: () => soundState.loadMix(mix),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => soundState.deleteMix(mix),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SaveMixDialog extends StatefulWidget {
  final SoundState soundState;

  const SaveMixDialog({super.key, required this.soundState});

  @override
  _SaveMixDialogState createState() => _SaveMixDialogState();
}

class _SaveMixDialogState extends State<SaveMixDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.saveMix), // Use the l10n extension method
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(hintText: context.l10n.enterMixName), // Use the l10n extension method
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel), // Use the l10n extension method
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.soundState.saveMix(_controller.text);
              Navigator.of(context).pop();
            }
          },
          child: Text(context.l10n.save), // Use the l10n extension method
        ),
      ],
    );
  }
}
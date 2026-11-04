import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/main_menu_screen.dart';
import 'services/audio_controller.dart';
import 'services/progress_controller.dart';
import 'services/settings_controller.dart';
import 'services/storage_service.dart';
import 'style/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // shared_preferences: load persisted high score, progress & sound settings.
  final storage = await StorageService.create();
  final settings = SettingsController(storage);
  final progress = ProgressController(storage);

  // audioplayers: looping background music + sound effects.
  final audio = AudioController(settings);
  audio.initialize();

  runApp(ColorPourApp(settings: settings, progress: progress, audio: audio));
}

class ColorPourApp extends StatelessWidget {
  const ColorPourApp({
    super.key,
    required this.settings,
    required this.progress,
    required this.audio,
  });

  final SettingsController settings;
  final ProgressController progress;
  final AudioController audio;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: progress),
        Provider<AudioController>.value(value: audio),
      ],
      child: MaterialApp(
        title: 'Color Pour',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Palette.accentPink,
            surface: Palette.backgroundMain,
          ),
          scaffoldBackgroundColor: Palette.backgroundMain,
          dialogTheme: const DialogThemeData(
            backgroundColor: Palette.backgroundMain,
          ),
        ),
        home: const MainMenuScreen(),
      ),
    );
  }
}

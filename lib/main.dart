import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/main_menu_screen.dart';
import 'screens/splash_screen.dart';
import 'services/audio_controller.dart';
import 'services/progress_controller.dart';
import 'services/settings_controller.dart';
import 'services/storage_service.dart';
import 'style/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  // shared_preferences: persisted progress, high scores & sound settings.
  final storage = await StorageService.create();
  final settings = SettingsController(storage);
  final progress = ProgressController(storage);

  // audioplayers: looping music, SFX and neta voice reactions.
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
        title: 'Color Pour · Neta Edition',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Palette.saffron,
            brightness: Brightness.dark,
            surface: Palette.bgTop,
          ),
          scaffoldBackgroundColor: Palette.bgTop,
          fontFamily: Palette.bodyFont,
          splashFactory: InkSparkle.splashFactory,
          dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF241A45)),
        ),
        home: const _Root(),
      ),
    );
  }
}

/// Shows the animated splash once, then the main menu.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _splash = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _splash
          ? Scaffold(
              key: const ValueKey('splash'),
              backgroundColor: Palette.bgTop,
              body: SplashScreen(onDone: () => setState(() => _splash = false)),
            )
          : const MainMenuScreen(key: ValueKey('menu')),
    );
  }
}

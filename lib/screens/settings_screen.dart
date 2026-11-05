import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../services/audio_controller.dart';
import '../services/progress_controller.dart';
import '../services/settings_controller.dart';
import '../style/palette.dart';
import '../widgets/animated_background.dart';
import '../widgets/game_button.dart';
import 'main_menu_screen.dart';
import 'soundboard_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final progress = context.read<ProgressController>();
    final audio = context.read<AudioController>();

    return Scaffold(
      body: AnimatedBackground(
        colors: const [Palette.bgTop, Color(0xFF1E1B4B), Color(0xFF2B1B5A)],
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Settings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: Palette.displayFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 46),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _SectionTitle('AUDIO'),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Column(
                        children: [
                          _ToggleRow(
                            icon: Icons.volume_up_rounded,
                            label: 'Sound',
                            value: !settings.muted,
                            onChanged: (_) => settings.toggleMuted(),
                          ),
                          _ToggleRow(
                            icon: Icons.music_note_rounded,
                            label: 'Music',
                            value: settings.musicOn,
                            enabled: !settings.muted,
                            onChanged: (_) => settings.toggleMusic(),
                          ),
                          _ToggleRow(
                            icon: Icons.graphic_eq_rounded,
                            label: 'Sound FX',
                            value: settings.sfxOn,
                            enabled: !settings.muted,
                            onChanged: (_) => settings.toggleSfx(),
                          ),
                          _ToggleRow(
                            icon: Icons.mic_rounded,
                            label: 'Neta voices',
                            value: settings.voicesOn,
                            enabled: !settings.muted,
                            onChanged: (_) => settings.toggleVoices(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionTitle('MUSIC TRACK'),
                    GlassCard(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          for (var i = 0; i < musicTracks.length; i++)
                            _TrackRow(
                              title: musicTracks[i].title,
                              selected: settings.musicTrack == i,
                              onTap: () {
                                settings.setMusicTrack(i);
                                audio.ensureMusicStarted();
                              },
                            ),
                          const SizedBox(height: 4),
                          const Text(
                            'Music: Kevin MacLeod (incompetech.com) · CC BY 4.0',
                            style: TextStyle(
                              fontFamily: Palette.bodyFont,
                              fontSize: 9.5,
                              color: Palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionTitle('VOICES'),
                    GlassCard(
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Browse all 18 meme lines and play them any time.',
                              style: TextStyle(
                                fontFamily: Palette.bodyFont,
                                fontSize: 12.5,
                                color: Palette.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 130,
                            child: GameButton(
                              label: 'Open',
                              compact: true,
                              width: 130,
                              gradient: Palette.blueButton,
                              onPressed: () => Navigator.of(context).push(
                                fadeRoute(const SoundboardScreen()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle('PROGRESS'),
                    Center(
                      child: GameButton(
                        label: 'Reset progress',
                        icon: Icons.delete_forever_rounded,
                        width: 250,
                        compact: true,
                        gradient: Palette.pinkButton,
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF241A45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              title: const Text(
                                'Reset progress?',
                                style: TextStyle(
                                  fontFamily: Palette.displayFont,
                                  color: Colors.white,
                                ),
                              ),
                              content: const Text(
                                'This erases your high score, stars and unlocked levels.',
                                style: TextStyle(
                                  fontFamily: Palette.bodyFont,
                                  color: Palette.textSecondary,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Reset'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) await progress.reset();
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Color Pour · Neta Edition v1.0\n'
                      'Made for personal, non-commercial fun. Meme audio is fan parody — '
                      'rights belong to the original creators and speakers (Narendra Modi, '
                      'Ravi Kishan, Rahul Gandhi, Mahatma Gandhi, Lalu Yadav, Amit Shah).',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: Palette.bodyFont,
                        fontSize: 9.5,
                        height: 1.4,
                        color: Palette.textMuted.withValues(alpha: 0.85),
                      ),
                    ),
                  ].animate(interval: 60.ms).fadeIn(duration: 260.ms),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: Palette.bodyFont,
        fontWeight: FontWeight.w600,
        fontSize: 10,
        letterSpacing: 2.2,
        color: Palette.textMuted,
      ),
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: Palette.bodyFont,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.white.withValues(alpha: enabled ? 1 : 0.4),
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: Colors.white,
            activeTrackColor: Palette.indiaGreen,
          ),
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.title,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Palette.saffron.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: selected ? 0.45 : 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.equalizer_rounded : Icons.music_note_outlined,
              size: 17,
              color: selected ? Palette.saffron : Palette.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: Palette.bodyFont,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.white : Palette.textSecondary,
                ),
              ),
            ),
            if (selected)
              const Text(
                'NOW',
                style: TextStyle(
                  fontFamily: Palette.bodyFont,
                  fontSize: 9,
                  letterSpacing: 1.2,
                  color: Palette.saffron,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

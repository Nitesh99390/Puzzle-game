import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../services/progress_controller.dart';
import '../services/settings_controller.dart';
import '../style/palette.dart';
import '../widgets/game_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final progress = context.read<ProgressController>();

    final tiles = <Widget>[
      _SettingTile(
        icon: settings.muted
            ? Icons.volume_off_rounded
            : Icons.volume_up_rounded,
        label: 'Sound',
        value: !settings.muted,
        onChanged: (_) => settings.toggleMuted(),
      ),
      _SettingTile(
        icon: Icons.music_note_rounded,
        label: 'Music',
        value: settings.musicOn,
        enabled: !settings.muted,
        onChanged: (_) => settings.toggleMusic(),
      ),
      _SettingTile(
        icon: Icons.graphic_eq_rounded,
        label: 'Sound FX',
        value: settings.sfxOn,
        enabled: !settings.muted,
        onChanged: (_) => settings.toggleSfx(),
      ),
      const SizedBox(height: 24),
      GameButton(
        label: 'Reset progress',
        icon: Icons.delete_forever_rounded,
        color: Palette.accentPink,
        width: 280,
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Reset progress?'),
              content: const Text(
                'This erases your high score, stars and unlocked levels.',
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
          if (ok == true) {
            await progress.reset();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Player progress has been reset.'),
                ),
              );
            }
          }
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Palette.backgroundSettings,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                        fontSize: 32,
                        color: Palette.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: tiles
                    .animate(interval: 70.ms)
                    .fadeIn(duration: 250.ms)
                    .slideX(begin: -0.3, curve: Curves.easeOutCubic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.trueWhite.withValues(alpha: enabled ? 1 : 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.ink, width: 2.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: Palette.ink),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: Palette.displayFont,
                fontSize: 22,
                color: Palette.ink,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Palette.accentGreen,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

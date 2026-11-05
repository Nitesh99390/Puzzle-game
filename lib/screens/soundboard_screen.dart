import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../services/audio_controller.dart';
import '../services/neta_voices.dart';
import '../style/palette.dart';
import '../widgets/animated_background.dart';
import '../widgets/game_button.dart';

/// Tap any card to hear that personality's famous line.
class SoundboardScreen extends StatefulWidget {
  const SoundboardScreen({super.key});

  @override
  State<SoundboardScreen> createState() => _SoundboardScreenState();
}

class _SoundboardScreenState extends State<SoundboardScreen> {
  Neta? _filter;

  @override
  Widget build(BuildContext context) {
    final audio = context.read<AudioController>();
    final lines = NetaVoices.all
        .where((l) => _filter == null || l.neta == _filter)
        .toList();

    return Scaffold(
      body: AnimatedBackground(
        colors: const [Palette.bgTop, Color(0xFF2B1050), Color(0xFF4A1244)],
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Neta Soundboard',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: Palette.displayFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'tap a card to play the famous line',
                            style: TextStyle(
                              fontFamily: Palette.bodyFont,
                              fontSize: 10,
                              color: Palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 46),
                  ],
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _Chip(
                      label: 'All',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final n in Neta.values)
                      _Chip(
                        label: n.short,
                        selected: _filter == n,
                        onTap: () => setState(() => _filter = n),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<VoiceLine?>(
                  valueListenable: audio.speaking,
                  builder: (_, speaking, __) => ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                    physics: const BouncingScrollPhysics(),
                    itemCount: lines.length,
                    itemBuilder: (context, i) {
                      final l = lines[i];
                      final active = speaking?.id == l.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child:
                            GestureDetector(
                                  onTap: () {
                                    audio.ensureMusicStarted();
                                    audio.speakLine(l);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          l.neta.gradient.first.withValues(
                                            alpha: active ? 0.55 : 0.22,
                                          ),
                                          l.neta.gradient.last.withValues(
                                            alpha: active ? 0.45 : 0.14,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: active ? 0.7 : 0.18,
                                        ),
                                        width: active ? 1.8 : 1.1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: l.neta.gradient,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            l.neta.short,
                                            style: const TextStyle(
                                              fontFamily: Palette.bodyFont,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                l.neta.fullName,
                                                style: TextStyle(
                                                  fontFamily: Palette.bodyFont,
                                                  fontSize: 9.5,
                                                  letterSpacing: 1.1,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.7),
                                                ),
                                              ),
                                              Text(
                                                '“${l.caption}”',
                                                style: const TextStyle(
                                                  fontFamily: Palette.bodyFont,
                                                  fontSize: 13.5,
                                                  height: 1.25,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          active
                                              ? Icons.graphic_eq_rounded
                                              : Icons.play_circle_fill_rounded,
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .animate(delay: (24 * i).ms)
                                .fadeIn(duration: 260.ms)
                                .slideX(
                                  begin: 0.12,
                                  curve: Curves.easeOutCubic,
                                ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Fan parody · all meme voices belong to their original creators',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: Palette.bodyFont,
                    fontSize: 9.5,
                    color: Palette.textMuted.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? Palette.tricolor : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 0.5 : 0.16),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: Palette.bodyFont,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
              color: selected ? Palette.bgTop : Palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

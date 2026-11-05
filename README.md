# Color Pour — Neta Edition

A water/tube colour-sorting puzzle built with Flutter, upgraded into a polished
"desi meme" experience: glass tubes, smooth pour choreography, Indian neta voice
reactions, tricolour celebration and a cinematic landing screen.

> **Personal project / fan parody.** Not published on any store. All meme voice
> clips belong to their original creators and are used here as fan-made parody.

---

## Features

**Gameplay**
- 45 hand-tuned levels (`kLevelCount`), 3 → 12 colours, deterministic seeded boards
- Guaranteed-solvable generator + DFS solver (`PuzzleSolver`)
- Hints (3 per level), undo, restart, resume-saved-board
- Combo detection, illegal-move streak, stuck detection (`isStuck`)
- Stars, score, best score, per-level progress persistence

**Graphics & animation**
- Custom glass tube painter: layered liquid bands, gravity-correct surface slant,
  slosh waves, bubbles, gloss highlights, gold completion caps
- Full pour choreography on one `Ticker`: lift → fly → tilt about the mouth →
  Bezier liquid stream → splash particles with gravity → fly back
- Animated starfield + drifting orb background (single 40 s controller,
  `RepaintBoundary`-wrapped)
- Confetti with 3 emitters and tricolour palette on level complete
- `flutter_animate` micro-interactions throughout

**Sound**
- 18 neta meme voice lines mapped to in-game events with probability,
  priority and cooldown (`VoiceEvent` → `VoiceLine`)
- Music ducking while a voice plays, plus an on-screen speech bubble
- 5 CC-BY music tracks (Kevin MacLeod) + 20 CC0/free SFX
- Soundboard screen to browse and play every line
- Separate toggles for sound / music / SFX / neta voices

**Screens**
Splash · Main menu (landing) · Level select · Play · Win panel ·
Soundboard · Tutorial · Settings

---

## Event → voice mapping

| Event | Example line |
|---|---|
| `levelStart` | "Wah Modi ji, wah!" |
| `tubeComplete` | "Accha kiya, accha kiya!" |
| `comboTubes` | "Wah, kya scene hai!" |
| `illegalMove` / `illegalStreak` | "Ab aap log rona band kijiye…" |
| `hint` | "Iska karan Narendra Modi hai!" |
| `win` / `perfectWin` | "Sab changa si!" / "Jai Hind!" |
| `newHighScore` | "Pehchan! Money follows, my brother." |
| `gameFinished` | "Bharat Mata ki Jai!" |

---

## Run it

```bash
flutter pub get
flutter run                    # Android / desktop
flutter build web --release    # web preview (serve build/web)
flutter test                   # 5 tests: solver, hint, stuck detection, widget
```

Requires **Flutter 3.35.4 / Dart 3.9.2**.

---

## Project layout

```
lib/
  game/      game_logic.dart (levels, rules, solver) · level_state.dart (state machine)
  services/  audio_controller.dart · neta_voices.dart · settings · progress · storage
  screens/   splash · main_menu · play_session · level_selection · soundboard ·
             tutorial · settings
  widgets/   tube_painter · tube_view · game_board · neta_speech_bubble ·
             celebration_overlay · animated_background · game_button
  style/     palette.dart
assets/
  voices/ 18 neta lines     ui/ 20 SFX        music/ 5 tracks
  fonts/  Baloo 2, Fredoka
```

---

## Credits

- **Music** — Kevin MacLeod (incompetech.com), licensed **CC BY 4.0**:
  *Carefree*, *Fluffing a Duck*, *Monkeys Spinning Monkeys*, *Naraina*, *Vadodara*.
- **SFX** — Kenney.nl and OpenGameArt audio packs (**CC0**), plus generated tones;
  all normalised and converted to MP3.
- **Fonts** — Baloo 2 and Fredoka (SIL Open Font License).
- **Meme voice clips** — fan-parody use of publicly circulating clips; rights stay
  with the original creators and speakers. This project is not affiliated with,
  endorsed by, or representing any of them.

Not for commercial distribution.

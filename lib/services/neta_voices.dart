import 'package:flutter/material.dart';

import '../style/palette.dart';

/// Famous personalities whose meme lines are used as reactions.
enum Neta {
  modi('Narendra Modi', 'NaMo', Icons.wb_sunny_rounded, [
    Color(0xFFFFB347),
    Color(0xFFFF7A1A),
  ]),
  raviKishan('Ravi Kishan', 'RK', Icons.theater_comedy_rounded, [
    Color(0xFFFF5F8F),
    Color(0xFFB0245E),
  ]),
  rahul('Rahul Gandhi', 'RaGa', Icons.front_hand_rounded, [
    Color(0xFF5DA9FF),
    Color(0xFF2F57D8),
  ]),
  gandhi('Mahatma Gandhi', 'Bapu', Icons.visibility_rounded, [
    Color(0xFFF5F1E6),
    Color(0xFFBFAF8C),
  ]),
  lalu('Lalu Yadav', 'Lalu', Icons.sports_mma_rounded, [
    Color(0xFF52E39A),
    Color(0xFF128A52),
  ]),
  amitShah('Amit Shah', 'Shah', Icons.record_voice_over_rounded, [
    Color(0xFFB993FF),
    Color(0xFF6A3BD6),
  ]),
  janta('Janta', 'Janta', Icons.groups_rounded, [
    Palette.saffron,
    Palette.indiaGreen,
  ]);

  const Neta(this.fullName, this.short, this.icon, this.gradient);
  final String fullName;
  final String short;
  final IconData icon;
  final List<Color> gradient;
}

/// One meme audio line.
class VoiceLine {
  const VoiceLine(this.id, this.neta, this.caption, {this.english});
  final String id;
  final Neta neta;
  final String caption;
  final String? english;

  String get asset => 'voices/$id.mp3';
}

/// Game moments that can trigger a neta reaction.
enum VoiceEvent {
  levelStart,
  tubeComplete,
  comboTubes,
  illegalMove,
  illegalStreak,
  undo,
  restart,
  hint,
  win,
  perfectWin,
  newHighScore,
  gameFinished,
}

class NetaVoices {
  NetaVoices._();

  static const modiWah = VoiceLine(
    'modi_wah_modiji_wah',
    Neta.modi,
    'Wah Modi ji, wah!',
  );
  static const modiScene = VoiceLine(
    'modi_wah_kya_scene_hai',
    Neta.modi,
    'Wah, kya scene hai!',
  );
  static const modiAccha = VoiceLine(
    'modi_accha_kiya',
    Neta.modi,
    'Modi ji ne accha kiya, accha kiya!',
  );
  static const modiKaran = VoiceLine(
    'modi_iska_karan',
    Neta.modi,
    'Iska karan Narendra Modi hai!',
  );
  static const modiChanga = VoiceLine(
    'modi_sab_changa_si',
    Neta.modi,
    'Sab changa si!',
  );
  static const modiRona = VoiceLine(
    'modi_rona_band_kijiye',
    Neta.modi,
    'Ab aap log rona band kijiye…',
  );
  static const crowdModi = VoiceLine(
    'crowd_modi_modi',
    Neta.janta,
    'Modi! Modi! Modi! Modi!',
  );
  static const raviJhand = VoiceLine(
    'ravi_zindagi_jhand_ba',
    Neta.raviKishan,
    'Zindagi jhand ba, phir bhi ghamand ba!',
  );
  static const raviOmg = VoiceLine(
    'ravi_omg_zindagi_jhand',
    Neta.raviKishan,
    'Oh my God! Zindagi jhand ba…',
  );
  static const raviPehchan = VoiceLine(
    'ravi_pehchan',
    Neta.raviKishan,
    'Pehchan! Money follows, my brother.',
  );
  static const raviNaam = VoiceLine(
    'ravi_naam_ya_daam',
    Neta.raviKishan,
    'Naam ya daam? NAAM!',
  );
  static const rahulMaza = VoiceLine(
    'rahul_maza_aaya',
    Neta.rahul,
    'Maza aaya! Ye maza har Hindustani ko dena chahta hoon.',
  );
  static const rahulKhatam = VoiceLine(
    'rahul_khatam_tata_bye',
    Neta.rahul,
    'Khatam! Bye bye, tata, goodbye, gaya!',
  );
  static const gandhiRaah = VoiceLine(
    'gandhi_jis_raah_pe',
    Neta.gandhi,
    'Jis raah pe tum chal rahe ho beta, ek din buri tarah phasoge!',
  );
  static const laluMukka = VoiceLine(
    'lalu_do_mukka',
    Neta.lalu,
    'De denge do mukka, naach ke gir jaoge!',
  );
  static const shahKyaBaat = VoiceLine(
    'shah_kya_baat_kar_rahe_ho',
    Neta.amitShah,
    'Arre, kya baat kar rahe ho!',
  );
  static const jaiHind = VoiceLine('jai_hind', Neta.janta, 'Jai Hind!');
  static const bharatMata = VoiceLine(
    'bharat_mata_ki_jai',
    Neta.janta,
    'Bharat Mata ki Jai!',
  );

  static const List<VoiceLine> all = [
    modiWah,
    modiScene,
    modiAccha,
    modiKaran,
    modiChanga,
    modiRona,
    crowdModi,
    raviJhand,
    raviOmg,
    raviPehchan,
    raviNaam,
    rahulMaza,
    rahulKhatam,
    gandhiRaah,
    laluMukka,
    shahKyaBaat,
    jaiHind,
    bharatMata,
  ];

  /// Which lines fit which moment ("jo jaha match hoga").
  static const Map<VoiceEvent, List<VoiceLine>> byEvent = {
    VoiceEvent.levelStart: [modiChanga, jaiHind],
    VoiceEvent.tubeComplete: [modiWah, modiAccha, raviPehchan, modiScene],
    VoiceEvent.comboTubes: [modiScene, rahulMaza, raviNaam],
    VoiceEvent.illegalMove: [shahKyaBaat, raviOmg],
    VoiceEvent.illegalStreak: [raviJhand, gandhiRaah, laluMukka],
    VoiceEvent.undo: [modiRona],
    VoiceEvent.restart: [rahulKhatam],
    VoiceEvent.hint: [modiKaran],
    VoiceEvent.win: [rahulMaza, modiScene, modiAccha, modiWah],
    VoiceEvent.perfectWin: [crowdModi, raviNaam],
    VoiceEvent.newHighScore: [crowdModi, modiKaran],
    VoiceEvent.gameFinished: [bharatMata],
  };

  /// Probability that an event actually speaks (keeps it fun, not spammy).
  static const Map<VoiceEvent, double> chance = {
    VoiceEvent.levelStart: 0.35,
    VoiceEvent.tubeComplete: 0.55,
    VoiceEvent.comboTubes: 1,
    VoiceEvent.illegalMove: 0.35,
    VoiceEvent.illegalStreak: 1,
    VoiceEvent.undo: 0.6,
    VoiceEvent.restart: 1,
    VoiceEvent.hint: 1,
    VoiceEvent.win: 1,
    VoiceEvent.perfectWin: 1,
    VoiceEvent.newHighScore: 1,
    VoiceEvent.gameFinished: 1,
  };

  /// Higher priority lines may interrupt lower priority ones.
  static int priority(VoiceEvent e) => switch (e) {
    VoiceEvent.gameFinished ||
    VoiceEvent.perfectWin ||
    VoiceEvent.newHighScore ||
    VoiceEvent.win => 3,
    VoiceEvent.restart || VoiceEvent.hint || VoiceEvent.illegalStreak => 2,
    _ => 1,
  };
}

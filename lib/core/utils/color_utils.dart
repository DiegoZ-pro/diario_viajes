import 'package:flutter/material.dart';

class AppColorUtils {
  static const _palette = <Color>[
    Color(0xFF1565C0),
    Color(0xFF00695C),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFF2E7D32),
    Color(0xFFAD1457),
    Color(0xFF0277BD),
    Color(0xFF4E342E),
    Color(0xFF00838F),
    Color(0xFF558B2F),
  ];

  static Color forSeed(String seed) {
    var hash = 5381;
    for (final c in seed.codeUnits) {
      hash = ((hash << 5) + hash) ^ c;
    }
    return _palette[hash.abs() % _palette.length];
  }
}

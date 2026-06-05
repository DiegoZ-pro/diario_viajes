import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _settingsBox = 'settings';
const _themeModeKey = 'theme_mode';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  void _load() {
    try {
      final box = Hive.box(_settingsBox);
      final stored = box.get(_themeModeKey, defaultValue: 'system') as String;
      state = _parse(stored);
    } catch (_) {}
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      final box = Hive.box(_settingsBox);
      await box.put(_themeModeKey, _serialize(mode));
    } catch (_) {}
  }

  static ThemeMode _parse(String s) {
    if (s == 'light') return ThemeMode.light;
    if (s == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  static String _serialize(ThemeMode m) {
    if (m == ThemeMode.light) return 'light';
    if (m == ThemeMode.dark) return 'dark';
    return 'system';
  }
}

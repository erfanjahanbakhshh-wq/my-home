import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide font choice stored locally on this device.
class FontSettings extends ChangeNotifier {
  static const _storageKey = 'app_font_family';
  static const options = <FontOption>[
    FontOption(id: 'Vazirmatn', title: 'وزیرمتن', description: 'خوانا و رسمی'),
    FontOption(id: 'Gandom', title: 'گندم', description: 'گرم و دوستانه'),
    FontOption(id: 'Sahel', title: 'ساحل', description: 'پررنگ و صمیمی'),
  ];

  String _family = options.first.id;
  String get family => _family;
  FontOption get selected => options.firstWhere(
        (option) => option.id == _family,
        orElse: () => options.first,
      );

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_storageKey);
    if (options.any((option) => option.id == stored)) {
      _family = stored!;
      notifyListeners();
    }
  }

  Future<void> select(String family) async {
    if (!options.any((option) => option.id == family) || family == _family) return;
    _family = family;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, family);
  }
}

class FontOption {
  const FontOption({required this.id, required this.title, required this.description});
  final String id;
  final String title;
  final String description;
}

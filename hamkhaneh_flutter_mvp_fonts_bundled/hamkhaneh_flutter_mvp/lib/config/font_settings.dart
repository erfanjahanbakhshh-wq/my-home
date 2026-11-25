/// فونت‌های محلی همراه برنامه. Sahel از WOFF به TTF تبدیل شده است.
class FontSettings {
  static const String defaultFamily = 'Vazirmatn';
  static const List<FontOption> options = [
    FontOption(label: 'وزیرمتن (متوسط)', family: 'Vazirmatn'),
    FontOption(label: 'گندم', family: 'Gandom'),
    FontOption(label: 'ساحل (پررنگ)', family: 'Sahel'),
  ];
}

class FontOption {
  const FontOption({required this.label, required this.family});
  final String label;
  final String family;
}

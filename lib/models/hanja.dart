class Hanja {
  final int id;
  final String hanja;
  final String hangul;
  final String meaning;
  final String pinyin;
  final String radical;
  final int strokeCount;
  final List<String> examples;

  Hanja({
    required this.id,
    required this.hanja,
    required this.hangul,
    required this.meaning,
    required this.pinyin,
    required this.radical,
    required this.strokeCount,
    required this.examples,
  });

  factory Hanja.fromJson(Map<String, dynamic> json) {
    List<String> exampleList = [];
    if (json['examples'] != null && json['examples'] is String && json['examples'].isNotEmpty) {
      exampleList = (json['examples'] as String).split(',').map((e) => e.trim()).toList();
    }
    return Hanja(
      id: int.parse(json['no'].toString()),
      hanja: json['h1'],
      hangul: json['h3'],
      meaning: json['h2'].trim(),
      pinyin: json['h4'] ?? '',
      radical: json['radical'] ?? 'N/A',
      strokeCount: int.tryParse(json['strokeCount'].toString()) ?? 0,
      examples: exampleList,
    );
  }
}
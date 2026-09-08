import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_result.dart';

class QuizResultStore {
  static const _key = 'quiz_results';

  static Future<List<QuizResult>> loadResults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => QuizResult.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveResult(QuizResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(json.encode(result.toJson()));
    await prefs.setStringList(_key, raw);
  }
}

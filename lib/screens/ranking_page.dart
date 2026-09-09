import 'package:flutter/material.dart';

import '../models/quiz_result.dart';
import '../services/quiz_result_store.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  static const _modes = ['meaning', 'fillBlank', 'order', 'matching'];
  static const _modeLabels = ['뜻', '빈칸', '순서', '짝'];

  late Future<List<QuizResult>> _resultsLoader;

  @override
  void initState() {
    super.initState();
    _resultsLoader = QuizResultStore.loadResults();
  }

  Future<void> _refresh() async {
    final results = await QuizResultStore.loadResults();
    if (!mounted) return;
    setState(() {
      _resultsLoader = Future.value(results);
    });
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}.${two(date.month)}.${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
  }

  static const _topN = 5;

  List<QuizResult> _sortedFor(List<QuizResult> all, String mode) {
    final filtered = all.where((r) => r.mode == mode).toList();
    filtered.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return b.date.compareTo(a.date);
    });
    return filtered.take(_topN).toList();
  }

  Widget _buildList(List<QuizResult> results) {
    if (results.isEmpty) {
      return const Center(
        child: Text(
          '아직 퀴즈 기록이 없습니다.\n퀴즈를 풀어보세요!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final result = results[index];
          final rank = index + 1;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: rank <= 3 ? Colors.amber : Colors.grey.shade300,
              child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text(
              '${result.score}점  (${result.correctCount}/${result.totalQuestions})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              result.elapsedSeconds != null
                  ? '${result.elapsedSeconds}초 · ${_formatDate(result.date)}'
                  : _formatDate(result.date),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _modes.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('랭킹'),
          bottom: TabBar(
            tabs: [for (final label in _modeLabels) Tab(text: label)],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: FutureBuilder<List<QuizResult>>(
          future: _resultsLoader,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = snapshot.data ?? [];
            return TabBarView(
              children: [for (final mode in _modes) _buildList(_sortedFor(all, mode))],
            );
          },
        ),
      ),
    );
  }
}

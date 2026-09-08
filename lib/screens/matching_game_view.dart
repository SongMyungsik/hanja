import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/hanja.dart';
import '../models/quiz_result.dart';
import '../services/quiz_result_store.dart';
import 'ranking_page.dart';

enum _Difficulty { easy, hard }

extension on _Difficulty {
  int get pairCount => this == _Difficulty.easy ? 6 : 8;
  int get timeLimitSeconds => this == _Difficulty.easy ? 60 : 90;
  int get crossAxisCount => 4;
  String get label =>
      this == _Difficulty.easy ? '쉬움 (3×4, 6쌍) · 60초' : '어려움 (4×4, 8쌍) · 90초';
}

class _MatchCard {
  final int pairId;
  final bool isHanjaFace;
  final String text;

  _MatchCard({required this.pairId, required this.isHanjaFace, required this.text});
}

class MatchingGameView extends StatefulWidget {
  final List<Hanja> hanjaList;

  const MatchingGameView({super.key, required this.hanjaList});

  @override
  State<MatchingGameView> createState() => _MatchingGameViewState();
}

class _MatchingGameViewState extends State<MatchingGameView> {
  final Random _random = Random();
  Timer? _timer;

  _Difficulty? _difficulty;
  List<_MatchCard> _cards = [];
  final Set<int> _matchedPairIds = {};
  final List<int> _flipped = [];
  int _remainingSeconds = 0;
  int _mistakes = 0;
  bool _locked = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame(_Difficulty difficulty) {
    final pool = List<Hanja>.from(widget.hanjaList)..shuffle(_random);
    final chosen = pool.take(difficulty.pairCount).toList();
    final cards = <_MatchCard>[];
    for (final h in chosen) {
      cards.add(_MatchCard(pairId: h.id, isHanjaFace: true, text: h.hanja));
      cards.add(_MatchCard(pairId: h.id, isHanjaFace: false, text: '${h.meaning} (${h.hangul})'));
    }
    cards.shuffle(_random);

    _timer?.cancel();
    setState(() {
      _difficulty = difficulty;
      _cards = cards;
      _matchedPairIds.clear();
      _flipped.clear();
      _mistakes = 0;
      _remainingSeconds = difficulty.timeLimitSeconds;
      _locked = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        _finishGame(completed: false);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  bool _isMatched(int index) => _matchedPairIds.contains(_cards[index].pairId);

  void _tapCard(int index) {
    if (_locked) return;
    if (_isMatched(index)) return;
    if (_flipped.contains(index)) return;
    if (_flipped.length >= 2) return;

    setState(() => _flipped.add(index));
    if (_flipped.length < 2) return;

    _locked = true;
    final a = _cards[_flipped[0]];
    final b = _cards[_flipped[1]];
    if (a.pairId == b.pairId) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        setState(() {
          _matchedPairIds.add(a.pairId);
          _flipped.clear();
          _locked = false;
        });
        if (_matchedPairIds.length == _difficulty!.pairCount) {
          _timer?.cancel();
          _finishGame(completed: true);
        }
      });
    } else {
      _mistakes++;
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _flipped.clear();
          _locked = false;
        });
      });
    }
  }

  Future<void> _finishGame({required bool completed}) async {
    final difficulty = _difficulty!;
    final elapsed = difficulty.timeLimitSeconds - _remainingSeconds;
    final result = QuizResult(
      date: DateTime.now(),
      correctCount: _matchedPairIds.length,
      totalQuestions: difficulty.pairCount,
      mode: 'matching',
      elapsedSeconds: elapsed,
    );
    await QuizResultStore.saveResult(result);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(completed ? '완료!' : '시간 종료'),
        content: Text(
          completed
              ? '${difficulty.pairCount}쌍을 $elapsed초만에 모두 맞췄습니다!\n실수: $_mistakes회'
              : '${_matchedPairIds.length}/${difficulty.pairCount}쌍을 맞췄습니다.\n실수: $_mistakes회',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _difficulty = null);
            },
            child: const Text('다시 하기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RankingPage()));
            },
            child: const Text('랭킹 보기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _difficulty == null ? _buildDifficultySelector() : _buildGameBoard();
  }

  Widget _buildDifficultySelector() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('카드 짝맞추기', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          '한자 카드와 뜻 카드를 뒤집어 짝을 맞춰보세요',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => _startGame(_Difficulty.easy),
          child: Text(_Difficulty.easy.label),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => _startGame(_Difficulty.hard),
          child: Text(_Difficulty.hard.label),
        ),
      ],
    );
  }

  Widget _buildGameBoard() {
    final difficulty = _difficulty!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, color: _remainingSeconds <= 10 ? Colors.red : Colors.indigo),
            const SizedBox(width: 6),
            Text(
              '$_remainingSeconds초',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _remainingSeconds <= 10 ? Colors.red : Colors.indigo),
            ),
            const SizedBox(width: 20),
            Text('${_matchedPairIds.length}/${difficulty.pairCount}쌍', style: const TextStyle(fontSize: 16, color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: min(360.0, MediaQuery.sizeOf(context).width - 40),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: difficulty.crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: _cards.length,
            itemBuilder: (context, index) {
              final card = _cards[index];
              final isMatched = _isMatched(index);
              final isFaceUp = isMatched || _flipped.contains(index);
              return GestureDetector(
                onTap: () => _tapCard(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isMatched ? Colors.green.shade100 : (isFaceUp ? Colors.indigo.shade50 : Colors.indigo),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isMatched ? Colors.green : Colors.indigo.shade200),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(4),
                  child: isFaceUp
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            card.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: card.isHanjaFace ? 28 : 14,
                              fontWeight: FontWeight.bold,
                              color: isMatched ? Colors.green.shade800 : Colors.black87,
                            ),
                          ),
                        )
                      : const Icon(Icons.help_outline, color: Colors.white70),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

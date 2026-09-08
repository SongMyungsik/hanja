import 'dart:math';
import 'package:flutter/material.dart';
import '../models/hanja.dart';
import '../models/quiz_result.dart';
import '../services/quiz_result_store.dart';
import 'ranking_page.dart';

class QuizPage extends StatefulWidget {
  final List<Hanja> hanjaList;
  const QuizPage({super.key, required this.hanjaList});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  static const int questionsPerRound = 10;

  Hanja? currentHanja;
  List<Hanja> options = [];
  Hanja? selectedOption;
  bool? isCorrect;
  int correctAnswers = 0;
  int incorrectAnswers = 0;
  int questionNumber = 0;

  @override
  void initState() {
    super.initState();
    _generateQuiz();
  }

  void _startNewRound() {
    correctAnswers = 0;
    incorrectAnswers = 0;
    questionNumber = 0;
    _generateQuiz();
  }

  void _generateQuiz() {
    setState(() {
      selectedOption = null;
      isCorrect = null;
      questionNumber++;
      final random = Random();
      currentHanja = widget.hanjaList[random.nextInt(widget.hanjaList.length)];
      options = [currentHanja!];
      while (options.length < 4) {
        final randomHanja = widget.hanjaList[random.nextInt(widget.hanjaList.length)];
        if (!options.any((h) => h.id == randomHanja.id)) {
          options.add(randomHanja);
        }
      }
      options.shuffle();
    });
  }

  void _onNextPressed() {
    if (questionNumber >= questionsPerRound) {
      _finishRound();
    } else {
      _generateQuiz();
    }
  }

  Future<void> _finishRound() async {
    final result = QuizResult(
      date: DateTime.now(),
      correctCount: correctAnswers,
      totalQuestions: questionsPerRound,
    );
    await QuizResultStore.saveResult(result);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('퀴즈 완료'),
        content: Text('정답 $correctAnswers / $questionsPerRound\n점수: ${result.score}점'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewRound();
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

  void _checkAnswer(Hanja option) {
    setState(() {
      selectedOption = option;
      isCorrect = (option.id == currentHanja!.id);
      if (isCorrect!) {
        correctAnswers++;
      } else {
        incorrectAnswers++;
      }
    });
  }

  Color _getOptionColor(Hanja option) {
    if (selectedOption == null) return Colors.grey.shade200;
    if (option.id == currentHanja!.id) return Colors.green;
    if (option.id == selectedOption!.id && isCorrect == false) return Colors.red;
    return Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    if (currentHanja == null) {
      return const Scaffold(appBar: null, body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('한자 퀴즈')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '문제 $questionNumber / $questionsPerRound',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            // --- [수정] Stack 위젯을 사용하여 번호 표시 ---
            Stack(
              alignment: Alignment.center,
              children: [
                // 기존의 큰 한자
                Text(
                  currentHanja!.hanja,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 120, fontWeight: FontWeight.bold),
                ),
                // 왼쪽 위에 작게 표시되는 번호
                Positioned(
                  top: 0,
                  left: 20, // 중앙 정렬된 Stack 안에서 위치 조정
                  child: Text(
                    currentHanja!.id.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            // -----------------------------------------
            const Spacer(),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 3.5,
              children: options.map((option) {
                return ElevatedButton(
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.all<Color>(Colors.black87),
                    backgroundColor: WidgetStateProperty.all<Color?>(_getOptionColor(option)),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  onPressed: selectedOption == null ? () => _checkAnswer(option) : null,
                  child: Text('${option.meaning} (${option.hangul})', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                );
              }).toList(),
            ),
            const Spacer(),
            if (selectedOption != null)
              Column(children: [
                Text(isCorrect! ? '정답입니다!' : '오답입니다!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isCorrect! ? Colors.green : Colors.red)),
                const SizedBox(height: 12),
                Text('정답: $correctAnswers / 오답: $incorrectAnswers', style: const TextStyle(fontSize: 16, color: Colors.black54)),
              ])
            else
              const SizedBox(height: 62),
            const Spacer(),
            if (selectedOption != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _onNextPressed,
                child: Text(
                  questionNumber >= questionsPerRound ? '결과 보기' : '다음 문제',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
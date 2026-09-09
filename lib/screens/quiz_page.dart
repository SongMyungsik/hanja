import 'dart:math';
import 'package:flutter/material.dart';
import '../models/hanja.dart';
import '../models/quiz_result.dart';
import '../services/quiz_result_store.dart';
import 'ranking_page.dart';
import 'matching_game_view.dart';

enum QuizMode { meaning, fillBlank, order, matching }

extension _QuizModeX on QuizMode {
  String get label => switch (this) {
        QuizMode.meaning => '뜻',
        QuizMode.fillBlank => '빈칸',
        QuizMode.order => '순서',
        QuizMode.matching => '짝',
      };

  String get storageKey => switch (this) {
        QuizMode.meaning => 'meaning',
        QuizMode.fillBlank => 'fillBlank',
        QuizMode.order => 'order',
        QuizMode.matching => 'matching',
      };
}

class QuizPage extends StatefulWidget {
  final List<Hanja> hanjaList;
  const QuizPage({super.key, required this.hanjaList});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  static const int questionsPerRound = 10;
  final Random _random = Random();

  late final List<Hanja> _sortedHanjas;
  late final List<List<Hanja>> _phrases;

  QuizMode _mode = QuizMode.meaning;
  int correctAnswers = 0;
  int incorrectAnswers = 0;
  int questionNumber = 0;
  bool _answered = false;

  // '뜻 맞추기' 모드 상태
  Hanja? currentHanja;
  List<Hanja> meaningOptions = [];
  Hanja? selectedMeaningOption;

  // '빈칸 채우기' 모드 상태
  List<Hanja> currentPhrase = [];
  int blankIndex = 0;
  List<Hanja> fillOptions = [];
  Hanja? selectedFillOption;

  // '순서 배열' 모드 상태
  List<Hanja> orderPhrase = [];
  List<Hanja?> orderSlots = [];
  List<Hanja> orderBank = [];
  List<Hanja> orderMeaningOrder = [];
  bool? orderCorrect;

  @override
  void initState() {
    super.initState();
    _sortedHanjas = List<Hanja>.from(widget.hanjaList)..sort((a, b) => a.id.compareTo(b.id));
    _phrases = [
      for (var i = 0; i + 3 < _sortedHanjas.length; i += 4) _sortedHanjas.sublist(i, i + 4),
    ];
    _startNewRound();
  }

  void _startNewRound() {
    correctAnswers = 0;
    incorrectAnswers = 0;
    questionNumber = 0;
    _generateQuestion();
  }

  void _changeMode(QuizMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    _startNewRound();
  }

  void _generateQuestion() {
    if (_mode == QuizMode.matching) return;
    setState(() {
      _answered = false;
      questionNumber++;
      switch (_mode) {
        case QuizMode.meaning:
          _generateMeaningQuestion();
        case QuizMode.fillBlank:
          _generateFillBlankQuestion();
        case QuizMode.order:
          _generateOrderQuestion();
        case QuizMode.matching:
          break;
      }
    });
  }

  void _generateMeaningQuestion() {
    selectedMeaningOption = null;
    currentHanja = widget.hanjaList[_random.nextInt(widget.hanjaList.length)];
    meaningOptions = [currentHanja!];
    while (meaningOptions.length < 4) {
      final candidate = widget.hanjaList[_random.nextInt(widget.hanjaList.length)];
      if (!meaningOptions.any((h) => h.id == candidate.id)) {
        meaningOptions.add(candidate);
      }
    }
    meaningOptions.shuffle(_random);
  }

  void _generateFillBlankQuestion() {
    selectedFillOption = null;
    currentPhrase = _phrases[_random.nextInt(_phrases.length)];
    blankIndex = _random.nextInt(currentPhrase.length);
    final answer = currentPhrase[blankIndex];
    final phraseIds = currentPhrase.map((h) => h.id).toSet();
    fillOptions = [answer];
    while (fillOptions.length < 4) {
      final candidate = _sortedHanjas[_random.nextInt(_sortedHanjas.length)];
      if (!phraseIds.contains(candidate.id) && !fillOptions.any((h) => h.id == candidate.id)) {
        fillOptions.add(candidate);
      }
    }
    fillOptions.shuffle(_random);
  }

  void _generateOrderQuestion() {
    orderCorrect = null;
    orderPhrase = _phrases[_random.nextInt(_phrases.length)];
    orderSlots = List<Hanja?>.filled(orderPhrase.length, null);
    orderBank = List<Hanja>.from(orderPhrase)..shuffle(_random);
    while (_sameOrder(orderBank, orderPhrase)) {
      orderBank.shuffle(_random);
    }
    orderMeaningOrder = List<Hanja>.from(orderBank);
  }

  bool _sameOrder(List<Hanja> a, List<Hanja> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _recordAnswer(bool correct) {
    _answered = true;
    if (correct) {
      correctAnswers++;
    } else {
      incorrectAnswers++;
    }
  }

  void _selectMeaningOption(Hanja option) {
    if (_answered) return;
    setState(() {
      selectedMeaningOption = option;
      _recordAnswer(option.id == currentHanja!.id);
    });
  }

  void _selectFillOption(Hanja option) {
    if (_answered) return;
    setState(() {
      selectedFillOption = option;
      _recordAnswer(option.id == currentPhrase[blankIndex].id);
    });
  }

  void _tapBankTile(Hanja tile) {
    if (_answered) return;
    final emptyIndex = orderSlots.indexOf(null);
    if (emptyIndex == -1) return;
    setState(() {
      orderSlots[emptyIndex] = tile;
      orderBank.remove(tile);
      if (!orderSlots.contains(null)) {
        final correct = _sameOrder(orderSlots.cast<Hanja>(), orderPhrase);
        orderCorrect = correct;
        _recordAnswer(correct);
      }
    });
  }

  void _tapSlot(int index) {
    if (_answered) return;
    final tile = orderSlots[index];
    if (tile == null) return;
    setState(() {
      orderSlots[index] = null;
      orderBank.add(tile);
    });
  }

  void _onNextPressed() {
    if (questionNumber >= questionsPerRound) {
      _finishRound();
    } else {
      _generateQuestion();
    }
  }

  Future<void> _finishRound() async {
    final result = QuizResult(
      date: DateTime.now(),
      correctCount: correctAnswers,
      totalQuestions: questionsPerRound,
      mode: _mode.storageKey,
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

  bool get _isCurrentCorrect => switch (_mode) {
        QuizMode.meaning => selectedMeaningOption?.id == currentHanja?.id,
        QuizMode.fillBlank => selectedFillOption?.id == currentPhrase[blankIndex].id,
        QuizMode.order => orderCorrect ?? false,
        QuizMode.matching => false,
      };

  Color _choiceColor({required bool isCorrectOption, required bool isSelected}) {
    if (!_answered) return Colors.grey.shade200;
    if (isCorrectOption) return Colors.green;
    if (isSelected) return Colors.red;
    return Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('한자 퀴즈')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Center(child: _buildModeSelector()),
                    const SizedBox(height: 12),
                    if (_mode != QuizMode.matching)
                      Text(
                        '문제 $questionNumber / $questionsPerRound',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 16),
                    _buildQuizBody(),
                    if (_mode != QuizMode.matching && _answered) ...[
                      const SizedBox(height: 16),
                      Text(
                        _isCurrentCorrect ? '정답입니다!' : '오답입니다!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _isCurrentCorrect ? Colors.green : Colors.red),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '정답: $correctAnswers / 오답: $incorrectAnswers',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: _onNextPressed,
                        child: Text(
                          questionNumber >= questionsPerRound ? '결과 보기' : '다음 문제',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return SegmentedButton<QuizMode>(
      showSelectedIcon: false,
      segments: [
        for (final mode in QuizMode.values) ButtonSegment(value: mode, label: Text(mode.label)),
      ],
      selected: {_mode},
      onSelectionChanged: (selection) => _changeMode(selection.first),
    );
  }

  Widget _buildQuizBody() {
    return switch (_mode) {
      QuizMode.meaning => _buildMeaningBody(),
      QuizMode.fillBlank => _buildFillBlankBody(),
      QuizMode.order => _buildOrderBody(),
      QuizMode.matching => MatchingGameView(hanjaList: widget.hanjaList),
    };
  }

  Widget _buildMeaningBody() {
    if (currentHanja == null) return const CircularProgressIndicator();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Text(currentHanja!.hanja, textAlign: TextAlign.center, style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold)),
            Positioned(
              top: 0,
              left: 12,
              child: Text(currentHanja!.id.toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: min(300.0, MediaQuery.sizeOf(context).width - 40),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.2,
            children: meaningOptions.map((option) {
              final isCorrectOption = option.id == currentHanja!.id;
              final isSelected = selectedMeaningOption?.id == option.id;
              return ElevatedButton(
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all<Color>(Colors.black87),
                  backgroundColor: WidgetStateProperty.all<Color?>(_choiceColor(isCorrectOption: isCorrectOption, isSelected: isSelected)),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
                onPressed: _answered ? null : () => _selectMeaningOption(option),
                child: Text('${option.meaning} (${option.hangul})', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFillBlankBody() {
    if (currentPhrase.isEmpty) return const CircularProgressIndicator();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('구절 속 빈칸에 들어갈 한자를 고르세요', style: TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < currentPhrase.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: i == blankIndex ? Colors.indigo : Colors.grey.shade300, width: i == blankIndex ? 2 : 1),
                  borderRadius: BorderRadius.circular(8),
                  color: i == blankIndex ? Colors.indigo.shade50 : null,
                ),
                child: Text(
                  i == blankIndex && !_answered ? '?' : currentPhrase[i].hanja,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: i == blankIndex ? Colors.indigo : Colors.black87),
                ),
              ),
            ],
          ],
        ),
        if (_answered) ...[
          const SizedBox(height: 8),
          _buildPhraseMeaningHint(currentPhrase),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: min(280.0, MediaQuery.sizeOf(context).width - 40),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: fillOptions.map((option) {
              final isCorrectOption = option.id == currentPhrase[blankIndex].id;
              final isSelected = selectedFillOption?.id == option.id;
              return ElevatedButton(
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all<Color>(Colors.black87),
                  backgroundColor: WidgetStateProperty.all<Color?>(_choiceColor(isCorrectOption: isCorrectOption, isSelected: isSelected)),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
                onPressed: _answered ? null : () => _selectFillOption(option),
                child: Text('${option.hanja} (${option.hangul})', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderBody() {
    if (orderPhrase.isEmpty) return const CircularProgressIndicator();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('한자를 순서대로 탭하여 배치하세요', style: TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < orderSlots.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _tapSlot(i),
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _answered
                          ? (orderSlots[i]?.id == orderPhrase[i].id ? Colors.green : Colors.red)
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: orderSlots[i] != null ? Colors.indigo.shade50 : Colors.grey.shade100,
                  ),
                  child: Text(orderSlots[i]?.hanja ?? '', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        _buildPhraseMeaningHint(_answered ? orderPhrase : orderMeaningOrder),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: orderBank.map((tile) {
            return GestureDetector(
              onTap: _answered ? null : () => _tapBankTile(tile),
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                ),
                child: Text(tile.hanja, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        ),
        if (_answered && orderCorrect == false) ...[
          const SizedBox(height: 14),
          Text(
            '정답: ${orderPhrase.map((h) => h.hanja).join(' ')}',
            style: const TextStyle(fontSize: 15, color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }

  Widget _buildPhraseMeaningHint(List<Hanja> chars) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 2,
      children: chars
          .map((h) => Text(
                '${h.hanja}(${h.hangul}) ${h.meaning}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ))
          .toList(),
    );
  }
}

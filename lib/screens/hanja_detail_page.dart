import 'package:flutter/material.dart';
import '../models/hanja.dart';
import '../widgets/hanzi_writer_view.dart';

class HanjaDetailPage extends StatefulWidget {
  final List<Hanja> hanjaList;
  final int initialIndex;

  const HanjaDetailPage({super.key, required this.hanjaList, required this.initialIndex});

  @override
  State<HanjaDetailPage> createState() => _HanjaDetailPageState();
}

class _HanjaDetailPageState extends State<HanjaDetailPage> {
  late int currentIndex;
  Hanja get currentHanja => widget.hanjaList[currentIndex];

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  void _goToPrevious() {
    if (currentIndex > 0) setState(() => currentIndex--);
  }

  void _goToNext() {
    if (currentIndex < widget.hanjaList.length - 1) setState(() => currentIndex++);
  }
  
  // 스타일링을 위한 헬퍼 위젯
  Widget _buildLabelText(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)));
  Widget _buildValueText(String text, {Color color = Colors.black}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text(text, style: TextStyle(fontSize: 16, color: color)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${currentHanja.hanja} (${currentHanja.hangul})')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(elevation: 4, child: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: [
              Stack(children: [
                Positioned(top: 0, left: 0, child: Text('${currentHanja.id}', style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold))),
                Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(icon: const Icon(Icons.arrow_left, size: 40), onPressed: _goToPrevious),
                  Column(children: [Text(currentHanja.hanja, style: const TextStyle(fontSize: 100)), Text(currentHanja.hangul, style: const TextStyle(fontSize: 40))]),
                  IconButton(icon: const Icon(Icons.arrow_right, size: 40), onPressed: _goToNext),
                ])),
              ]),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [_buildLabelText('뜻 / 음'), _buildLabelText('부수'), _buildLabelText('총획'), _buildLabelText('Pinyin')]),
                const SizedBox(width: 24),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildValueText(': ${currentHanja.meaning} ... ${currentHanja.hangul}'), _buildValueText(': ${currentHanja.radical}'), _buildValueText(': ${currentHanja.strokeCount}획'), _buildValueText(': ${currentHanja.pinyin}', color: Colors.redAccent)]),
              ]),
            ]))),
            const SizedBox(height: 20),
            const Text('획순 / 쓰기 연습', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Center(
              child: HanziWriterView(
                key: ValueKey(currentHanja.id),
                character: currentHanja.hanja,
              ),
            ),
            const SizedBox(height: 20),
            const Text('사용 예시', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (currentHanja.examples.isNotEmpty)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: currentHanja.examples.map((example) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text('• $example', style: const TextStyle(fontSize: 16)))).toList())
            else
              const Text('등록된 사용 예시가 없습니다.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
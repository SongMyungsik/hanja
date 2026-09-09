import 'package:flutter/material.dart';
import '../models/hanja.dart';
import 'hanja_detail_page.dart';

class HanjaListPage extends StatefulWidget {
  final List<Hanja> allHanjas;
  final Map<int, String> phraseMeanings;
  const HanjaListPage({super.key, required this.allHanjas, required this.phraseMeanings});

  @override
  State<HanjaListPage> createState() => _HanjaListPageState();
}

class _HanjaListPageState extends State<HanjaListPage> {
  List<Hanja> filteredHanjas = [];
  final TextEditingController _hangulSearchController = TextEditingController();
  final TextEditingController _meaningSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredHanjas = widget.allHanjas;
    _hangulSearchController.addListener(_filterHanjas);
    _meaningSearchController.addListener(_filterHanjas);
  }

  @override
  void dispose() {
    _hangulSearchController.removeListener(_filterHanjas);
    _meaningSearchController.removeListener(_filterHanjas);
    _hangulSearchController.dispose();
    _meaningSearchController.dispose();
    super.dispose();
  }

  bool get _isFiltering => _hangulSearchController.text.isNotEmpty || _meaningSearchController.text.isNotEmpty;

  void _filterHanjas() {
    final hangulQuery = _hangulSearchController.text.toLowerCase();
    final meaningQuery = _meaningSearchController.text.toLowerCase();

    setState(() {
      filteredHanjas = widget.allHanjas.where((hanja) {
        final hangulMatch = hangulQuery.isEmpty || hanja.hangul.toLowerCase().contains(hangulQuery) || hanja.hanja.contains(hangulQuery);
        final meaningMatch = meaningQuery.isEmpty || hanja.meaning.toLowerCase().contains(meaningQuery);
        return hangulMatch && meaningMatch;
      }).toList();
    });
  }

  Widget _buildCard(Hanja hanja) {
    Color cardColor = hanja.strokeCount <= 5 ? Colors.blue[50]! : (hanja.strokeCount <= 10 ? Colors.green[50]! : Colors.orange[50]!);

    return GestureDetector(
      onTap: () {
        // 상세 페이지에서 좌우 이동을 위해 전체 리스트에서의 인덱스를 찾아 전달
        int originalIndex = widget.allHanjas.indexWhere((h) => h.id == hanja.id);
        Navigator.push(context, MaterialPageRoute(builder: (context) => HanjaDetailPage(hanjaList: widget.allHanjas, initialIndex: originalIndex)));
      },
      child: Card(
        color: cardColor,
        elevation: 2,
        child: Stack(
          children: [
            Positioned(top: 4, left: 6, child: Text('${hanja.id}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700))),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(hanja.hanja, style: const TextStyle(fontSize: 42, height: 1.0)),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.0),
                      children: <TextSpan>[
                        TextSpan(text: '${hanja.hangul} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: hanja.pinyin, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showCaptions = !_isFiltering;
    final rowCount = (filteredHanjas.length / 4).ceil();

    return Scaffold(
      appBar: AppBar(title: const Text('천자문 목록')),
      body: Column(
        children: [
          // 검색 필드
          Row(
            children: [
              Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(16, 16, 8, 16), child: TextField(controller: _hangulSearchController, decoration: InputDecoration(prefixIcon: const Icon(Icons.volume_up_outlined), labelText: '음으로 검색', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)), suffixIcon: _hangulSearchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () {_hangulSearchController.clear();}) : null)))),
              Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(8, 16, 16, 16), child: TextField(controller: _meaningSearchController, decoration: InputDecoration(prefixIcon: const Icon(Icons.lightbulb_outlined), labelText: '뜻으로 검색', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)), suffixIcon: _meaningSearchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () {_meaningSearchController.clear();}) : null)))),
            ],
          ),
          // 한자 목록 (4글자씩 한 구절)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: rowCount,
              itemBuilder: (context, rowIndex) {
                final start = rowIndex * 4;
                final end = (start + 4 > filteredHanjas.length) ? filteredHanjas.length : start + 4;
                final rowHanjas = filteredHanjas.sublist(start, end);
                final meaning = showCaptions ? widget.phraseMeanings[rowHanjas.first.id] : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < rowHanjas.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8.0),
                            Expanded(
                              child: AspectRatio(
                                aspectRatio: 0.8,
                                child: _buildCard(rowHanjas[i]),
                              ),
                            ),
                          ],
                          if (rowHanjas.length < 4) Expanded(flex: 4 - rowHanjas.length, child: const SizedBox.shrink()),
                        ],
                      ),
                      if (meaning != null && meaning.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                          child: Text(
                            meaning.trim(),
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

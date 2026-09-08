import 'package:flutter/material.dart';
import '../models/hanja.dart';
import 'hanja_detail_page.dart';

class HanjaListPage extends StatefulWidget {
  final List<Hanja> allHanjas;
  const HanjaListPage({super.key, required this.allHanjas});

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

  @override
  Widget build(BuildContext context) {
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
          // 한자 그리드 뷰
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8.0, mainAxisSpacing: 8.0, childAspectRatio: 0.8),
              itemCount: filteredHanjas.length,
              itemBuilder: (context, index) {
                final hanja = filteredHanjas[index];
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
                        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(hanja.hanja, style: const TextStyle(fontSize: 42)),
                          const SizedBox(height: 4),
                          RichText(text: TextSpan(style: const TextStyle(fontSize: 14, color: Colors.black87), children: <TextSpan>[TextSpan(text: '${hanja.hangul} ', style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: hanja.pinyin, style: const TextStyle(color: Colors.red))]), overflow: TextOverflow.ellipsis),
                        ])),
                      ],
                    ),
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
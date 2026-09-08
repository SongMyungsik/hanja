import 'package:flutter/material.dart';

class HanziWriterView extends StatelessWidget {
  final String character;

  const HanziWriterView({super.key, required this.character});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '획순 애니메이션과 직접 쓰기 기능은\n웹 버전에서만 사용할 수 있습니다.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}

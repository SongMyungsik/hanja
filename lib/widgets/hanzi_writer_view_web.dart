import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class HanziWriterView extends StatefulWidget {
  final String character;

  const HanziWriterView({super.key, required this.character});

  @override
  State<HanziWriterView> createState() => _HanziWriterViewState();
}

class _HanziWriterViewState extends State<HanziWriterView> {
  static const double _size = 260;
  static int _viewCounter = 0;

  late final String _viewType;
  JSObject? _writer;
  String? _quizFeedback;

  @override
  void initState() {
    super.initState();
    _viewCounter++;
    _viewType = 'hanzi-writer-view-$_viewCounter';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final div = web.HTMLDivElement()..id = _viewType;
      div.style
        ..setProperty('width', '${_size}px')
        ..setProperty('height', '${_size}px');

      final hanziWriterCtor = globalContext.getProperty('HanziWriter'.toJS);
      if (hanziWriterCtor != null) {
        final options = JSObject()
          ..setProperty('width'.toJS, _size.toJS)
          ..setProperty('height'.toJS, _size.toJS)
          ..setProperty('padding'.toJS, 8.toJS)
          ..setProperty('showOutline'.toJS, true.toJS)
          ..setProperty('strokeAnimationSpeed'.toJS, 1.toJS)
          ..setProperty('delayBetweenStrokes'.toJS, 300.toJS);

        _writer = (hanziWriterCtor as JSObject).callMethodVarArgs(
          'create'.toJS,
          [div, widget.character.toJS, options],
        );
      }
      return div;
    });
  }

  void _playAnimation() {
    final writer = _writer;
    if (writer == null) return;
    setState(() => _quizFeedback = null);
    writer.callMethodVarArgs('animateCharacter'.toJS);
  }

  void _startQuiz() {
    final writer = _writer;
    if (writer == null) return;
    setState(() => _quizFeedback = null);

    void onComplete(JSObject summary) {
      final totalMistakes =
          (summary.getProperty('totalMistakes'.toJS) as JSNumber?)?.toDartInt ?? 0;
      if (!mounted) return;
      setState(() {
        _quizFeedback = totalMistakes == 0
            ? '완벽해요! 실수 없이 완성했습니다 🎉'
            : '완성했습니다! 실수 $totalMistakes회';
      });
    }

    final options = JSObject()..setProperty('onComplete'.toJS, onComplete.toJS);
    writer.callMethodVarArgs('quiz'.toJS, [options]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: _size,
          height: _size,
          child: HtmlElementView(viewType: _viewType),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _playAnimation,
              icon: const Icon(Icons.play_arrow),
              label: const Text('획순 보기'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _startQuiz,
              icon: const Icon(Icons.edit),
              label: const Text('직접 써보기'),
            ),
          ],
        ),
        if (_quizFeedback != null) ...[
          const SizedBox(height: 8),
          Text(_quizFeedback!, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }
}

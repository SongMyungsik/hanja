import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

class HanziWriterView extends StatefulWidget {
  final String character;
  // 퀴즈(직접 써보기) 진행 중인지 알려준다. 상위 화면이 이 값으로 스크롤을
  // 잠그면 필기 드래그가 스크롤로 새는 것을 막을 수 있다. 획을 그을 때마다가
  // 아니라 퀴즈 시작/종료 시점에만 한 번씩 호출되므로, 필기 도중 리빌드가
  // WebView의 터치 상태를 깨뜨리는 문제가 없다.
  final ValueChanged<bool>? onQuizSessionChanged;

  const HanziWriterView({super.key, required this.character, this.onQuizSessionChanged});

  @override
  State<HanziWriterView> createState() => _HanziWriterViewState();
}

class _HanziWriterViewState extends State<HanziWriterView> {
  static const double _size = 220;

  // webview_flutter는 안드로이드/iOS만 공식 지원한다. 데스크톱(Windows 등)에서는
  // 대체 안내 위젯을 보여준다.
  static bool get _isSupportedPlatform => Platform.isAndroid || Platform.isIOS;

  WebViewController? _controller;
  bool _pageReady = false;
  String? _quizFeedback;
  final GlobalKey _feedbackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (!_isSupportedPlatform) return;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel('FlutterBridge', onMessageReceived: _onBridgeMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _pageReady = true;
            _loadCharacter();
          },
        ),
      )
      ..loadFlutterAsset('assets/hanzi_writer/index.html');

    _controller = controller;
  }

  @override
  void dispose() {
    widget.onQuizSessionChanged?.call(false);
    super.dispose();
  }

  void _onBridgeMessage(JavaScriptMessage message) {
    if (!mounted) return;
    Map<String, dynamic> data;
    try {
      data = jsonDecode(message.message) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    switch (data['event']) {
      case 'quizComplete':
        final totalMistakes = (data['totalMistakes'] as num?)?.toInt() ?? 0;
        widget.onQuizSessionChanged?.call(false);
        setState(() {
          _quizFeedback = totalMistakes == 0
              ? '완벽해요! 실수 없이 완성했습니다 🎉'
              : '완성했습니다! 실수 $totalMistakes회';
        });
        _showFeedback();
      case 'dataUnavailable':
        setState(() {
          _quizFeedback = '이 글자는 획순 데이터가 없습니다.';
        });
        _showFeedback();
      case 'requestCharData':
        final char = data['char'] as String?;
        if (char != null) _deliverCharData(char);
    }
  }

  // 메시지가 화면 밖에 있으면 보이는 위치까지 스크롤한다.
  void _showFeedback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedbackContext = _feedbackKey.currentContext;
      if (feedbackContext == null) return;
      Scrollable.ensureVisible(
        feedbackContext,
        duration: const Duration(milliseconds: 250),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  // file:// 로 로드된 페이지는 fetch()로 로컬 자산을 읽을 수 없으므로,
  // 획순 데이터를 rootBundle로 직접 읽어 JS 쪽에 문자열로 전달한다.
  Future<void> _deliverCharData(String char) async {
    final controller = _controller;
    if (controller == null) return;
    final codepoint = char.runes.first.toRadixString(16);
    String? jsonContent;
    try {
      jsonContent = await rootBundle.loadString('assets/hanzi_writer/data/$codepoint.json');
    } catch (_) {
      jsonContent = null;
    }
    if (!mounted) return;
    final jsArg = jsonContent == null ? 'null' : jsonEncode(jsonContent);
    controller.runJavaScript('deliverCharData(${jsonEncode(char)}, $jsArg);');
  }

  void _loadCharacter() {
    final controller = _controller;
    if (controller == null || !_pageReady) return;
    controller.runJavaScript('loadCharacter(${jsonEncode(widget.character)});');
  }

  void _playAnimation() {
    final controller = _controller;
    if (controller == null) return;
    widget.onQuizSessionChanged?.call(false);
    setState(() => _quizFeedback = null);
    controller.runJavaScript('playAnimation();');
  }

  void _startQuiz() {
    final controller = _controller;
    if (controller == null) return;
    widget.onQuizSessionChanged?.call(true);
    setState(() => _quizFeedback = null);
    controller.runJavaScript('startQuiz();');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupportedPlatform) {
      return Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '획순 애니메이션과 직접 쓰기 기능은\n이 플랫폼에서는 사용할 수 없습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: _size,
          height: _size,
          child: WebViewWidget(controller: _controller!),
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
        // 메시지가 없을 때도 자리를 비워 두어, 완료 시 레이아웃이 밀리지 않게 한다.
        Padding(
          key: _feedbackKey,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(_quizFeedback ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'models/hanja.dart';
import 'screens/splash_screen.dart';
import 'screens/hanja_list_page.dart';
import 'screens/hanja_detail_page.dart';
import 'screens/quiz_page.dart';
import 'screens/ranking_page.dart';

void main() {
  runApp(const MyApp());
}

// 앱 루트 위젯
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '천자문 앱',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const SplashScreen(), // 시작 화면으로 앱 시작
    );
  }
}

// BottomNavigationBar와 페이지들을 포함하는 메인 화면
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late Future<List<Hanja>> _hanjaLoader;
  List<Widget> _widgetOptions = [];

  // 한자 데이터를 한 번만 로드
  Future<List<Hanja>> _loadHanjaData() async {
    final String jsonString = await rootBundle.loadString('assets/cheonjamun.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Hanja.fromJson(json)).toList();
  }

  @override
  void initState() {
    super.initState();
    _hanjaLoader = _loadHanjaData();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Hanja>>(
      future: _hanjaLoader,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('데이터 로딩 실패: ${snapshot.error}')));
        }
        if (snapshot.hasData) {
          final allHanjas = snapshot.data!;

          // 로드된 데이터로 페이지들을 초기화
          _widgetOptions = <Widget>[
            HanjaListPage(allHanjas: allHanjas),
            // '상세' 탭은 기본적으로 첫 번째 한자를 보여줌
            HanjaDetailPage(hanjaList: allHanjas, initialIndex: 0),
            QuizPage(hanjaList: allHanjas),
            const RankingPage(),
          ];

          return Scaffold(
            body: Center(
              child: _widgetOptions.elementAt(_selectedIndex),
            ),
            bottomNavigationBar: BottomNavigationBar( // 하단 네비게이션 바 [[4](https://nayotutorial.tistory.com/44)]
              type: BottomNavigationBarType.fixed,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: '목록'),
                BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: '상세'),
                BottomNavigationBarItem(icon: Icon(Icons.quiz_outlined), label: '퀴즈'),
                BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: '랭킹'),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.indigo,
              onTap: _onItemTapped,
            ),
          );
        }
        return const Scaffold(body: Center(child: Text('준비 중...')));
      },
    );
  }
}
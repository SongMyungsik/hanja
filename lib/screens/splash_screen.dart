import 'package:flutter/material.dart';
import '../main.dart'; // MainScreen에 접근하기 위해 import

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('千字文', style: TextStyle(fontSize: 80, color: Colors.indigo[700])),
            const SizedBox(height: 24),
            Text('천자문 학습', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo[800])),
            const SizedBox(height: 16),
            Text(
              '한자 목록 보기\n글자별 상세보기\n퀴즈 - 뜻, 빈칸, 순서, 짝\n랭킹',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.6, color: Colors.indigo[600]),
            ),
            const SizedBox(height: 44),
            ElevatedButton.icon(
              onPressed: () {
                // BottomNavigationBar가 있는 MainScreen으로 이동 [[6](https://ffuny.tistory.com/104)]
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('시작하기'),
            ),
          ],
        ),
      ),
    );
  }
}
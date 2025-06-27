import 'package:flutter/material.dart';
import 'package:healthymeal/recommendationPage/recommendation.dart';
import 'package:healthymeal/scoreboardPage/scoreboard.dart';
import 'package:healthymeal/dashboardPage/dashboard.dart'; // ✅ Dashboard import
// import 'package:image_picker/image_picker.dart'; // 현재 사용되지 않음

// 앱의 주요 페이지를 나타내는 열거형
enum AppPage {
  scoreboard,
  dashboard, // 또는 다른 주요 페이지 (예: home)
  recommendation,
  // 필요에 따라 다른 페이지 추가
}

class CommonBottomNavigationBar extends StatelessWidget {
  final AppPage currentPage; // 현재 활성화된 페이지
  // final ImagePicker? imagePickerInstance; // 현재 직접 사용되지 않으므로 주석 처리 또는 제거 가능

  const CommonBottomNavigationBar({
    super.key,
    required this.currentPage,
    // this.imagePickerInstance,
  });

  @override
  Widget build(BuildContext context) {
    int currentIndex = 0; // BottomNavigationBar의 현재 선택된 인덱스

    // currentPage 값에 따라 currentIndex 설정
    switch (currentPage) {
      case AppPage.scoreboard:
        currentIndex = 0;
        break;
      case AppPage.dashboard: // 예시: Dashboard가 중앙 (인덱스 1)이라고 가정
        currentIndex = 1;
        break;
      case AppPage.recommendation:
        currentIndex = 2;
        break;
      // 다른 AppPage 케이스 추가 가능
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.black87, // 선택된 아이템 색상
      unselectedItemColor: Colors.grey.shade600, // 선택되지 않은 아이템 색상
      showSelectedLabels: false, // 선택된 아이템 레이블 숨김
      showUnselectedLabels: false, // 선택되지 않은 아이템 레이블 숨김
      type: BottomNavigationBarType.fixed, // 모든 아이템이 항상 보이도록 설정
      backgroundColor: Colors.white, // 네비게이션 바 배경색
      elevation: 8.0, // 약간의 그림자 효과
      iconSize: 30, // 아이콘 크기 기본값
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined), // 스코어보드 아이콘
            activeIcon: Icon(Icons.bar_chart), // 활성화 시 아이콘
            label: 'Scoreboard'),
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined), // 대시보드 아이콘 (또는 홈 아이콘)
            activeIcon: Icon(Icons.dashboard), // 활성화 시 아이콘
            label: 'Dashboard'),
        BottomNavigationBarItem(
            icon: Icon(Icons.star_border_outlined), // 추천 아이콘
            activeIcon: Icon(Icons.star), // 활성화 시 아이콘
            label: 'Recommendation'),
      ],
      onTap: (index) {
        // 이미 현재 페이지에 있다면 아무 작업도 하지 않음
        if (index == currentIndex) return;

        // 탭된 인덱스에 따라 페이지 이동
        // 페이지 이동 시 현재 스택을 모두 제거하고 새 페이지로 이동 (pushAndRemoveUntil)
        // 이는 하단 탭으로 메인 화면들을 전환할 때 일반적인 패턴입니다.
        switch (index) {
          case 0: // Scoreboard
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const ScoreboardScreen()),
              (route) => false, // 모든 이전 라우트를 제거
            );
            break;
          case 1: // Dashboard (또는 Home)
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Dashboard()), // Dashboard 위젯으로 변경
              (route) => false,
            );
            break;
          case 2: // Recommendation
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const MenuRecommendScreen()),
              (route) => false,
            );
            break;
        }
      },
    );
  }
}

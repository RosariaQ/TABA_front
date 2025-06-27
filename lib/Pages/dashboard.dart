// lib/Pages/dashboard.dart

// import 'dart:io'; // 현재 이 파일에서 직접 사용되지 않음

import 'package:flutter/material.dart';
import 'package:healthymeal/dailystatusPage/dailystatus.dart';
import 'package:healthymeal/mealrecordPage/mealrecord.dart'; // 식사 기록 페이지
import 'package:healthymeal/profilePage/profile.dart'; // 프로필 페이지
import 'package:healthymeal/scoreboardPage/scoreboard.dart'; // 스코어보드 페이지
// import 'package:healthymeal/recommendationPage/recommendation.dart'; // 추천 페이지 (현재 네비게이션 없음)
// import 'package:image_picker/image_picker.dart'; // 현재 이 파일에서 직접 사용되지 않음

// 이 대시보드 파일은 lib/dashboardPage/dashboard.dart 와 유사한 기능을 하지만,
// 현재 앱의 메인 네비게이션 흐름에서는 lib/dashboardPage/dashboard.dart가 주로 사용되는 것으로 보입니다.
// 이 파일은 초기 버전이거나 다른 실험적 레이아웃일 수 있습니다.

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // File? _imageFile; // 프로필 이미지용 (현재는 사용되지 않음)
  /*
  final ImagePicker _picker = ImagePicker(); // 이미지 피커 (현재는 사용되지 않음)
  
  Future<void> _takePicture() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      },);
    } else {
      print('사진이 선택되지 않았습니다');
    }
  }
  */

  // 하단 네비게이션 바 아이템 탭 시 호출되는 함수
  void _onBottomNavigationTap(BuildContext context, int index) {
    switch (index) {
      case 0: // 스코어보드 (차트 아이콘)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScoreboardScreen()),
        );
        break;
      case 1: // 식사 기록 (카메라 아이콘)
        // TODO: MealRecord 페이지로 이동 시 이미지 촬영 로직 필요 (현재는 직접 페이지 이동)
        // 예: _takePicture().then((_) { if (_imageFile != null) Navigator.push(...); });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MealRecord()),
        );
        break;
      case 2: // 메뉴 추천 (별 아이콘) - 현재 주석 처리된 RecommendationPage
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => const MenuRecommendScreen()),
        // );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메뉴 추천 기능은 준비 중입니다.')),
        );
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    // 이 Dashboard 위젯은 자체적으로 MaterialApp을 포함하고 있어,
    // 앱의 메인 MaterialApp 내의 라우트 대상으로 사용될 경우 중첩 MaterialApp 구조가 될 수 있습니다.
    // 일반적으로 각 화면은 Scaffold를 최상위로 하고, MaterialApp은 앱 전체에 하나만 사용합니다.
    // 이 구조가 의도된 것이 아니라면, Scaffold를 반환하도록 수정하는 것이 좋습니다.
    return MaterialApp( // 중첩 MaterialApp 가능성 있음
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          // 페이지 배경 스타일
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 84, 239, 138), Color.fromARGB(255, 239, 186, 86)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          // 위젯 목록 (스크롤 가능)
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(context), // 헤더 빌드 (context 전달)
                  _buildDailyStatusCard(context), // 일일 상태 카드 빌드 (context 전달)
                  _buildWeeklyScoreCard(context), // 주간 점수 카드 빌드 (context 전달)
                  const SizedBox(height: 20), // 하단 여백
                ],
              ),
            ),
          ),
        ),
        // 하단 네비게이션 바
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1, // 기본 선택 아이템 (카메라) - 상태 관리 필요
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          iconSize: 35, // 아이콘 크기 조정
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '스코어보드'),
            BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: '식사기록'),
            BottomNavigationBarItem(icon: Icon(Icons.star_border), label: '메뉴추천'),
          ],
          onTap: (index) => _onBottomNavigationTap(context, index), // 컨텍스트 전달
        ),
      ),
    );
  }

  // 헤더 위젯 빌드 함수
  Widget _buildHeader(BuildContext context) { // context 파라미터 추가
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0), // 패딩 조정
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white), // 텍스트 색상 변경
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white), // 아이콘 색상 변경
                onPressed: () {
                  // TODO: 알림 기능 구현
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('알림 기능은 준비 중입니다.')),
                  );
                },
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Profile()),
                  );
                },
                child: CircleAvatar(
                  radius: 20,
                  // backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null, // 현재 _imageFile 사용 안 함
                  backgroundColor: Colors.white.withOpacity(0.8), // 배경색 변경
                  child: const Icon(Icons.person_outline, size: 28, color: Colors.black54), // 아이콘 및 색상 변경
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 일일 상태 요약 카드 위젯 빌드 함수
  Widget _buildDailyStatusCard(BuildContext context) { // context 파라미터 추가
    // TODO: 이 데이터는 실제 API 호출 또는 상태 관리를 통해 동적으로 받아와야 합니다.
    final nutrients = [
      {"label": "탄수화물", "value": 0.95, "color": Colors.orange.shade300},
      {"label": "단백질", "value": 0.75, "color": Colors.yellow.shade300},
      {"label": "지방", "value": 0.65, "color": Colors.green.shade300},
      {"label": "나트륨", "value": 0.9, "color": Colors.red.shade300},
      {"label": "식이섬유", "value": 0.6, "color": Colors.purple.shade200},
      // {"label": "당류", "value": 0.5, "color": Colors.lightBlue.shade200},
      // {"label": "콜레스테롤", "value": 0.85, "color": Colors.deepOrange.shade200},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: InkWell( // 카드 탭 시 페이지 이동
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DailyStatus()),
          );
        },
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          color: Colors.white.withOpacity(0.85), // 카드 배경 투명도 조정
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "일일 영양 상태", // "Daily Status" -> "일일 영양 상태"
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                ...nutrients.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item["label"]! as String, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: item["value"]! as double,
                            backgroundColor: Colors.grey[300]?.withOpacity(0.7),
                            color: item["color"] as Color,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 주간 점수 요약 카드 위젯 빌드 함수
  Widget _buildWeeklyScoreCard(BuildContext context) { // context 파라미터 추가
    // TODO: 이 데이터는 실제 API 호출 또는 상태 관리를 통해 동적으로 받아와야 합니다.
    final scores = [
      {"day": "월요일", "value": 0.6}, {"day": "화요일", "value": 0.3},
      {"day": "수요일", "value": 0.8}, {"day": "목요일", "value": 0.85},
      {"day": "금요일", "value": 0.4}, {"day": "토요일", "value": 0.2},
      {"day": "일요일", "value": 0.5},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: InkWell( // 카드 탭 시 페이지 이동
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScoreboardScreen()),
          );
        },
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          color: Colors.white.withOpacity(0.85), // 카드 배경 투명도 조정
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "주간 점수", // "Weekly Score" -> "주간 점수"
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                ...scores.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 70, // 요일 텍스트 너비 조정
                            child: Text(
                              item["day"]! as String,
                              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54),
                            ),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: item["value"]! as double,
                              backgroundColor: Colors.grey[300]?.withOpacity(0.7),
                              color: Colors.tealAccent.shade200.withOpacity(0.8), // 색상 조정
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:math'; // Random 클래스 사용을 위해
import 'package:flutter/material.dart';
import 'package:healthymeal/widgets/common_bottom_navigation_bar.dart'; // 공통 하단 네비게이션 바

class MenuRecommendScreen extends StatefulWidget {
  const MenuRecommendScreen({super.key});

  @override
  State<MenuRecommendScreen> createState() => _MenuRecommendScreenState();
}

class _MenuRecommendScreenState extends State<MenuRecommendScreen> {
  // 모든 가능한 영양소 태그 목록 정의
  final List<String> _allNutrientTags = [
    '단백질',
    '지방',
    '탄수화물',
    '당류',
    '식이섬유',
    '나트륨',
    '콜레스테롤',
    '비타민C', // 예시 태그 추가
    '칼슘',   // 예시 태그 추가
  ];

  // 태그별 색상 맵 정의
  final Map<String, Color> _tagColors = {
    '단백질': Colors.amber.shade700,
    '지방': Colors.orange.shade500,
    '탄수화물': Colors.purple.shade400,
    '당류': Colors.pink.shade300,
    '식이섬유': Colors.green.shade500,
    '나트륨': Colors.blue.shade400,
    '콜레스테롤': Colors.red.shade400,
    '비타민C': Colors.lightGreen.shade600,
    '칼슘': Colors.indigo.shade300,
  };

  // 임의의 개수(1~2개)의 영양소 태그 위젯을 생성하는 함수
  List<Widget> _getRandomNutrientTags() {
    final random = Random();
    // 원본 리스트를 복사하여 사용 (중복 선택 방지 및 원본 유지)
    List<String> availableTags = List.from(_allNutrientTags);
    // 1개 또는 2개의 태그를 생성
    int numberOfTags = random.nextInt(2) + 1;
    List<Widget> selectedTagWidgets = [];

    for (int i = 0; i < numberOfTags; i++) {
      if (availableTags.isEmpty) break; // 선택할 태그가 더 이상 없으면 종료

      int randomIndex = random.nextInt(availableTags.length);
      String selectedTag = availableTags.removeAt(randomIndex); // 태그를 선택하고 리스트에서 제거 (중복 방지)
      Color tagColor = _tagColors[selectedTag] ?? Colors.grey.shade400; // 정의되지 않은 태그는 회색 처리

      // 이미 추가된 태그가 있으면 간격 추가
      if (selectedTagWidgets.isNotEmpty) {
        selectedTagWidgets.add(const SizedBox(width: 6));
      }
      selectedTagWidgets.add(_buildTag(selectedTag, tagColor));
    }
    return selectedTagWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // 화면 전체 배경색 약간 변경
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 사용자 정의 앱바 ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54, size: 22), // 아이콘 변경 및 크기 조정
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    tooltip: '뒤로 가기',
                  ),
                  const Expanded(
                    child: Text(
                      '오늘의 메뉴 추천', // 타이틀 변경
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22, // 폰트 크기 조정
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // IconButton과 동일한 너비의 투명 위젯으로 중앙 정렬 유지
                  Opacity(
                    opacity: 0.0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                      onPressed: null,
                    ),
                  ),
                ],
              ),
            ),

            // --- 메인 콘텐츠 영역 ---
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- 선호도 우선 추천 섹션 ---
                      _buildSectionContainer(
                        title: '나의 선호도 높은 메뉴', // 섹션 제목 변경
                        children: [
                          _buildMenuItem(
                            imagePath: 'assets/image/namul.jpg', // TODO: 실제 이미지 경로 확인
                            title: '시금치 나물', // 메뉴 이름 구체화
                            subtitle: '고소하고 건강한 맛', // 부제목 추가
                          ),
                          const SizedBox(height: 12),
                          _buildMenuItem(
                            imagePath: 'assets/image/dubu.jpg', // TODO: 실제 이미지 경로 확인
                            title: '두부조림',
                            subtitle: '든든한 단백질 반찬',
                          ),
                          const SizedBox(height: 12),
                          _buildMenuItem(
                            imagePath: 'assets/image/goguma.jpg', // TODO: 실제 이미지 경로 확인
                            title: '군고구마와 견과류',
                            subtitle: '달콤하고 영양 가득 간식',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24), // 섹션 간 간격 조정

                      // --- 영양 균형 우선 추천 섹션 ---
                      _buildSectionContainer(
                        title: '영양 균형 맞춤 메뉴', // 섹션 제목 변경
                        children: [
                          _buildMenuItem(
                            imagePath: 'assets/image/gyeran.jpg', // TODO: 실제 이미지 경로 확인
                            title: '채소 계란찜',
                            subtitle: '부드럽고 소화가 편한 식사',
                          ),
                          const SizedBox(height: 12),
                          _buildMenuItem(
                            imagePath: 'assets/image/saengseon.jpg', // TODO: 실제 이미지 경로 확인
                            title: '고등어 구이와 현미밥',
                            subtitle: '오메가3와 건강 탄수화물',
                          ),
                          const SizedBox(height: 12),
                          _buildMenuItem(
                            imagePath: 'assets/image/yogurt.jpg', // TODO: 실제 이미지 경로 확인
                            title: '과일 그릭요거트',
                            subtitle: '프로바이오틱스와 비타민',
                          ),
                        ],
                      ),
                      const SizedBox(height: 30), // 섹션과 버튼 간 간격 조정

                      // --- 메뉴 목록 캡처 버튼 ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildCaptureButton(),
                      ),
                      const SizedBox(height: 16), // 하단 여백
                    ],
                  ),
                ),
              ),
            ),
            // const SizedBox(height: 10), // 하단 네비게이션 바와의 간격 (제거 또는 조정)
          ],
        ),
      ),
      // 공통 하단 네비게이션 바
      bottomNavigationBar: const CommonBottomNavigationBar(
        currentPage: AppPage.recommendation, // 현재 페이지를 recommendation으로 설정
      ),
    );
  }

  // --- 섹션 컨테이너 위젯 빌드 헬퍼 ---
  Widget _buildSectionContainer({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white, // 배경색 흰색
        borderRadius: BorderRadius.circular(20.0), // 모서리 둥글게
        boxShadow: [ // 부드러운 그림자 효과
          BoxShadow(
            color: Colors.grey.withOpacity(0.15), // 그림자 색상 및 투명도
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4), // 그림자 위치
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title), // 섹션 제목
          const SizedBox(height: 15),
          ...children, // 메뉴 아이템 목록
        ],
      ),
    );
  }

  // --- 섹션 제목 위젯 빌드 헬퍼 ---
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 19, // 폰트 크기 조정
        fontWeight: FontWeight.w600, // 폰트 두께 조정
        color: Colors.black.withOpacity(0.85), // 텍스트 색상 및 투명도
      ),
    );
  }

  // --- 메뉴 아이템 위젯 빌드 헬퍼 ---
  Widget _buildMenuItem({
    required String imagePath,
    required String title,
    required String subtitle,
  }) {
    List<Widget> randomTags = _getRandomNutrientTags(); // 각 메뉴 아이템마다 임의의 태그 생성
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), // 내부 패딩 조정
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // 아이템 배경색 약간 변경
        borderRadius: BorderRadius.circular(15.0), // 모서리 둥글기 조정
      ),
      child: Row(
        children: [
          // 음식 이미지 (CircleAvatar)
          CircleAvatar(
            radius: 30, // 이미지 크기 조정
            backgroundColor: Colors.grey.shade300, // 이미지 로드 전 배경색
            backgroundImage: AssetImage(imagePath),
            onBackgroundImageError: (exception, stackTrace) {
              // 이미지 로드 실패 시 콘솔에 에러 출력 (더 나은 에러 처리 가능)
              print('이미지 로드 오류: $imagePath, 오류: $exception');
              // TODO: 기본 이미지 또는 아이콘 표시 로직 추가 가능
            },
          ),
          const SizedBox(width: 15),
          // 메뉴 제목 및 부제목
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.5, // 폰트 크기 조정
                    fontWeight: FontWeight.w600, // 폰트 두께
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4), // 제목과 부제목 사이 간격
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5, // 폰트 크기 조정
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // 영양소 태그 (가로로 표시)
          Row(
            mainAxisSize: MainAxisSize.min, // 태그 내용만큼만 너비 차지
            children: randomTags,
          ),
        ],
      ),
    );
  }

  // --- 태그 위젯 빌드 헬퍼 ---
  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: color, // 태그 배경색
        borderRadius: BorderRadius.circular(12.0), // 태그 모서리 둥글게
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white, // 태그 텍스트 색상
          fontSize: 10.5, // 태그 폰트 크기 조정
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // --- "메뉴 목록 캡처" 버튼 위젯 빌드 헬퍼 ---
  Widget _buildCaptureButton() {
    return ElevatedButton(
      onPressed: () {
        // TODO: "메뉴 목록 캡처" 버튼 클릭 시 실행될 로직 구현
        print('메뉴 목록 캡처 버튼 클릭됨!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메뉴 목록 캡처 기능은 준비 중입니다.')),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepOrange.shade400, // 버튼 배경색 변경
        padding: const EdgeInsets.symmetric(vertical: 16.0), // 버튼 내부 패딩 조정
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0), // 버튼 모서리 둥글게
        ),
        elevation: 3, // 버튼 그림자 효과
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '추천 메뉴 목록 캡처', // 버튼 텍스트 변경
            style: TextStyle(
              fontSize: 17, // 폰트 크기 조정
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10),
          Icon(Icons.camera_enhance_outlined, color: Colors.white, size: 22), // 아이콘 변경 및 크기 조정
        ],
      ),
    );
  }
}

// lib/scoreboardPage/widgets/monthly_calendar_view.dart
import 'package:flutter/material.dart';
import 'package:healthymeal/scoreboardPage/scoreboard_constants.dart'; // dayNamesKorean 사용
import '../services/scoreboard_data_service.dart'; // ScoreboardDataService 사용

class MonthlyCalendarView extends StatefulWidget {
  final DateTime selectedMonth; // 현재 선택/표시된 월 (항상 해당 월의 1일)
  final ScoreboardDataService dataService; // 데이터를 가져오기 위해 필요
  final Function(DateTime) onDateSelected; // 날짜 선택 시 콜백 (선택된 날짜 전달)
  final Function(int) onChangeMonthBySwipe; // 스와이프로 월 변경 시 콜백 (monthsToAdd 전달)
  final bool canGoBackMonth; // 이전 달 이동 가능 여부
  final bool canGoForwardMonth; // 다음 달 이동 가능 여부

  const MonthlyCalendarView({
    super.key,
    required this.selectedMonth,
    required this.dataService,
    required this.onDateSelected,
    required this.onChangeMonthBySwipe,
    required this.canGoBackMonth,
    required this.canGoForwardMonth,
  });

  @override
  State<MonthlyCalendarView> createState() => _MonthlyCalendarViewState();
}

class _MonthlyCalendarViewState extends State<MonthlyCalendarView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController; // 애니메이션 컨트롤러
  late Animation<double> _fadeAnimation; // 페이드인 애니메이션
  late Animation<Offset> _slideAnimation; // 슬라이드업 애니메이션

  Map<int, int> _currentMonthScoresData = {}; // 일자(int) : 점수(int) 저장
  bool _isCalendarLoading = true; // 달력 데이터 로딩 상태
  String? _calendarErrorMessage; // 달력 데이터 로딩 오류 메시지

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450), // 애니메이션 지속 시간 조정
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.15), // 슬라이드 시작 위치 약간 조정
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _loadCalendarData(); // 위젯 초기화 시 달력 데이터 로드
  }

  @override
  void didUpdateWidget(covariant MonthlyCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 선택된 달이 변경되면 애니메이션과 함께 데이터 다시 로드
    if (oldWidget.selectedMonth.year != widget.selectedMonth.year ||
        oldWidget.selectedMonth.month != widget.selectedMonth.month) {
      if (mounted) {
        _animationController.reset(); // 애니메이션 리셋
        _loadCalendarData(); // 데이터 다시 로드
      }
    }
  }

  // 달력 데이터를 비동기적으로 로드하는 함수
  Future<void> _loadCalendarData() async {
    if (!mounted) return;
    setState(() {
      _isCalendarLoading = true;
      _calendarErrorMessage = null;
    });
    try {
      // 데이터 서비스로부터 해당 월의 점수 데이터를 가져옴
      final scores = await widget.dataService.getMonthlyScores(widget.selectedMonth);
      if (mounted) {
        setState(() {
          _currentMonthScoresData = scores;
          _isCalendarLoading = false;
        });
        _animationController.forward(from: 0.0); // 데이터 로드 성공 후 애니메이션 시작
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _calendarErrorMessage = "달력 데이터를 불러오는데 실패했습니다.";
          _isCalendarLoading = false;
        });
      }
      print("달력 데이터 로딩 오류: $e");
    }
  }

  @override
  void dispose() {
    _animationController.dispose(); // 컨트롤러 해제
    super.dispose();
  }

  // 요일 헤더 (일, 월, 화...) 위젯 빌드
  Widget _buildDayOfWeekHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0), // 패딩 조정
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: dayNamesKorean.map((day) { // scoreboard_constants.dart의 dayNamesKorean 사용
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: const TextStyle(
                    fontSize: 11.5, // 폰트 크기 조정
                    fontWeight: FontWeight.bold,
                    color: Colors.black54),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthlyScoresToUse = _currentMonthScoresData; // 현재 월의 점수 데이터
    // 현재 선택된 월의 총 일수
    final daysInMonth = DateUtils.getDaysInMonth(widget.selectedMonth.year, widget.selectedMonth.month);
    // 현재 선택된 월의 첫째 날 DateTime 객체
    final firstDayOfMonth = DateTime(widget.selectedMonth.year, widget.selectedMonth.month, 1);
    // 달력에서 첫째 날 앞에 표시될 빈 셀의 개수 (일요일 시작 기준)
    // DateTime.weekday: 월요일(1) ~ 일요일(7)
    // dayNamesKorean (일요일 시작, 인덱스 0~6) 기준으로 맞추기 위해 (firstDayOfMonth.weekday % 7) 사용
    final emptyCellsPrefix = firstDayOfMonth.weekday % 7;

    if (_isCalendarLoading) { // 로딩 중일 때
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.teal));
    }
    if (_calendarErrorMessage != null) { // 오류 발생 시
        return Center(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_calendarErrorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 15)),
        ));
    }

    return GestureDetector( // 스와이프 감지를 위한 GestureDetector
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        // 오른쪽으로 스와이프 (이전 달)
        if (details.primaryVelocity! > 150 && widget.canGoBackMonth) { // 민감도 조절
          widget.onChangeMonthBySwipe(-1);
        }
        // 왼쪽으로 스와이프 (다음 달)
        else if (details.primaryVelocity! < -150 && widget.canGoForwardMonth) { // 민감도 조절
          widget.onChangeMonthBySwipe(1);
        }
      },
      child: SlideTransition( // 슬라이드 애니메이션 적용
        position: _slideAnimation,
        child: FadeTransition( // 페이드인 애니메이션 적용
          opacity: _fadeAnimation,
          child: Column( // 요일 헤더와 GridView를 수직으로 배치
            children: [
              _buildDayOfWeekHeader(), // 요일 헤더 표시
              Expanded( // GridView가 남은 공간을 모두 차지하도록
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(), // 달력 자체는 스크롤되지 않도록 (부모 스크롤 사용)
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7, // 일주일은 7일
                    childAspectRatio: 0.95, // 각 셀의 가로세로 비율 조정 (세로 약간 길게)
                    mainAxisSpacing: 2.0, // 셀 간의 수직 간격
                    crossAxisSpacing: 2.0, // 셀 간의 수평 간격
                  ),
                  itemCount: daysInMonth + emptyCellsPrefix, // 총 셀 개수 (빈 셀 + 날짜 셀)
                  itemBuilder: (context, index) {
                    // 첫째 날 이전의 빈 셀 처리
                    if (index < emptyCellsPrefix) {
                      return Container(); // 빈 컨테이너
                    }

                    final dayNumber = index - emptyCellsPrefix + 1; // 실제 날짜 (1일부터 시작)
                    final currentDate = DateTime(widget.selectedMonth.year, widget.selectedMonth.month, dayNumber);
                    final score = monthlyScoresToUse[dayNumber] ?? 0; // 해당 날짜의 점수 (없으면 0)

                    // 오늘 날짜인지 확인
                    final bool isToday = DateUtils.isSameDay(currentDate, DateTime.now());
                    Color cellColor = Colors.white; // 기본 셀 배경색
                    Color textColor = Colors.black87; // 기본 텍스트 색상

                    if (score > 0) { // 점수가 있을 경우에만 색상 변경
                      // 점수에 따라 투명도 조절 (0.2 ~ 1.0 범위)
                      double opacity = (score / 100.0).clamp(0.2, 1.0);
                      cellColor = Colors.teal.withOpacity(opacity); // Teal 계열 색상, 점수에 따라 투명도
                      if (opacity > 0.6) { // 배경색이 충분히 진하면 텍스트 색상을 흰색으로
                        textColor = Colors.white;
                      }
                    }

                    return GestureDetector(
                      onTap: () => widget.onDateSelected(currentDate), // 날짜 셀 클릭 시 콜백 호출
                      child: Container(
                        margin: const EdgeInsets.all(1.5), // 셀 간의 아주 작은 간격
                        decoration: BoxDecoration(
                          // 오늘 날짜 강조 테두리
                          border: isToday
                              ? Border.all(color: Colors.deepOrangeAccent.withOpacity(0.8), width: 2.0)
                              : Border.all(color: Colors.grey.shade300, width: 0.5),
                          borderRadius: BorderRadius.circular(8.0), // 셀 모서리 둥글게 (반경 증가)
                          color: cellColor, // 계산된 셀 배경색
                          boxShadow: [ // 약간의 그림자 효과 (선택 사항)
                            if (score > 0)
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 0.5,
                                blurRadius: 1.5,
                                offset: const Offset(0, 1),
                              )
                          ]
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 날짜 텍스트
                              Text(
                                '$dayNumber',
                                style: TextStyle(
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12.5, // 폰트 크기
                                  // 오늘 날짜이고, 점수가 낮아 배경이 밝으면 강조색, 아니면 계산된 텍스트 색
                                  color: isToday && score <= 60 ? Colors.deepOrangeAccent : textColor,
                                ),
                              ),
                              // 점수 텍스트 (점수가 있을 때만 표시)
                              if (score > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.5), // 점수와 날짜 사이 간격
                                  child: Text(
                                    '$score', // 점수
                                    style: TextStyle(
                                      fontSize: 9.5, // 점수 폰트 크기
                                      color: textColor.withOpacity(0.85), // 약간 투명하게
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

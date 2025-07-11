// lib/nutrientintakePage/widgets/nutrient_monthly_calendar_view.dart
import 'package:flutter/material.dart';
import 'package:healthymeal/scoreboardPage/scoreboard_constants.dart'; // dayNamesKorean 사용
// import '../services/nutrient_intake_data_service.dart'; // 이제 직접적인 서비스 의존성 없음
// kNutrientKeys, kNutrientApiFieldMap 등 (필요시)

class NutrientMonthlyCalendarView extends StatefulWidget {
  final DateTime selectedMonth; // 현재 선택/표시된 월 (항상 해당 월의 1일)
  final Map<int, double> monthlyNutrientData; // 일자(int) : 섭취량(double)
  // final NutrientIntakeDataService dataService; // 이제 부모에서 criterionValue를 직접 받으므로 필요 X
  final Function(DateTime) onDateSelected; // 날짜 선택 시 콜백
  final Function(int) onChangeMonthBySwipe; // 스와이프로 월 변경 시 콜백
  final Function(int) onChangeNutrientBySwipe; // 스와이프로 영양소 변경 시 콜백
  final bool canGoBackMonth; // 이전 달 이동 가능 여부
  final bool canGoForwardMonth; // 다음 달 이동 가능 여부
  final String currentNutrientName; // 현재 선택된 영양소 이름 (UI 표시용)
  final double? criterionValue; // 현재 선택된 영양소의 식단 기준치 (nullable)

  const NutrientMonthlyCalendarView({
    super.key,
    required this.selectedMonth,
    required this.monthlyNutrientData,
    // required this.dataService, // 제거
    required this.onDateSelected,
    required this.onChangeMonthBySwipe,
    required this.onChangeNutrientBySwipe,
    required this.canGoBackMonth,
    required this.canGoForwardMonth,
    required this.currentNutrientName,
    this.criterionValue, // 생성자에 criterionValue 추가
  });

  @override
  State<NutrientMonthlyCalendarView> createState() => _NutrientMonthlyCalendarViewState();
}

class _NutrientMonthlyCalendarViewState extends State<NutrientMonthlyCalendarView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController; // 애니메이션 컨트롤러
  late Animation<double> _fadeAnimation; // 페이드인 애니메이션
  late Animation<Offset> _slideAnimation; // 슬라이드업 애니메이션

  // final Color _scoreBaseColor = Colors.teal; // 이제 동적 색상 및 기준치 기반 투명도 사용

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // 애니메이션 지속 시간
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2), // 아래에서 약간 위로
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // 위젯 빌드 후 애니메이션 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(covariant NutrientMonthlyCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 선택된 월, 데이터, 영양소, 또는 기준치가 변경되면 애니메이션 다시 시작
    if (oldWidget.selectedMonth.year != widget.selectedMonth.year ||
        oldWidget.selectedMonth.month != widget.selectedMonth.month ||
        oldWidget.monthlyNutrientData != widget.monthlyNutrientData ||
        oldWidget.currentNutrientName != widget.currentNutrientName ||
        oldWidget.criterionValue != widget.criterionValue) { // criterionValue 변경 감지
      if (mounted) {
        _animationController.forward(from: 0.0); // 애니메이션을 처음부터 다시 시작
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose(); // 컨트롤러 해제
    super.dispose();
  }

  // 요일 헤더 (일, 월, 화...) 위젯 빌드
  Widget _buildDayOfWeekHeader() {
    const List<String> displayDayNames = dayNamesKorean; // scoreboard_constants.dart 에서 가져옴
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: displayDayNames.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 셀 배경색 결정 함수
  // nutrientValue: 현재 섭취량, criterion: 해당 영양소의 식단 기준치
  Color _getCellColor(double nutrientValue, double? criterion) {
    if (criterion == null || criterion <= 0) {
      // 기준치가 없거나 유효하지 않으면, 섭취량에 따라 기본 색상 처리
      if (nutrientValue <= 0) return Colors.white; // 섭취량 없으면 흰색

      // 예시: 섭취량에 따라 Teal 계열 투명도 조절 (또는 다른 단일 기본 색상)
      // 시각적 최대치를 임의로 설정 (예: 기준치가 보통 100이라면 1.5배인 150)
      final double arbitraryMaxForOpacity = (widget.criterionValue ?? 100.0) * 1.5;
      double opacity = (nutrientValue / arbitraryMaxForOpacity).clamp(0.15, 0.85); // 투명도 범위 조정
      return Colors.teal.withOpacity(opacity);
    }

    final ratio = nutrientValue / criterion; // 기준치 대비 섭취 비율

    // 비율에 따른 색상 및 투명도 조절
    if (ratio < 0.5) { // 80% 미만: 빨간색 계열
      // 0%에 가까울수록 연하게, 80%에 가까울수록 진하게
      double opacity = 0.3 + (ratio / 0.8 * 0.5).clamp(0.0, 0.5);
      return Colors.red.shade300.withOpacity(opacity);
    } else if (ratio <= 1.0) { // 80% ~ 120%: 초록색 계열
      // 100%에 가까울수록 진하게
      double opacityFactor = 1 - ( (ratio - 1.0).abs() / 0.2 ); // 100%에서 멀어질수록 연해짐 (0.8~1.0, 1.0~1.2)
      double opacity = 0.4 + (opacityFactor * 0.45).clamp(0.0, 0.45);
      return Colors.green.shade400.withOpacity(opacity);
    } else { // 120% 초과: 파란색 계열
      // 120%에서 멀어질수록(더 많이 초과할수록) 진하게, 최대 200%까지 고려
      double opacityFactor = (ratio - 1.2) / 0.8; // 120% 초과분을 0.8(200%까지)로 정규화
      double opacity = 0.3 + (opacityFactor * 0.5).clamp(0.0, 0.5);
      return Colors.blue.shade300.withOpacity(opacity);
    }
  }


  @override
  Widget build(BuildContext context) {
    // 현재 선택된 월의 총 일수
    final daysInMonth = DateUtils.getDaysInMonth(widget.selectedMonth.year, widget.selectedMonth.month);
    // 현재 선택된 월의 첫째 날 DateTime 객체
    final firstDayOfMonth = DateTime(widget.selectedMonth.year, widget.selectedMonth.month, 1);
    // 달력에서 첫째 날 앞에 표시될 빈 셀의 개수 (일요일 시작 기준)
    final emptyCellsPrefix = firstDayOfMonth.weekday % 7;

    // 달력 셀의 시각적 최대치 (투명도 계산용, 현재는 _getCellColor 내부에서 처리)
    // final double criterionBaseForCalendar = widget.criterionValue ?? 0;
    // final double calendarEffectiveMaxValue = criterionBaseForCalendar > 0 ? criterionBaseForCalendar * 1.5 : 100.0; // 기본 최대값

    return GestureDetector( // 스와이프 감지
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! > 200 && widget.canGoBackMonth) { // 오른쪽 스와이프 (이전 달)
          widget.onChangeMonthBySwipe(-1);
        } else if (details.primaryVelocity! < -200 && widget.canGoForwardMonth) { // 왼쪽 스와이프 (다음 달)
          widget.onChangeMonthBySwipe(1);
        }
      },
      onVerticalDragEnd: (details) { // 세로 스와이프로 영양소 변경
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! > 200) { // 위로 스와이프
          widget.onChangeNutrientBySwipe(1); // 다음 영양소
        } else if (details.primaryVelocity! < -200) { // 아래로 스와이프
          widget.onChangeNutrientBySwipe(-1); // 이전 영양소
        }
      },
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildDayOfWeekHeader(), // 요일 헤더
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(), // 달력 자체는 스크롤 X
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7, // 일주일 7일
                    childAspectRatio: 0.9, // 셀 가로세로 비율
                    mainAxisSpacing: 1.0, // 셀 수직 간격
                    crossAxisSpacing: 1.0, // 셀 수평 간격
                  ),
                  itemCount: daysInMonth + emptyCellsPrefix, // 총 셀 개수
                  itemBuilder: (context, index) {
                    if (index < emptyCellsPrefix) { // 첫째 날 이전 빈 셀
                      return Container();
                    }

                    final dayNumber = index - emptyCellsPrefix + 1; // 실제 날짜
                    final currentDate = DateTime(widget.selectedMonth.year, widget.selectedMonth.month, dayNumber);
                    final double nutrientValue = widget.monthlyNutrientData[dayNumber] ?? 0.0; // 해당 날짜 섭취량

                    // 셀 배경색 및 텍스트 색상 결정
                    Color cellColor = _getCellColor(nutrientValue, widget.criterionValue);
                    Color textColor = Colors.black87; // 기본 텍스트 색상
                    bool isToday = DateUtils.isSameDay(currentDate, DateTime.now()); // 오늘 날짜 여부

                    // 배경색 밝기에 따라 텍스트 색상 조정 (어두운 배경이면 흰색 텍스트)
                    if (ThemeData.estimateBrightnessForColor(cellColor) == Brightness.dark) {
                        textColor = Colors.white;
                    }


                    return GestureDetector(
                      onTap: () => widget.onDateSelected(currentDate), // 날짜 선택 시 콜백
                      child: Container(
                        margin: const EdgeInsets.all(1.5), // 셀 간 아주 작은 간격
                        decoration: BoxDecoration(
                          border: isToday // 오늘 날짜 테두리 강조
                            ? Border.all(color: Colors.deepOrangeAccent, width: 1.5)
                            : Border.all(color: Colors.grey.shade300, width: 0.5),
                          borderRadius: BorderRadius.circular(6.0), // 셀 모서리 둥글게
                          color: cellColor, // 계산된 셀 배경색
                          boxShadow: [ // 약간의 그림자 효과
                            if (nutrientValue > 0) // 섭취량 있을 때만
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                          ],
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
                                  fontSize: 12.5,
                                  // 오늘 날짜이고, 배경이 밝으면 강조색, 아니면 계산된 텍스트 색
                                  color: (isToday && textColor != Colors.white && ThemeData.estimateBrightnessForColor(cellColor) == Brightness.light)
                                          ? Colors.deepOrangeAccent
                                          : textColor,
                                ),
                              ),
                              // 섭취량 텍스트 (섭취량 있을 때만 표시)
                              if (nutrientValue > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    nutrientValue.toStringAsFixed(1), // 소수점 한 자리
                                    style: TextStyle(
                                      fontSize: 9.5,
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

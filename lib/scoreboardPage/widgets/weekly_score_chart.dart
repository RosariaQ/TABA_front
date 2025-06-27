// lib/scoreboardPage/widgets/weekly_score_chart.dart
import 'package:flutter/material.dart';
import 'dart:math'; // max 함수 사용
import '../scoreboard_constants.dart'; // 상수 (색상, 요일 이름 등)

// 막대 높이 계산 함수 (점수, 최대 막대 높이, 기준 최대 점수를 받음)
double _calculateBarHeight(
    int value, double heightForMaxPossibleBar, int referenceMaxValueInPeriod) {
  if (value <= 0 ||
      referenceMaxValueInPeriod <= 0 ||
      heightForMaxPossibleBar <= 0) {
    return 0; // 유효하지 않은 값일 경우 높이 0 반환
  }
  // 점수는 일반적으로 0-100 범위라고 가정하고, 이를 기준으로 막대 높이 계산
  // referenceMaxValueInPeriod는 현재 사용되지 않으나, 점수 범위가 유동적일 경우 활용 가능
  double calculatedHeight = (value / 100.0) * heightForMaxPossibleBar;
  // 계산된 높이가 NaN이거나 음수일 경우 0으로 처리
  return max(0, calculatedHeight.isNaN ? 0 : calculatedHeight);
}

class WeeklyScoreChart extends StatefulWidget {
  final List<Map<String, dynamic>> weekData; // 주간 데이터 리스트 ({'day': String, 'value': int, 'date': DateTime})
  final Function(int) onChangeWeek; // 주 변경 콜백 함수 (weeksToAdd: -1 또는 1)
  final bool canGoBack; // 이전 주로 이동 가능한지 여부
  final bool canGoForward; // 다음 주로 이동 가능한지 여부

  const WeeklyScoreChart({
    super.key,
    required this.weekData,
    required this.onChangeWeek,
    required this.canGoBack,
    required this.canGoForward,
  });

  @override
  State<WeeklyScoreChart> createState() => _WeeklyScoreChartState();
}

class _WeeklyScoreChartState extends State<WeeklyScoreChart>
    with SingleTickerProviderStateMixin, RouteAware { // RouteAware 믹스인 추가 (화면 전환 감지)
  late AnimationController _controller; // 애니메이션 컨트롤러
  late Animation<double> _fadeAnimation; // 페이드인 애니메이션
  late Animation<Offset> _slideAnimation; // 슬라이드업 애니메이션

  // RouteObserver는 main.dart에서 MaterialApp의 navigatorObservers에 등록되어야 합니다.
  // final RouteObserver<PageRoute>? routeObserver = MyApp.routeObserver; // 예시 (실제로는 main.dart에서 가져와야 함)

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550), // 애니메이션 지속 시간 조정
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.15), // 아래에서 약간 위로 올라오는 효과 (시작 위치 조정)
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // 데이터가 있을 경우 위젯 빌드 후 애니메이션 시작
    if (widget.weekData.isNotEmpty) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) _controller.forward(from: 0.0);
       });
    }
  }

  @override
  void didUpdateWidget(covariant WeeklyScoreChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // weekData가 변경되었을 때 (특히, 데이터가 없다가 생기거나 내용이 변경될 때) 애니메이션 다시 시작
    // List의 내용을 직접 비교하는 것은 복잡하므로, 참조가 변경되거나 데이터 유무가 바뀔 때 애니메이션을 트리거합니다.
    if (oldWidget.weekData != widget.weekData || (widget.weekData.isNotEmpty && oldWidget.weekData.isEmpty)) {
       if (mounted) {
         _controller.reset(); // 애니메이션 상태 초기화
         if (widget.weekData.isNotEmpty) { // 새로운 데이터가 있을 때만 애니메이션 실행
            _controller.forward();
         }
       }
    }
  }

  // RouteAware 관련: 현재 화면이 다른 화면에 의해 가려졌다가 다시 나타날 때 호출
  @override
  void didPopNext() {
    if (mounted) {
      _controller.reset();
      _controller.forward(); // 애니메이션 다시 시작
    }
  }

  // RouteAware 관련: 위젯이 화면 스택에 추가될 때 RouteObserver에 등록
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // final route = ModalRoute.of(context);
    // if (route is PageRoute && routeObserver != null) {
    //   routeObserver!.subscribe(this, route);
    // }
    // TODO: main.dart에 routeObserver를 설정하고 여기서 구독해야 합니다.
    // 현재는 ModalRoute.of(context)를 직접 사용하는 대신 didPopNext를 활용합니다.
  }

  @override
  void dispose() {
    // final route = ModalRoute.of(context);
    // if (route is PageRoute && routeObserver != null) {
    //   routeObserver!.unsubscribe(this);
    // }
    _controller.dispose(); // 컨트롤러 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector( // 가로 스와이프 감지
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        // 오른쪽으로 스와이프 (이전 주)
        if (details.primaryVelocity! > 180 && widget.canGoBack) { // 스와이프 민감도 조절
          widget.onChangeWeek(-1);
        }
        // 왼쪽으로 스와이프 (다음 주)
        else if (details.primaryVelocity! < -180 && widget.canGoForward) { // 스와이프 민감도 조절
          widget.onChangeWeek(1);
        }
      },
      child: SlideTransition( // 슬라이드 애니메이션
        position: _slideAnimation,
        child: FadeTransition( // 페이드인 애니메이션
          opacity: _fadeAnimation,
          child: LayoutBuilder(builder: (context, constraints) {
            // 차트 영역의 최대 높이에서 상단 점수 텍스트, 하단 요일 텍스트, 약간의 여백 제외
            final double heightFor100Score = constraints.maxHeight - 45; // 점수 100일 때의 막대 최대 높이 (여유 공간 확보)
            // 좌우 화살표 버튼 및 내부 패딩 제외한 순수 막대 영역 너비
            final double availableWidthForBars = constraints.maxWidth - (32 * 2) - (8.0 * 2); // 버튼 크기, 좌우 패딩
            // 각 막대의 너비 계산 (막대 간 간격을 주기 위해 비율 적용)
            final double barWidth = widget.weekData.isEmpty
                ? 0
                : (availableWidthForBars / widget.weekData.length) * 0.60; // 막대 너비 비율 조정

            // 데이터가 없을 경우 메시지 표시
            if (widget.weekData.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "표시할 주간 점수 데이터가 없습니다.",
                    style: TextStyle(fontSize: 14.5, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0), // 내부 패딩 조정
              decoration: BoxDecoration(
                color: Colors.grey.shade200, // 배경색
                borderRadius: BorderRadius.circular(14), // 모서리 둥글게 (반경 증가)
              ),
              child: Row(
                children: [
                  // 이전 주 이동 버튼
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded), // 아이콘 변경
                    iconSize: 30.0, // 아이콘 크기
                    padding: EdgeInsets.zero, // 내부 패딩 제거
                    tooltip: "이전 주",
                    onPressed:
                        widget.canGoBack ? () => widget.onChangeWeek(-1) : null, // 이동 불가 시 비활성화
                    color: widget.canGoBack
                        ? Colors.grey.shade700 // 활성 색상
                        : Colors.grey.shade400, // 비활성 색상
                  ),
                  // 주간 막대 차트 영역
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround, // 막대 간격 균등하게
                      crossAxisAlignment: CrossAxisAlignment.end, // 막대를 아래쪽 기준으로 정렬
                      children: widget.weekData.asMap().entries.map((entry) {
                        // final int index = entry.key; // 인덱스 (필요시 사용)
                        final Map<String, dynamic> dayData = entry.value;
                        final int scoreValue = dayData['value'] as int? ?? 0; // 점수 (null이면 0)
                        final String dayLabel = dayData['day'] as String? ?? ''; // 요일 (null이면 빈 문자열)
                        // final DateTime date = dayData['date'] as DateTime; // 날짜 정보 (필요시 사용)

                        // 실제 막대 높이 계산
                        final barHeight = _calculateBarHeight(
                            scoreValue, heightFor100Score, 100); // 점수는 0-100 기준

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end, // 내용물을 아래쪽 기준으로 정렬
                          children: [
                            // 점수 텍스트
                            Text(
                              "$scoreValue",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10.5, // 폰트 크기 조정
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 3), // 점수와 막대 사이 간격
                            // 애니메이션 적용된 막대
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: barHeight), // 0에서 계산된 높이까지
                              duration: const Duration(milliseconds: 450), // 애니메이션 속도
                              curve: Curves.easeOutQuart, // 부드러운 애니메이션 곡선
                              builder: (context, animatedHeight, child) {
                                return Container(
                                  height: animatedHeight,
                                  width: barWidth > 0 ? barWidth : 10, // 최소 너비 보장
                                  decoration: BoxDecoration(
                                    color: accentScoreboardColor, // 막대 색상 (상수 사용)
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(5), // 막대 상단 모서리 둥글게 (반경 증가)
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4), // 막대와 요일 사이 간격
                            // 요일 텍스트
                            Text(
                              dayLabel,
                              style: const TextStyle(
                                fontSize: 10.5, // 폰트 크기 조정
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  // 다음 주 이동 버튼
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded), // 아이콘 변경
                    iconSize: 30.0,
                    padding: EdgeInsets.zero,
                    tooltip: "다음 주",
                    onPressed: widget.canGoForward
                        ? () => widget.onChangeWeek(1)
                        : null,
                    color: widget.canGoForward
                        ? Colors.grey.shade700
                        : Colors.grey.shade400,
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

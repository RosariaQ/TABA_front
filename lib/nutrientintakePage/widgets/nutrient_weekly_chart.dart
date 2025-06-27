// lib/nutrientintakePage/widgets/nutrient_weekly_chart.dart
import 'package:flutter/material.dart';
import 'dart:math'; // max 함수 사용
import '../nutrient_intake_constants.dart'; // 상수 (색상, 텍스트 크기 등)
// import '../services/nutrient_intake_data_service.dart'; // calculateBarHeight 함수가 이 파일로 이동했으므로 주석 처리 또는 삭제

class NutrientWeeklyChart extends StatefulWidget {
  final List<Map<String, dynamic>> weekData; // 주간 데이터 ({'day': String, 'value': double, 'date': DateTime})
  final Function(int) onChangeWeek; // 주 변경 콜백 (weeksToAdd: -1 또는 1)
  final Function(int) onChangeNutrientViaSwipe; // 스와이프로 영양소 변경 콜백
  final bool canGoBack; // 이전 주로 이동 가능한지 여부
  final bool canGoForward; // 다음 주로 이동 가능한지 여부
  final bool isWeekPeriodSelected; // 현재 주간 보기가 선택되었는지 여부
  final double? criterionValue; // 현재 선택된 영양소의 식단 기준치 (nullable)

  const NutrientWeeklyChart({
    super.key,
    required this.weekData,
    required this.onChangeWeek,
    required this.onChangeNutrientViaSwipe,
    required this.canGoBack,
    required this.canGoForward,
    required this.isWeekPeriodSelected,
    this.criterionValue, // 생성자에 criterionValue 추가
  });

  @override
  State<NutrientWeeklyChart> createState() => _NutrientWeeklyChartState();
}

class _NutrientWeeklyChartState extends State<NutrientWeeklyChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // 애니메이션 컨트롤러
  late Animation<double> _fadeAnimation; // 페이드인 애니메이션
  late Animation<Offset> _slideAnimation; // 슬라이드업 애니메이션

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // 애니메이션 지속 시간
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1), // 아래에서 약간 위로 올라오는 효과
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // 데이터가 있을 경우 위젯 빌드 후 애니메이션 시작
    if (widget.weekData.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward(from: 0.0);
      });
    }
  }

  @override
  void didUpdateWidget(covariant NutrientWeeklyChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // weekData 또는 criterionValue가 변경되면 애니메이션 다시 시작
    if (oldWidget.weekData != widget.weekData || oldWidget.criterionValue != widget.criterionValue) {
      if (mounted) {
        _controller.reset(); // 애니메이션 상태 초기화
        if (widget.weekData.isNotEmpty) { // 새로운 데이터가 있을 때만 애니메이션 실행
          _controller.forward();
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // 컨트롤러 해제
    super.dispose();
  }

  // 막대 높이 계산 함수 (이 위젯 내부 또는 static 헬퍼로 관리)
  // value: 현재 섭취량, maxVisualBarHeight: 차트에서 막대가 가질 수 있는 최대 픽셀 높이
  // effectiveMaxValue: 시각적 최대치 (기준치 * 1.5)
  static double _calculateBarHeight(double value, double maxVisualBarHeight, double effectiveMaxValue) {
    if (value <= 0 || effectiveMaxValue <= 0 || maxVisualBarHeight <= 0) {
      return 0.0; // 유효하지 않은 값이면 높이 0
    }
    // effectiveMaxValue (기준치 * 1.5) 대비 현재 값(value)의 비율로 높이 계산
    double calculatedHeight = (value / effectiveMaxValue) * maxVisualBarHeight;
    // 계산된 높이가 실제 막대 최대 높이를 넘지 않도록 clamp
    return max(0.0, calculatedHeight.clamp(0.0, maxVisualBarHeight));
  }

  // 막대 색상 결정 함수
  // nutrientValue: 현재 섭취량, criterion: 해당 영양소의 식단 기준치
  Color _getBarColor(double nutrientValue, double? criterion) {
    if (criterion == null || criterion <= 0) {
      // 기준치가 없거나 유효하지 않으면 기본 강조 색상 사용
      return kNutrientIntakeGraphAccentColor; // nutrient_intake_constants.dart에 정의된 색상
    }
    final ratio = nutrientValue / criterion; // 기준치 대비 섭취 비율
    if (ratio < 0.5) {
      return Colors.red.shade400; // 80% 미만: 빨간색 계열
    } else if (ratio <= 1.0) {
      return Colors.green.shade500; // 80% ~ 120%: 초록색 계열
    } else {
      return Colors.blue.shade400; // 120% 초과: 파란색 계열
    }
  }


  @override
  Widget build(BuildContext context) {
    // 시각적 최대치 (effectiveMaxValue): 기준치 * 1.5.
    // 기준치(widget.criterionValue)가 null이거나 0 이하이면 기본값(예: 100)을 사용.
    final double criterionBase = widget.criterionValue ?? 0;
    // 기준치가 0보다 클 때만 1.5배, 아니면 임의의 기본 최대값(예: 100g/mg)으로 설정
    final double effectiveMaxValue = criterionBase > 0 ? criterionBase * 1.5 : 100.0;
    debugPrint("NutrientWeeklyChart - Criterion: ${widget.criterionValue}, EffectiveMax: $effectiveMaxValue");


    return GestureDetector(
      // 가로 스와이프로 주 변경
      onHorizontalDragEnd: (details) {
        if (widget.isWeekPeriodSelected && details.primaryVelocity != null) {
          if (details.primaryVelocity! > 100 && widget.canGoBack) { // 오른쪽 스와이프 (이전 주)
            widget.onChangeWeek(-1);
          } else if (details.primaryVelocity! < -100 && widget.canGoForward) { // 왼쪽 스와이프 (다음 주)
            widget.onChangeWeek(1);
          }
        }
      },
      // 세로 스와이프로 영양소 변경
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 200) { // 위로 스와이프 (다음 영양소)
            widget.onChangeNutrientViaSwipe(1);
          } else if (details.primaryVelocity! < -200) { // 아래로 스와이프 (이전 영양소)
            widget.onChangeNutrientViaSwipe(-1);
          }
        }
      },
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder( // 부모 위젯의 크기를 기준으로 내부 UI 크기 동적 계산
            builder: (context, constraints) {
              // 차트 막대의 최대 픽셀 높이 계산
              final double maxBarHeight = constraints.maxHeight - // 전체 사용 가능 높이
                  (kGraphTextLineHeightApproximation * 2) - // 상단 값 텍스트, 하단 요일 텍스트 높이 근사치
                  kGraphTopSizedBoxHeight - // 막대 위 여백
                  kGraphBottomSizedBoxHeight - // 막대 아래 여백
                  kGraphContainerVerticalPadding; // 컨테이너 상하 패딩

              // 각 막대의 너비 계산
              final double barWidth = widget.weekData.isEmpty
                  ? 0
                  : (constraints.maxWidth - (36 * 2) - 16) / (widget.weekData.length * 1.5); // 좌우 화살표, 내부 패딩 제외

              return Container(
                decoration: BoxDecoration(
                  color: kNutrientIntakeGraphBackgroundColor, // 차트 배경색
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: kGraphContainerVerticalPadding / 2, horizontal: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 이전 주 이동 버튼
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      iconSize: 32.0,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: widget.isWeekPeriodSelected && widget.canGoBack
                          ? () => widget.onChangeWeek(-1)
                          : null, // 이동 불가 시 비활성화
                      color: widget.isWeekPeriodSelected && widget.canGoBack
                          ? Colors.grey.shade700 // 활성 색상
                          : Colors.grey.shade300, // 비활성 색상
                    ),
                    // 주간 막대 차트 영역
                    Expanded(
                      child: widget.weekData.isEmpty
                          ? const Center(child: Text("표시할 데이터가 없습니다.", style: TextStyle(color: Colors.grey)))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround, // 막대 간격 균등하게
                              crossAxisAlignment: CrossAxisAlignment.end, // 막대를 아래쪽 기준으로 정렬
                              children: widget.weekData.asMap().entries.map((entry) {
                                final Map<String, dynamic> data = entry.value;
                                final double nutrientValue = data['value'] as double? ?? 0.0; // 현재 섭취량
                                final String dayName = data['day'] as String? ?? ''; // 요일 이름

                                // 실제 막대 높이 계산
                                final barHeight = _calculateBarHeight(
                                  nutrientValue,
                                  maxBarHeight > 0 ? maxBarHeight : 1.0, // maxBarHeight가 0 이하가 되지 않도록 보정
                                  effectiveMaxValue, // 수정된 effectiveMaxValue 사용
                                );
                                // 막대 색상 결정
                                final barColor = _getBarColor(nutrientValue, widget.criterionValue);


                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.end, // 내용물을 아래쪽 기준으로 정렬
                                  children: [
                                    // 섭취량 텍스트 (소수점 한 자리까지 표시)
                                    Text(
                                      nutrientValue.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: kGraphValueTextFontSize, // 9.5
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: kGraphTopSizedBoxHeight), // 막대 위 여백 (2.0)
                                    // 애니메이션 적용된 막대
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: barHeight < 0 ? 0 : barHeight), // 0에서 계산된 높이까지
                                      duration: const Duration(milliseconds: 500), // 애니메이션 속도
                                      curve: Curves.easeOutCubic, // 부드러운 애니메이션 곡선
                                      builder: (context, animatedHeight, child) {
                                        return Container(
                                          height: animatedHeight,
                                          width: barWidth > 0 ? barWidth : 10, // 최소 너비 보장
                                          decoration: BoxDecoration(
                                            color: barColor, // 동적으로 결정된 색상 사용
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(6), // 막대 상단 모서리 둥글게
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: kGraphBottomSizedBoxHeight), // 막대 아래 여백 (3.0)
                                    // 요일 텍스트
                                    Text(
                                      dayName,
                                      style: const TextStyle(
                                        fontSize: kGraphDayTextFontSize, // 10.0
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
                      icon: const Icon(Icons.chevron_right),
                      iconSize: 32.0,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed:
                          widget.isWeekPeriodSelected && widget.canGoForward
                              ? () => widget.onChangeWeek(1)
                              : null,
                      color: widget.isWeekPeriodSelected && widget.canGoForward
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

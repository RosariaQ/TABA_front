import 'package:flutter/material.dart';
import 'package:healthymeal/dailystatusPage/dailystatus.dart'; // IntakeData 클래스 사용

class IntakeLevel extends StatefulWidget {
  final IntakeData intake; // 표시할 영양소 섭취 데이터

  const IntakeLevel(this.intake, {super.key});

  @override
  State<IntakeLevel> createState() => _IntakeLevelState();
}

class _IntakeLevelState extends State<IntakeLevel>
    with SingleTickerProviderStateMixin {
  // 바의 전체 너비와 높이 상수
  final double _totalWidth = 320.0; // 바의 전체 가로 길이
  final double _blockHeight = 22.0; // 바의 세로 높이 (패딩 제외 순수 바 높이)

  late AnimationController _controller; // 애니메이션 컨트롤러
  late Animation<double> _fillAnimation; // 바 채우기 애니메이션

  Color _barColor = Colors.grey; // 바의 색상 (섭취 비율에 따라 변경됨)

  // 섭취 비율에 따라 바의 색상을 결정하는 함수
  void _updateBarColor(double ratio) {
    Color newColor;
    if (ratio <= 0.4) {
      newColor = Colors.red.shade400; // 매우 부족 (강한 빨강)
    } else if (ratio <= 0.8) {
      newColor = Colors.orange.shade400; // 부족 (주황)
    } else if (ratio <= 1.2) {
      newColor = Colors.green.shade500; // 적정 (초록)
    } else if (ratio <= 1.6) {
      newColor = Colors.amber.shade600; // 약간 초과 (진한 노랑/주황)
    } else {
      newColor = Colors.deepOrange.shade600; // 많이 초과 (진한 주황/빨강)
    }
    // 색상이 실제로 변경되었을 때만 setState 호출하여 불필요한 리빌드 방지
    if (_barColor != newColor) {
      setState(() {
        _barColor = newColor;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // 초기 섭취 비율 계산 및 바 색상 설정
    double initialRatio = widget.intake.intakeamount / widget.intake.requiredintake;
    if (widget.intake.requiredintake == 0) { // 분모가 0인 경우 처리
        initialRatio = widget.intake.intakeamount > 0 ? 2.0 : 0.0; // 섭취량이 있으면 최대로, 없으면 0으로
    }
    _updateBarColor(initialRatio.isNaN || initialRatio.isInfinite ? 0.0 : initialRatio);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // 애니메이션 지속 시간
    );

    // 바 채우기 애니메이션 설정 (0에서 초기 비율까지)
    _fillAnimation = Tween<double>(begin: 0, end: initialRatio.isNaN || initialRatio.isInfinite ? 0.0 : initialRatio).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic), // 부드러운 애니메이션 커브
    );

    // 위젯 빌드 후 애니메이션 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward(from: 0.0);
    });
  }

  // 위젯의 데이터(intake)가 변경될 때마다 애니메이션 및 색상 업데이트
  @override
  void didUpdateWidget(covariant IntakeLevel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // intake 데이터가 실제로 변경되었을 때만 재실행
    if (widget.intake != oldWidget.intake) {
      double newRatio = widget.intake.intakeamount / widget.intake.requiredintake;
      if (widget.intake.requiredintake == 0) {
        newRatio = widget.intake.intakeamount > 0 ? 2.0 : 0.0;
      }
      final validNewRatio = newRatio.isNaN || newRatio.isInfinite ? 0.0 : newRatio;

      _updateBarColor(validNewRatio); // 새 비율에 맞춰 바 색상 업데이트

      // 애니메이션의 end 값을 새 비율로 업데이트하고 애니메이션 재시작
      _fillAnimation = Tween<double>(begin: 0, end: validNewRatio).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0.0); // 애니메이션을 처음부터 다시 시작
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // 컨트롤러 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double centerLinePosition = _totalWidth / 2; // 기준선 위치 (중앙)
    final double maxRatioVisualized = 2.0; // 시각적으로 표현할 최대 비율 (예: 200%)
    final double infoPartHeight = 26; // 바의 상단 및 하단 정보표시 영역크기

    // 권장 섭취량이 0일 경우 처리
    double currentRatio = widget.intake.requiredintake == 0
        ? (widget.intake.intakeamount > 0 ? maxRatioVisualized : 0.0)
        : widget.intake.intakeamount / widget.intake.requiredintake;
    currentRatio = currentRatio.isNaN || currentRatio.isInfinite ? 0.0 : currentRatio;


    return Card( // 각 영양소 항목을 카드로 감싸 시각적 구분 강화
      elevation: 1.5, // 카드 그림자 효과
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 0), // 카드 간 여백
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 카드 모서리 둥글게
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16.0), // 카드 내부 패딩
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // 내용물 왼쪽 정렬
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal:8),
              // 상단: 영양소 이름 및 현재 섭취량 표시
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양 끝 정렬
                children: [
                  Text(
                    widget.intake.nutrientname,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87), // 폰트 스타일 조정
                  ),
                  Text(
                    '${widget.intake.intakeamount.toStringAsFixed(1)}${widget.intake.intakeunit} 섭취', // 소수점 한 자리까지 표시
                    style: TextStyle(
                        color: _barColor, // 현재 섭취량 텍스트 색상을 바 색상과 동일하게
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height:0), // 텍스트와 바 사이 간격
            // 중앙: 섭취량 시각화 바 영역
            SizedBox(
              width: _totalWidth, // 전체 너비 고정
              height: _blockHeight + infoPartHeight, // 바와 텍스트들을 포함할 충분한 높이
              child: Stack( // 여러 요소를 겹쳐서 표현
                alignment: Alignment.centerLeft, // 기본 정렬은 왼쪽 중앙
                children: [
                  // 1. 바 배경 (전체 영역)
                  Container(
                    height: _blockHeight,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 169, 169, 169), // 바 배경색
                      borderRadius: BorderRadius.circular(10), // 모서리 둥글게
                      // border: Border.all(color: Colors.grey.shade300, width: 1), // 테두리 (선택 사항)
                    ),
                  ),
                  // 2. 채워지는 바 (애니메이션 적용)
                  AnimatedBuilder(
                    animation: _fillAnimation,
                    builder: (context, child) {
                      final double animatedRatio = _fillAnimation.value;
                      // 실제 바의 너비 계산 (최대 비율까지만 시각화)
                      final double barWidth = (animatedRatio.clamp(0.0, maxRatioVisualized) / maxRatioVisualized) * _totalWidth;
                      return Container(
                        width: barWidth,
                        height: _blockHeight,
                        decoration: BoxDecoration(
                          color: _barColor, // 계산된 바 색상
                          borderRadius: BorderRadius.circular(9), // 배경보다 약간 작은 둥글기
                        ),
                      );
                    },
                  ),
                  // 3. 기준선 (100% 위치)
                  Positioned(
                    left: centerLinePosition - 1.5, // 기준선 두께 고려하여 중앙 정렬
                    top: 13, // 바 위쪽으로 살짝 올림
                    bottom: 13, // 바 아래쪽으로 살짝 내림 (텍스트 공간 확보)
                    child: Container(
                      width: 3, // 기준선 두께
                      decoration: BoxDecoration(
                        color: Colors.black, // 기준선 색상
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                  // 4. 기준 섭취량 텍스트 (100% 위치 상단)
                  Positioned(
                    left: centerLinePosition - 15, // 기준선 기준으로 텍스트 위치 조정
                    top: 0, // 바 위쪽으로 더 올림
                    child: Text(
                      '${widget.intake.requiredintake.toStringAsFixed(widget.intake.requiredintake % 1 == 0 ? 0 : 1)}${widget.intake.intakeunit}', // 정수면 소수점 없이, 아니면 한 자리
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                  ),
                  // 5. 현재 섭취 퍼센트 텍스트 (바 끝 또는 바깥쪽)
                  AnimatedBuilder(
                    animation: _fillAnimation,
                    builder: (context, child) {
                      final double textRatio = _fillAnimation.value;
                       // 실제 바의 너비 계산 (최대 비율까지만 시각화)
                      final double currentBarWidth = (textRatio.clamp(0.0, maxRatioVisualized) / maxRatioVisualized) * _totalWidth;
                      // 텍스트 위치 계산 (바 안쪽 또는 바깥쪽)
                      double textLeftPosition = currentBarWidth - 25; // 기본적으로 바 안쪽 끝에 위치
                      if (currentBarWidth < 40) { // 바가 너무 짧으면
                        textLeftPosition = 15; // 바 바깥 오른쪽에 표시
                      }
                      if (textLeftPosition < 0) textLeftPosition = 5; // 화면 왼쪽 벗어남 방지
                      if (textLeftPosition > _totalWidth - 30) textLeftPosition = _totalWidth - 30; // 화면 오른쪽 벗어남 방지
                      return Positioned(
                        left: textLeftPosition,
                        top: _blockHeight - 5, // 바 아래쪽에 위치
                        child: Text(
                          '${(textRatio * 100).round()}%', // 퍼센트 표시
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

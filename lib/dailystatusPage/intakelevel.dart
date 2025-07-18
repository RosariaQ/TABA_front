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
  // 바 전체 너비·높이
  final double _totalWidth = 320.0;
  final double _barHeight = 22.0;
  // 최대 시각화 비율 (200%)
  final double _maxVisualRatio = 2.0;

  late final AnimationController _controller;
  late Animation<double> _fillAnimation;
  Color _barColor = Colors.grey;

  /// 비율(ratio) 기준으로 바 색상 결정
  /// ratio = intakeAmount / requiredIntake
  Color _getColorForRatio(double ratio) {
    if (ratio <= 0.5) {
      // 0–50%: 노랑
      return Colors.yellow.shade400;
    } else if (ratio <= 1.0) {
      // 50–100%: 초록
      return Colors.green.shade500;
    } else if (ratio <= 1.5) {
      // 100–150%: 다시 노랑
      return Colors.yellow.shade400;
    } else {
      // 그 이상: 빨강
      return Colors.red.shade400;
    }
  }

  @override
  void initState() {
    super.initState();

    final intake = widget.intake;
    double initialRatio;
    if (intake.requiredIntake == 0) {
      initialRatio = intake.intakeAmount > 0 ? _maxVisualRatio : 0.0;
    } else {
      initialRatio = intake.intakeAmount / intake.requiredIntake;
    }
    if (initialRatio.isNaN || initialRatio.isInfinite) {
      initialRatio = 0.0;
    }

    _barColor = _getColorForRatio(initialRatio);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fillAnimation = Tween<double>(begin: 0.0, end: initialRatio).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(covariant IntakeLevel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.intake != oldWidget.intake) {
      final intake = widget.intake;
      double newRatio;
      if (intake.requiredIntake == 0) {
        newRatio = intake.intakeAmount > 0 ? _maxVisualRatio : 0.0;
      } else {
        newRatio = intake.intakeAmount / intake.requiredIntake;
      }
      if (newRatio.isNaN || newRatio.isInfinite) {
        newRatio = 0.0;
      }

      setState(() {
        _barColor = _getColorForRatio(newRatio);
        _fillAnimation = Tween<double>(begin: 0.0, end: newRatio).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );
        _controller.forward(from: 0.0);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final centerLine = _totalWidth / 2;
    const double labelHeight = 26.0;

    // 기준량 수치를 소수점 없이(정수) 또는 소수점 1자리로 포맷
    final req = widget.intake.requiredIntake;
    final reqText = req % 1 == 0
        ? req.toInt().toString()
        : req.toStringAsFixed(1);

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 상단: 이름 + 섭취량 (텍스트는 검정색 고정)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.intake.nutrientName,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
                Text(
                  '${widget.intake.intakeAmount.toStringAsFixed(1)}${widget.intake.intakeUnit} 섭취',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 바 + 기준선 + 텍스트
            SizedBox(
              width: _totalWidth,
              height: _barHeight + labelHeight,
              child: Stack(alignment: Alignment.centerLeft, children: [
                // 배경 바
                Container(
                  height: _barHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // 채워진 바
                AnimatedBuilder(
                  animation: _fillAnimation,
                  builder: (context, child) {
                    final ratio =
                        _fillAnimation.value.clamp(0.0, _maxVisualRatio);
                    final width = (ratio / _maxVisualRatio) * _totalWidth;
                    return Container(
                      width: width,
                      height: _barHeight,
                      decoration: BoxDecoration(
                        color: _barColor,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    );
                  },
                ),
                // 100% 기준선
                Positioned(
                  left: centerLine - 1.5,
                  top: 13,
                  bottom: 13,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(1.5)),
                  ),
                ),
                // 기준량 텍스트 (100% 위치 상단)
                Positioned(
                  left: centerLine - 15,
                  top: 0,
                  child: Text(
                    reqText,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
                // 퍼센트 텍스트
                AnimatedBuilder(
                  animation: _fillAnimation,
                  builder: (context, child) {
                    final ratio =
                        _fillAnimation.value.clamp(0.0, _maxVisualRatio);
                    final barWidth = (ratio / _maxVisualRatio) * _totalWidth;
                    double left = barWidth - 25;
                    if (barWidth < 40) left = 15;
                    left = left.clamp(5.0, _totalWidth - 30);
                    return Positioned(
                      left: left,
                      top: _barHeight - 5,
                      child: Text(
                        '${(ratio * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    );
                  },
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

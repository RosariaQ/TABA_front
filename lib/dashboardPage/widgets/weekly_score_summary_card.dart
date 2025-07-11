// lib/dashboardPage/widgets/weekly_score_summary_card.dart
import 'package:flutter/material.dart';

// TODO: 실제 앱에서는 ScoreboardDataService 등을 통해 주간 점수 데이터를 가져와야 합니다.

class WeeklyScoreSummaryCard extends StatelessWidget {
  // StatelessWidget에서는 생성자를 통해 받은 프로퍼티에 'this.' 또는 직접 이름으로 접근합니다.
  // 'widget.' 접두사는 State 클래스 내에서 StatefulWidget의 프로퍼티에 접근할 때 사용됩니다.
  final double scale; // 카드 클릭 시 애니메이션을 위한 스케일 값
  final Function(TapDownDetails) onTapDown; // 탭 다운 이벤트 콜백
  final Function(TapUpDetails) onTapUp; // 탭 업 이벤트 콜백
  final VoidCallback onTapCancel; // 탭 취소 이벤트 콜백
  final VoidCallback? onTap; // 카드 전체 탭 이벤트 콜백 (페이지 이동 등)

  // TODO: 이 데이터는 실제 API 호출 또는 상태 관리를 통해 동적으로 받아와야 합니다.
  // 현재는 예시용 하드코딩된 데이터입니다.
  final List<Map<String, dynamic>> _scoresData = const [
    {"day": "월요일", "value": 0.60},
    {"day": "화요일", "value": 0.35},
    {"day": "수요일", "value": 0.80},
    {"day": "목요일", "value": 0.85},
    {"day": "금요일", "value": 0.45},
    {"day": "토요일", "value": 0.25},
    {"day": "일요일", "value": 0.55},
  ];

  const WeeklyScoreSummaryCard({
    super.key,
    required this.scale,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    this.onTap,
  });

  // 점수 값에 따라 진행률 바의 색상을 결정하는 함수
  Color _getProgressColor(double scoreValue) {
    if (scoreValue <= 0.25) return Colors.red.shade400; // 매우 낮음
    if (scoreValue <= 0.45) return Colors.orange.shade400; // 낮음
    if (scoreValue <= 0.65) return Colors.amber.shade500; // 보통
    if (scoreValue <= 0.85) return Colors.lightGreen.shade500; // 좋음
    return Colors.green.shade600; // 매우 좋음
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: GestureDetector(
        // StatelessWidget 내에서는 'this.' 또는 프로퍼티 이름으로 직접 접근합니다.
        // 예를 들어, this.onTapDown 또는 그냥 onTapDown으로 사용합니다.
        onTapDown: onTapDown,
        onTapUp: onTapUp,
        onTapCancel: onTapCancel,
        onTap: onTap,
        child: AnimatedScale(
          scale: scale, // 'this.scale' 또는 'scale'로 접근
          duration: const Duration(milliseconds: 150),
          child: Card(
            color: const Color(0xFFFCFCFC),
            elevation: 4,
            shadowColor: Colors.grey.withAlpha(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.grey.shade200, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "주간 점수 요약",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  // _scoresData는 이 클래스 내에 정의된 final 필드이므로 직접 접근 가능합니다.
                  ..._scoresData.map((item) {
                    final double value = item["value"]! as double;
                    final String dayLabel = item["day"]! as String;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 70,
                            child: Text(
                              dayLabel,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13.5,
                                  color: Colors.black54),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: value),
                              duration: Duration(
                                  milliseconds: 750 + (value * 250).toInt()),
                              curve: Curves.easeInOutCubic,
                              builder: (context, animatedValue, child) {
                                return LinearProgressIndicator(
                                  value: animatedValue.clamp(0.0, 1.0),
                                  backgroundColor: Colors.grey.shade300,
                                  // _getProgressColor는 이 클래스 내의 메소드이므로 직접 호출합니다.
                                  color: _getProgressColor(animatedValue),
                                  minHeight: 10,
                                  borderRadius: BorderRadius.circular(10),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

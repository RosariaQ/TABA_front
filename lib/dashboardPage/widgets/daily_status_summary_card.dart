// lib/dashboardPage/widgets/daily_status_summary_card.dart
import 'package:flutter/material.dart';
import 'package:healthymeal/dailystatusPage/service/dailystatusservice.dart';

// TODO: 실제 앱에서는 DailyStatusService를 통해 데이터를 가져와야 합니다.
// import 'package:healthymeal/dailystatusPage/service/dailystatusservice.dart';

class DailyStatusSummaryCard extends StatefulWidget {
  final double scale; // 카드 클릭 시 애니메이션을 위한 스케일 값
  final Function(TapDownDetails) onTapDown; // 탭 다운 이벤트 콜백
  final Function(TapUpDetails) onTapUp; // 탭 업 이벤트 콜백
  final VoidCallback onTapCancel; // 탭 취소 이벤트 콜백
  final VoidCallback? onTap; // 카드 전체 탭 이벤트 콜백 (페이지 이동 등)

  const DailyStatusSummaryCard({
    super.key, // 애니메이션 강제 리부트를 위해 key를 받을 수 있도록 수정
    required this.scale,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    this.onTap, // onTap 콜백 추가
  });

  @override
  State<DailyStatusSummaryCard> createState() => _DailyStatusSummaryCardState();
}

class _DailyStatusSummaryCardState extends State<DailyStatusSummaryCard> {
  // 추후 API Request를 위한 Service 인스턴스 (현재는 주석 처리)
  // final DailyStatusService _dailyStatusService = DailyStatusService(baseUrl: "YOUR_API_BASE_URL");

  // TODO: 이 데이터는 실제 API 호출 또는 상태 관리를 통해 동적으로 받아와야 합니다.
  // 현재는 예시용 하드코딩된 데이터입니다.
  final List<Map<String, dynamic>> _nutrientsData = const [
    {"label": "탄수화물", "value": 0.75, "target": 100.0, "current": 75.0, "unit": "g"}, // 목표치, 현재치, 단위 추가
    {"label": "단백질", "value": 0.90, "target": 60.0, "current": 54.0, "unit": "g"},
    {"label": "지방", "value": 0.55, "target": 50.0, "current": 27.5, "unit": "g"},
    {"label": "나트륨", "value": 0.80, "target": 2000.0, "current": 1600.0, "unit": "mg"},
    {"label": "식이섬유", "value": 0.60, "target": 25.0, "current": 15.0, "unit": "g"},
    // {"label": "당류", "value": 0.5, "color": Colors.lightBlue}, // 필요시 추가
    // {"label": "콜레스테롤", "value": 0.85, "color": Colors.deepOrange}, // 필요시 추가
  ];

  // DailyStatus Widget을 위한 Service class
  final DailyStatusService _dailyStatusService = DailyStatusService();

  @override
  void initState() {
    super.initState();
  }

  // 진행률 바의 색상을 결정하는 함수
  Color _getProgressColor(double animatedValue) {
    if (animatedValue <= 0.3) return Colors.red.shade400; // 부족
    if (animatedValue <= 0.6) return Colors.orange.shade400; // 약간 부족
    if (animatedValue <= 0.9) return Colors.amber.shade500; // 적정 근접
    if (animatedValue <= 1.1) return Colors.lightGreen.shade500; // 적정
    return Colors.green.shade600; // 충분 또는 초과 (색상 조정 가능)
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: GestureDetector( // 카드 전체에 탭 효과 및 이벤트 적용
        onTapDown: widget.onTapDown,
        onTapUp: widget.onTapUp,
        onTapCancel: widget.onTapCancel,
        onTap: widget.onTap, // 전체 탭 이벤트 연결
        child: AnimatedScale( // 탭 시 카드 크기 변경 애니메이션
          scale: widget.scale,
          duration: const Duration(milliseconds: 150),
          child: Card(
            color: const Color(0xFFFCFCFC), // 카드 배경색
            elevation: 4, // 그림자 깊이
            shadowColor: Colors.grey.withAlpha(50), // 그림자 색상 및 투명도
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18), // 카드 모서리 둥글게
              side: BorderSide(color: Colors.grey.shade200, width: 0.5), // 카드 테두리
            ),
            child: Padding(
              padding: const EdgeInsets.all(20), // 카드 내부 패딩
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "오늘의 영양 상태 요약", // 카드 제목
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  // 각 영양소별 진행률 표시
                  ..._nutrientsData.map((item) {
                    final double value = item["value"]! as double; // 목표 대비 현재 섭취 비율
                    final String label = item["label"]! as String;
                    final double currentAmount = item["current"]! as double;
                    final double targetAmount = item["target"]! as double;
                    final String unit = item["unit"]! as String;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8), // 각 항목 간 수직 여백
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row( // 영양소 이름과 현재/목표 섭취량 표시
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(label,
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500)),
                              Text('${currentAmount.toStringAsFixed(1)}$unit / ${targetAmount.toStringAsFixed(1)}$unit',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 애니메이션과 함께 진행률 바 표시
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: value), // 0에서 실제 값까지 애니메이션
                            duration: Duration(
                                milliseconds: 800 + (value * 200).toInt()), // 값에 따라 애니메이션 시간 조절
                            curve: Curves.easeInOutCubic, // 애니메이션 커브
                            builder: (context, animatedValue, child) {
                              // 진행률 바 위젯
                              return LinearProgressIndicator(
                                value: animatedValue.clamp(0.0, 1.0), // 값은 0.0과 1.0 사이로 제한
                                backgroundColor: Colors.grey.shade300, // 바 배경색
                                color: _getProgressColor(animatedValue), // 바 색상 (값에 따라 동적 변경)
                                minHeight: 10, // 바 최소 높이
                                borderRadius: BorderRadius.circular(10), // 바 모서리 둥글게
                              );
                            },
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

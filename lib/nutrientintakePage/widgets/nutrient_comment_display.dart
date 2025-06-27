// lib/nutrientintakePage/widgets/nutrient_comment_display.dart
import 'package:flutter/material.dart';
import '../nutrient_intake_constants.dart'; // kDefaultComment 사용

class NutrientCommentDisplay extends StatelessWidget {
  final String nutrientName; // 현재 선택된 영양소 이름
  // final double averageIntake; // 주간 또는 월간 평균 섭취량 (필요시 주입)
  // final String intakeStatus; // 섭취 상태 (예: "부족", "적정", "과다") (필요시 주입)

  const NutrientCommentDisplay({
    super.key,
    required this.nutrientName,
    // this.averageIntake,
    // this.intakeStatus,
  });

  // 실제 앱에서는 averageIntake, intakeStatus 등의 데이터를 기반으로
  // 좀 더 정교한 코멘트 생성 로직이 필요합니다.
  // 여기서는 nutrientName에 따라 간단한 동적 텍스트를 생성합니다.
  Map<String, dynamic> _getDynamicCommentParts(String nutrient) {
    String textPart;
    Color textColor;

    // 예시: 영양소별 코멘트 및 색상 설정
    switch (nutrient) {
      case 'Protein': // 단백질
      case 'Fiber': // 섬유질 (식이섬유)
        textPart = "권장량에 비해 다소 부족한 편";
        textColor = Colors.orange.shade700;
        break;
      case 'Fat': // 지방
        textPart = "적정 수준을 유지하고 있지만, 과다 섭취에 주의";
        textColor = Colors.amber.shade800;
        break;
      case 'Carbohydrate': // 탄수화물
        textPart = "섭취량이 적절해 보입니다. 좋은 습관을 유지하세요";
        textColor = Colors.green.shade700;
        break;
      default: // 기타 영양소 (예: 당류, 나트륨 등)
        textPart = "섭취량 관찰이 필요하며, 균형 잡힌 식단이 중요";
        textColor = Colors.red.shade700;
    }
    return {'text': textPart, 'color': textColor};
  }

  @override
  Widget build(BuildContext context) {
    final commentParts = _getDynamicCommentParts(nutrientName);
    final String dynamicTextPart = commentParts['text'];
    final Color dynamicTextColor = commentParts['color'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // 상하 패딩 추가
      child: Container( // 코멘트 영역을 더 잘 구분하기 위해 Container 추가
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100, // 연한 배경색
          borderRadius: BorderRadius.circular(12.0), // 모서리 둥글게
        ),
        child: Center(
          child: SingleChildScrollView( // 내용이 길어질 경우 스크롤 가능하도록
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.5), // 기본 스타일
                children: [
                  const TextSpan(text: "선택된 "),
                  TextSpan(
                    text: "'$nutrientName'", // 현재 선택된 영양소 이름
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark),
                  ),
                  const TextSpan(text: " 섭취량은\n"), // 줄바꿈 추가
                  TextSpan(
                    text: dynamicTextPart, // 영양소별 동적 코멘트
                    style: TextStyle(fontWeight: FontWeight.bold, color: dynamicTextColor),
                  ),
                  const TextSpan(text: "입니다.\n"), // 줄바꿈 추가
                  TextSpan(text: kDefaultComment, style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5)), // 기본 조언
                ],
              ),
              textAlign: TextAlign.center, // 텍스트 중앙 정렬
            ),
          ),
        ),
      ),
    );
  }
}

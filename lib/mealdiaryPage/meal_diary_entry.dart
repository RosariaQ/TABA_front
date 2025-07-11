import 'package:intl/intl.dart'; // 날짜 및 시간 포맷팅을 위해

class MealDiaryEntry {
  final int id; // ✅ 식단 고유 ID
  final String imagePath; // 이미지 전체 경로
  final String time; // 오전 10:03 형식 시간
  final String foodName; // 대표 음식 이름
  final double energyKcal; // 칼로리 (kcal)
  final double intakeAmount; // 섭취량 (인분 기준)
  final String notes; // 사용자 메모
  final DateTime createdAt; // 생성 시간

  MealDiaryEntry({
    required this.id,
    required this.imagePath,
    required this.time,
    required this.foodName,
    required this.energyKcal,
    required this.intakeAmount,
    required this.notes,
    required this.createdAt,
  });

  factory MealDiaryEntry.fromJson(Map<String, dynamic> json) {
    final DateTime createdAt = DateTime.parse(json['createdAt'] as String);
    final String timeFormatted =
        DateFormat('M월 d일 a h:mm', 'ko_KR').format(createdAt);

    final String imageBaseUrl = 'http://healthymeal.kro.kr:4912/uploads/';
    final String fullImagePath =
        imageBaseUrl + (json['imgPath'] as String? ?? '');

    final foodList = json['mealInfoFoodLinks'] as List<dynamic>? ?? [];
    final food = foodList.isNotEmpty
        ? foodList[0]['food'] as Map<String, dynamic>? ?? {}
        : {};

    final String foodName = food['name'] ?? '이름 없음';
    final double energyKcal = (food['energyKcal'] as num?)?.toDouble() ?? 0.0;
    final double intakeAmount =
        (json['intakeAmount'] as num?)?.toDouble() ?? 0.0;

    return MealDiaryEntry(
      id: json['id'] as int? ?? -1, // ✅ id 파싱 (없으면 -1)
      imagePath: fullImagePath,
      time: timeFormatted,
      foodName: foodName,
      energyKcal: energyKcal,
      intakeAmount: intakeAmount,
      notes: json['diary'] as String? ?? '',
      createdAt: createdAt,
    );
  }
}

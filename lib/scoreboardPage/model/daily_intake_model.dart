// lib/scoreboardPage/model/daily_intake_model.dart

// 이 파일은 API 응답을 Dart 객체로 변환하기 위한 모델입니다.
// 스코어보드 기능에서는 주로 날짜(day)와 점수(score) 필드를 사용합니다.
// 다른 영양 정보 필드들은 상세 분석이나 다른 기능에서 활용될 수 있습니다.

class DailyIntake {
  final int id; // 기록의 고유 식별자 (API 응답에 따라 String일 수도 있음)
  final DateTime day; // 해당 날짜
  final int energyKcal; // 에너지 (kcal)
  final double proteinG; // 단백질 (g)
  final double fatG; // 지방 (g)
  final double carbohydrateG; // 탄수화물 (g)
  final double sugarsG; // 당류 (g)
  final double celluloseG; // 식이섬유 (g)
  final double sodiumMg; // 나트륨 (mg)
  final double cholesterolMg; // 콜레스테롤 (mg)
  final int score; // 해당 날짜의 종합 식단 점수

  // 'user' 필드는 API 스키마에 'any' 타입으로 되어 있어,
  // 필요에 따라 구체적인 User 모델로 정의하거나 Map<String, dynamic>으로 처리,
  // 또는 이 모델에서는 생략할 수 있습니다. 현재는 생략된 상태입니다.

  DailyIntake({
    required this.id,
    required this.day,
    required this.energyKcal,
    required this.proteinG,
    required this.fatG,
    required this.carbohydrateG,
    required this.sugarsG,
    required this.celluloseG,
    required this.sodiumMg,
    required this.cholesterolMg,
    required this.score,
  });

  // JSON 데이터로부터 DailyIntake 객체를 생성하는 factory 생성자
  factory DailyIntake.fromJson(Map<String, dynamic> json) {
    // 숫자 타입 필드는 안전하게 num으로 받고 toDouble() 또는 toInt()로 변환
    // API 응답에 해당 필드가 없을 수 있으므로 null 체크 및 기본값 설정
    return DailyIntake(
      id: json['id'] as int? ?? -1, // id가 null이거나 타입이 다르면 -1과 같은 기본값 또는 오류 처리
      day: DateTime.parse(json['day'] as String), // API 날짜 형식이 ISO 8601 문자열이라고 가정
      energyKcal: json['energyKcal'] as int? ?? 0, // API 응답에 필드가 없거나 null이면 0으로 처리
      proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fatG'] as num?)?.toDouble() ?? 0.0,
      carbohydrateG: (json['carbohydrateG'] as num?)?.toDouble() ?? 0.0,
      sugarsG: (json['sugarsG'] as num?)?.toDouble() ?? 0.0,
      celluloseG: (json['celluloseG'] as num?)?.toDouble() ?? 0.0,
      sodiumMg: (json['sodiumMg'] as num?)?.toDouble() ?? 0.0,
      cholesterolMg: (json['cholesterolMg'] as num?)?.toDouble() ?? 0.0,
      score: json['score'] as int? ?? 0, // 점수도 null일 수 있다면 0으로 처리
    );
  }

  // DailyIntake 객체를 JSON으로 변환하는 메소드 (필요시 구현)
  // Map<String, dynamic> toJson() {
  //   return {
  //     'id': id,
  //     'day': day.toIso8601String(),
  //     'energyKcal': energyKcal,
  //     'proteinG': proteinG,
  //     'fatG': fatG,
  //     'carbohydrateG': carbohydrateG,
  //     'sugarsG': sugarsG,
  //     'celluloseG': celluloseG,
  //     'sodiumMg': sodiumMg,
  //     'cholesterolMg': cholesterolMg,
  //     'score': score,
  //   };
  // }
}

// lib/nutrientintakePage/model/daily_intake_model.dart

// kNutrientApiFieldMap을 사용하기 위해 constants 파일을 import 합니다.
import '../nutrient_intake_constants.dart';

class DailyIntake {
  final String id; // 고유 ID (API 응답에 따라 타입 변경 가능, 예: int)
  final DateTime day; // 해당 날짜
  final int? energyKcal; // 에너지 (kcal)
  final double? proteinG; // 단백질 (g)
  final double? fatG; // 지방 (g)
  final double? carbohydrateG; // 탄수화물 (g)
  final double? sugarsG; // 당류 (g)
  final double? celluloseG; // 섬유질 (g)
  final double? sodiumMg; // 나트륨 (mg)
  final double? cholesterolMg; // 콜레스테롤 (mg)
  final int score; // 해당 날짜의 종합 점수 (이 값을 그래프 등에 사용)

  DailyIntake({
    required this.id,
    required this.day,
    this.energyKcal,
    this.proteinG,
    this.fatG,
    this.carbohydrateG,
    this.sugarsG,
    this.celluloseG,
    this.sodiumMg,
    this.cholesterolMg,
    required this.score,
  });

  // JSON 데이터로부터 DailyIntake 객체를 생성하는 factory 생성자
  factory DailyIntake.fromJson(Map<String, dynamic> json) {
    return DailyIntake(
      // API 응답의 ID 타입이 불확실하면 (숫자 또는 문자열), 안전하게 문자열로 처리
      // 또는 API 스펙에 따라 정확한 타입으로 캐스팅 (예: json['id'] as int)
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(), // id가 null일 경우 현재 시간으로 임시 id 생성
      day: DateTime.parse(json['day'] as String), // 날짜 문자열을 DateTime 객체로 변환
      energyKcal: json['energyKcal'] as int?, // int 타입, null 허용
      proteinG: (json['proteinG'] as num?)?.toDouble(), // num 타입을 double로 변환, null 허용
      fatG: (json['fatG'] as num?)?.toDouble(),
      carbohydrateG: (json['carbohydrateG'] as num?)?.toDouble(),
      sugarsG: (json['sugarsG'] as num?)?.toDouble(),
      celluloseG: (json['celluloseG'] as num?)?.toDouble(),
      sodiumMg: (json['sodiumMg'] as num?)?.toDouble(),
      cholesterolMg: (json['cholesterolMg'] as num?)?.toDouble(),
      score: json['score'] as int? ?? 0, // score가 null이면 0으로 기본값 처리
    );
  }

  // 특정 영양소의 값을 문자열 키(kNutrientKeys에 정의된)를 사용하여 가져오는 헬퍼 메소드
  // nutrientKey는 'Protein', 'Fat' 등 UI에 표시되는 영양소 이름입니다.
  // kNutrientApiFieldMap을 통해 실제 JSON 필드명('proteinG', 'fatG' 등)으로 변환하여 값을 찾습니다.
  double? getNutrientValue(String nutrientKey) {
    // nutrientKey (예: 'Protein')를 실제 JSON 필드명 (예: 'proteinG')으로 매핑
    final fieldName = kNutrientApiFieldMap[nutrientKey];
    if (fieldName == null) return null; // 매핑되는 필드명이 없으면 null 반환

    switch (fieldName) {
      case 'proteinG':
        return proteinG;
      case 'fatG':
        return fatG;
      case 'carbohydrateG':
        return carbohydrateG;
      case 'celluloseG': // 섬유질
        return celluloseG;
      case 'sugarsG': // 당류
        return sugarsG;
      case 'sodiumMg': // 나트륨
        return sodiumMg;
      case 'cholesterolMg': // 콜레스테롤
        return cholesterolMg;
      // energyKcal은 int? 타입이므로 double?로 변환 필요시 아래와 같이 처리
      // case 'energyKcal':
      //   return energyKcal?.toDouble();
      default:
        // 정의되지 않은 필드명에 대해서는 null 반환
        return null;
    }
  }
}

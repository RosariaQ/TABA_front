// lib/nutrientintakePage/nutrient_intake_constants.dart
import 'package:flutter/material.dart';

// Colors
const Color kNutrientIntakePrimaryColor = Colors.teal; // 주요 색상 (예: AppBar, 버튼 등)
const Color kNutrientIntakeGraphAccentColor = Colors.redAccent; // 그래프 바 색상
final Color kNutrientIntakeGraphBackgroundColor = Colors.grey.shade200; // 그래프 배경색

// API Configuration
// TODO: 실제 운영 환경에서는 이 URL을 안전한 곳에 보관하거나 환경별로 관리해야 합니다.
const String kApiBaseUrl = "http://healthymeal.kro.kr:4912"; // API 기본 URL
// const String kDefaultUserId = "TestUser"; // 기본 사용자 ID (테스트용, 실제 앱에서는 동적으로 가져와야 함)

// Nutrient Keys - UI 표시 및 데이터 매핑에 사용
// DailyIntake 모델의 getNutrientValue 및 NutrientIntakeDataService의 getCurrentNutrientName 등에서 사용
const List<String> kNutrientKeys = [
  'Carbohydrate', // 탄수화물
  'Protein',      // 단백질
  'Fat',          // 지방
  'Fiber',        // 섬유질 (식이섬유)
  'Sugars',       // 당류
  'Sodium',       // 나트륨
  'Cholesterol'   // 콜레스테롤
  // 필요에 따라 'Energy' (에너지) 등 다른 영양소 추가 가능
];

// UI에 표시되는 영양소 이름(kNutrientKeys)과 DailyIntake 모델의 실제 필드명(API 응답 기준)을 매핑
// DailyIntake 모델의 getNutrientValue 메소드에서 사용됩니다.
const Map<String, String> kNutrientApiFieldMap = {
  'Carbohydrate': 'carbohydrateG',
  'Protein': 'proteinG',
  'Fat': 'fatG',
  'Fiber': 'celluloseG', // API 스키마에서 celluloseG가 섬유질에 해당
  'Sugars': 'sugarsG',
  'Sodium': 'sodiumMg',
  'Cholesterol': 'cholesterolMg',
  // 'Energy': 'energyKcal', // 필요시 에너지 필드 매핑 추가
};


// UI Texts
const String kAppBarTitle = "섭취 데이터 분석"; // 앱바 제목
const String kDefaultComment = "선택된 영양소의 섭취량을 확인하고 식단 조절에 참고하세요. 일별 종합 점수는 그래프에 표시됩니다."; // 기본 코멘트
const String kErrorPreviousData = "더 이상 이전 데이터가 없습니다."; // 이전 데이터 없음 오류 메시지
const String kErrorNextData = "더 이상 다음 데이터가 없습니다."; // 다음 데이터 없음 오류 메시지
const String kErrorLoadingData = "데이터를 불러오는 중 오류가 발생했습니다."; // 데이터 로딩 오류 메시지
const String kLoadingData = "데이터를 불러오는 중..."; // 데이터 로딩 중 텍스트

// 주간 차트 요일 표시 (NutrientWeeklyChart에서 사용, 월요일 시작 기준)
const List<String> kDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// Graph visual constants (NutrientWeeklyChart에서 사용)
const double kGraphValueTextFontSize = 9.5; // 그래프 값 텍스트 크기
const double kGraphDayTextFontSize = 10.0; // 그래프 요일 텍스트 크기
// 텍스트 높이 근사치 (폰트 크기 및 line-height에 따라 조절)
const double kGraphTextLineHeightApproximation = kGraphValueTextFontSize * 1.8;
const double kGraphTopSizedBoxHeight = 2.0; // 바 위쪽 여백
const double kGraphBottomSizedBoxHeight = 3.0; // 바 아래쪽 여백 (요일 텍스트 전)
const double kGraphContainerVerticalPadding = 6.0 * 2; // 그래프 컨테이너 상하 패딩

// DailyIntake 모델 클래스는 nutrientintakePage/model/daily_intake_model.dart 로 이동되었습니다.

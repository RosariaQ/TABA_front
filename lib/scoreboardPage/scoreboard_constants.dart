// lib/scoreboardPage/scoreboard_constants.dart
import 'package:flutter/material.dart';

// 스코어보드 화면 전용 주요 색상 (앱 전체 테마와 통합 또는 별도 관리 가능)
const Color primaryScoreboardColor = Colors.teal; // 주요 색상 (예: 선택된 토글 버튼, 상세 보기 버튼 테두리)
const Color accentScoreboardColor = Colors.redAccent; // 강조 색상 (예: 주간 차트 막대)

// API 조회 범위 결정 등에 참고될 수 있는 상수
// 예: 오늘을 기준으로 과거 12주, 미래 4주까지의 데이터를 조회 범위로 설정
const int weeksOfDataBeforeToday = 12; // 과거 데이터 조회 주 수
const int weeksOfDataAfterToday = 4;  // 미래 데이터 조회 주 수 (필요시)


// 요일 이름 (주간 차트 등에서 사용 - 영어 약자, 월요일 시작 기준)
// DateTime.weekday는 1(월요일) ~ 7(일요일)이므로, 리스트 인덱스 접근 시 (date.weekday - 1) 사용
const List<String> dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// 요일 이름 (월간 달력 헤더 표시용 - 한국어, 일요일 시작 기준)
// MonthlyCalendarView에서 DateTime.weekday (1:월 ~ 7:일)를
// 0:일 ~ 6:토 인덱스로 변환하여 사용합니다.
const List<String> dayNamesKorean = ['일', '월', '화', '수', '목', '금', '토'];

// 실제 API의 기본 URL
// TODO: 실제 운영 환경에서는 이 URL을 안전한 곳에 보관하거나 환경별로 관리해야 합니다.
const String apiBaseUrl = 'http://healthymeal.kro.kr:4912/v3'; // 스코어보드 관련 API 기본 주소

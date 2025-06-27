// lib/scoreboardPage/services/scoreboard_data_service.dart

import 'dart:convert'; // JSON 디코딩을 위해
import 'package:flutter/material.dart'; // DateUtils 사용을 위해
import 'package:http/http.dart' as http; // HTTP 요청을 위해
import 'package:intl/intl.dart'; // 날짜 포맷팅을 위해

import '../scoreboard_constants.dart'; // 상수 파일 (API URL, 요일 이름 등)
import '../model/daily_intake_model.dart'; // 일일 섭취량 데이터 모델

class ScoreboardDataService {
  DateTime currentWeekStartDate; // 현재 선택된 주의 시작일 (월요일 기준)
  late DateTime oldestWeekStartDate; // 조회 가능한 가장 오래된 주의 시작일
  late DateTime newestWeekStartDate; // 조회 가능한 가장 최신 주의 시작일
  DateTime currentSelectedMonth; // 현재 선택된 월 (해당 월의 1일)

  final String _userId; // API 호출에 필요한 사용자 ID
  List<DailyIntake> _allDailyIntakes = []; // API로부터 받아온 전체 데이터 캐싱
  bool _isFetchingData = false; // 데이터 요청 중복 방지 플래그
  bool _initialDataFetched = false; // 초기 데이터 로드 완료 여부

  // 생성자: 사용자 ID를 받아 초기 날짜 설정
  ScoreboardDataService({required String userId})
      : _userId = userId,
        currentWeekStartDate = _getInitialWeekStartDate(),
        currentSelectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1) { // 현재 월의 1일로 초기화
    _initializeDateBoundaries();
  }

  // 현재 주의 시작일(월요일)을 계산하는 static 메소드
  static DateTime _getInitialWeekStartDate() {
    final now = DateTime.now();
    // Dart의 DateTime.weekday는 월요일이 1, 일요일이 7
    return now.subtract(Duration(days: now.weekday - 1));
  }

  // 조회 가능한 날짜 경계를 초기화하는 메소드
  void _initializeDateBoundaries() {
    final initialWeekStart = _getInitialWeekStartDate();
    // 예시: 과거 12주, 미래 4주까지의 데이터를 UI에서 이동 가능하도록 설정 (scoreboard_constants.dart 참고)
    oldestWeekStartDate = initialWeekStart.subtract(Duration(days: weeksOfDataBeforeToday * 7));
    newestWeekStartDate = initialWeekStart.add(Duration(days: weeksOfDataAfterToday * 7));
  }

  // 사용자 ID를 반환하는 getter (필요시 사용)
  String get userId => _userId;

  // 초기 데이터 로드 완료 여부를 반환하는 getter
  bool get isInitialDataFetched => _initialDataFetched;


  // 특정 사용자의 모든 일일 섭취 데이터를 API로부터 가져오는 메소드
  Future<void> fetchAllDataForUser({bool forceRefresh = false}) async {
    // 이미 데이터를 가져오는 중이거나, 이미 초기 데이터를 가져왔고 강제 새로고침이 아니면 중복 요청 방지
    if (_isFetchingData && !forceRefresh) return;
    if (_initialDataFetched && !forceRefresh) return;

    _isFetchingData = true;
    // TODO: API 기본 URL은 scoreboard_constants.dart의 apiBaseUrl 사용
    final Uri uri = Uri.parse('$apiBaseUrl/users/$_userId/daily-intake');
    print('Scoreboard 서비스 - 데이터 요청: $uri (사용자: $_userId)');

    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'}, // 요청 헤더
      ).timeout(const Duration(seconds: 20)); // 타임아웃 설정 (20초)

      if (response.statusCode == 200) {
        // UTF-8로 디코딩하여 한글 깨짐 방지
        final List<dynamic> decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        _allDailyIntakes = decodedData
            .map((jsonItem) => DailyIntake.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
        _allDailyIntakes.sort((a, b) => a.day.compareTo(b.day)); // 날짜순으로 정렬
        _initialDataFetched = true; // 초기 데이터 로드 완료 플래그 설정
        print('Scoreboard 서비스 - 일일 섭취 기록 ${_allDailyIntakes.length}개 로드 성공.');
      } else {
        print('Scoreboard 서비스 - 일일 섭취 기록 로드 실패. 상태 코드: ${response.statusCode}');
        print('응답 본문: ${response.body}');
        _allDailyIntakes = []; // 실패 시 데이터 초기화
        // throw Exception('일일 섭취 기록 로드 실패: ${response.statusCode}'); // UI에서 처리하도록 예외 발생 가능
      }
    } catch (e) {
      print('Scoreboard 서비스 - 일일 섭취 기록 로드 중 오류: $e');
      _allDailyIntakes = []; // 예외 발생 시 데이터 초기화
      // throw Exception('일일 섭취 기록 로드 중 오류: $e'); // UI에서 처리하도록 예외 발생 가능
    } finally {
      _isFetchingData = false;
    }
  }

  // 특정 주의 데이터를 가공하여 차트에 표시할 형태로 반환하는 메소드
  Future<List<Map<String, dynamic>>> getWeekData(DateTime startDate) async {
    // 초기 데이터가 로드되지 않았고, 현재 데이터를 가져오는 중도 아니라면 데이터 로드 시도
    if (!_initialDataFetched && !_isFetchingData) {
      await fetchAllDataForUser();
    }

    // 입력된 startDate를 기준으로 해당 주의 월요일 계산
    final weekStartDate = startDate.subtract(Duration(days: startDate.weekday - 1));
    final endDate = weekStartDate.add(const Duration(days: 6)); // 해당 주의 일요일

    // 해당 주에 포함되는 섭취 기록 필터링
    List<DailyIntake> weekIntakes = _allDailyIntakes.where((intake) {
      return !intake.day.isBefore(weekStartDate) && !intake.day.isAfter(endDate);
    }).toList();

    // 차트에 사용할 데이터 형태로 변환 (7일치 데이터 생성)
    List<Map<String, dynamic>> weekDataForChart = List.generate(7, (index) {
      final currentDate = weekStartDate.add(Duration(days: index));
      // 해당 날짜의 섭취 기록 찾기 (없으면 기본값 사용)
      final intakeForDay = weekIntakes.firstWhere(
        (intake) => DateUtils.isSameDay(intake.day, currentDate), // DateUtils로 날짜 비교
        orElse: () => DailyIntake(id: -1, day: currentDate, score: 0, energyKcal:0, proteinG:0, fatG:0, carbohydrateG:0, sugarsG:0, celluloseG:0, sodiumMg:0, cholesterolMg:0), // 기본값
      );
      // 요일 약어 (scoreboard_constants.dart의 dayNames 사용, 월요일=0 인덱스)
      String dayAbbreviation = dayNames[currentDate.weekday - 1];
      return {
        'day': dayAbbreviation, // 요일 (예: "Mon")
        'value': intakeForDay.score, // 점수
        'date': currentDate, // 실제 날짜
      };
    });
    return weekDataForChart;
  }

  // 특정 월의 일별 점수 데이터를 반환하는 메소드
  Future<Map<int, int>> getMonthlyScores(DateTime month) async {
     if (!_initialDataFetched && !_isFetchingData) {
      await fetchAllDataForUser();
    }

    Map<int, int> scores = {}; // 일(day)을 key, 점수를 value로 하는 맵
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month); // 해당 월의 총 일수

    // 해당 월에 포함되는 섭취 기록 필터링
    List<DailyIntake> monthIntakes = _allDailyIntakes.where((intake) {
      return intake.day.year == month.year && intake.day.month == month.month;
    }).toList();

    // 각 날짜별 점수 매핑
    for (int dayNum = 1; dayNum <= daysInMonth; dayNum++) {
      final currentDate = DateTime(firstDayOfMonth.year, firstDayOfMonth.month, dayNum);
      final intakeForDay = monthIntakes.firstWhere(
        (intake) => DateUtils.isSameDay(intake.day, currentDate),
        orElse: () => DailyIntake(id: -1, day: currentDate, score: 0, energyKcal:0, proteinG:0, fatG:0, carbohydrateG:0, sugarsG:0, celluloseG:0, sodiumMg:0, cholesterolMg:0),
      );
      scores[dayNum] = intakeForDay.score; // 점수가 없는 날은 0점으로 처리
    }
    return scores;
  }

  // 주어진 주간 데이터의 평균 점수를 계산하는 메소드
  double calculateAverageScore(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 0;
    // 점수가 0보다 큰 유효한 점수들만 필터링하여 평균 계산
    final validScores = data
        .where((d) => d['value'] != null && (d['value'] as int) > 0)
        .map((d) => d['value'] as int)
        .toList();
    if (validScores.isEmpty) return 0;
    final totalScore = validScores.reduce((a, b) => a + b);
    return totalScore / validScores.length;
  }

  // 주어진 월간 점수 데이터의 평균 점수를 계산하는 메소드
  double calculateAverageMonthlyScore(Map<int, int> monthlyScores) {
    if (monthlyScores.isEmpty) return 0;
    final validScores = monthlyScores.values.where((score) => score > 0).toList();
    if (validScores.isEmpty) return 0;
    final totalScore = validScores.reduce((a, b) => a + b);
    return totalScore / validScores.length;
  }

  // 주간 날짜 범위를 포맷팅하는 메소드 (예: "5월 1일 ~ 5월 7일, 2023")
  String formatDateRange(DateTime startDate) {
    // 입력된 startDate를 기준으로 해당 주의 월요일 계산
    final weekStartDate = startDate.subtract(Duration(days: startDate.weekday - 1));
    final endDate = weekStartDate.add(const Duration(days: 6)); // 해당 주의 일요일

    // 시작일과 종료일의 월이 다르면 각 월을 표시, 같으면 한 번만 표시
    if (weekStartDate.month == endDate.month) {
      return "${DateFormat('MMMM d일', 'ko_KR').format(weekStartDate)} ~ ${DateFormat('d일', 'ko_KR').format(endDate)}, ${weekStartDate.year}";
    } else {
      return "${DateFormat('MMMM d일', 'ko_KR').format(weekStartDate)} ~ ${DateFormat('MMMM d일', 'ko_KR').format(endDate)}, ${weekStartDate.year}";
    }
  }

  // 월을 포맷팅하는 메소드 (예: "2023년 5월")
  String formatMonth(DateTime month) {
    return DateFormat('yyyy년 MMMM', 'ko_KR').format(month); // 연도와 한국어 월 표시
  }

  // 주를 변경하는 로직 (weeksToAdd: -1 또는 1)
  Map<String, dynamic> changeWeek(int weeksToAdd) {
    final targetStartDate = currentWeekStartDate.add(Duration(days: weeksToAdd * 7));
    String? snackBarMessage;
    bool dateActuallyChanged = false;

    // 조회 가능한 날짜 경계 확인
    if (targetStartDate.isBefore(oldestWeekStartDate)) {
      snackBarMessage = '더 이상 이전 데이터가 없습니다.';
      // currentWeekStartDate = oldestWeekStartDate; // 경계로 설정 (선택적)
    } else if (targetStartDate.isAfter(newestWeekStartDate)) {
      snackBarMessage = '더 이상 다음 데이터가 없습니다.';
      // currentWeekStartDate = newestWeekStartDate; // 경계로 설정 (선택적)
    } else {
      if (!DateUtils.isSameDay(currentWeekStartDate, targetStartDate)) {
        currentWeekStartDate = targetStartDate;
        dateActuallyChanged = true;
      }
    }
    return {
      'newDate': currentWeekStartDate, // 변경된 (또는 변경되지 않은) 주의 시작일
      'snackBarMessage': snackBarMessage, // 표시할 스낵바 메시지
      'dateChanged': dateActuallyChanged, // 실제 날짜 변경 여부
    };
  }

  // 월을 변경하는 로직 (monthsToAdd: -1 또는 1)
  Map<String, dynamic> changeMonth(int monthsToAdd) {
    DateTime newMonth = DateTime(currentSelectedMonth.year, currentSelectedMonth.month + monthsToAdd, 1);
    // 월간 조회 경계 설정 (예: 현재 날짜 기준 과거 2년, 미래 1년)
    // TODO: 이 경계값들은 앱 전체 설정 또는 사용자 프로필에 따라 동적으로 관리될 수 있습니다.
    DateTime oldestMonthBoundary = DateTime(DateTime.now().year - 2, 1, 1);
    DateTime newestMonthBoundary = DateTime(DateTime.now().year + 1, 12, 1);

    String? snackBarMessage;
    bool monthActuallyChanged = false;

    if (newMonth.isBefore(oldestMonthBoundary)) {
      newMonth = oldestMonthBoundary; // 경계값으로 설정
      snackBarMessage = '더 이상 이전 데이터가 없습니다.';
    } else if (newMonth.isAfter(newestMonthBoundary)) {
      newMonth = newestMonthBoundary; // 경계값으로 설정
      snackBarMessage = '더 이상 다음 데이터가 없습니다.';
    } else {
      // 월이 실제로 변경되었는지 확인 (연도와 월 모두 비교)
      if (currentSelectedMonth.year != newMonth.year || currentSelectedMonth.month != newMonth.month) {
         monthActuallyChanged = true;
      }
    }
    currentSelectedMonth = newMonth; // 현재 선택된 월 업데이트
    return {
      'newDate': currentSelectedMonth, // 변경된 (또는 변경되지 않은) 월의 첫날
      'snackBarMessage': snackBarMessage,
      'dateChanged': monthActuallyChanged,
    };
  }
}

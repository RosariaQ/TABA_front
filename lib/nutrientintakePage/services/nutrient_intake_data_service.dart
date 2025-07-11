// lib/nutrientintakePage/services/nutrient_intake_data_service.dart
import 'dart:convert'; // for json.decode
// for max function
import 'package:flutter/material.dart'; // Required for DateUtils
import 'package:http/http.dart' as http; // HTTP 요청을 위한 패키지
import 'package:intl/intl.dart'; // 날짜 포맷팅을 위한 패키지
import '../nutrient_intake_constants.dart'; // 상수 (API URL, UI 텍스트 등)
import '../model/daily_intake_model.dart'; // DailyIntake 모델 클래스

class NutrientIntakeDataService {
  late DateTime currentWeekStartDate;
  late DateTime oldestWeekStartDateForDisplay;
  late DateTime newestWeekStartDateForDisplay;
  int selectedNutrientIndex = 0;

  late DateTime currentSelectedMonth;
  late DateTime oldestMonthForDisplay;
  late DateTime newestMonthForDisplay;

  final String userId;
  List<DailyIntake> _allFetchedIntakes = [];
  bool _isFetchingAllIntakes = false;
  bool _hasFetchedInitialAllIntakes = false;

  Map<String, dynamic>? _userProfileData;
  Map<String, dynamic>? _dietCriterionData;
  bool _isFetchingUserAndCriterion = false;
  bool _hasFetchedInitialUserAndCriterion = false;

  final String _baseApiUrl = "http://healthymeal.kro.kr:4912";

  NutrientIntakeDataService({required this.userId}) {
    _initializeDatesAndNutrient();
  }

  void _initializeDatesAndNutrient() {
    final now = DateTime.now();
    currentWeekStartDate = _getStartOfWeek(now);
    oldestWeekStartDateForDisplay = currentWeekStartDate.subtract(const Duration(days: 365 * 1));
    newestWeekStartDateForDisplay = currentWeekStartDate.add(const Duration(days: 90));
    currentSelectedMonth = DateTime(now.year, now.month, 1);
    oldestMonthForDisplay = DateTime(now.year - 1, 1, 1);
    newestMonthForDisplay = DateTime(now.year, now.month + 3, 1);
    if (newestMonthForDisplay.isAfter(DateTime(now.year, now.month + 3, 0))) {
      newestMonthForDisplay = DateTime(now.year, now.month + 3, 0);
    }
    selectedNutrientIndex = 0;
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void setCurrentWeekFromDate(DateTime date) {
    currentWeekStartDate = _getStartOfWeek(date);
  }

  Future<void> _fetchUserProfile() async {
    if (userId.isEmpty) {
      _userProfileData = null;
      debugPrint('User ID is empty, cannot fetch profile.');
      return;
    }
    debugPrint('Fetching user profile for user: $userId');
    try {
      final response = await http.get(Uri.parse('$_baseApiUrl/users/$userId'));
      if (response.statusCode == 200) {
        _userProfileData = json.decode(utf8.decode(response.bodyBytes));
        debugPrint('User profile fetched successfully: $_userProfileData');
      } else {
        debugPrint('Failed to load user profile. Status: ${response.statusCode}, Body: ${response.body}');
        _userProfileData = null;
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      _userProfileData = null;
    }
  }

  // _fetchDietCriterion 함수가 특정 나이를 인자로 받을 수 있도록 수정
  Future<bool> _fetchDietCriterion({int? specificAge}) async {
    if (_userProfileData == null || _userProfileData!['gender'] == null) {
      debugPrint("User profile data (especially gender) is incomplete for fetching diet criterion. Profile: $_userProfileData");
      _dietCriterionData = null;
      return false; // 성별 정보가 없으면 기준치 조회 불가
    }
    
    int ageToUse;

    if (specificAge != null) {
      ageToUse = specificAge;
      debugPrint('Using specific age for diet criterion: $ageToUse');
    } else {
      // 동적으로 나이 계산
      final birthDateString = _userProfileData!['birthday'] as String?;
      if (birthDateString == null) {
        _dietCriterionData = null;
        debugPrint('Birthday is null, cannot calculate dynamic age.');
        return false; // 생년월일 정보 없으면 동적 나이 계산 불가
      }
      final birthDate = DateTime.parse(birthDateString);
      final now = DateTime.now();
      ageToUse = now.year - birthDate.year;
      if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
        ageToUse--;
      }
      debugPrint('Calculated dynamic age for diet criterion: $ageToUse');
    }

    final gender = _userProfileData!['gender'] as String?;
    if (gender == null) { // 이중 확인 (위에서 이미 체크했지만)
      _dietCriterionData = null;
      debugPrint('Gender is null.');
      return false;
    }
    
    String apiGenderParam = gender;
    if (gender == 'm' || gender == 'f') { 
      apiGenderParam = gender.toUpperCase();
    }
    
    debugPrint('Fetching diet criterion for age: $ageToUse, gender for API: $apiGenderParam');

    try {
      final url = Uri.parse('$_baseApiUrl/diet-criteria/')
                      .replace(queryParameters: {'age': ageToUse.toString(), 'gender': apiGenderParam });
      debugPrint('Requesting Diet Criterion from URL: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic>? criterionDataFromApi = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>?;
        
        if (criterionDataFromApi != null && criterionDataFromApi.isNotEmpty) {
          _dietCriterionData = criterionDataFromApi;
          debugPrint('Diet criterion fetched successfully (as Map): $_dietCriterionData');
          return true; // 데이터 로드 성공
        } else {
          _dietCriterionData = null;
          debugPrint('Diet criterion data not found or empty for age: $ageToUse, gender: $apiGenderParam. Response: ${response.body}');
          return false; // 데이터 없음
        }
      } else {
        debugPrint('Failed to load diet criterion. Status: ${response.statusCode}, Body: ${response.body}');
        _dietCriterionData = null;
        return false; // API 호출 실패
      }
    } catch (e) {
      debugPrint('Error fetching or parsing diet criterion: $e');
      _dietCriterionData = null;
      return false; // 예외 발생
    }
  }

  // fetchUserAndCriterionData 함수가 특정 나이를 override 할 수 있도록 수정
  Future<bool> fetchUserAndCriterionData({bool forceRefresh = false, int? specificAgeOverride}) async {
    if (_isFetchingUserAndCriterion && !forceRefresh) return false;
    // _hasFetchedInitialUserAndCriterion 플래그는 최초 동적 연령 시도에만 사용하거나,
    // specificAgeOverride가 있을 경우 다르게 처리할 수 있음.
    // 여기서는 forceRefresh가 true이거나, 아직 초기 로드를 안했거나, override가 있을 때 진행하도록 함.
    if (!forceRefresh && _hasFetchedInitialUserAndCriterion && specificAgeOverride == null) return _dietCriterionData != null;

    _isFetchingUserAndCriterion = true;
    bool profileFetched = false;
    if (_userProfileData == null || forceRefresh) { // 프로필 정보가 없거나 강제 새로고침 시에만 프로필 다시 로드
        await _fetchUserProfile();
    }
    profileFetched = _userProfileData != null;

    bool criterionFetched = false;
    if (profileFetched) { // 프로필 정보가 있어야 기준치 요청 가능
      criterionFetched = await _fetchDietCriterion(specificAge: specificAgeOverride);
    } else {
      _dietCriterionData = null; // 프로필 없으면 기준치도 null
      debugPrint("Skipped fetching diet criterion due to missing user profile.");
    }
    
    // specificAgeOverride가 없을 때만 _hasFetchedInitialUserAndCriterion 플래그 업데이트 (최초 동적 연령 시도 완료)
    if (specificAgeOverride == null) {
        _hasFetchedInitialUserAndCriterion = true;
    }
    _isFetchingUserAndCriterion = false;
    debugPrint("Finished fetching user and criterion data. Profile: $_userProfileData, Criterion: $_dietCriterionData. Criterion Fetched: $criterionFetched");
    return criterionFetched; // 식단 기준 데이터 로드 성공 여부 반환
  }
  
  double? getCriterionForSelectedNutrient() {
    if (_dietCriterionData == null) {
      // debugPrint("getCriterionForSelectedNutrient: Diet criterion data is null."); // 이 로그는 너무 자주 나올 수 있음
      return null;
    }

    final String currentNutrientUiName = getCurrentNutrientName();
    final String? apiFieldName = kNutrientApiFieldMap[currentNutrientUiName];

    if (apiFieldName == null) {
      debugPrint("getCriterionForSelectedNutrient: API field name not found for UI nutrient: $currentNutrientUiName");
      return null;
    }
    
    if (!_dietCriterionData!.containsKey(apiFieldName)) {
        debugPrint("getCriterionForSelectedNutrient: Key '$apiFieldName' not found in _dietCriterionData. Available keys: ${_dietCriterionData!.keys.toList()}.");
        // _dietCriterionData 내용 전체를 로그로 남기는 것은 너무 길 수 있으므로 주요 정보만 남기거나 필요시 주석 해제
        // debugPrint("_dietCriterionData content: $_dietCriterionData"); 
        return null;
    }

    final dynamic value = _dietCriterionData![apiFieldName];
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value);
    }
    debugPrint("getCriterionForSelectedNutrient: Criterion value for $apiFieldName is not a number: $value (type: ${value.runtimeType})");
    return null;
  }

  Future<void> fetchAllDailyIntakes({bool forceRefresh = false}) async {
    if (_isFetchingAllIntakes && !forceRefresh) return;
    if (_hasFetchedInitialAllIntakes && !forceRefresh) return;
    _isFetchingAllIntakes = true;
    debugPrint('Attempting to fetch all daily intakes for user: $userId');
    try {
      final response = await http.get(
        Uri.parse('$_baseApiUrl/users/$userId/daily-intake'),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(utf8.decode(response.bodyBytes));
        _allFetchedIntakes = decodedData.map((jsonItem) => DailyIntake.fromJson(jsonItem)).toList();
        _allFetchedIntakes.sort((a, b) => a.day.compareTo(b.day));
        _hasFetchedInitialAllIntakes = true;
        debugPrint('Successfully fetched ${_allFetchedIntakes.length} daily intake records.');
      } else {
        debugPrint('Failed to load daily intakes. Status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        _allFetchedIntakes = [];
        throw Exception('$kErrorLoadingData (Status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error fetching daily intakes: $e');
      _allFetchedIntakes = [];
      throw Exception('$kErrorLoadingData ($e)');
    } finally {
      _isFetchingAllIntakes = false;
    }
  }

  List<Map<String, dynamic>> getNutrientIntakeForWeek(DateTime weekStartDate, String nutrientKey) {
    if (!_hasFetchedInitialAllIntakes) {
      debugPrint("Warning: Trying to get week nutrient intakes before initial data fetch.");
      return List.generate(7, (i) => {'day': kDayNames[i], 'value': 0.0, 'date': weekStartDate.add(Duration(days: i))});
    }
    List<Map<String, dynamic>> weekNutrientData = [];
    for (int i = 0; i < 7; i++) {
      final currentDate = weekStartDate.add(Duration(days: i));
      final intakeForDay = _allFetchedIntakes.firstWhere(
        (intake) => DateUtils.isSameDay(intake.day, currentDate),
        orElse: () => DailyIntake(id: '', day: currentDate, score: 0),
      );
      final nutrientValue = intakeForDay.getNutrientValue(nutrientKey);
      weekNutrientData.add({
        'day': kDayNames[i],
        'value': nutrientValue ?? 0.0,
        'date': currentDate,
      });
    }
    return weekNutrientData;
  }

  Map<int, double> getNutrientIntakeForMonth(DateTime monthDate, String nutrientKey) {
    if (!_hasFetchedInitialAllIntakes) {
      debugPrint("Warning: Trying to get month nutrient intakes before initial data fetch.");
      return {};
    }
    Map<int, double> monthNutrientData = {};
    final daysInMonth = DateUtils.getDaysInMonth(monthDate.year, monthDate.month);

    for (int day = 1; day <= daysInMonth; day++) {
      final currentDate = DateTime(monthDate.year, monthDate.month, day);
      final intakeForDay = _allFetchedIntakes.firstWhere(
        (intake) => DateUtils.isSameDay(intake.day, currentDate),
        orElse: () => DailyIntake(id: '', day: currentDate, score: 0),
      );
      final nutrientValue = intakeForDay.getNutrientValue(nutrientKey);
      monthNutrientData[day] = nutrientValue ?? 0.0;
    }
    return monthNutrientData;
  }
  
  double getAverageMonthlyIntakeForSelectedNutrient(DateTime monthDate) {
    if (!_hasFetchedInitialAllIntakes) return 0.0;
    final String nutrientKey = getCurrentNutrientName();
    List<double> intakesThisMonth = [];
    final daysInMonth = DateUtils.getDaysInMonth(monthDate.year, monthDate.month);
    for (int day = 1; day <= daysInMonth; day++) {
      final currentDate = DateTime(monthDate.year, monthDate.month, day);
      final dailyIntakeData = _allFetchedIntakes.firstWhere(
        (intake) => DateUtils.isSameDay(intake.day, currentDate),
        orElse: () => DailyIntake(id: '', day: currentDate, score: 0),
      );
      final value = dailyIntakeData.getNutrientValue(nutrientKey);
      if (value != null && value > 0) {
        intakesThisMonth.add(value);
      }
    }
    if (intakesThisMonth.isEmpty) return 0.0;
    return intakesThisMonth.reduce((a, b) => a + b) / intakesThisMonth.length;
  }

  void resetToCurrentWeekAndDefaultNutrient() {
    _initializeDatesAndNutrient();
    _hasFetchedInitialUserAndCriterion = false; 
    _hasFetchedInitialAllIntakes = false;
  }

  String formatMonth(DateTime month) {
    return DateFormat('yyyy년 MMMM', 'ko_KR').format(month);
  }

  Map<String, dynamic> changeMonth(int monthsToAdd) {
    DateTime newMonthTarget = DateTime(currentSelectedMonth.year, currentSelectedMonth.month + monthsToAdd, 1);
    String? snackBarMessage;
    bool dateActuallyChanged = false;
    if (newMonthTarget.isBefore(oldestMonthForDisplay) && !DateUtils.isSameDay(newMonthTarget, oldestMonthForDisplay)) {
      snackBarMessage = kErrorPreviousData;
    } else if (newMonthTarget.isAfter(newestMonthForDisplay) && !DateUtils.isSameDay(newMonthTarget, newestMonthForDisplay)) {
      snackBarMessage = kErrorNextData;
    } else {
      if (currentSelectedMonth.year != newMonthTarget.year || currentSelectedMonth.month != newMonthTarget.month) {
           currentSelectedMonth = newMonthTarget;
           dateActuallyChanged = true;
      }
    }
    return {
      'newDate': currentSelectedMonth,
      'snackBarMessage': snackBarMessage,
      'dateChanged': dateActuallyChanged,
    };
  }

  String formatDateRange(DateTime startDate) {
    final endDate = startDate.add(const Duration(days: 6));
    if (startDate.month == endDate.month) {
      return "${DateFormat('yyyy년 MMMM d일', 'ko_KR').format(startDate)} ~ ${DateFormat('d일', 'ko_KR').format(endDate)}";
    } else {
      return "${DateFormat('yyyy년 MMMM d일', 'ko_KR').format(startDate)} ~ ${DateFormat('MMMM d일', 'ko_KR').format(endDate)}";
    }
  }

  Map<String, dynamic> changeWeek(int weeksToAdd) {
    final targetStartDate = currentWeekStartDate.add(Duration(days: weeksToAdd * 7));
    String? snackBarMessage;
    bool dateActuallyChanged = false;
    if (targetStartDate.isBefore(oldestWeekStartDateForDisplay)) {
      snackBarMessage = kErrorPreviousData;
    } else if (targetStartDate.isAfter(newestWeekStartDateForDisplay)) {
      snackBarMessage = kErrorNextData;
    } else {
      if (!DateUtils.isSameDay(currentWeekStartDate, targetStartDate)) {
        currentWeekStartDate = targetStartDate;
        dateActuallyChanged = true;
      }
    }
    return {
      'newDate': currentWeekStartDate,
      'snackBarMessage': snackBarMessage,
      'dateChanged': dateActuallyChanged,
    };
  }

  String getCurrentNutrientName() {
    if (selectedNutrientIndex < 0 || selectedNutrientIndex >= kNutrientKeys.length) {
      return "알 수 없음";
    }
    return kNutrientKeys[selectedNutrientIndex];
  }

  void changeNutrient(int indexOffset) {
    selectedNutrientIndex = (selectedNutrientIndex + indexOffset + kNutrientKeys.length) % kNutrientKeys.length;
  }

  bool get canGoBackWeek => currentWeekStartDate.isAfter(oldestWeekStartDateForDisplay);
  bool get canGoForwardWeek => currentWeekStartDate.isBefore(newestWeekStartDateForDisplay);

  bool get canGoBackMonth {
    final currentMonthFirstDay = DateTime(currentSelectedMonth.year, currentSelectedMonth.month, 1);
    return currentMonthFirstDay.isAfter(oldestMonthForDisplay);
  }

  bool get canGoForwardMonth {
    final currentMonthFirstDay = DateTime(currentSelectedMonth.year, currentSelectedMonth.month, 1);
    return currentMonthFirstDay.isBefore(newestMonthForDisplay);
  }

  bool get hasFetchedInitialDataStatus => _hasFetchedInitialAllIntakes;
  bool get hasFetchedUserAndCriterionStatus => _hasFetchedInitialUserAndCriterion;
  bool get isCriterionDataAvailable => _hasFetchedInitialUserAndCriterion; // 이전 디버깅용 getter 유지
}

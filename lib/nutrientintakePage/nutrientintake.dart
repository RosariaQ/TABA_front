// lib/nutrientintakePage/nutrientintake.dart
import 'package:flutter/material.dart';
import 'package:healthymeal/scoreboardPage/widgets/scoreboard_period_toggle.dart'; // 기간 선택 토글
import 'package:healthymeal/widgets/common_bottom_navigation_bar.dart'; // 공통 하단 네비게이션 바
import 'nutrient_intake_constants.dart'; // 상수
import 'services/nutrient_intake_data_service.dart'; // 데이터 서비스
import 'widgets/nutrient_selector_button.dart'; // 영양소 선택 버튼
import 'widgets/nutrient_weekly_chart.dart'; // 주간 차트
import 'widgets/nutrient_comment_display.dart'; // 코멘트 표시
import 'widgets/nutrient_monthly_calendar_view.dart'; // 월간 달력

class NutrientIntakeScreen extends StatefulWidget {
  final String userId; // 사용자 ID를 외부에서 받음

  const NutrientIntakeScreen({super.key, required this.userId});

  @override
  State<NutrientIntakeScreen> createState() => _NutrientIntakeScreenState();
}

class _NutrientIntakeScreenState extends State<NutrientIntakeScreen> {
  late NutrientIntakeDataService _dataService; // 데이터 서비스 인스턴스
  final List<bool> _isSelectedPeriod = [true, false, false, false]; // 기간 선택 상태 (주간, 월간, 분기, 연간)

  List<Map<String, dynamic>> _currentWeekChartData = []; // 주간 차트용 데이터
  Map<int, double> _currentMonthNutrientData = {}; // 월간 달력용 데이터 (일: 섭취량)
  double? _currentNutrientCriterion; // 현재 선택된 영양소의 식단 기준치

  late DateTime _displayedDate; // 현재 화면에 표시되는 기준 날짜 (주의 시작일 또는 월의 첫날)
  String _currentDateRangeFormatted = ""; // 화면에 표시될 날짜 범위 문자열
  String _currentNutrientNameForComment = ""; // 코멘트에 표시될 현재 영양소 이름

  bool _isLoading = true; // 데이터 로딩 상태
  String _loadingError = ""; // 로딩 중 오류 메시지
  bool _fallbackDialogShown = false; // 대체 데이터 사용 여부 팝업이 이미 표시되었는지 여부

  @override
  void initState() {
    super.initState();
    _dataService = NutrientIntakeDataService(userId: widget.userId); // userId로 서비스 초기화
    _displayedDate = _dataService.currentWeekStartDate; // 초기 표시는 현재 주의 시작일
    _fetchAllDataAndLoadUI(); // 데이터 로딩 시작
  }

  // 사용자에게 20세 기준 데이터 사용 여부를 묻는 다이얼로그 표시
  Future<bool?> _showUseFallbackDataDialog() async {
    if (!mounted) return false;
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 바깥 영역 탭해도 안 닫히도록
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('식단 기준 알림'),
          content: const Text('현재 연령대에 맞는 식단 기준 데이터가 없습니다.\n20세 기준으로 데이터를 보시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop(false); // 사용자가 취소
              },
            ),
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                Navigator.of(context).pop(true); // 사용자가 확인
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchAllDataAndLoadUI({bool isFallbackAttempt = false, int? fallbackAge}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadingError = "";
    });

    try {
      // 1. 사용자 프로필 정보 및 식단 기준 로드
      //    specificAgeOverride는 fallback 시에만 전달
      bool criterionFetchedSuccessfully = await _dataService.fetchUserAndCriterionData(
        specificAgeOverride: fallbackAge,
        forceRefresh: isFallbackAttempt, // fallback 시에는 캐시된 프로필 사용 가능, 필요시 true
      );

      // 2. 일일 섭취 기록 로드 (이것은 사용자 기준치와 별개로 항상 필요)
      //    만약 _dataService.fetchAllDailyIntakes가 이미 호출되었다면, forceRefresh 없이 호출
      if (!_dataService.hasFetchedInitialDataStatus || isFallbackAttempt) { // fallback 시에는 다시 로드할 필요 없을 수 있음
          await _dataService.fetchAllDailyIntakes(forceRefresh: isFallbackAttempt);
      }


      if (!criterionFetchedSuccessfully && !isFallbackAttempt && !_fallbackDialogShown) {
        // 동적 연령 기준 데이터 로드 실패 & 아직 fallback 시도 안 함 & 다이얼로그 아직 안 뜸
        _fallbackDialogShown = true; // 다이얼로그가 표시되었음을 기록
        bool? useFallback = await _showUseFallbackDataDialog();
        if (useFallback == true) {
          // 사용자가 20세 기준 사용에 동의하면, 20세 기준으로 데이터 다시 로드
          // 재귀 호출 대신, 명시적으로 fallbackAge를 사용하여 다시 호출
          await _fetchAllDataAndLoadUI(isFallbackAttempt: true, fallbackAge: 20);
          return; // 여기서 함수 종료 (데이터 로딩은 재귀 호출된 곳에서 마무리)
        }
        // 사용자가 취소했거나 다이얼로그가 닫힌 경우, 현재 상태로 UI 로드 (기준치 없는 상태)
      }
      
      // 3. 현재 선택된 뷰에 따라 데이터 표시
      _loadDataForCurrentSelection();

    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = e.toString().replaceFirst("Exception: ", "");
        });
      }
      debugPrint("Error in _fetchAllDataAndLoadUI: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  void _loadDataForCurrentSelection() {
    if (!mounted) return;
    _currentNutrientNameForComment = _dataService.getCurrentNutrientName();
    _currentNutrientCriterion = _dataService.getCriterionForSelectedNutrient();
     debugPrint("NutrientIntakeScreen - LoadData - Current Nutrient: $_currentNutrientNameForComment, Criterion: $_currentNutrientCriterion");

    if (_isSelectedPeriod[0]) {
      _loadDataForWeek(_dataService.currentWeekStartDate);
    } else if (_isSelectedPeriod[1]) {
      _loadDataForMonth(_dataService.currentSelectedMonth);
    } else {
      setState(() {
        _currentWeekChartData = [];
        _currentMonthNutrientData = {};
        _currentDateRangeFormatted = "${_getPeriodName(_isSelectedPeriod.indexWhere((e) => e))} 데이터 (미구현)";
      });
    }
  }

  void _loadDataForWeek(DateTime dateForWeek) {
    if (!mounted) return;
    _dataService.setCurrentWeekFromDate(dateForWeek);
    final weekStartDate = _dataService.currentWeekStartDate;
    final String currentNutrientKey = _dataService.getCurrentNutrientName();
    // 영양소 변경 시에도 기준치가 업데이트되도록 여기서 다시 가져옴
    _currentNutrientCriterion = _dataService.getCriterionForSelectedNutrient(); 

    setState(() {
      _displayedDate = weekStartDate;
      _currentWeekChartData = _dataService.getNutrientIntakeForWeek(weekStartDate, currentNutrientKey);
      _currentDateRangeFormatted = _dataService.formatDateRange(weekStartDate);
      _currentNutrientNameForComment = currentNutrientKey;
    });
  }

  void _loadDataForMonth(DateTime monthDate) {
    if (!mounted) return;
    final firstDayOfMonth = _dataService.currentSelectedMonth = DateTime(monthDate.year, monthDate.month, 1);
    final String currentNutrientKey = _dataService.getCurrentNutrientName();
    _currentNutrientCriterion = _dataService.getCriterionForSelectedNutrient();

    setState(() {
      _displayedDate = firstDayOfMonth;
      _currentMonthNutrientData = _dataService.getNutrientIntakeForMonth(firstDayOfMonth, currentNutrientKey);
      _currentDateRangeFormatted = _dataService.formatMonth(firstDayOfMonth);
      _currentNutrientNameForComment = currentNutrientKey;
    });
  }

  void _onPeriodToggleChanged(int index) {
    if (!mounted) return;
    if (_isSelectedPeriod[index] && !_isLoading) return;

    DateTime newDateToDisplay;
    if (index == 0) {
      newDateToDisplay = _dataService.currentWeekStartDate;
    } else if (index == 1) {
      newDateToDisplay = _dataService.currentSelectedMonth;
    } else {
      newDateToDisplay = _displayedDate;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_getPeriodName(index)} 데이터 표시는 아직 구현되지 않았습니다.')),
        );
      }
    }

    setState(() {
      for (int i = 0; i < _isSelectedPeriod.length; i++) {
        _isSelectedPeriod[i] = (i == index);
      }
      _displayedDate = newDateToDisplay;
    });
    _loadDataForCurrentSelection();
  }

  String _getPeriodName(int index) {
    if (index == 1) return "월간";
    if (index == 2) return "분기별";
    if (index == 3) return "연간";
    return "주간";
  }

  void _handleChangeWeek(int weeksToAdd) {
    final result = _dataService.changeWeek(weeksToAdd);
    final String? snackBarMessage = result['snackBarMessage'];
    final bool dateActuallyChanged = result['dateChanged'];
    final DateTime newDisplayDate = _dataService.currentWeekStartDate;

    if (mounted && snackBarMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snackBarMessage), duration: const Duration(seconds: 1)),
      );
    }
    if (dateActuallyChanged) {
      _loadDataForWeek(newDisplayDate);
    }
  }

  void _handleMonthChangeRequest(int monthsToAdd) {
    final result = _dataService.changeMonth(monthsToAdd);
    final String? snackBarMessage = result['snackBarMessage'];
    final bool dateActuallyChanged = result['dateChanged'];
    final DateTime newDisplayMonth = _dataService.currentSelectedMonth;

    if (mounted && snackBarMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snackBarMessage), duration: const Duration(seconds: 1)),
      );
    }
    if (dateActuallyChanged) {
       _loadDataForMonth(newDisplayMonth);
    }
  }

  void _handleChangeNutrient(int indexOffset) {
    _dataService.changeNutrient(indexOffset);
    final newNutrientName = _dataService.getCurrentNutrientName();
    if(mounted) {
      setState(() {
        _currentNutrientNameForComment = newNutrientName;
        _currentNutrientCriterion = _dataService.getCriterionForSelectedNutrient();
        debugPrint("Nutrient Changed - Nutrient: $_currentNutrientNameForComment, New Criterion: $_currentNutrientCriterion");
      });
      if (_isSelectedPeriod[0]) {
        _loadDataForWeek(_displayedDate);
      } else if (_isSelectedPeriod[1]) {
        _loadDataForMonth(_displayedDate);
      }
    }
  }

  void _switchToWeekViewForDate(DateTime date) {
    if (!mounted) return;
    setState(() {
      _isSelectedPeriod[0] = true;
      _isSelectedPeriod[1] = false;
      _isSelectedPeriod[2] = false;
      _isSelectedPeriod[3] = false;
    });
    _loadDataForWeek(date);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    bool canGoMonthBack = false;
    bool canGoMonthForward = false;
    if (_isSelectedPeriod[1]) {
        canGoMonthBack = _dataService.canGoBackMonth;
        canGoMonthForward = _dataService.canGoForwardMonth;
    }

    Widget bodyContent;
    if (_isLoading) {
      bodyContent = const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(kLoadingData),
        ],
      ));
    } else if (_loadingError.isNotEmpty) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_loadingError, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: () => _fetchAllDataAndLoadUI(), // isFallbackAttempt 기본값 false
                  child: const Text("다시 시도"))
            ],
          ),
        ),
      );
    } 
    // _dataService.isCriterionDataAvailable는 NutrientIntakeDataService에 추가된 getter를 사용합니다.
    // 만약 해당 getter가 없다면 _dataService.hasFetchedUserAndCriterionStatus를 사용해야 합니다.
    else if (!_dataService.isCriterionDataAvailable && !_isLoading && !_fallbackDialogShown) { 
        // 이 조건은 초기 로드 시 기준치 데이터가 없고, 아직 다이얼로그를 통해 fallback 시도를 안 한 경우에만 해당될 수 있습니다.
        // 하지만 _fetchAllDataAndLoadUI 내부에서 다이얼로그 로직이 이미 처리되므로, 이 조건은 거의 발생하지 않거나
        // _fallbackDialogShown 플래그와 함께 좀 더 정교하게 관리되어야 합니다.
        // 현재 로직에서는 _fetchAllDataAndLoadUI가 완료된 후 _isLoading이 false가 되므로,
        // 기준치 없음 + 로딩 아님 + 다이얼로그 안 뜸 상태는 _fetchAllDataAndLoadUI 내부에서 처리됩니다.
        // 따라서 이 else if 블록은 실제로 도달하기 어려울 수 있으며, UI 피드백은 _fetchAllDataAndLoadUI 내부에서 관리됩니다.
        // 만약을 위해 남겨두지만, 동작을 면밀히 검토해야 합니다.
        bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 48),
              const SizedBox(height: 16),
              const Text("사용자 맞춤 식단 기준 정보를 가져오지 못했습니다.\n기본 설정으로 표시될 수 있습니다.", textAlign: TextAlign.center, style: TextStyle(color: Colors.orange, fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: () => _fetchAllDataAndLoadUI(),
                  child: const Text("정보 다시 불러오기"))
            ],
          ),
        ),
      );
    }
    else {
      bodyContent = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ScoreboardPeriodToggle(
            isSelected: _isSelectedPeriod,
            onPressed: _onPeriodToggleChanged,
          ),
          const SizedBox(height: 8),
          if (_isSelectedPeriod[0] || _isSelectedPeriod[1])
            Text(
              _currentDateRangeFormatted,
              style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 12),
          NutrientSelectorButton(
            selectedNutrientName: _currentNutrientNameForComment,
            onPressed: () => _handleChangeNutrient(1),
            buttonWidth: screenSize.width - (16.0 * 2),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: _isSelectedPeriod[1] ? 9 : 6,
            child: _isSelectedPeriod[0]
                ? NutrientWeeklyChart(
                    weekData: _currentWeekChartData,
                    onChangeWeek: _handleChangeWeek,
                    onChangeNutrientViaSwipe: _handleChangeNutrient,
                    canGoBack: _dataService.canGoBackWeek,
                    canGoForward: _dataService.canGoForwardWeek,
                    isWeekPeriodSelected: _isSelectedPeriod[0],
                    criterionValue: _currentNutrientCriterion,
                  )
                : _isSelectedPeriod[1]
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
                        decoration: BoxDecoration(
                          color: kNutrientIntakeGraphBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    iconSize: 30.0,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: canGoMonthBack ? () => _handleMonthChangeRequest(-1) : null,
                                    color: canGoMonthBack ? Colors.grey.shade700 : Colors.grey.shade300,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    iconSize: 30.0,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: canGoMonthForward ? () => _handleMonthChangeRequest(1) : null,
                                    color: canGoMonthForward ? Colors.grey.shade700 : Colors.grey.shade300,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: NutrientMonthlyCalendarView(
                                selectedMonth: DateTime(_displayedDate.year, _displayedDate.month, 1),
                                monthlyNutrientData: _currentMonthNutrientData,
                                onDateSelected: (date) {
                                   _switchToWeekViewForDate(date);
                                },
                                onChangeMonthBySwipe: _handleMonthChangeRequest,
                                onChangeNutrientBySwipe: _handleChangeNutrient,
                                canGoBackMonth: canGoMonthBack,
                                canGoForwardMonth: canGoMonthForward,
                                currentNutrientName: _currentNutrientNameForComment,
                                criterionValue: _currentNutrientCriterion,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Center(child: Text("${_getPeriodName(_isSelectedPeriod.indexWhere((e) => e))} 데이터 표시는 아직 구현되지 않았습니다.")),
          ),
          const SizedBox(height: 10),
          Flexible(
            flex: _isSelectedPeriod[1] ? 1 : 2,
            fit: FlexFit.loose,
            child: NutrientCommentDisplay(
              nutrientName: _currentNutrientNameForComment,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(kAppBarTitle, style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: bodyContent,
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(
        currentPage: AppPage.scoreboard, // TODO: 현재 페이지에 맞게 수정 필요
      ),
    );
  }
}

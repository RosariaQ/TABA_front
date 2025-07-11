// lib/scoreboardPage/scoreboard.dart
import 'package:flutter/material.dart';
import 'package:healthymeal/nutrientintakePage/nutrientintake.dart'; // 영양 섭취 상세 페이지
import 'package:shared_preferences/shared_preferences.dart'; // 사용자 ID 로드를 위해

import 'widgets/scoreboard_period_toggle.dart'; // 기간 선택 토글 위젯
import 'widgets/average_score_display.dart'; // 평균 점수 표시 위젯
import 'widgets/weekly_score_chart.dart'; // 주간 점수 차트 위젯
import 'widgets/score_comment_display.dart'; // 점수 코멘트 표시 위젯
import 'services/scoreboard_data_service.dart'; // 데이터 서비스
import '../../widgets/common_bottom_navigation_bar.dart'; // 공통 하단 네비게이션 바
import 'widgets/monthly_calendar_view.dart'; // 월간 달력 위젯
// 상수 (API URL, 요일 이름 등)
// import 'models/daily_intake_model.dart'; // 모델 import는 서비스 파일에서 처리

class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  // 기간 선택 토글 상태 (0:주간, 1:월간, 2:분기, 3:연간)
  final List<bool> _isSelectedToggle = [true, false, false, false];

  late ScoreboardDataService _dataService; // 스코어보드 데이터 서비스
  List<Map<String, dynamic>> _currentWeekChartData = []; // 현재 주의 차트 데이터
  // Map<int, int> _currentMonthScores = {}; // 현재 월의 점수 데이터 (MonthlyCalendarView 내부에서 관리)

  double _currentAverageScore = 0; // 현재 기간의 평균 점수
  String _currentDateRangeFormatted = ""; // 화면에 표시될 날짜 범위 문자열
  late DateTime _displayedDate; // 현재 화면에 표시되는 기준 날짜 (주의 시작일 또는 월의 첫날)

  bool _isLoading = true; // 데이터 로딩 상태
  String? _errorMessage; // 오류 메시지
  String? _userId; // 현재 사용자 ID (SharedPreferences에서 로드)

  @override
  void initState() {
    super.initState();
    // initState에서는 async 작업을 직접 호출할 수 없으므로 별도 함수로 분리
    _initializeData();
  }

  // 데이터 초기화 (사용자 ID 로드 및 초기 데이터 가져오기)
  Future<void> _initializeData() async {
    await _loadUserId(); // 사용자 ID 로드
    if (_userId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "사용자 정보를 불러올 수 없습니다. 로그인이 필요합니다.";
        });
      }
      return;
    }
    _dataService =
        ScoreboardDataService(userId: _userId!); // 사용자 ID로 데이터 서비스 초기화
    _displayedDate = _dataService.currentWeekStartDate; // 초기 표시는 현재 주의 시작일
    await _loadInitialData(); // 초기 데이터 로드 (API 호출)
  }

  // SharedPreferences에서 사용자 ID를 로드하는 함수
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userId = prefs.getString('userId');
      });
    }
  }

  // 초기 데이터 로드 (앱 시작 시 또는 새로고침 시 전체 데이터 한 번 로드)
  Future<void> _loadInitialData() async {
    if (!mounted || _userId == null) return; // userId가 없으면 진행하지 않음
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _dataService.fetchAllDataForUser(); // 데이터 서비스에서 모든 데이터 가져오기
      await _loadDataForCurrentSelection(); // 현재 선택된 뷰(주간)에 대한 데이터 로드
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "초기 데이터 로딩 실패: $e";
          _isLoading = false;
        });
      }
    }
  }

  // 현재 선택된 기간(주간/월간 등)에 맞춰 데이터를 로드하는 함수
  Future<void> _loadDataForCurrentSelection() async {
    if (!mounted || _userId == null) return;
    // 초기 데이터가 아직 로드되지 않았고, 현재 로딩 중도 아니라면 초기 데이터 로드 시도
    if (!_dataService.isInitialDataFetched && !_isLoading) {
      await _loadInitialData();
      return; // _loadInitialData가 이 함수를 다시 호출할 것임
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSelectedToggle[0]) {
        // 주간 보기 선택 시
        await _loadDataForWeek(_displayedDate);
      } else if (_isSelectedToggle[1]) {
        // 월간 보기 선택 시
        await _loadDataForMonth(_displayedDate);
      } else {
        // 분기별/연간 보기 (현재 미구현 상태)
        if (mounted) {
          setState(() {
            _currentWeekChartData = []; // 주간 차트 데이터 초기화
            // _currentMonthScores = {}; // 월간 점수 데이터 초기화 (MonthlyCalendarView가 자체 관리)
            _currentAverageScore = 0;
            _currentDateRangeFormatted =
                _isSelectedToggle[2] ? "분기별 (미구현)" : "연간 (미구현)";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "데이터를 불러오는 중 오류가 발생했습니다: $e";
          _isLoading = false;
        });
      }
      print("스코어보드 데이터 로딩 오류 (_loadDataForCurrentSelection): $e");
    }
  }

  // 특정 주의 데이터를 로드하는 함수
  Future<void> _loadDataForWeek(DateTime targetDate) async {
    if (!mounted || _userId == null) return;
    // targetDate는 사용자가 보려는 주의 아무 날짜나 될 수 있음. 주의 시작일로 정규화.
    final weekStartDate =
        targetDate.subtract(Duration(days: targetDate.weekday - 1));

    final weekData = await _dataService.getWeekData(weekStartDate);
    final averageScore = _dataService.calculateAverageScore(weekData);
    final dateRange = _dataService.formatDateRange(weekStartDate);

    if (mounted) {
      setState(() {
        _displayedDate = weekStartDate; // 화면 기준 날짜 업데이트
        _currentWeekChartData = weekData;
        _currentAverageScore = averageScore;
        _currentDateRangeFormatted = dateRange;
        _dataService.currentWeekStartDate = weekStartDate; // 서비스의 현재 주도 업데이트
        _isLoading = false;
      });
    }
  }

  // 특정 월의 데이터를 로드하는 함수
  Future<void> _loadDataForMonth(DateTime targetMonthDate) async {
    if (!mounted || _userId == null) return;
    // targetMonthDate는 해당 월의 아무 날짜나 될 수 있음. 월의 첫날로 정규화.
    final firstDayOfMonth =
        DateTime(targetMonthDate.year, targetMonthDate.month, 1);

    // 월간 달력은 자체적으로 데이터를 로드하므로, 여기서는 평균 점수와 날짜 범위만 업데이트
    // final monthlyScores = await _dataService.getMonthlyScores(firstDayOfMonth); // 필요시 직접 로드
    // final averageScore = _dataService.calculateAverageMonthlyScore(monthlyScores);
    // 임시로 주간 평균 계산 로직 사용 (월간 평균은 데이터 구조에 따라 다를 수 있음)
    // TODO: 월간 평균 점수 계산 로직을 ScoreboardDataService에 추가하고 호출해야 함.
    //       현재는 getMonthlyScores를 호출하고 그 결과를 calculateAverageMonthlyScore에 넘겨야 함.
    //       또는, 월간 뷰에서는 평균 점수를 다르게 표시하거나, 달력 자체에서 평균을 보여줄 수 있음.
    final tempMonthlyDataForAvg =
        await _dataService.getMonthlyScores(firstDayOfMonth); // 월간 데이터 가져오기
    final averageScore = _dataService
        .calculateAverageMonthlyScore(tempMonthlyDataForAvg); // 월간 평균 계산
    final monthFormatted = _dataService.formatMonth(firstDayOfMonth);

    if (mounted) {
      setState(() {
        _displayedDate = firstDayOfMonth; // 화면 기준 날짜 업데이트
        _currentAverageScore = averageScore; // 월간 평균 점수로 업데이트
        _currentDateRangeFormatted = monthFormatted; // 포맷팅된 월 이름으로 업데이트
        _dataService.currentSelectedMonth = firstDayOfMonth; // 서비스의 현재 월도 업데이트
        _isLoading = false;
      });
    }
  }

  // 주 변경 요청 처리
  void _handleWeekChangeRequest(int weeksToAdd) {
    if (_userId == null) return;
    final result = _dataService.changeWeek(weeksToAdd);
    final DateTime newDisplayDate = result['newDate'];
    _showSnackBarMessage(result['snackBarMessage']);

    if (result['dateChanged'] || _displayedDate != newDisplayDate) {
      if (mounted) {
        setState(() {
          _displayedDate = newDisplayDate; // UI가 즉시 반응하도록 먼저 날짜 업데이트
        });
      }
      _loadDataForWeek(newDisplayDate); // 변경된 displayedDate 기준으로 데이터 로드
    }
  }

  // 월 변경 요청 처리
  void _handleMonthChangeRequest(int monthsToAdd) {
    if (_userId == null) return;
    final result = _dataService.changeMonth(monthsToAdd);
    final DateTime newDisplayMonth = result['newDate']; // 해당 월의 1일
    _showSnackBarMessage(result['snackBarMessage']);

    if (result['dateChanged'] || _displayedDate != newDisplayMonth) {
      if (mounted) {
        setState(() {
          _displayedDate = newDisplayMonth;
        });
      }
      _loadDataForMonth(newDisplayMonth); // 월간 데이터 로드 (주로 평균 점수 및 날짜 범위 업데이트)
    }
  }

  // 스낵바 메시지 표시
  void _showSnackBarMessage(String? message) {
    if (mounted && message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar(); // 이전 스낵바가 있다면 제거
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  // 기간 선택 토글 변경 시 호출
  void _onPeriodToggleChanged(int index) {
    if (!mounted || _userId == null) return;
    if (_isSelectedToggle[index] && !_isLoading) {
      return; // 이미 선택된 탭이거나 로딩 중이 아니면 변경 없음
    }

    DateTime newDateToDisplay;
    if (index == 0) {
      // 주간
      newDateToDisplay = _dataService.currentWeekStartDate;
    } else if (index == 1) {
      // 월간
      newDateToDisplay = DateTime(_dataService.currentSelectedMonth.year,
          _dataService.currentSelectedMonth.month, 1);
    } else {
      // 분기/연간 (미구현)
      newDateToDisplay = _displayedDate; // 일단 현재 날짜 유지
      if (mounted) {
        // 미구현 알림
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "${_isSelectedToggle[2] ? "분기별" : "연간"} 보기는 아직 준비 중입니다.")),
        );
      }
    }

    if (mounted) {
      setState(() {
        for (int i = 0; i < _isSelectedToggle.length; i++) {
          _isSelectedToggle[i] = (i == index);
        }
        _displayedDate = newDateToDisplay; // _displayedDate를 먼저 업데이트
      });
    }
    _loadDataForCurrentSelection(); // 그 후 데이터 로드
  }

  // 월간 달력에서 특정 날짜 클릭 시 해당 날짜가 포함된 주로 전환
  void _switchToWeekViewForDate(DateTime date) {
    if (!mounted || _userId == null) return;
    final newWeekStartDate =
        date.subtract(Duration(days: date.weekday - 1)); // 선택된 날짜가 속한 주의 월요일
    if (mounted) {
      setState(() {
        _isSelectedToggle[0] = true; // 주간 탭 활성화
        _isSelectedToggle[1] = false;
        _isSelectedToggle[2] = false;
        _isSelectedToggle[3] = false;
        _displayedDate = newWeekStartDate; // _displayedDate 업데이트
      });
    }
    _loadDataForWeek(newWeekStartDate); // 해당 주의 데이터 로드
  }

  @override
  Widget build(BuildContext context) {
    // 이전/다음 이동 가능 여부 (데이터 로드 상태 및 userId 확인 후 결정)
    bool canGoWeekBack = false;
    bool canGoWeekForward = false;
    bool canGoMonthBack = false;
    bool canGoMonthForward = false;

    if (_userId != null && _dataService.isInitialDataFetched) {
      if (_isSelectedToggle[0]) {
        // 주간 뷰
        canGoWeekBack =
            _displayedDate.isAfter(_dataService.oldestWeekStartDate);
        canGoWeekForward =
            _displayedDate.isBefore(_dataService.newestWeekStartDate);
      } else if (_isSelectedToggle[1]) {
        // 월간 뷰
        // TODO: 월간 경계 로직을 dataService에서 가져오거나 여기서 명확히 정의해야 함
        DateTime oldestMonthBoundary =
            DateTime(DateTime.now().year - 2, 1, 1); // 예시
        DateTime newestMonthBoundary =
            DateTime(DateTime.now().year + 1, 12, 1); // 예시
        DateTime currentMonthStart =
            DateTime(_displayedDate.year, _displayedDate.month, 1);

        canGoMonthBack = currentMonthStart.isAfter(oldestMonthBoundary);
        canGoMonthForward = currentMonthStart.isBefore(newestMonthBoundary);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("스코어보드", // "Scoreboard" -> "스코어보드"
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 20)), // 폰트 크기 조정
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87, // 아이콘 및 텍스트 색상
        elevation: 1, // 약간의 그림자
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0), // 화면 전체 패딩
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 기간 선택 토글 버튼
            ScoreboardPeriodToggle(
              isSelected: _isSelectedToggle,
              onPressed: _onPeriodToggleChanged,
            ),
            const SizedBox(height: 18), // 위젯 간 간격 조정
            // 평균 점수 및 날짜 범위 표시
            AverageScoreDisplay(
              averageScore: _currentAverageScore,
              dateRangeFormatted: _currentDateRangeFormatted,
              onDetailPressed: () {
                // 상세 보기 버튼 클릭 시 영양 섭취 상세 페이지로 이동
                if (_userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NutrientIntakeScreen(
                            userId: _userId!)), // userId 전달
                  );
                } else {
                  _showSnackBarMessage("사용자 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.");
                }
              },
            ),
            const SizedBox(height: 14), // 위젯 간 간격 조정
            // 주간 차트 또는 월간 달력 표시 영역
            Expanded(
              flex: _isSelectedToggle[1] ? 9 : 7, // 월간 뷰일 때 더 많은 공간 할당 (비율 조정)
              child: _isLoading // 로딩 중
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.teal))
                  : _errorMessage != null // 오류 발생 시
                      ? Center(
                          child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        ))
                      : _userId == null // 사용자 ID가 없을 때 (보통 로딩 전에 표시됨)
                          ? const Center(
                              child: Text("사용자 정보를 가져오는 중...",
                                  style: TextStyle(
                                      fontSize: 15, color: Colors.grey)))
                          : _isSelectedToggle[0] // 주간 뷰 선택 시
                              ? WeeklyScoreChart(
                                  weekData: _currentWeekChartData,
                                  onChangeWeek: _handleWeekChangeRequest,
                                  canGoBack: canGoWeekBack,
                                  canGoForward: canGoWeekForward,
                                )
                              : _isSelectedToggle[1] // 월간 뷰 선택 시
                                  ? Container(
                                      // 월간 달력 컨테이너
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6.0,
                                          horizontal: 2.0), // 패딩 조정
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.grey.shade100, // 배경색 약간 변경
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        children: [
                                          // 월 이동 버튼 영역
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.chevron_left_rounded),
                                                iconSize: 28.0, // 아이콘 크기 조정
                                                padding: EdgeInsets.zero,
                                                onPressed: canGoMonthBack
                                                    ? () =>
                                                        _handleMonthChangeRequest(
                                                            -1)
                                                    : null,
                                                color: canGoMonthBack
                                                    ? Colors.grey.shade700
                                                    : Colors.grey.shade300,
                                              ),
                                              // 현재 월 표시 (선택적, AverageScoreDisplay에서 이미 표시됨)
                                              // Text(_dataService.formatMonth(_displayedDate), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              IconButton(
                                                icon: const Icon(Icons
                                                    .chevron_right_rounded),
                                                iconSize: 28.0,
                                                padding: EdgeInsets.zero,
                                                onPressed: canGoMonthForward
                                                    ? () =>
                                                        _handleMonthChangeRequest(
                                                            1)
                                                    : null,
                                                color: canGoMonthForward
                                                    ? Colors.grey.shade700
                                                    : Colors.grey.shade300,
                                              ),
                                            ],
                                          ),
                                          // 요일 헤더는 MonthlyCalendarView 내부에서 처리하도록 변경 가능
                                          Expanded(
                                            // 실제 달력 위젯
                                            child: MonthlyCalendarView(
                                              selectedMonth: DateTime(
                                                  _displayedDate.year,
                                                  _displayedDate.month,
                                                  1),
                                              dataService: _dataService,
                                              onDateSelected:
                                                  _switchToWeekViewForDate,
                                              onChangeMonthBySwipe:
                                                  _handleMonthChangeRequest,
                                              canGoBackMonth: canGoMonthBack,
                                              canGoForwardMonth:
                                                  canGoMonthForward,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  // 분기별/연간 보기 (미구현)
                                  : Center(
                                      child: Text(
                                          "${_isSelectedToggle[2] ? "분기별" : "연간"} 뷰는 아직 준비 중입니다.",
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey))),
            ),
            // 주간 코멘트는 주간 뷰이고, 로딩/에러가 아닐 때, 데이터가 있을 때만 표시
            if (_isSelectedToggle[0] &&
                _currentWeekChartData.isNotEmpty &&
                !_isLoading &&
                _errorMessage == null &&
                _userId != null)
              const ScoreCommentDisplay() // 코멘트 내용 동적 주입 가능
            else // 그 외의 경우 하단 여백 확보
              const SizedBox(height: 10),
          ],
        ),
      ),
      // 공통 하단 네비게이션 바
      bottomNavigationBar: CommonBottomNavigationBar(
        currentPage: AppPage.scoreboard, // 현재 페이지를 스코어보드로 설정
      ),
    );
  }
}

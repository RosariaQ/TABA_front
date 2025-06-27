import 'package:flutter/material.dart';
import 'package:healthymeal/dailystatusPage/intakelevel.dart'; // 각 영양소 섭취 수준을 표시하는 위젯
import 'package:healthymeal/dailystatusPage/model/mealinfo.dart';
import 'package:healthymeal/dailystatusPage/service/dailystatusservice.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 식사 정보 모델

// 일일 영양 상태 화면을 구성하는 StatefulWidget
class DailyStatus extends StatefulWidget {
  const DailyStatus({super.key});

  @override
  State<DailyStatus> createState() => _DailyStatusState();
}

// 일일 권장 섭취량 기준을 정의하는 클래스
class IntakeCriterion {
  final double carbonhydrateCriterion; // 탄수화물 기준 (g)
  final double proteinCriterion; // 단백질 기준 (g)
  final double fatCriterion; // 지방 기준 (g)
  final double sodiumCriterion; // 나트륨 기준 (mg)
  final double celluloseCriterion; // 식이섬유 기준 (g)
  final double sugarCriterion; // 당류 기준 (g)
  final double cholesterolCriterion; // 콜레스테롤 기준 (mg)

  const IntakeCriterion(
    this.carbonhydrateCriterion,
    this.proteinCriterion,
    this.fatCriterion,
    this.sodiumCriterion,
    this.celluloseCriterion,
    this.sugarCriterion,
    this.cholesterolCriterion,
  );
}

// 각 영양소의 섭취 데이터를 나타내는 클래스 -> intakelevel의 
class IntakeData {
  final String nutrientname; // 영양소 이름
  final String intakeunit; // 섭취 단위 (g, mg 등)
  final double requiredintake; // 권장 섭취량
  final double intakeamount; // 실제 섭취량

  IntakeData(this.nutrientname, this.requiredintake, this.intakeamount,
      this.intakeunit);
}

class _DailyStatusState extends State<DailyStatus> {
  // 현재는 예시용 하드코딩된 데이터입니다.
  final List<MealInfo> _hardmeals = [
    MealInfo(
      carbonhydrate_g: 10.93,
      protein_g: 1.45,
      fat_g: 0.24,
      sodium_mg: 172,
      cellulose_g: 1.2,
      sugar_g: 0,
      cholesterol_mg: 0,
      intaketime: DateTime(2025, 05, 12, 07, 30),
      mealtype: "Breakfast",
      intakeamount: 1,
      meals: ["콩나물 국밥"],
      imagepath: 'assets/image/konggukbap.jpeg', // TODO: 실제 이미지 경로 확인
    ),
    MealInfo(
      carbonhydrate_g: 20.26,
      protein_g: 7,
      fat_g: 7.22,
      sodium_mg: 335,
      cellulose_g: 1.8,
      sugar_g: 0.71,
      cholesterol_mg: 33.45,
      intaketime: DateTime(2025, 05, 12, 12, 15),
      mealtype: "Lunch",
      intakeamount: 1,
      meals: ["참치 김밥"],
      imagepath: 'assets/image/chamchigimbap.jpeg', // TODO: 실제 이미지 경로 확인
    ),
    MealInfo(
      carbonhydrate_g: 25.94,
      protein_g: 10.58,
      fat_g: 12.29,
      sodium_mg: 595,
      cellulose_g: 0,
      sugar_g: 6.14,
      cholesterol_mg: 18.43,
      intaketime: DateTime(2025, 05, 12, 18, 20),
      mealtype: "Dinner",
      intakeamount: 1,
      meals: ["맥치킨 모짜버거"],
      imagepath: 'assets/image/mcchickenmozza.jpg', // TODO: 실제 이미지 경로 확인
    ),
    MealInfo(
      carbonhydrate_g: 50,
      protein_g: 4.17,
      fat_g: 20.83,
      sodium_mg: 42,
      cellulose_g: 0,
      sugar_g: 41.67,
      cholesterol_mg: 20.83,
      intaketime: DateTime(2025, 05, 12, 20, 32),
      mealtype: "Snack",
      intakeamount: 1,
      meals: ["블루베리 마카롱"],
      imagepath: 'assets/image/blueberrymacaron.jpg', // TODO: 실제 이미지 경로 확인
    ),
  ];
  // 일일 식단기록 정보
  List<MealInfo> _meals = [];
  // API 요청을 위한 서비스 인스턴스
  final DailyStatusService _dailyStatusService = DailyStatusService();
  // 화면에 표시될 영양소 섭취 데이터 리스트
  final List<IntakeData> _intakes = [];
  // 일일 권장 섭취량 기준 (성별, 나이 등에 따라 동적으로 설정될 수 있음)
  late final IntakeCriterion _criterion;

  int _currentSelectedMealIndex = -1; // 현재 선택된 식단 인덱스 (-1은 전체 식단)

  // 사용자 ID를 가져오는 내부 함수
  Future<String> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? returnstr = prefs.getString('userId');
    if (returnstr == null) {
      return "";
    } else {
      return returnstr;
    }
  }


  @override
  void initState() {
    super.initState();
    print("dailustatus시작");
    _initData();
  }

  void _initData() async {
    print("init시작");
    final String userId = await _getUserId();
    print("사용자아이디가져오기완료");
    // 일일 권장 섭취량 가져오기
    List<String> userInfo = await _dailyStatusService.getUserInfo(userId);
    print("사용자정보가져오기 완료 : ${userInfo[0]}, ${userInfo[1]}");
    List<double> criterionValue = await _dailyStatusService.fetchCriterion(int.parse(userInfo[1]), userInfo[0]);
    print("권장섭취량 완료");
    List<MealInfo> mealstoinput = await _dailyStatusService.fetchMeals(userId);
    print("일일식단기록 완료");
    _criterion = IntakeCriterion(criterionValue[0], criterionValue[1], criterionValue[2], criterionValue[3], criterionValue[4], criterionValue[5], criterionValue[6]);
    _meals = mealstoinput;
    _updateIntakeLevels(_meals);
  }
  // 주어진 식단 목록을 바탕으로 각 영양소의 총 섭취량을 계산하고 _intakes 리스트를 업데이트하는 함수
  void _updateIntakeLevels(List<MealInfo> mealsToProcess) {
    if (!mounted) return;

    double totalCarbon = 0;
    double totalProtein = 0;
    double totalFat = 0;
    double totalSodium = 0;
    double totalCellulose = 0;
    double totalSugar = 0;
    double totalCholesterol = 0;

    for (MealInfo meal in mealsToProcess) {
      totalCarbon += meal.carbonhydrate_g;
      totalProtein += meal.protein_g;
      totalFat += meal.fat_g;
      totalSodium += meal.sodium_mg;
      totalCellulose += meal.cellulose_g;
      totalSugar += meal.sugar_g;
      totalCholesterol += meal.cholesterol_mg;
    }

    setState(() {
      _intakes.clear(); // 기존 데이터 초기화
      _intakes.add(IntakeData(
          "탄수화물", _criterion.carbonhydrateCriterion, totalCarbon, "g"));
      _intakes.add(
          IntakeData("단백질", _criterion.proteinCriterion, totalProtein, "g"));
      _intakes.add(IntakeData("지방", _criterion.fatCriterion, totalFat, "g"));
      _intakes.add(
          IntakeData("나트륨", _criterion.sodiumCriterion, totalSodium, "mg"));
      _intakes.add(IntakeData(
          "식이섬유", _criterion.celluloseCriterion, totalCellulose, "g"));
      _intakes
          .add(IntakeData("당류", _criterion.sugarCriterion, totalSugar, "g"));
      _intakes.add(IntakeData(
          "콜레스테롤", _criterion.cholesterolCriterion, totalCholesterol, "mg"));
    });
  }

  // 특정 식단 또는 전체 식단을 선택했을 때 호출되는 함수
  void _setSelectedMealAndUpdateLevels(int index) {
    if (!mounted) return;
    print("선택된 식단 인덱스: $index");
    setState(() {
      _currentSelectedMealIndex = index; // 현재 선택된 식단 인덱스 업데이트
      if (index == -1) {
        // 전체 식단 선택 시
        _updateIntakeLevels(_meals);
      } else {
        // 특정 식단 선택 시
        _updateIntakeLevels([_meals[index]]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 상단 AppBar
      appBar: AppBar(
        title: const Text('일일 영양 상태',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold)), // 폰트 크기 조정
        centerTitle: true,
        leading: IconButton(
          // 뒤로가기 버튼
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87, // 아이콘 및 텍스트 색상
        elevation: 1, // 약간의 그림자 효과
      ),
      // 본문 Container
      body: Container(
        // 배경 그라데이션
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDE68A), // 밝은 노란색 (상단)
              Color(0xFFC8E6C9), // 연한 녹색 (중간)
              Colors.white, // 흰색 (하단)
            ],
            stops: [0.0, 0.6, 1.0], // 색상 전환 지점
          ),
        ),
        child: SingleChildScrollView( // 내용이 길 경우 스크롤 가능하도록
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 내부 패딩
              child: Column(
                children: [
                  // 각 영양소별 섭취 수준을 표시하는 IntakeLevel 위젯 목록
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: _intakes
                        .map((intake) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 3.0), // 위젯 간 간격
                              child: IntakeLevel(intake, key: ValueKey(intake.nutrientname + intake.intakeamount.toString())), // key 추가로 상태 변경 시 올바르게 업데이트
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20), // 영양소 바와 식단 선택 영역 사이 간격
                  // 기록된 식단 목록을 가로로 스크롤하며 선택할 수 있는 영역
                  SizedBox(
                    height: 70, // 가로 스크롤 영역 높이 고정
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal, // 가로 스크롤 설정
                      itemCount: _meals.length + 1, // "전체" 버튼 포함
                      itemBuilder: (context, index) {
                        bool isSelected;
                        Widget displayItem;
            
                        if (index == 0) { // "전체" 버튼
                          isSelected = _currentSelectedMealIndex == -1;
                          displayItem = Container(
                            width: 90, // 버튼 너비
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.orange.shade100 : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.deepOrangeAccent
                                    : Colors.grey.shade300,
                                width: isSelected ? 2.5 : 1.5, // 선택 시 테두리 두껍게
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(color: Colors.deepOrangeAccent.withOpacity(0.3), blurRadius: 5, spreadRadius: 1)
                              ] : [
                                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 3, spreadRadius: 1)
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                "전체 식단",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5, // 폰트 크기 조정
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          );
                        } else { // 개별 식단 아이템
                          final mealIndex = index - 1;
                          final meal = _meals[mealIndex];
                          isSelected = _currentSelectedMealIndex == mealIndex;
                          displayItem = Container(
                            width: 170, // 각 식단 아이템 너비
                            margin: const EdgeInsets.only(right: 10), // 아이템 간 간격
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.orange.shade100 : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.deepOrangeAccent
                                    : Colors.grey.shade300,
                                width: isSelected ? 2.5 : 1.5,
                              ),
                               boxShadow: isSelected ? [
                                BoxShadow(color: Colors.deepOrangeAccent.withOpacity(0.3), blurRadius: 5, spreadRadius: 1)
                              ] : [
                                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 3, spreadRadius: 1)
                              ],
                            ),
                            child: Row(
                              children: [
                                // 식단 이미지 (원형)
                                ClipOval(
                                  child: Image.network(
                                    meal.imagepath, // 이미지 경로
                                    width: 45, // 이미지 크기
                                    height: 45,
                                    fit: BoxFit.cover, // 이미지를 원에 맞게 채움
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container( // 이미지 로드 실패 시 기본 아이콘 표시
                                        width: 45, height: 45,
                                        color: Colors.grey.shade200,
                                        child: Icon(Icons.restaurant, color: Colors.grey.shade400),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // 식단 텍스트 정보 (메뉴 이름, 식사 유형)
                                Expanded( // 텍스트가 길 경우 자동 줄바꿈
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        meal.meals.isNotEmpty ? meal.meals[0] : "알 수 없는 메뉴", // 메뉴 이름 (첫 번째 항목)
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13, // 폰트 크기 조정
                                          overflow: TextOverflow.ellipsis, // 길면 말줄임표
                                        ),
                                        maxLines: 1,
                                      ),
                                      Text(
                                        meal.mealtype, // 식사 유형
                                        style: TextStyle(
                                            fontSize: 11.5, color: Colors.black54), // 폰트 크기 및 색상 조정
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        // 각 아이템을 탭 가능하도록 GestureDetector로 감쌈
                        return GestureDetector(
                          onTap: () => _setSelectedMealAndUpdateLevels(index == 0 ? -1 : index -1),
                          child: displayItem,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 50), // 화면 하단 여백
                ],
              ),
            ),
      ),
    );
  }
}

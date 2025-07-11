import 'package:flutter/material.dart';
import 'package:healthymeal/dailystatusPage/intakelevel.dart';
import 'package:healthymeal/dailystatusPage/model/mealinfo.dart';
import 'package:healthymeal/dailystatusPage/service/dailystatusservice.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 일일 권장 섭취량 기준 클래스
class IntakeCriterion {
  final double carbohydrateCriterion;  // 탄수화물 (g)
  final double proteinCriterion;       // 단백질 (g)
  final double fatCriterion;           // 지방 (g)
  final double sodiumCriterion;        // 나트륨 (mg)
  final double celluloseCriterion;     // 식이섬유 (g)
  final double sugarCriterion;         // 당류 (g)
  final double cholesterolCriterion;   // 콜레스테롤 (mg)
  final double energyKcalCriterion;    // 칼로리 (kcal)

  const IntakeCriterion({
    required this.carbohydrateCriterion,
    required this.proteinCriterion,
    required this.fatCriterion,
    required this.sodiumCriterion,
    required this.celluloseCriterion,
    required this.sugarCriterion,
    required this.cholesterolCriterion,
    required this.energyKcalCriterion,
  });
}

// 화면에 표시할 “섭취량 vs 기준” 데이터
class IntakeData {
  final String nutrientName;
  final double requiredIntake;
  final double intakeAmount;
  final String intakeUnit;

  IntakeData(
    this.nutrientName,
    this.requiredIntake,
    this.intakeAmount,
    this.intakeUnit,
  );
}

class DailyStatus extends StatefulWidget {
  const DailyStatus({super.key});

  @override
  State<DailyStatus> createState() => _DailyStatusState();
}

class _DailyStatusState extends State<DailyStatus> {
  final DailyStatusService _svc = DailyStatusService();

  late final IntakeCriterion _criterion;
  List<MealInfo> _meals = [];
  List<IntakeData> _intakes = [];
  int _selectedMealIndex = -1; // -1: 전체

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? "";
    // 1) 유저 정보
    final userInfo = await _svc.getUserInfo(userId); // [gender, age]
    // 2) 권장 섭취 기준
    final crit = await _svc.fetchCriterion(
      int.parse(userInfo[1]),
      userInfo[0],
    );
    _criterion = IntakeCriterion(
      carbohydrateCriterion: crit[0],
      proteinCriterion: crit[1],
      fatCriterion: crit[2],
      sodiumCriterion: crit[3],
      celluloseCriterion: crit[4],
      sugarCriterion: crit[5],
      cholesterolCriterion: crit[6],
      energyKcalCriterion: crit[7],
    );
    // 3) 오늘의 식사 기록
    final meals = await _svc.fetchMeals(userId);

    setState(() {
      _meals = meals;
      _updateIntakeLevels(_meals);
    });
  }

  // 전체 or 개별 식사에 따라 _intakes 리스트 갱신
  void _updateIntakeLevels(List<MealInfo> list) {
    double tCarb = 0, tProt = 0, tFat = 0,
        tSod = 0, tCell = 0, tSugar = 0,
        tChol = 0, tCal = 0;

    for (var m in list) {
      tCarb += m.carbonhydrate_g;
      tProt += m.protein_g;
      tFat  += m.fat_g;
      tSod  += m.sodium_mg;
      tCell += m.cellulose_g;
      tSugar+= m.sugar_g;
      tChol += m.cholesterol_mg;
      tCal  += m.Kcal_g;
    }

    _intakes = [
      IntakeData("칼로리",    _criterion.energyKcalCriterion, tCal,   "kcal"),
      IntakeData("탄수화물",  _criterion.carbohydrateCriterion, tCarb, "g"),
      IntakeData("단백질",    _criterion.proteinCriterion,      tProt, "g"),
      IntakeData("지방",      _criterion.fatCriterion,          tFat,  "g"),
      IntakeData("나트륨",    _criterion.sodiumCriterion,       tSod,  "mg"),
      IntakeData("식이섬유",  _criterion.celluloseCriterion,    tCell, "g"),
      IntakeData("당류",      _criterion.sugarCriterion,        tSugar,"g"),
      IntakeData("콜레스테롤",_criterion.cholesterolCriterion,  tChol, "mg"),
    ];
  }

  // 인덱스 변경 시 호출
  void _onMealTap(int idx) {
    setState(() {
      _selectedMealIndex = idx;
      if (idx < 0) {
        _updateIntakeLevels(_meals);
      } else {
        _updateIntakeLevels([_meals[idx]]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '일일 영양 상태',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDE68A),
              Color(0xFFC8E6C9),
              Colors.white,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // 영양소 바
              ..._intakes.map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: IntakeLevel(i,
                        key: ValueKey('${i.nutrientName}-${i.intakeAmount}')),
                  )),
              const SizedBox(height: 20),
              // 식사 선택 가로 리스트
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _meals.length + 1,
                  itemBuilder: (_, idx) {
                    final isAll = idx == 0;
                    final isSelected =
                        isAll ? _selectedMealIndex < 0 : _selectedMealIndex == idx - 1;

                    Widget child;
                    if (isAll) {
                      child = _buildMealTile(
                        label: "전체 식단",
                        isSelected: isSelected,
                        onTap: () => _onMealTap(-1),
                      );
                    } else {
                      final m = _meals[idx - 1];
                      child = _buildMealTile(
                        label: m.meals.first,
                        subtitle: m.mealtype,
                        imageUrl: m.imagepath,  // 네트워크 URL
                        isSelected: isSelected,
                        onTap: () => _onMealTap(idx - 1),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: child,
                    );
                  },
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // 식사 아이템 공통 빌더
  Widget _buildMealTile({
    required String label,
    String? subtitle,
    String? imageUrl,   // 네트워크 URL
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isSelected ? 180 : (subtitle != null ? 170 : 90),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade100 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.deepOrangeAccent : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isSelected
                      ? Colors.deepOrangeAccent
                      : Colors.grey)
                  .withOpacity(0.2),
              blurRadius: isSelected ? 5 : 3,
              spreadRadius: 1,
            )
          ],
        ),
        child: subtitle == null
            ? Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              )
            : Row(
                children: [
                  ClipOval(
                    child: Image.network(
                      imageUrl!,
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 45,
                        height: 45,
                        color: Colors.grey.shade200,
                        child:
                            Icon(Icons.restaurant, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                              fontSize: 11.5, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

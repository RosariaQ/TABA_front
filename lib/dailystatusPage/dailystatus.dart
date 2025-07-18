import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthymeal/dailystatusPage/intakelevel.dart';
import 'package:healthymeal/dailystatusPage/model/mealinfo.dart';
import 'package:healthymeal/dailystatusPage/service/dailystatusservice.dart';

/// 일일 권장 섭취량 기준 클래스
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

/// 화면에 표시할 “섭취량 vs 기준” 데이터
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

// 수정—콜레스테롤 키 추가
Map<String, double> _weights = {
  '칼로리':     0.0,
  '탄수화물':   0.0,
  '지방':       0.0,
  '단백질':     0.0,
  '식이섬유':   0.0,
  '당류':       0.0,
  '나트륨':     0.0,
  '콜레스테롤': 0.0,  // ← 요기
};

  @override
  void initState() {
    super.initState();
    _loadNutritionPreferences().then((_) => _loadAllData());
  }

  /// SharedPreferences에 저장된 가중치(JSON)를 불러와 _weights에 적용
  Future<void> _loadNutritionPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('nutrition_preferences');
    if (jsonStr == null) return;
    final Map<String, dynamic> map = jsonDecode(jsonStr);
    map.forEach((key, value) {
      if (_weights.containsKey(key)) {
        _weights[key] = (value as num).toDouble();
      }
    });
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
      proteinCriterion:      crit[1],
      fatCriterion:          crit[2],
      sodiumCriterion:       crit[3],
      celluloseCriterion:    crit[4],
      sugarCriterion:        crit[5],
      cholesterolCriterion:  crit[6],
      energyKcalCriterion:   crit[7],
    );

    // 3) 오늘의 식사 기록
    final meals = await _svc.fetchMeals(userId);

    setState(() {
      _meals = meals;
      _updateIntakeLevels(_meals);
    });
  }

  /// 전체 or 개별 식사에 따라 _intakes 리스트 갱신 (가중치 반영)
  void _updateIntakeLevels(List<MealInfo> list) {
    double tCal = 0, tCarb = 0, tProt = 0, tFat = 0;
    double tSod = 0, tCell = 0, tSugar = 0, tChol = 0;

    for (var m in list) {
      tCal  += m.Kcal_g;
      tCarb += m.carbonhydrate_g;
      tProt += m.protein_g;
      tFat  += m.fat_g;
      tSod  += m.sodium_mg;
      tCell += m.cellulose_g;
      tSugar+= m.sugar_g;
      tChol += m.cholesterol_mg;
    }

    // 가중치 함수: (1 + sliderValue)
    double w(String key) => 1 + (_weights[key] ?? 0);

    _intakes = [
      IntakeData("칼로리",
        _criterion.energyKcalCriterion * w("칼로리"), tCal, "kcal"),
      IntakeData("탄수화물",
        _criterion.carbohydrateCriterion * w("탄수화물"), tCarb, "g"),
      IntakeData("단백질",
        _criterion.proteinCriterion * w("단백질"), tProt, "g"),
      IntakeData("지방",
        _criterion.fatCriterion * w("지방"), tFat, "g"),
      IntakeData("나트륨",
        _criterion.sodiumCriterion * w("나트륨"), tSod, "mg"),
      IntakeData("식이섬유",
        _criterion.celluloseCriterion * w("식이섬유"), tCell, "g"),
      IntakeData("당류",
        _criterion.sugarCriterion * w("당류"), tSugar, "g"),
     IntakeData(  "콜레스테롤",
        _criterion.cholesterolCriterion * w("콜레스테롤"),tChol,  "mg",),
    ];
  }

  // 인덱스 변경 시
  void _onMealTap(int idx) {
    setState(() {
      _selectedMealIndex = idx;
      _updateIntakeLevels(idx < 0 ? _meals : [_meals[idx]]);
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
                    child: IntakeLevel(
                      i,
                      key: ValueKey('${i.nutrientName}-${i.intakeAmount}'),
                    ),
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

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => _onMealTap(isAll ? -1 : idx - 1),
                        child: _buildMealTile(
                          label: isAll ? "전체 식단" : _meals[idx - 1].meals.first,
                          subtitle: isAll ? null : _meals[idx - 1].mealtype,
                          imageUrl: isAll ? null : _meals[idx - 1].imagepath,
                          isSelected: isSelected,
                        ),
                      ),
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

  Widget _buildMealTile({
    required String label,
    String? subtitle,
    String? imageUrl,
    required bool isSelected,
  }) {
    return Container(
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
            color: (isSelected ? Colors.deepOrangeAccent : Colors.grey)
                .withOpacity(0.2),
            blurRadius: isSelected ? 5 : 3,
            spreadRadius: 1,
          )
        ],
      ),
      child: subtitle == null
          ? Center(
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
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
                      child: Icon(Icons.restaurant, color: Colors.grey.shade400),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(subtitle,
                          style:
                              const TextStyle(fontSize: 11.5, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

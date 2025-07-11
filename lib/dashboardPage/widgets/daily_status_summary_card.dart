// lib/dashboardPage/widgets/daily_status_summary_card.dart
import 'package:flutter/material.dart';
import 'package:healthymeal/dailystatusPage/service/dailystatusservice.dart';
import 'package:healthymeal/dailystatusPage/model/mealinfo.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 화면에 표시할 "섭취량 vs 기준" 데이터 (dailystatusPage와 동일)
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

class DailyStatusSummaryCard extends StatefulWidget {
  final double scale;
  final Function(TapDownDetails) onTapDown;
  final Function(TapUpDetails) onTapUp;
  final VoidCallback onTapCancel;
  final VoidCallback? onTap;

  const DailyStatusSummaryCard({
    super.key,
    required this.scale,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    this.onTap,
  });

  @override
  State<DailyStatusSummaryCard> createState() => _DailyStatusSummaryCardState();
}

class _DailyStatusSummaryCardState extends State<DailyStatusSummaryCard> {
  final DailyStatusService _svc = DailyStatusService();
  
  bool _isLoading = true;
  List<IntakeData> _intakes = [];
  
  @override
  void initState() {
    super.initState();
    _loadNutritionData();
  }
  
  Future<void> _loadNutritionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? "";
      
      if (userId.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // 1) 유저 정보
      final userInfo = await _svc.getUserInfo(userId); // [gender, age]
      
      // 2) 권장 섭취 기준
      final crit = await _svc.fetchCriterion(
        int.parse(userInfo[1]),
        userInfo[0],
      );
      
      // 3) 오늘의 식사 기록
      final meals = await _svc.fetchMeals(userId);
      
      // 4) 전체 영양소 합계 계산
      double tCarb = 0, tProt = 0, tFat = 0,
          tSod = 0, tCell = 0, tSugar = 0,
          tChol = 0, tCal = 0;

      for (var m in meals) {
        tCarb += m.carbonhydrate_g;
        tProt += m.protein_g;
        tFat  += m.fat_g;
        tSod  += m.sodium_mg;
        tCell += m.cellulose_g;
        tSugar+= m.sugar_g;
        tChol += m.cholesterol_mg;
        tCal  += m.Kcal_g;
      }
      
      // 5) IntakeData 리스트 생성 (8개 영양소)
      final intakes = [
        IntakeData("칼로리",    crit[7], tCal,   "kcal"),
        IntakeData("탄수화물",  crit[0], tCarb,  "g"),
        IntakeData("단백질",    crit[1], tProt,  "g"),
        IntakeData("지방",      crit[2], tFat,   "g"),
        IntakeData("나트륨",    crit[3], tSod,   "mg"),
        IntakeData("식이섬유",  crit[4], tCell,  "g"),
        IntakeData("당류",      crit[5], tSugar, "g"),
        IntakeData("콜레스테롤", crit[6], tChol,  "mg"),
      ];
      
      setState(() {
        _intakes = intakes;
        _isLoading = false;
      });
      
    } catch (e) {
      print('영양 데이터 로드 중 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 비율에 따른 색상 결정 (dailystatusPage의 IntakeLevel과 동일한 로직)
  Color _getColorForRatio(double ratio) {
    if (ratio <= 0.5) {
      return Colors.yellow.shade400;  // 0-50%: 노랑
    } else if (ratio <= 1.0) {
      return Colors.green.shade500;   // 50-100%: 초록
    } else if (ratio <= 1.5) {
      return Colors.yellow.shade400;  // 100-150%: 노랑
    } else {
      return Colors.red.shade400;     // 150% 이상: 빨강
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: GestureDetector(
        onTapDown: widget.onTapDown,
        onTapUp: widget.onTapUp,
        onTapCancel: widget.onTapCancel,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: widget.scale,
          duration: const Duration(milliseconds: 150),
          child: Card(
            color: const Color(0xFFFCFCFC),
            elevation: 4,
            shadowColor: Colors.grey.withAlpha(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.grey.shade200, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildCardContent(),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCardContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_intakes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "오늘의 식사 기록이 없습니다.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "오늘의 영양 상태 요약",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87
          ),
        ),
        const SizedBox(height: 16),
        
        // 8개 영양소 표시
        ..._intakes.map((intake) {
          // 비율 계산
          double ratio = 0;
          if (intake.requiredIntake > 0) {
            ratio = intake.intakeAmount / intake.requiredIntake;
          }
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSimpleNutrientBar(intake, ratio),
          );
        }),
      ],
    );
  }
  
  // 간단한 영양소 바 위젯
  Widget _buildSimpleNutrientBar(IntakeData intake, double ratio) {
    final color = _getColorForRatio(ratio);
    final percentage = (ratio * 100).toStringAsFixed(0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 영양소명과 섭취량/권장량
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              intake.nutrientName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              '${intake.intakeAmount.toStringAsFixed(1)}/${intake.requiredIntake.toStringAsFixed(0)}${intake.intakeUnit}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        // 프로그레스 바
        Stack(
          children: [
            // 배경 바
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // 채워진 바
            FractionallySizedBox(
              widthFactor: ratio.clamp(0.0, 2.0) / 2.0, // 최대 200%까지 표시
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // 100% 위치 표시 (선택사항)
            if (ratio > 1.0)
              Positioned(
                left: MediaQuery.of(context).size.width * 0.35, // 대략적인 50% 위치
                child: Container(
                  width: 1,
                  height: 8,
                  color: Colors.grey.shade400,
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        
        // 퍼센티지 표시
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            if (ratio > 1.0)
              Text(
                ratio <= 1.5 ? '적정 초과' : '과다 섭취',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
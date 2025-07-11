import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class FoodInfo {
  final String name;
  final double energyKcal;

  FoodInfo({
    required this.name,
    required this.energyKcal,
  });

  factory FoodInfo.fromJson(Map<String, dynamic> json) {
    return FoodInfo(
      name: json['name'] ?? '이름 없음',
      energyKcal: (json['energyKcal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MealEntry {
  final int id;
  final String imgPath;
  final double intakeAmount;
  final DateTime createdAt;
  final FoodInfo food;

  MealEntry({
    required this.id,
    required this.imgPath,
    required this.intakeAmount,
    required this.createdAt,
    required this.food,
  });

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    final foodList = json['mealInfoFoodLinks'] as List<dynamic>? ?? [];
    final food = foodList.isNotEmpty
        ? FoodInfo.fromJson(foodList[0]['food'] ?? {})
        : FoodInfo(name: '알 수 없음', energyKcal: 0.0);

    return MealEntry(
      id: json['id'] as int? ?? -1,
      imgPath: json['imgPath'] ?? '',
      intakeAmount: (json['intakeAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt']),
      food: food,
    );
  }
}

class MealDiaryCard extends StatefulWidget {
  final String diaryDate;
  final String userId;
  final VoidCallback? onTap;
  final Function(TapDownDetails)? onTapDown;
  final Function(TapUpDetails)? onTapUp;
  final VoidCallback? onTapCancel;
  final double scale;

  const MealDiaryCard({
    super.key,
    required this.userId,
    required this.diaryDate,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.scale = 1.0,
  });

  @override
  State<MealDiaryCard> createState() => _MealDiaryCardState();
}

class _MealDiaryCardState extends State<MealDiaryCard> {
  List<MealEntry> _todayMeals = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final String _imageBaseUrl = 'http://healthymeal.kro.kr:4912/uploads/';

  @override
  void initState() {
    super.initState();
    _fetchTodayMeals();
  }

  @override
  void didUpdateWidget(covariant MealDiaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.diaryDate != widget.diaryDate) {
      _fetchTodayMeals();
    }
  }

  Future<void> _fetchTodayMeals() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final url = Uri.parse(
      'http://healthymeal.kro.kr:4912/users/${widget.userId}/meal-info?date=${widget.diaryDate}',
    );

    try {
      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final filtered = data
            .map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        setState(() {
          _todayMeals = filtered.take(3).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = '식단 정보를 불러오지 못했습니다 (서버 오류: ${response.statusCode}).';
        });
      }
    } catch (e) {
      print('오늘 식단 불러오기 실패: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '식단 정보를 불러오는 중 오류가 발생했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: widget.onTapDown,
        onTapUp: widget.onTapUp,
        onTapCancel: widget.onTapCancel,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "오늘의 식단 일기 요약 (${widget.diaryDate})",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      ),
                    )
                  else if (_errorMessage.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                              fontSize: 15, color: Colors.redAccent),
                        ),
                      ),
                    )
                  else if (_todayMeals.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          "오늘의 식단 기록이 없습니다.",
                          style: TextStyle(fontSize: 15, color: Colors.black54),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _todayMeals.length,
                      itemBuilder: (context, index) {
                        final entry = _todayMeals[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: Image.network(
                                  _imageBaseUrl + entry.imgPath,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      child: Icon(
                                        Icons.restaurant_menu_outlined,
                                        color: Colors.grey.shade400,
                                        size: 30,
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.food.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('a h:mm', 'ko_KR')
                                          .format(entry.createdAt),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "섭취량: ${entry.intakeAmount.toStringAsFixed(1)} 인분",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "칼로리: ${entry.food.energyKcal.toStringAsFixed(0)} kcal",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey.shade200,
                        thickness: 0.8,
                        height: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

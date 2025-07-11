import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:healthymeal/dashboardPage/dashboard.dart';

import 'meal_diary_entry.dart';
import 'widgets/meal_diary_card.dart';

class MealDiaryScreen extends StatefulWidget {
  final DateTime displayDate;

  const MealDiaryScreen({
    super.key,
    required this.displayDate,
  });

  @override
  State<MealDiaryScreen> createState() => _MealDiaryScreenState();
}

class _MealDiaryScreenState extends State<MealDiaryScreen> {
  List<MealDiaryEntry> _diaryEntries = [];
  bool _isLoading = true;
  String? _userId;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchLast7DaysEntries();
  }

  Future<void> _loadUserIdAndFetchLast7DaysEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '사용자 정보를 찾을 수 없습니다. 로그인이 필요합니다.';
      });
      return;
    }

    setState(() => _userId = userId);
    await _fetchLast7DaysEntries(userId);
  }

  Future<void> _fetchLast7DaysEntries(String userId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final now = DateTime.now();
    final List<DateTime> last7Days = List.generate(
      7,
      (i) => now.subtract(Duration(days: i)),
    );

    final List<MealDiaryEntry> allEntries = [];

    try {
      for (final date in last7Days) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final url =
            'http://healthymeal.kro.kr:4912/users/$userId/meal-info?date=$dateStr';

        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final List<dynamic> data =
              json.decode(utf8.decode(response.bodyBytes));

          final entries = data
              .map((e) => MealDiaryEntry.fromJson(e as Map<String, dynamic>))
              .toList();

          allEntries.addAll(entries);
        }
      }

      setState(() {
        _diaryEntries = allEntries
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 최신순 정렬
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '식단 기록을 불러오는 중 오류가 발생했습니다: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat appBarDateFormat = DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR');

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFDE68A),
            Color(0xFFC8E6C9),
            Colors.white,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(appBarDateFormat.format(widget.displayDate)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Dashboard()),
              );
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  )
                : _diaryEntries.isEmpty
                    ? const Center(child: Text('최근 7일간의 식단 기록이 없습니다!'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: _diaryEntries.length,
                        itemBuilder: (context, index) {
                          final entry = _diaryEntries[index];
                          return MealDiaryCard(
                            key: ValueKey(entry.foodName +
                                entry.createdAt.toIso8601String()),
                            entry: entry,
                            onDelete: () {
                              if (mounted) {
                                setState(() {
                                  _diaryEntries.removeAt(index);
                                });
                              }
                            },
                          );
                        },
                      ),
      ),
    );
  }
}

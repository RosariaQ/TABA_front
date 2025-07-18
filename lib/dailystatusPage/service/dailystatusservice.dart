import 'dart:convert'; // JSON 디코딩을 위해
import 'package:healthymeal/dailystatusPage/model/mealinfo.dart'; // 식사 정보 모델
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyStatusService {
  final String _baseUrl = "http://healthymeal.kro.kr:4912";

  // 현재 날짜(yyyy-MM-dd) 가져오기
  String _getDatetimeNow() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  // 사용자 성별·나이 정보 가져오기
  Future<List<String>> getUserInfo(String userId) async {
    final today = _getDatetimeNow();
    final url = Uri.parse('$_baseUrl/users/$userId');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    try {
      final response = await http.get(url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final gender = data['gender'] as String;
        final birth = data['birthday'] as String; // ex: "1996-07-11"
        final age = (int.parse(today.split('-')[0]) - int.parse(birth.split('-')[0])).toString();
        return [gender, age];
      } else {
        print('유저 정보 로드 실패: ${response.statusCode} / ${response.body}');
        throw Exception('유저 정보를 불러오는데 실패했습니다');
      }
    } catch (e) {
      print('getUserInfo 예외: $e');
      rethrow;
    }
  }

  // JSON 숫자를 항상 double로 반환하는 헬퍼
  double _parseDouble(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v == null) return 0;
    return (v as num).toDouble();
  }

  // 권장 섭취량 기준 가져오기
  Future<List<double>> fetchCriterion(int userAge, String userGender) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final url = Uri.parse('$_baseUrl/diet-criteria/')
        .replace(queryParameters: {
      'age': userAge.toString(),
      'gender': userGender,
    });

    try {
      final response = await http.get(url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return [
          _parseDouble(data, 'carbohydrateG'),
          _parseDouble(data, 'proteinG'),
          _parseDouble(data, 'fatG'),
          _parseDouble(data, 'sodiumMg'),
          _parseDouble(data, 'celluloseG'),
          _parseDouble(data, 'sugarsG'),
          _parseDouble(data, 'cholesterolMg'),
          _parseDouble(data, 'energyKcal'),  // 이제 energyKcal 도 빠짐없이 처리됩니다
        ];
      } else {
        print('권장섭취량 로드 실패: ${response.statusCode} / ${response.body}');
        throw Exception('권장섭취량 정보를 불러오는데 실패했습니다');
      }
    } catch (e) {
      print('fetchCriterion 예외: $e');
      rethrow;
    }
  }

  // 오늘의 식단 기록 가져오기
  Future<List<MealInfo>> fetchMeals(String userId) async {
    final date = _getDatetimeNow();
    final url = Uri.parse('$_baseUrl/users/$userId/meal-info')
        .replace(queryParameters: {'date': date});
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    try {
      final response = await http.get(url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        return body
            .whereType<Map<String, dynamic>>()
            .map((e) => MealInfo.fromJson(e))
            .toList();
      } else {
        print('식사 정보 로드 실패: ${response.statusCode} / ${response.body}');
        throw Exception('식사 정보를 불러오는데 실패했습니다');
      }
    } catch (e, st) {
      print('fetchMeals 예외: $e\n$st');
      rethrow;
    }
  }

  // 오늘의 daily-intake를 가져오는 함수 (dashboard 위젯용)
  // Future<...> getDailyIntake(...) { ... }
}

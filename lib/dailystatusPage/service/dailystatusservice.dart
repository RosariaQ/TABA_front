import 'dart:convert'; // JSON 디코딩을 위해
import 'package:healthymeal/dailystatusPage/model/mealinfo.dart'; // 식사 정보 모델
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyStatusService {

  final String _baseUrl = "http://152.67.196.3:4912";
  // 현재시각을 가져오는 함수
  String _getDatetimeNow() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');
    final formattedTime = formatter.format(now);
    return formattedTime;
  }

  // 사용자 섭취량 기준을 가져오는 API 함수
  Future<List<String>> getUserInfo(String userId) async {
    final date = _getDatetimeNow();
    print("현재시각가져오기완료");
    List<String> returnInfo = [];
    final url = Uri.parse('$_baseUrl/users/$userId');
    try{
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responsedata = json.decode(response.body) as Map<String, dynamic>;
        returnInfo.add(responsedata['gender']);
        String age = responsedata['birthday'] as String;
        age = (int.parse(date.split('-')[0]) - int.parse(age.split('-')[0])).toString();
        returnInfo.add(age);
        return returnInfo;
      }
      else {
        print('유저 정보 로드 실패 - 상태 코드: ${response.statusCode}, 응답: ${response.body}');
        throw Exception('유저 정보를 불러오는데 실패했습니다 (상태 코드: ${response.statusCode})');
      }
    } catch (e) {
      print('유저 정보 로드 중 예외 발생: $e');
      throw Exception('유저 정보 로드 중 오류 발생: $e');
    }
  }
  Future<List<double>> fetchCriterion(int userAge, String userGender) async {
    print("criterionfetch시작");
    List<double> returnCriterion = [];
    final url = Uri.parse('$_baseUrl/diet-criteria/')
      .replace(queryParameters: {'age': userAge.toString(), 'gender':userGender});
    try {
      final response = await http.get(url);
      print("criterionapirequest");
      if (response.statusCode == 200) {
        final responsedata = json.decode(response.body) as Map<String, dynamic>;
        responsedata['carbohydrateG'] == null ? returnCriterion.add(0) :
        returnCriterion.add(responsedata['carbohydrateG'] as double);
        responsedata['proteinG'] == null ? returnCriterion.add(0) :
        returnCriterion.add(responsedata['proteinG'] as double);
        responsedata['fatG'] == null ? returnCriterion.add(0) :
        returnCriterion.add(responsedata['fatG'] as double);
        responsedata['sodiumMg'] == null ? returnCriterion.add(0) :
        returnCriterion.add(responsedata['sodiumMg'] as double);
        responsedata['celluloseG'] == null ? returnCriterion.add(0) :
        returnCriterion.add(responsedata['celluloseG'] as double);
        responsedata['sugarsG'] == null ? returnCriterion.add(0) :
        returnCriterion.add(responsedata['sugarsG'] as double);
        responsedata['cholesterolMg'] == null ? returnCriterion.add(0) :
        returnCriterion.add(responsedata['cholesterolMg'] as double);
        return returnCriterion;
      } else {
        print('권장섭취량 정보 로드 실패 - 상태 코드: ${response.statusCode}, 응답: ${response.body}');
        throw Exception('권장섭취량 정보를 불러오는데 실패했습니다 (상태 코드: ${response.statusCode})');
      }
    } catch (e) {
      print('권장섭취량 정보 로드 중 예외 발생: $e');
      throw Exception('권장섭취량 정보 로드 중 오류 발생: $e');
    }
  }

  // 오늘의 식단 기록을 모두 가져오는 API 함수
  Future<List<MealInfo>> fetchMeals(String userId) async {
    final date = _getDatetimeNow();
    List<MealInfo> returnMeals = [];
    final url = Uri.parse('$_baseUrl/users/$userId/meal-info')
      .replace(queryParameters: {'date': date});
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responsebody = json.decode(response.body) as List<dynamic>;
        for (var data in responsebody) {
          if (data is Map<String, dynamic>) {
            returnMeals.add(MealInfo.fromJson(data));
          }
        }
        return returnMeals;
      } else {
        // 서버에서 오류 응답을 받은 경우
        print('식사 정보 로드 실패 - 상태 코드: ${response.statusCode}, 응답: ${response.body}');
        throw Exception('식사 정보를 불러오는데 실패했습니다 (상태 코드: ${response.statusCode})');
      }
    } catch (e, stackTrace) {
      // 네트워크 오류 또는 기타 예외 발생 시
      print('식사 정보 로드 중 예외 발생: $e / $stackTrace');
      throw Exception('식사 정보 로드 중 오류 발생: $e');
    }
  }

  // 오늘의 daily-intake를 가져오는 함수 (이건 dashboard widget용)
  //Future<
}

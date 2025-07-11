import 'dart:convert';
import 'dart:io'; // File 클래스 사용
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // MediaType 사용
import 'package:path/path.dart'; // basename 사용
import 'package:shared_preferences/shared_preferences.dart';

class MealGptService {
  // API 기본 URL (상수로 관리하는 것이 좋음)
  final String _baseUrl = "http://healthymeal.kro.kr:4912";

  // 사용자 ID를 가져오는 내부 함수
  Future<String?> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // 식사 이미지를 서버로 전송하고 분석 요청
  Future<Map<String, dynamic>> sendMealImageAndAnalyze(File imageFile) async {
    final userId = await _getUserId();
    if (userId == null) {
      return {'error': "사용자 ID를 찾을 수 없습니다. 로그인이 필요합니다."};
    }

    print('$userId 사용자가 식단 사진 전송 시도');
    // 이미지 업로드 URI
    final uri = Uri.parse("$_baseUrl/users/$userId/meal-info");

    // Multipart request 생성
    final request = http.MultipartRequest("POST", uri);
    // 기본 필드 추가 (섭취량, 다이어리 내용은 현재 하드코딩 또는 null)
    request.fields['intake_amount'] = '1'; // 기본 섭취량 (추후 UI에서 입력받도록 수정 가능)
    request.fields['diary'] = 'null'; // 기본 다이어리 내용 (추후 UI에서 입력받도록 수정 가능)

    // 이미지 파일 추가
    request.files.add(
      http.MultipartFile.fromBytes(
        'img', // 서버에서 기대하는 필드명
        await imageFile.readAsBytes(),
        filename: basename(imageFile.path), // 파일 이름
        contentType: MediaType('image', 'jpeg'), // 이미지 타입 (jpeg 또는 png 등)
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 이미지 업로드 성공 시, 응답 본문(JSON) 파싱
        final Map<String, dynamic> jsonData =
            json.decode(utf8.decode(response.bodyBytes)); // UTF-8 디코딩
        final int mealId = jsonData['id'] as int; // 식별자 (mealId) 추출

        // 업로드된 식사에 대한 분석 요청
        final String menuName = await _analyzeMeal(userId, mealId);
        if (menuName.startsWith("❌") || menuName.startsWith("⚠️")) {
          // 분석 실패 시 오류 반환
          return {'error': "식단 분석 실패: $menuName", 'mealId': mealId};
        }
        return {'menuName': menuName, 'mealId': mealId}; // 메뉴 이름과 mealId 반환
      } else {
        // 이미지 업로드 실패
        return {
          'error': "❌ 이미지 업로드 오류: ${response.statusCode}, 응답: ${response.body}"
        };
      }
    } catch (e) {
      // 요청 중 예외 발생
      return {'error': "⚠️ 이미지 전송/분석 요청 중 오류 발생: $e"};
    }
  }

  // 특정 식사에 대한 분석을 서버에 요청 (내부 호출용)
  Future<String> _analyzeMeal(String userId, int mealId) async {
    final url = Uri.parse("$_baseUrl/users/$userId/meal-info/$mealId/analyze");
    try {
      final response =
          await http.post(url); // POST 요청으로 변경 (API 스펙에 따라 GET일 수도 있음)
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)); // UTF-8 디코딩
        // API 응답이 리스트 형태이고, 첫 번째 요소가 메뉴 이름이라고 가정
        return data.isNotEmpty ? data[0].toString() : "분석 결과 없음";
      } else {
        return "❌ GPT 분석 오류: ${response.statusCode}, 응답: ${response.body}";
      }
    } catch (e) {
      return "⚠️ GPT 분석 요청 중 오류 발생: $e";
    }
  }

  // 식단 기록 (섭취량, 다이어리 내용 업데이트)
  Future<String> recordMeal(int mealId, double amount, {String? diary}) async {
    final userId = await _getUserId();
    if (userId == null) {
      return "사용자 ID를 찾을 수 없습니다. 로그인이 필요합니다.";
    }

    // 쿼리 파라미터 구성
    final queryParameters = {
      'amount': amount.toString(),
      'diary': diary ?? 'null', // diary가 null이면 'null' 문자열로 전송
    };

    final url = Uri.parse("$_baseUrl/users/$userId/meal-info/$mealId")
        .replace(queryParameters: queryParameters);

    try {
      final response = await http.patch(url); // PATCH 요청
      if (response.statusCode == 200 || response.statusCode == 201) {
        return "✅ 식단 기록 성공";
      } else {
        return "⚠️ 식단 기록 중 오류 발생: ${response.statusCode}, ${response.body}";
      }
    } catch (e) {
      return "⚠️ 식단 기록 요청 중 오류 발생: $e";
    }
  }

  // 식단 기록 삭제
  Future<String> deleteMeal(int mealId) async {
    final userId = await _getUserId();
    if (userId == null) {
      return "사용자 ID를 찾을 수 없습니다. 로그인이 필요합니다.";
    }

    final url = Uri.parse("$_baseUrl/users/$userId/meal-info/$mealId");
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        // 204 No Content도 성공으로 간주
        return "✅ 식단 삭제 성공";
      } else {
        return "⚠️ 식단 삭제 중 오류 발생: ${response.statusCode}, ${response.body}";
      }
    } catch (e) {
      return "⚠️ 식단 삭제 요청 중 오류 발생: $e";
    }
  }

  // 서버 상태 확인용 Ping (테스트 목적)
  Future<void> sendPing() async {
    // Ping 엔드포인트가 로컬호스트로 되어 있어, 실제 서버 주소로 변경 필요 시 수정
    final uri = Uri.parse("$_baseUrl/ping"); // baseUrl 사용
    try {
      final response = await http.get(uri); // GET 요청으로 변경 (일반적인 ping)
      if (response.statusCode == 200) {
        print("✅ Ping 응답 성공: ${response.body}");
      } else {
        print("❌ Ping 오류 상태 코드: ${response.statusCode}");
        print("응답 본문: ${response.body}");
      }
    } catch (e) {
      print("Ping 요청 중 오류 발생: $e");
    }
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // HTTP 요청
import 'package:shared_preferences/shared_preferences.dart'; // 로컬 저장소 접근
import 'dart:convert'; // JSON 파싱 (필요시)

class UserQuitPage extends StatefulWidget {
  const UserQuitPage({super.key});

  @override
  State<UserQuitPage> createState() => _UserQuitPageState();
}

class _UserQuitPageState extends State<UserQuitPage> {
  bool _isLoading = false; // 회원 탈퇴 요청 처리 중인지 여부

  // TODO: API 기본 URL은 상수로 관리하는 것이 좋습니다.
  final String _apiBaseUrl = 'http://healthymeal.kro.kr:4912';

  // 회원 탈퇴 처리 함수
  Future<void> _deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('userId'); // 저장된 사용자 ID 가져오기

    if (id == null) {
      _showResultDialog("오류", "로그인 정보가 없습니다. 다시 로그인 후 시도해주세요.");
      return;
    }

    // 사용자에게 탈퇴 의사를 다시 한번 확인
    final bool confirmed = await _showConfirmationDialog(
      title: "회원 탈퇴 확인",
      content: "정말로 회원에서 탈퇴하시겠습니까?\n모든 사용자 정보가 영구적으로 삭제되며, 이 작업은 되돌릴 수 없습니다.",
      confirmText: "탈퇴하기",
      cancelText: "취소",
    );

    if (!confirmed) return; // 사용자가 취소한 경우 함수 종료

    if (mounted) {
      setState(() => _isLoading = true); // 로딩 상태 시작
    }

    try {
      // 서버에 회원 탈퇴 요청
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/users/$id'),
      );

      if (!mounted) return;
      setState(() => _isLoading = false); // 로딩 상태 종료

      if (response.statusCode == 200 || response.statusCode == 204) { // 성공 (204 No Content 포함)
        await prefs.remove('userId'); // 로컬에 저장된 사용자 ID 제거
        _showResultDialog(
          "탈퇴 완료",
          "회원 탈퇴가 정상적으로 처리되었습니다. 이용해주셔서 감사합니다.",
          onConfirmed: () {
            // 로그인 화면으로 이동하고 이전 모든 화면 스택 제거
            Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
          },
        );
      } else {
        // 서버에서 오류 응답을 받은 경우
        String errorMessage = "서버 오류로 인해 회원 탈퇴에 실패했습니다 (오류 코드: ${response.statusCode}).";
        try {
          // 오류 응답 본문이 JSON 형태일 경우 메시지 추출 시도
          final decodedBody = json.decode(utf8.decode(response.bodyBytes));
          if (decodedBody['message'] != null) {
            errorMessage += "\n오류 메시지: ${decodedBody['message']}";
          }
        } catch (_) {
          // JSON 파싱 실패 시 응답 본문 그대로 사용
           errorMessage += "\n응답 내용: ${utf8.decode(response.bodyBytes)}";
        }
        _showResultDialog("탈퇴 실패", errorMessage);
      }
    } catch (e) {
      // 네트워크 오류 또는 기타 예외 발생 시
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showResultDialog("네트워크 오류", "회원 탈퇴 처리 중 오류가 발생했습니다: $e");
    }
  }

  // 사용자에게 확인을 받는 다이얼로그 표시 함수
  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    String confirmText = "확인",
    String cancelText = "취소",
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // 다이얼로그 바깥 탭으로 닫기 비활성화
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false), // 'false' 반환 (취소)
                child: Text(cancelText),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true), // 'true' 반환 (확인)
                style: TextButton.styleFrom(foregroundColor: Colors.red), // 확인 버튼 텍스트 색상 강조
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false; // 사용자가 다이얼로그를 닫는 다른 방법(예: 안드로이드 뒤로가기 버튼)을 사용한 경우 false 반환
  }

  // 처리 결과를 보여주는 다이얼로그 표시 함수
  void _showResultDialog(String title, String content, {VoidCallback? onConfirmed}) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // 다이얼로그 닫기
              onConfirmed?.call(); // 확인 콜백 실행 (예: 페이지 이동)
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("회원 탈퇴", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1, // 약간의 그림자
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center( // 내용을 중앙에 배치
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 수직 중앙 정렬
            crossAxisAlignment: CrossAxisAlignment.stretch, // 자식 위젯 가로로 꽉 채우기
            children: [
              Icon(Icons.warning_amber_rounded, size: 60, color: Colors.red.shade300),
              const SizedBox(height: 20),
              const Text(
                "회원 탈퇴를 진행하시겠습니까?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                "계정을 삭제하면 모든 개인 정보와 활동 기록이 영구적으로 제거되며, 이 작업은 되돌릴 수 없습니다. 신중하게 결정해주세요.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator()) // 로딩 중일 때
                  : ElevatedButton( // 회원 탈퇴 버튼
                      onPressed: _deleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400, // 버튼 배경색
                        foregroundColor: Colors.white, // 버튼 텍스트색
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // 버튼 모서리 둥글게
                        ),
                      ),
                      child: const Text("회원 정보 영구 삭제"),
                    ),
              const SizedBox(height: 12),
              TextButton( // 취소 버튼
                onPressed: () => Navigator.of(context).pop(),
                child: Text("취소하고 돌아가기", style: TextStyle(color: Colors.grey.shade600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

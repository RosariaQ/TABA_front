import 'package:flutter/material.dart';
import 'package:healthymeal/registerationPage/registeration.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _idController.dispose(); // 컨트롤러 해제
    _pwController.dispose(); // 컨트롤러 해제
    super.dispose();
  }

  // 사용자 로그인 시도
  Future<bool> loginUser(String id, String password) async {
    // API 엔드포인트 URL (실제 환경에 맞게 수정 필요)
    final url = Uri.parse('http://healthymeal.kro.kr:4912/users/${id.trim()}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        // 서버에서 받은 해시된 비밀번호와 사용자가 입력한 비밀번호 비교
        // 주의: 실제 앱에서는 클라이언트에서 비밀번호를 직접 비교하는 것은 보안상 취약합니다.
        //       서버에서 ID/PW를 받아 인증 처리를 해야 합니다.
        final serverPassword = user['hashedPassword']?.toString().trim();
        final inputPassword = password.trim();
        return serverPassword == inputPassword;
      } else {
        // 로그인 실패 (예: 사용자를 찾을 수 없음)
        return false;
      }
    } catch (e) {
      // 네트워크 오류 또는 기타 예외 처리
      print('❌ 로그인 오류: $e');
      return false;
    }
  }

  // 로그인 성공 시 사용자 ID를 SharedPreferences에 저장
  Future<void> saveLoginId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', id);
  }

  // 로그인 버튼 클릭 시 실행되는 함수
  void _handleLogin() async {
    setState(() => _isLoading = true); // 로딩 상태 시작
    final id = _idController.text.trim();
    final pw = _pwController.text.trim();

    // loginUser 함수를 호출하여 로그인 시도
    final success = await loginUser(id, pw);
    setState(() => _isLoading = false); // 로딩 상태 종료

    if (success) {
      await saveLoginId(id); // 로그인 성공 시 ID 저장
      // 로그인 성공 시 대시보드 화면으로 이동하고 이전 화면 스택 제거
      if (mounted) { // 위젯이 여전히 마운트되어 있는지 확인
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else {
      // 로그인 실패 시 알림창 표시
      if (mounted) { // 위젯이 여전히 마운트되어 있는지 확인
        showDialog(
          context: context,
          builder: (_) => AlertDialog( // AlertDialog의 content를 const로 만들 수 없음
            title: const Text("로그인 실패"),
            content: const Text("아이디 또는 비밀번호가 올바르지 않습니다."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("확인"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          // 배경 그라데이션
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFCE38A), Color(0xFFF38181)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(242), // 약간 투명한 흰색 배경
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13), // 연한 그림자
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 내용물 크기에 맞게 조절
                  children: [
                    // 앱 타이틀
                    const Text(
                      "Healthy Meal",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 아이디 입력 필드
                    TextField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: '아이디',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    // 비밀번호 입력 필드
                    TextField(
                      controller: _pwController,
                      obscureText: true, // 비밀번호 가리기
                      decoration: const InputDecoration(
                        labelText: '비밀번호',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      keyboardType: TextInputType.visiblePassword,
                    ),
                    const SizedBox(height: 24),
                    // 로딩 중이거나 버튼 표시
                    _isLoading
                        ? const CircularProgressIndicator() // 로딩 인디케이터
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 회원가입 버튼
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const RegistrationPage()),
                                    );
                                  },
                                  child: const Text(
                                    "회원가입",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 로그인 버튼
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text("로그인", style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

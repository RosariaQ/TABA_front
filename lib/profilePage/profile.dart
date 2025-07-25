import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:healthymeal/userquitPage/userquit.dart';
import 'package:healthymeal/loginPage/login.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile>
    with RouteAware, TickerProviderStateMixin {
  // 1) 프로필 화면에서 조절할 영양소별 가중치(슬라이더 값)
  // Map의 value는 -0.5 ~ +0.5 범위, 실제 곱셈 땐 (1 + value) 사용
  final Map<String, double> _nutritionPreferences = {
    '칼로리':     0.0,
    '탄수화물':   0.0,
    '지방':       0.0,
    '단백질':     0.0,
    '식이섬유':   0.0,
    '당류':       0.0,
    '나트륨':     0.0,
    '콜레스테롤': 0.0,  // 추가
  };

  Map<String, dynamic>? _userInfo;
  bool _isLoadingUserInfo = true;
  String _userInfoError = '';
  final String _apiBaseUrl = 'http://healthymeal.kro.kr:4912';

  // 애니메이션 컨트롤러
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeSectionController;
  late Animation<double> _fadeSectionAnimation;
  bool _isNutritionExpanded = false;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 애니메이션 초기화
    _animationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500)
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn)
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
      .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _fadeSectionController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300)
    );
    _fadeSectionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeSectionController, curve: Curves.easeInOut)
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _animationController.forward();
      _fetchUserInfo();
      _loadSavedProfileImage();
      _loadNutritionPreferences();
    });
  }

  /// SharedPreferences에 저장된 가중치(JSON)을 불러와 _nutritionPreferences에 적용
  Future<void> _loadNutritionPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('nutrition_preferences');
    if (jsonStr == null) return;
    final Map<String, dynamic> map = jsonDecode(jsonStr);
    setState(() {
      map.forEach((key, value) {
        if (_nutritionPreferences.containsKey(key)) {
          _nutritionPreferences[key] = (value as num).toDouble();
        }
      });
    });
  }

  Future<void> _loadSavedProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/profile_$userId.png';
    final file = File(path);
    if (await file.exists()) {
      setState(() => _selectedImage = file);
    }
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final saved = await File(picked.path).copy('${dir.path}/profile_$userId.png');
    setState(() => _selectedImage = saved);
  }

  Future<void> _fetchUserInfo() async {
    setState(() {
      _isLoadingUserInfo = true;
      _userInfoError = '';
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('userId');
      if (id == null) throw Exception("로그인된 사용자 정보가 없습니다.");
      final res = await http.get(Uri.parse('$_apiBaseUrl/users/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        setState(() {
          _userInfo = json.decode(utf8.decode(res.bodyBytes));
          _isLoadingUserInfo = false;
        });
      } else {
        throw Exception('서버 오류: ${res.statusCode}');
      }
    } catch (e) {
      setState(() {
        _userInfoError = e.toString().replaceFirst("Exception: ", "");
        _isLoadingUserInfo = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('jwt_token');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  /// 비밀번호 확인 후 UserQuitPage로 이동
  Future<void> _confirmPasswordAndNavigateToQuit() async {
    final pwController = TextEditingController();
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('userId');
    if (id == null) {
      _showErrorDialog("오류", "로그인 정보가 없습니다.");
      return;
    }

    final input = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("비밀번호 확인"),
        content: TextField(
          controller: pwController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '비밀번호를 입력하세요',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, pwController.text.trim()),
              child: const Text("확인")),
        ],
      ),
    );

    if (input == null || input.isEmpty) return;

    final token = prefs.getString('jwt_token');
    try {
      final res = await http.get(Uri.parse('$_apiBaseUrl/users/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final user = jsonDecode(utf8.decode(res.bodyBytes));
        final serverPwd = user['hashedPassword']?.toString().trim();
        if (serverPwd == input) {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const UserQuitPage()));
        } else {
          _showErrorDialog("비밀번호 불일치", "입력하신 비밀번호가 올바르지 않습니다.");
        }
      } else {
        _showErrorDialog("오류", "서버 오류 (${res.statusCode})");
      }
    } catch (e) {
      _showErrorDialog("네트워크 오류", e.toString());
    }
  }

  String _getGenderLabel(String? code) {
    if (code == 'm') return '남성';
    if (code == 'f') return '여성';
    return '알 수 없음';
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("확인")),
        ],
      ),
    );
  }

  /// 슬라이더 UI 빌더
  Widget _buildNutritionSlider(String label, double currentValue) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 3, offset: const Offset(0,1))],
      ),
      child: Row(
        children: [
          SizedBox(
              width: 70,
              child: Text(label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          Expanded(
            child: Slider(
              value: currentValue,
              min: -0.5,
              max: 0.5,
              divisions: 10,
              label: "${((1 + currentValue) * 100).toInt()}%",
              activeColor: Colors.teal,
              inactiveColor: Colors.teal.withOpacity(0.3),
              onChanged: (newVal) => setState(() => _nutritionPreferences[label] = newVal),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text("${((1 + currentValue) * 100).toInt()}%",
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  /// 가중치(Preferences)를 SharedPreferences에 JSON으로 저장
  Future<void> _saveNutritionPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nutrition_preferences', jsonEncode(_nutritionPreferences));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("영양 정보가 저장되었습니다.")));
    _toggleNutritionSection();
  }

  void _toggleNutritionSection() {
    setState(() => _isNutritionExpanded = !_isNutritionExpanded);
    if (_isNutritionExpanded) {
      _fadeSectionController.forward();
    } else {
      _fadeSectionController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeSectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // 배경 그라데이션
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFDE68A), Color(0xFFC8E6C9), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.6, 1],
            ),
          ),
        ),
        SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 헤더
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(alignment: Alignment.center, children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color:
Colors.black54),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Text("내 프로필",
                            style: TextStyle(fontSize: 20, fontWeight:
FontWeight.bold)),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    // 프로필 정보
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _isLoadingUserInfo
                          ? const CircularProgressIndicator()
                          : _userInfoError.isNotEmpty
                              ? Text(_userInfoError,
                                  style: const TextStyle(color:
Colors.red))
                              : Row(children: [
                                  GestureDetector(
                                    onTap: _pickProfileImage,
                                    child: CircleAvatar(
                                      radius: 45,
                                      backgroundImage:
_selectedImage != null
                                          ? FileImage(_selectedImage!)
                                              as ImageProvider
                                          : const AssetImage(
                                                  'assets/image/default_man.png'),
                                      backgroundColor:
Colors.grey.shade200,
                                      child: const Align(
                                        alignment: Alignment.bottomRight,
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundColor:
Colors.white,
                                          child: Icon(Icons.camera_alt,
                                              size: 14,
                                              color:
Colors.black54),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            "아이디: ${_userInfo!['id']}",
                                            style: const TextStyle(
                                                fontWeight:
FontWeight.bold,
                                                fontSize: 17)),
                                        Text(
                                            "생년월일: ${_userInfo!['birthday']}"),
                                        Text(
                                            "성별: ${_getGenderLabel(_userInfo!['gender'])}"),
                                      ],
                                    ),
                                  ),
                                ]),
                    ),
                    const SizedBox(height: 24),
                    // 영양 정보 토글 버튼
                    ElevatedButton.icon(
                      onPressed: _toggleNutritionSection,
                      icon: Icon(_isNutritionExpanded
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down),
                      label: Text(_isNutritionExpanded
                          ? "영양 정보 숨기기"
                          : "영양 정보 변경"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
Colors.teal.shade400),
                    ),
                    const SizedBox(height: 16),
                    // 슬라이더 섹션
                    SizeTransition(
                      sizeFactor: _fadeSectionAnimation,
                      child: _isNutritionExpanded
                          ? Column(children: [
                              const Text(
                                  "각 영양소 섭취량 선호도 조절:",
                                  style: TextStyle(
                                      fontWeight:
FontWeight.bold)),
                              ..._nutritionPreferences.entries
                                  .map((e) =>
                                      _buildNutritionSlider(e.key,
e.value)),
                              ElevatedButton(
                                onPressed:
_saveNutritionPreferences,
                                style:
ElevatedButton.styleFrom(backgroundColor:
Colors.orange),
                                child: const Text("선호도 저장"),
                              ),
                            ])
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 32),
                    // 로그아웃 버튼
                    ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
Colors.deepOrangeAccent),
                      child: const Text("로그아웃",
                          style: TextStyle(color:
Colors.white)),
                    ),
                    const SizedBox(height: 12),
                    // 회원 탈퇴 버튼 (비밀번호 확인 후 이동)
                    ElevatedButton(
                      onPressed:
_confirmPasswordAndNavigateToQuit,
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
Colors.red),
                      child: const Text("회원 탈퇴",
                          style: TextStyle(color:
Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// lib/dashboardPage/dashboard.dart

import 'dart:io'; // ✅ File 사용 위해 추가

import 'package:flutter/material.dart';
import 'package:healthymeal/dailystatusPage/dailystatus.dart';
import 'package:healthymeal/mealrecordPage/mealrecord.dart';
import 'package:healthymeal/profilePage/profile.dart';
import 'package:healthymeal/recommendationPage/recommendation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:healthymeal/scoreboardPage/scoreboard.dart';
import 'package:healthymeal/underconstructionPage/underconstruction.dart';
import 'package:intl/intl.dart';
import 'package:healthymeal/mealdiaryPage/meal_diary_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart'; // ✅ 프로필 이미지 경로 확인 위해 필요

import '../main.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/daily_status_summary_card.dart';
import 'widgets/weekly_score_summary_card.dart';
import 'widgets/meal_diary_card.dart' as DashboardMealDiaryCard;

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with RouteAware, SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  int _scoreCardKey = DateTime.now().microsecondsSinceEpoch;
  int _dailyCardKey = DateTime.now().microsecondsSinceEpoch + 1;
  int _mealDiaryCardKey = DateTime.now().microsecondsSinceEpoch + 2;

  double _avatarScale = 1.0;
  double _dailyCardScale = 1.0;
  double _scoreCardScale = 1.0;
  double _mealDiaryCardScale = 1.0;

  int _selectedIndexInBottomNav = 1;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _userId;
  ImageProvider? _avatarImage; // ✅ 프로필 이미지 상태 변수

  late String _currentDateStringForMealDiary;
  late DateTime _currentDateAsDateTimeForMealDiary;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _currentDateStringForMealDiary = DateFormat('yyyy-MM-dd').format(now);
    _currentDateAsDateTimeForMealDiary = now;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward(from: 0.0);
      }
      _loadUserId();
    });
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('userId');

    if (mounted) {
      setState(() => _userId = id);
    }

    if (id != null) {
      final directory = await getApplicationDocumentsDirectory();
      final profilePath = '${directory.path}/profile_$id.png';
      final profileFile = File(profilePath);

      setState(() {
        _avatarImage = profileFile.existsSync()
            ? FileImage(profileFile)
            : const AssetImage('assets/image/default_man.png');
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    if (mounted) {
      _animationController.forward(from: 0.0);
      final nowMicroseconds = DateTime.now().microsecondsSinceEpoch;
      setState(() {
        _scoreCardKey = nowMicroseconds;
        _dailyCardKey = nowMicroseconds + 1;
        _mealDiaryCardKey = nowMicroseconds + 2;
        _avatarScale = 0.9;
        _dailyCardScale = 0.95;
        _scoreCardScale = 0.95;
        _mealDiaryCardScale = 0.95;
        _selectedIndexInBottomNav = 1;
      });
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          setState(() {
            _avatarScale = 1.0;
            _dailyCardScale = 1.0;
            _scoreCardScale = 1.0;
            _mealDiaryCardScale = 1.0;
          });
        }
      });
      _loadUserId();
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _takePictureAndNavigateToMealRecord() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.camera, imageQuality: 85, maxWidth: 1200);
      if (pickedFile != null) {
        if (mounted) {
          _navigateWithFadeTransition(
            context,
            MealRecord(initialImageFile: pickedFile),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사진 촬영이 취소되었거나 실패했습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카메라 접근 중 오류 발생: $e')),
        );
      }
    }
  }

  void _navigateWithFadeTransition(BuildContext context, Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _onBottomNavigationTap(int index) {
    if (_selectedIndexInBottomNav == index && index != 1) return;

    setState(() => _selectedIndexInBottomNav = index);

    switch (index) {
      case 0:
        _navigateWithFadeTransition(context, const ScoreboardScreen());
        break;
      case 1:
        _takePictureAndNavigateToMealRecord();
        break;
      case 2:
        _navigateWithFadeTransition(context, const MenuRecommendScreen());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFDE68A), Color(0xFFC8E6C9), Colors.white],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DashboardHeader(
                        avatarScale: _avatarScale,
                        avatarImage: _avatarImage, // ✅ ID 기반 이미지 전달
                        onAvatarTapDown: (_) =>
                            setState(() => _avatarScale = 0.9),
                        onAvatarTapUp: (_) {
                          setState(() => _avatarScale = 1.0);
                          _navigateWithFadeTransition(context, const Profile());
                        },
                        onAvatarTapCancel: () =>
                            setState(() => _avatarScale = 1.0),
                        onNotificationsPressed: () {
                          _navigateWithFadeTransition(
                              context, const Underconstruction());
                        },
                      ),
                      DailyStatusSummaryCard(
                        key: ValueKey('dailyCard_$_dailyCardKey'),
                        scale: _dailyCardScale,
                        onTapDown: (_) =>
                            setState(() => _dailyCardScale = 0.98),
                        onTapUp: (_) {
                          setState(() => _dailyCardScale = 1.0);
                          _navigateWithFadeTransition(
                              context, const DailyStatus());
                        },
                        onTapCancel: () => setState(() => _dailyCardScale = 1.0),
                        //onTap: () => _navigateWithFadeTransition(context, const DailyStatus()), -> 하...이거때문에 init 두번 실행되잖아요;;
                      ),
                      WeeklyScoreSummaryCard(
                        key: ValueKey('scoreCard_$_scoreCardKey'),
                        scale: _scoreCardScale,
                        onTapDown: (_) =>
                            setState(() => _scoreCardScale = 0.98),
                        onTapUp: (_) {
                          setState(() => _scoreCardScale = 1.0);
                          _navigateWithFadeTransition(
                              context, const ScoreboardScreen());
                        },
                        onTapCancel: () =>
                            setState(() => _scoreCardScale = 1.0),
                        onTap: () => _navigateWithFadeTransition(
                            context, const ScoreboardScreen()),
                      ),
                      if (_userId != null)
                        DashboardMealDiaryCard.MealDiaryCard( // alias 사용
                          key: ValueKey('mealDiaryCard_$_mealDiaryCardKey-${_userId ?? ""}-$_currentDateStringForMealDiary'),
                          diaryDate: _currentDateStringForMealDiary,
                          userId: _userId!,
                          scale: _mealDiaryCardScale,
                          onTapDown: (_) =>
                              setState(() => _mealDiaryCardScale = 0.98),
                          onTapUp: (_) {
                            setState(() => _mealDiaryCardScale = 1.0);
                            _navigateWithFadeTransition(
                              context,
                              MealDiaryScreen(
                                displayDate: _currentDateAsDateTimeForMealDiary,
                              ),
                            );
                          },
                          onTapCancel: () =>
                              setState(() => _mealDiaryCardScale = 1.0),
                          onTap: () => _navigateWithFadeTransition(
                            context,
                            MealDiaryScreen(
                                displayDate:
                                    _currentDateAsDateTimeForMealDiary),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 10.0),
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                            elevation: 4,
                            child: const SizedBox(
                              height: 100,
                              child: Center(child: Text("식단 일기 로딩 중...")),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndexInBottomNav,
        onTap: _onBottomNavigationTap,
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.grey.shade600,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8.0,
        iconSize: 30,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: '스코어보드'),
          BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label: '식사기록'),
          BottomNavigationBarItem(
              icon: Icon(Icons.star_border_outlined),
              activeIcon: Icon(Icons.star),
              label: '메뉴추천'),
        ],
      ),
    );
  }
}

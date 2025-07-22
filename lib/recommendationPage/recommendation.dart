// lib/recommendationPage/recommendation.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:healthymeal/widgets/common_bottom_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:healthymeal/dailystatusPage/service/dailystatusservice.dart';
import 'package:healthymeal/scoreboardPage/model/daily_intake_model.dart';
import 'package:intl/intl.dart';

// 메뉴 아이템 모델
class MenuItem {
  final String id;
  final String title;
  final String subtitle;
  final String imagePath;
  final List<NutrientInfo> nutrients;
  final double calories;
  final String recommendReason;
  final double preferenceScore;  // 선호도 점수
  final double nutritionScore;   // 영양 균형 점수
  bool isFavorite;

  MenuItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.nutrients,
    required this.calories,
    required this.recommendReason,
    this.preferenceScore = 0.0,
    this.nutritionScore = 0.0,
    this.isFavorite = false,
  });
}

// 영양소 정보 모델
class NutrientInfo {
  final String name;
  final double amount;
  final String unit;
  final Color color;

  NutrientInfo({
    required this.name,
    required this.amount,
    required this.unit,
    required this.color,
  });
}

// 추천 섹션 타입
enum RecommendSection {
  preference,    // 선호도 기준
  nutrition,     // 영양 균형
  supplement,    // 부족한 영양소 보충
  lowCalorie,    // 저칼로리
  highProtein,   // 고단백
}

// 추천 섹션 정보
class RecommendSectionInfo {
  final RecommendSection type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<MenuItem> items;

  RecommendSectionInfo({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class MenuRecommendScreen extends StatefulWidget {
  const MenuRecommendScreen({super.key});

  @override
  State<MenuRecommendScreen> createState() => _MenuRecommendScreenState();
}

class _MenuRecommendScreenState extends State<MenuRecommendScreen> 
    with SingleTickerProviderStateMixin {
  // 데이터 서비스
  final DailyStatusService _dailyStatusService = DailyStatusService();
  
  // 상태 변수
  bool _isLoading = true;
  bool _isSearchMode = false;
  String? _userId;
  DailyIntake? _todayIntake;
  List<MenuItem> _allMenuItems = [];
  List<MenuItem> _filteredMenuItems = []; // FIX: 초기화
  List<RecommendSectionInfo> _sections = [];
  RecommendSection? _selectedSection;  // 선택된 섹션 (null이면 전체 보기)
  String _searchQuery = '';
  
  // 필터 옵션
  Set<String> _selectedNutrients = {};
  double? _maxCalories;
  
  // UI 컨트롤러
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // 영양소 색상 맵
  final Map<String, Color> _nutrientColors = {
    '단백질': Colors.amber.shade700,
    '지방': Colors.orange.shade500,
    '탄수화물': Colors.purple.shade400,
    '당류': Colors.pink.shade300,
    '식이섬유': Colors.green.shade500,
    '나트륨': Colors.blue.shade400,
    '콜레스테롤': Colors.red.shade400,
    '칼로리': Colors.teal.shade600,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // 데이터 로드
  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // 사용자 ID 가져오기
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('userId');
      
      if (_userId != null && _userId!.isNotEmpty) {
        // 오늘의 영양 섭취 데이터 가져오기
        await _loadTodayIntake();
      }
      
      // 추천 메뉴 가져오기
      await _loadRecommendations();
      
      // *** FIX: 필터링된 리스트를 전체 리스트로 초기화 ***
      _filteredMenuItems = List.from(_allMenuItems);

      // 섹션별로 분류
      _organizeSections();
      
      setState(() => _isLoading = false);
      _animationController.forward(from: 0);
    } catch (e) {
      print('데이터 로드 중 오류: $e');
      setState(() => _isLoading = false);
    }
  }

  // 오늘의 영양 섭취 데이터 로드
  Future<void> _loadTodayIntake() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final url = Uri.parse('http://healthymeal.kro.kr:4912/users/$_userId/daily-intake')
          .replace(queryParameters: {'date': today});
      
      final response = await http.put(url);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        _todayIntake = DailyIntake.fromJson(data);
      }
    } catch (e) {
      print('영양 데이터 로드 실패: $e');
    }
  }

  // 추천 메뉴 로드 (실제로는 API 호출)
  Future<void> _loadRecommendations() async {
    await Future.delayed(const Duration(seconds: 1)); // 로딩 시뮬레이션
    _allMenuItems = _generateDummyMenuItems();
  }

  // 검색 및 필터링 적용
  void _applySearchAndFilter() {
    _filteredMenuItems = _allMenuItems.where((item) {
      // 검색어 필터
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!item.title.toLowerCase().contains(query) &&
            !item.subtitle.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // 칼로리 필터
      if (_maxCalories != null && item.calories > _maxCalories!) {
        return false;
      }
      
      // 영양소 필터
      if (_selectedNutrients.isNotEmpty) {
        final itemNutrients = item.nutrients.map((n) => n.name).toSet();
        if (!_selectedNutrients.every((nutrient) => itemNutrients.contains(nutrient))) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // 필터링된 결과로 섹션 재구성
    _organizeSections();
  }

  // 섹션별로 메뉴 분류
  void _organizeSections() {
    // *** FIX: 필터링 결과를 그대로 사용하도록 수정 ***
    // 이렇게 해야 검색 결과가 없을 때 빈 화면이 올바르게 표시됨
    final itemsToOrganize = _filteredMenuItems;
    
    _sections = [
      // 선호도 기준 추천
      RecommendSectionInfo(
        type: RecommendSection.preference,
        title: '선호 메뉴',
        subtitle: '취향을 분석해 추천해요',
        icon: Icons.favorite,
        color: Colors.pink.shade400,
        items: _getPreferenceBasedItems(itemsToOrganize),
      ),
      
      // 영양 균형 추천
      RecommendSectionInfo(
        type: RecommendSection.nutrition,
        title: '영양 균형 맞춤',
        subtitle: '균형잡힌 식사를 위한 추천',
        icon: Icons.balance,
        color: Colors.green.shade600,
        items: _getNutritionBalancedItems(itemsToOrganize),
      ),
      
      // 부족한 영양소 보충
      RecommendSectionInfo(
        type: RecommendSection.supplement,
        title: '영양소 보충',
        subtitle: '오늘 부족한 영양소를 채워요',
        icon: Icons.add_circle,
        color: Colors.orange.shade600,
        items: _getSupplementItems(itemsToOrganize),
      ),
      
      // 저칼로리 메뉴
      RecommendSectionInfo(
        type: RecommendSection.lowCalorie,
        title: '가벼운 한 끼',
        subtitle: '400kcal 이하 건강식',
        icon: Icons.eco,
        color: Colors.teal.shade500,
        items: _getLowCalorieItems(itemsToOrganize),
      ),
      
      // 고단백 메뉴
      RecommendSectionInfo(
        type: RecommendSection.highProtein,
        title: '단백질 듬뿍',
        subtitle: '근육 성장과 회복을 위해',
        icon: Icons.fitness_center,
        color: Colors.indigo.shade600,
        items: _getHighProteinItems(itemsToOrganize),
      ),
    ];
  }

  // *** REFACTOR: 함수 시그니처를 간결하게 수정 ***
  // 선호도 기반 메뉴
  List<MenuItem> _getPreferenceBasedItems(List<MenuItem> items) {
    var sortedItems = List<MenuItem>.from(items);
    sortedItems.sort((a, b) => b.preferenceScore.compareTo(a.preferenceScore));
    return sortedItems.take(4).toList();
  }

  // 영양 균형 메뉴
  List<MenuItem> _getNutritionBalancedItems(List<MenuItem> items) {
    var sortedItems = List<MenuItem>.from(items);
    sortedItems.sort((a, b) => b.nutritionScore.compareTo(a.nutritionScore));
    return sortedItems.take(4).toList();
  }

  // 부족한 영양소 보충 메뉴
  List<MenuItem> _getSupplementItems(List<MenuItem> items) {
    if (_todayIntake == null) return items.take(4).toList();
    
    var sortedItems = List<MenuItem>.from(items);
    // 부족한 영양소가 많이 포함된 메뉴 우선
    sortedItems.sort((a, b) {
      double scoreA = 0;
      double scoreB = 0;
      
      // 단백질 부족 시
      if (_todayIntake!.proteinG < 50) {
        final proteinA = a.nutrients.firstWhere((n) => n.name == '단백질', orElse: () => NutrientInfo(name: '', amount: 0, unit: '', color: Colors.grey)).amount;
        final proteinB = b.nutrients.firstWhere((n) => n.name == '단백질', orElse: () => NutrientInfo(name: '', amount: 0, unit: '', color: Colors.grey)).amount;
        scoreA += proteinA;
        scoreB += proteinB;
      }
      
      // 식이섬유 부족 시
      if (_todayIntake!.celluloseG < 25) {
        final fiberA = a.nutrients.firstWhere((n) => n.name == '식이섬유', orElse: () => NutrientInfo(name: '', amount: 0, unit: '', color: Colors.grey)).amount;
        final fiberB = b.nutrients.firstWhere((n) => n.name == '식이섬유', orElse: () => NutrientInfo(name: '', amount: 0, unit: '', color: Colors.grey)).amount;
        scoreA += fiberA;
        scoreB += fiberB;
      }
      
      return scoreB.compareTo(scoreA);
    });
    
    return sortedItems.take(4).toList();
  }

  // 저칼로리 메뉴
  List<MenuItem> _getLowCalorieItems(List<MenuItem> items) {
    var lowCalItems = items.where((item) => item.calories <= 400).toList();
    lowCalItems.sort((a, b) => a.calories.compareTo(b.calories));
    return lowCalItems.take(4).toList();
  }

  // 고단백 메뉴
  List<MenuItem> _getHighProteinItems(List<MenuItem> items) {
    var sortedItems = List<MenuItem>.from(items);
    sortedItems.sort((a, b) {
      final proteinA = a.nutrients.firstWhere((n) => n.name == '단백질', orElse: () => NutrientInfo(name: '', amount: 0, unit: '', color: Colors.grey)).amount;
      final proteinB = b.nutrients.firstWhere((n) => n.name == '단백질', orElse: () => NutrientInfo(name: '', amount: 0, unit: '', color: Colors.grey)).amount;
      return proteinB.compareTo(proteinA);
    });
    return sortedItems.take(4).toList();
  }

  // 더미 데이터 생성
  List<MenuItem> _generateDummyMenuItems() {
    return [
      MenuItem(
        id: '1',
        title: '그릴드 치킨 샐러드',
        subtitle: '고단백 저칼로리 건강식',
        imagePath: 'assets/images/chicken_salad.jpg',
        nutrients: [
          NutrientInfo(name: '단백질', amount: 35, unit: 'g', color: _nutrientColors['단백질']!),
          NutrientInfo(name: '식이섬유', amount: 8, unit: 'g', color: _nutrientColors['식이섬유']!),
        ],
        calories: 320,
        recommendReason: '오늘 단백질 섭취가 부족해요',
        preferenceScore: 0.8,
        nutritionScore: 0.9,
      ),
      MenuItem(
        id: '2',
        title: '현미밥과 된장찌개',
        subtitle: '균형잡힌 한식 정식',
        imagePath: 'assets/images/korean_meal.jpg',
        nutrients: [
          NutrientInfo(name: '탄수화물', amount: 45, unit: 'g', color: _nutrientColors['탄수화물']!),
          NutrientInfo(name: '나트륨', amount: 800, unit: 'mg', color: _nutrientColors['나트륨']!),
        ],
        calories: 450,
        recommendReason: '균형잡힌 영양소를 제공해요',
        preferenceScore: 0.9,
        nutritionScore: 0.85,
      ),
      MenuItem(
        id: '3',
        title: '연어 포케볼',
        subtitle: '오메가3 풍부한 건강 덮밥',
        imagePath: 'assets/images/salmon_poke.jpg',
        nutrients: [
          NutrientInfo(name: '단백질', amount: 28, unit: 'g', color: _nutrientColors['단백질']!),
          NutrientInfo(name: '지방', amount: 15, unit: 'g', color: _nutrientColors['지방']!),
        ],
        calories: 380,
        recommendReason: '건강한 지방 섭취를 도와줘요',
        preferenceScore: 0.7,
        nutritionScore: 0.95,
      ),
      MenuItem(
        id: '4',
        title: '퀴노아 채소볼',
        subtitle: '식이섬유 가득한 비건식',
        imagePath: 'assets/images/quinoa_bowl.jpg',
        nutrients: [
          NutrientInfo(name: '식이섬유', amount: 12, unit: 'g', color: _nutrientColors['식이섬유']!),
          NutrientInfo(name: '탄수화물', amount: 35, unit: 'g', color: _nutrientColors['탄수화물']!),
        ],
        calories: 280,
        recommendReason: '오늘 식이섬유가 부족해요',
        preferenceScore: 0.6,
        nutritionScore: 0.8,
      ),
      MenuItem(
        id: '5',
        title: '닭가슴살 스테이크',
        subtitle: '고단백 다이어트 메뉴',
        imagePath: 'assets/images/chicken_steak.jpg',
        nutrients: [
          NutrientInfo(name: '단백질', amount: 40, unit: 'g', color: _nutrientColors['단백질']!),
        ],
        calories: 250,
        recommendReason: '단백질 보충에 최적이에요',
        preferenceScore: 0.75,
        nutritionScore: 0.7,
      ),
      MenuItem(
        id: '6',
        title: '아보카도 토스트',
        subtitle: '건강한 지방과 비타민',
        imagePath: 'assets/images/avocado_toast.jpg',
        nutrients: [
          NutrientInfo(name: '지방', amount: 20, unit: 'g', color: _nutrientColors['지방']!),
          NutrientInfo(name: '식이섬유', amount: 10, unit: 'g', color: _nutrientColors['식이섬유']!),
        ],
        calories: 350,
        recommendReason: '아침 식사로 완벽해요',
        preferenceScore: 0.85,
        nutritionScore: 0.8,
      ),
      MenuItem(
        id: '7',
        title: '두부 김치찌개',
        subtitle: '단백질 풍부한 전통식',
        imagePath: 'assets/images/tofu_kimchi.jpg',
        nutrients: [
          NutrientInfo(name: '단백질', amount: 18, unit: 'g', color: _nutrientColors['단백질']!),
          NutrientInfo(name: '나트륨', amount: 900, unit: 'mg', color: _nutrientColors['나트륨']!),
        ],
        calories: 280,
        recommendReason: '포만감 높은 저칼로리식',
        preferenceScore: 0.9,
        nutritionScore: 0.75,
      ),
      MenuItem(
        id: '8',
        title: '그릭 요거트 파르페',
        subtitle: '프로바이오틱스와 과일',
        imagePath: 'assets/images/yogurt_parfait.jpg',
        nutrients: [
          NutrientInfo(name: '단백질', amount: 15, unit: 'g', color: _nutrientColors['단백질']!),
          NutrientInfo(name: '당류', amount: 20, unit: 'g', color: _nutrientColors['당류']!),
        ],
        calories: 220,
        recommendReason: '건강한 간식으로 좋아요',
        preferenceScore: 0.7,
        nutritionScore: 0.8,
      ),
    ];
  }

  // 필터 바텀시트 표시
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  // 필터 바텀시트
  Widget _buildFilterBottomSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 제목
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '필터',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedNutrients.clear();
                          _maxCalories = null;
                        });
                      },
                      child: const Text('초기화'),
                    ),
                  ],
                ),
              ),
              
              // 칼로리 필터
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '최대 칼로리',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _maxCalories ?? 800,
                            min: 200,
                            max: 800,
                            divisions: 12,
                            activeColor: Colors.teal,
                            onChanged: (value) {
                              setModalState(() {
                                _maxCalories = value;
                              });
                            },
                          ),
                        ),
                        Text(
                          '${(_maxCalories ?? 800).toStringAsFixed(0)} kcal',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 영양소 필터
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '포함 영양소',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _nutrientColors.keys.map((nutrient) {
                        final isSelected = _selectedNutrients.contains(nutrient);
                        return FilterChip(
                          label: Text(
                            nutrient,
                            style: TextStyle(fontSize: 12),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedNutrients.add(nutrient);
                              } else {
                                _selectedNutrients.remove(nutrient);
                              }
                            });
                          },
                          selectedColor: _nutrientColors[nutrient]!.withOpacity(0.3),
                          checkmarkColor: _nutrientColors[nutrient],
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              // 적용 버튼
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // *** FIX: setState를 호출해서 필터 적용 후 UI를 즉시 갱신 ***
                      setState(() {
                        _applySearchAndFilter();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '필터 적용',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Safe area bottom padding
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  // 찜하기 토글
  void _toggleFavorite(String itemId) {
    setState(() {
      final index = _allMenuItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _allMenuItems[index].isFavorite = !_allMenuItems[index].isFavorite;
        // 필터링된 리스트도 갱신
        final filteredIndex = _filteredMenuItems.indexWhere((item) => item.id == itemId);
        if (filteredIndex != -1) {
          _filteredMenuItems[filteredIndex].isFavorite = _allMenuItems[index].isFavorite;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // 커스텀 앱바
            _buildHeader(),
            
            // 섹션 탭
            if (!_isLoading) _buildSectionTabs(),
            
            // 메인 콘텐츠
            Expanded(
              child: _isLoading 
                  ? _buildLoadingState()
                  : _selectedSection == null
                      ? _buildAllSections()
                      : _buildSingleSection(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(
        currentPage: AppPage.recommendation,
      ),
    );
  }

  // 헤더
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 앱바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _isSearchMode
                      ? TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: '메뉴 검색...',
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _isSearchMode = false;
                                  _applySearchAndFilter();
                                });
                              },
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                               _searchQuery = value;
                               _applySearchAndFilter();
                            });
                          },
                        )
                      : const Text(
                          '맞춤 메뉴 추천',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                ),
                if (!_isSearchMode) ...[
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => setState(() => _isSearchMode = true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: _showFilterBottomSheet,
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  // 섹션 탭
  Widget _buildSectionTabs() {
    return Container(
      // *** FIX: Overflow 해결을 위해 패딩 조정 ***
      height: 100,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 전체 보기 탭
          _buildSectionTab(
            title: '전체',
            icon: Icons.dashboard,
            color: Colors.grey.shade600,
            isSelected: _selectedSection == null,
            onTap: () => setState(() => _selectedSection = null),
          ),
          
          // 각 섹션 탭
          ..._sections.map((section) => _buildSectionTab(
            // *** REFACTOR: 수동으로 문자열 자르는 로직 제거 ***
            title: section.title,
            icon: section.icon,
            color: section.color,
            isSelected: _selectedSection == section.type,
            onTap: () => setState(() => _selectedSection = section.type),
          )),
        ],
      ),
    );
  }

  // 섹션 탭 아이템
  Widget _buildSectionTab({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 85,
          // *** FIX: Overflow 해결을 위해 패딩 조정 ***
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey.shade600,
                // *** FIX: 아이콘 크기 살짝 줄이기 ***
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 로딩 상태
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.teal),
          const SizedBox(height: 16),
          Text(
            '맞춤 메뉴를 찾고 있어요...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // 전체 섹션 보기
  Widget _buildAllSections() {
    // *** FIX: 필터링 후 결과가 없는 경우를 올바르게 처리 ***
    if (_sections.every((section) => section.items.isEmpty)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _maxCalories != null || _selectedNutrients.isNotEmpty
                ? '조건에 맞는 메뉴가 없어요'
                : '추천 메뉴가 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                  _selectedNutrients.clear();
                  _maxCalories = null;
                  _applySearchAndFilter();
                });
              },
              child: const Text('필터 초기화'),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.teal,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final section = _sections[index];
          if (section.items.isEmpty) return const SizedBox.shrink();
          
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  index * 0.1,
                  1.0,
                  curve: Curves.easeOut,
                ),
              )),
              child: _buildSectionCard(section),
            ),
          );
        },
      ),
    );
  }

  // 단일 섹션 보기
  Widget _buildSingleSection() {
    final section = _sections.firstWhere(
      (s) => s.type == _selectedSection,
      orElse: () => _sections.first,
    );
    
    if (section.items.isEmpty) {
       return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              '표시할 메뉴가 없어요',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.teal,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 섹션 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: section.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(section.icon, color: section.color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: section.color,
                        ),
                      ),
                      Text(
                        section.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: section.color.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // 메뉴 아이템들
          ...section.items.map((item) => _buildMenuItem(item)),
        ],
      ),
    );
  }

  // 섹션 카드
  Widget _buildSectionCard(RecommendSectionInfo section) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 섹션 헤더
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: section.color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(section.icon, color: section.color, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        section.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: section.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        section.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: section.color.withOpacity(0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedSection = section.type);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '더보기',
                        style: TextStyle(color: section.color, fontSize: 12),
                      ),
                      Icon(Icons.arrow_forward_ios, 
                        size: 12, 
                        color: section.color,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 메뉴 아이템들 (최대 2개만 표시)
          ...section.items.take(2).map((item) => _buildCompactMenuItem(item)),
          
          if (section.items.isNotEmpty) const SizedBox(height: 8),
        ],
      ),
    );
  }

  // 컴팩트한 메뉴 아이템 (섹션 카드용)
  Widget _buildCompactMenuItem(MenuItem item) {
    return InkWell(
      onTap: () {
        // TODO: 상세 화면으로 이동
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.title} 상세 정보'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // 이미지
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.restaurant,
                      size: 25,
                      color: Colors.grey.shade400,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${item.calories.toStringAsFixed(0)} kcal',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 주요 영양소 1개만 표시
                      if (item.nutrients.isNotEmpty) ...[
                        Flexible(
                          child: Text(
                            '${item.nutrients.first.name} ${item.nutrients.first.amount}${item.nutrients.first.unit}',
                            style: TextStyle(
                              fontSize: 10,
                              color: item.nutrients.first.color,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // 찜하기
            GestureDetector(
              onTap: () => _toggleFavorite(item.id),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  item.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: item.isFavorite ? Colors.red : Colors.grey,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 전체 메뉴 아이템
  Widget _buildMenuItem(MenuItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: () {
            // TODO: 상세 화면으로 이동
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.title} 상세 정보'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지
                Hero(
                  tag: 'menu-${item.id}',
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        item.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.restaurant,
                            size: 40,
                            color: Colors.grey.shade400,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목 줄
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // 찜하기 버튼
                          GestureDetector(
                            onTap: () => _toggleFavorite(item.id),
                            child: Icon(
                              item.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: item.isFavorite ? Colors.red : Colors.grey,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // 부제목
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // 칼로리
                      Text(
                        '${item.calories.toStringAsFixed(0)} kcal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // 영양소 태그
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: item.nutrients.map((nutrient) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: nutrient.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: nutrient.color.withOpacity(0.5),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              '${nutrient.name} ${nutrient.amount}${nutrient.unit}',
                              style: TextStyle(
                                fontSize: 11,
                                color: nutrient.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      // 추천 이유
                      if (item.recommendReason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 14,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.recommendReason,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
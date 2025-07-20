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
  bool isFavorite;

  MenuItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.nutrients,
    required this.calories,
    required this.recommendReason,
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

// 필터 옵션
class FilterOptions {
  Set<String> selectedNutrients;
  double? maxCalories;
  String searchQuery;

  FilterOptions({
    Set<String>? selectedNutrients,
    this.maxCalories,
    this.searchQuery = '',
  }) : selectedNutrients = selectedNutrients ?? {};
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
  String? _userId;
  DailyIntake? _todayIntake;
  List<MenuItem> _allMenuItems = [];
  List<MenuItem> _filteredMenuItems = [];
  FilterOptions _filterOptions = FilterOptions();
  
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
      
      setState(() => _isLoading = false);
      _animationController.forward();
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
    // TODO: 실제 API 연동 시 구현
    // 현재는 더미 데이터 생성
    await Future.delayed(const Duration(seconds: 1)); // 로딩 시뮬레이션
    
    _allMenuItems = _generateDummyMenuItems();
    _filteredMenuItems = List.from(_allMenuItems);
    
    // 영양 상태 기반 정렬
    if (_todayIntake != null) {
      _sortByNutritionNeeds();
    }
  }

  // 영양 필요에 따른 정렬
  void _sortByNutritionNeeds() {
    // 부족한 영양소 우선순위 계산
    _filteredMenuItems.sort((a, b) {
      double scoreA = _calculateRecommendScore(a);
      double scoreB = _calculateRecommendScore(b);
      return scoreB.compareTo(scoreA);
    });
  }

  // 추천 점수 계산
  double _calculateRecommendScore(MenuItem item) {
    if (_todayIntake == null) return 0;
    
    double score = 0;
    
    // 각 영양소별 부족분 계산
    for (var nutrient in item.nutrients) {
      switch (nutrient.name) {
        case '단백질':
          if (_todayIntake!.proteinG < 50) score += nutrient.amount / 50;
          break;
        case '식이섬유':
          if (_todayIntake!.celluloseG < 25) score += nutrient.amount / 25;
          break;
        // 다른 영양소들도 추가
      }
    }
    
    return score;
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
      ),
    ];
  }

  // 검색 및 필터링
  void _applyFilters() {
    setState(() {
      _filteredMenuItems = _allMenuItems.where((item) {
        // 검색어 필터
        if (_filterOptions.searchQuery.isNotEmpty) {
          final query = _filterOptions.searchQuery.toLowerCase();
          if (!item.title.toLowerCase().contains(query) &&
              !item.subtitle.toLowerCase().contains(query)) {
            return false;
          }
        }
        
        // 칼로리 필터
        if (_filterOptions.maxCalories != null &&
            item.calories > _filterOptions.maxCalories!) {
          return false;
        }
        
        // 영양소 필터
        if (_filterOptions.selectedNutrients.isNotEmpty) {
          final itemNutrients = item.nutrients.map((n) => n.name).toSet();
          if (!itemNutrients.containsAll(_filterOptions.selectedNutrients)) {
            return false;
          }
        }
        
        return true;
      }).toList();
      
      // 영양 필요에 따른 재정렬
      if (_todayIntake != null) {
        _sortByNutritionNeeds();
      }
    });
  }

  // 찜하기 토글
  void _toggleFavorite(String menuId) {
    setState(() {
      final index = _allMenuItems.indexWhere((item) => item.id == menuId);
      if (index != -1) {
        _allMenuItems[index].isFavorite = !_allMenuItems[index].isFavorite;
      }
    });
    
    // TODO: 서버에 찜하기 상태 저장
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // 커스텀 앱바 및 검색 바
            _buildHeader(),
            
            // 메인 콘텐츠
            Expanded(
              child: _isLoading 
                  ? _buildLoadingState()
                  : _filteredMenuItems.isEmpty
                      ? _buildEmptyState()
                      : _buildMenuList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(
        currentPage: AppPage.recommendation,
      ),
    );
  }

  // 헤더 (앱바 + 검색바)
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 앱바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Text(
                    '맞춤 메뉴 추천',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterBottomSheet,
                ),
              ],
            ),
          ),
          
          // 검색 바
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '메뉴 검색...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _filterOptions.searchQuery = '';
                          _applyFilters();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                _filterOptions.searchQuery = value;
                _applyFilters();
              },
            ),
          ),
        ],
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

  // Empty 상태
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              '추천 메뉴가 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '검색 조건을 변경하거나\n필터를 조정해보세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _filterOptions = FilterOptions();
                _applyFilters();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '필터 초기화',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 메뉴 리스트
  Widget _buildMenuList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.teal,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredMenuItems.length + 1, // +1 for bottom padding
        itemBuilder: (context, index) {
          if (index == _filteredMenuItems.length) {
            return const SizedBox(height: 80); // 하단 여백
          }
          
          final item = _filteredMenuItems[index];
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
              child: _buildMenuItem(item),
            ),
          );
        },
      ),
    );
  }

  // 메뉴 아이템
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '필터',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _filterOptions = FilterOptions();
                        });
                      },
                      child: const Text('초기화'),
                    ),
                  ],
                ),
              ),
              
              // 칼로리 필터
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '최대 칼로리',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _filterOptions.maxCalories ?? 1000,
                      min: 200,
                      max: 1000,
                      divisions: 16,
                      label: '${(_filterOptions.maxCalories ?? 1000).toStringAsFixed(0)} kcal',
                      activeColor: Colors.teal,
                      onChanged: (value) {
                        setModalState(() {
                          _filterOptions.maxCalories = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              // 영양소 필터
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '포함 영양소',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _nutrientColors.keys.map((nutrient) {
                        final isSelected = _filterOptions.selectedNutrients.contains(nutrient);
                        return FilterChip(
                          label: Text(nutrient),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _filterOptions.selectedNutrients.add(nutrient);
                              } else {
                                _filterOptions.selectedNutrients.remove(nutrient);
                              }
                            });
                          },
                          selectedColor: _nutrientColors[nutrient]!.withOpacity(0.3),
                          checkmarkColor: _nutrientColors[nutrient],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              // 적용 버튼
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
}
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // ✅ 날짜 포맷 추가
import '../meal_diary_entry.dart';

class MealDiaryCard extends StatefulWidget {
  final MealDiaryEntry entry;
  final VoidCallback? onDelete;

  const MealDiaryCard({super.key, required this.entry, this.onDelete});

  @override
  State<MealDiaryCard> createState() => _MealDiaryCardState();
}

class _MealDiaryCardState extends State<MealDiaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isSettingTapped = false;
  late double _intakeAmount;
  late String _notes;

  @override
  void initState() {
    super.initState();
    _intakeAmount = widget.entry.intakeAmount;
    _notes = widget.entry.notes;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> updateDiary({
    required int mealInfoId,
    required double amount,
    required String newDiary,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('jwt_token');

    if (userId == null) throw Exception('❗ 로그인 정보 없음');

    final url = Uri.parse(
      'http://healthymeal.kro.kr:4912/users/$userId/meal-info/$mealInfoId'
      '?amount=$amount&diary=${Uri.encodeComponent(newDiary)}',
    );

    final response = await http.patch(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': '*/*'
    });
    if (response.statusCode != 200) {
      throw Exception('다이어리 수정 실패: ${response.statusCode}, ${response.body}');
    }
  }

  Future<void> deleteDiary(int mealInfoId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('jwt_token');

    if (userId == null) throw Exception('❗ 로그인 정보 없음');

    final url = Uri.parse(
      'http://healthymeal.kro.kr:4912/users/$userId/meal-info/$mealInfoId',
    );

    final response = await http.delete(url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 삭제가 완료되었습니다')),
        );
      }
      widget.onDelete?.call();
    } else {
      throw Exception('삭제 실패: ${response.statusCode}, ${response.body}');
    }
  }

  void _showEditDeleteOptions(BuildContext context, int mealInfoId) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading:
                const Icon(Icons.edit_note_outlined, color: Colors.blueAccent),
            title: const Text('메모 수정'),
            onTap: () => Navigator.pop(context, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title:
                const Text('기록 삭제', style: TextStyle(color: Colors.redAccent)),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
    );

    if (action == 'edit') {
      _editDiaryNote(context, mealInfoId);
    } else if (action == 'delete') {
      _confirmAndDeleteDiary(context, mealInfoId);
    }
  }

  void _editDiaryNote(BuildContext context, int mealInfoId) async {
    double currentAmount = _intakeAmount;
    final controller = TextEditingController(text: _notes);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('식단 메모 수정'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 4,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: '메모를 입력하세요...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text('섭취량: ${currentAmount.toStringAsFixed(1)} 인분'),
                Slider(
                  value: currentAmount,
                  min: 0.0,
                  max: 2.0,
                  divisions: 15,
                  label: currentAmount.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      currentAmount = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, {
                  'notes': controller.text,
                  'amount': currentAmount,
                }),
                child: const Text('저장'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null &&
        (result['notes'] != _notes || result['amount'] != _intakeAmount)) {
      try {
        await updateDiary(
          mealInfoId: mealInfoId,
          amount: result['amount'],
          newDiary: result['notes'],
        );
        if (mounted) {
          setState(() {
            _notes = result['notes'];
            _intakeAmount = result['amount'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ 메모와 섭취량이 수정되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('⚠️ 수정 실패: $e')),
          );
        }
      }
    }
  }

  void _confirmAndDeleteDiary(BuildContext context, int mealInfoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 식단 기록을 정말 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await deleteDiary(mealInfoId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('⚠️ 삭제 실패: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.28;
    final int mealInfoId = widget.entry.id;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  widget.entry.imagePath,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: imageSize,
                      height: imageSize,
                      color: Colors.grey[200],
                      child: Icon(Icons.restaurant_menu,
                          color: Colors.grey[400], size: imageSize * 0.5),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: imageSize,
                      height: imageSize,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.entry.time,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapDown: (_) =>
                              setState(() => _isSettingTapped = true),
                          onTapUp: (_) {
                            setState(() => _isSettingTapped = false);
                            _showEditDeleteOptions(context, mealInfoId);
                          },
                          onTapCancel: () =>
                              setState(() => _isSettingTapped = false),
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, bottom: 8),
                            child: AnimatedScale(
                              scale: _isSettingTapped ? 0.85 : 1.0,
                              duration: const Duration(milliseconds: 150),
                              child: AnimatedOpacity(
                                opacity: _isSettingTapped ? 0.6 : 1.0,
                                duration: const Duration(milliseconds: 150),
                                child: Icon(Icons.more_vert,
                                    color: Colors.grey.shade600),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      widget.entry.foodName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '섭취량: ${_intakeAmount.toStringAsFixed(1)} 인분',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '${DateFormat('M월 d일').format(widget.entry.createdAt)} 기록',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      _notes.isEmpty ? "작성된 메모가 없습니다." : _notes,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _notes.isEmpty
                            ? Colors.grey.shade500
                            : Colors.grey[800],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

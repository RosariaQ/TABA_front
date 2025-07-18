// lib/mealrecordPage/mealrecord.dart

import 'package:flutter/material.dart';
import 'package:healthymeal/mealrecordPage/services/meal_gpt_service.dart'; // GPT 서비스
import 'dart:io'; // File 클래스 사용
import 'dart:math'; // max 함수 사용
import 'package:image_picker/image_picker.dart'; // 이미지 피커
// import 'package:healthymeal/mealrecordPage/services/menu_analysis_service.dart'; // 현재 직접 사용되지 않음
// import 'package:healthymeal/mealrecordPage/services/meal_data_service.dart'; // 현재 직접 사용되지 않음

// UI 텍스트 및 상태 문자열 상수 클래스
class MealRecordStrings {
  static const String appBarTitle = '식사 기록'; // 앱바 제목
  static const String menuLabel = '메뉴'; // 메뉴 레이블
  static const String servingLabel = '섭취량'; // 섭취량 레이블
  static const String timeLabel = '식사 시간'; // 식사 시간 레이블
  static const String saveButtonText = '저장하기'; // 저장 버튼 텍스트
  static const String retakeTooltip = '다시 촬영'; // 재촬영 툴팁
  static const String cancelTooltip = '기록 취소'; // 기록 취소 툴팁
  static const String editTooltip = '수정'; // 수정 툴팁
  static const String confirmEditTooltip = '확인'; // 수정 확인 툴팁

  static const String statusAnalyzing = "분석 중..."; // 분석 중 상태
  static const String statusNoMenuName = "메뉴 이름 없음"; // 메뉴 이름 없음 상태
  static const String statusSelectPhotoFirst = "사진 선택 후 분석됩니다"; // 사진 먼저 선택 안내
  static const String statusAnalysisFailed =
      "분석 실패"; // 분석 실패 상태 (MenuAnalysisService.defaultAnalysisError 대신 직접 정의)
  static const String statusImagePathError =
      "이미지 경로 오류"; // 이미지 경로 오류 상태 (MenuAnalysisService.defaultImagePathError 대신 직접 정의)

  static const String hintEditMenu = '메뉴 이름을 입력하세요'; // 메뉴 수정 힌트
  static const String hintAddPhoto = '음식 사진을 추가하세요'; // 사진 추가 힌트
  static const String cameraButtonText = '카메라'; // 카메라 버튼 텍스트
  static const String galleryButtonText = '갤러리'; // 갤러리 버튼 텍스트

  static const String snackBarImageCancelled =
      '이미지 선택이 취소되었습니다.'; // 이미지 선택 취소 스낵바
  static const String snackBarImageError =
      '이미지를 가져오는 중 오류 발생: '; // 이미지 가져오기 오류 스낵바
  static const String snackBarAnalysisError = '음식 이름 분석 중 오류 발생: '; // 분석 오류 스낵바
  static const String snackBarSaveError =
      '객체 파일 저장 또는 데이터 전송 중 오류 발생: '; // 저장 오류 스낵바
  static const String snackBarSaveSuccess =
      '데이터가 준비되었고, 객체 파일이 저장되었습니다: '; // 저장 성공 스낵바 (현재는 recordMeal 결과 직접 사용)
  static const String snackBarNoPhotoToSave = '먼저 음식 사진을 선택해주세요.'; // 사진 없음 스낵바
  static const String snackBarInvalidMenuNameToSave =
      '메뉴 이름 분석이 완료되지 않았거나 유효하지 않습니다. 확인 또는 수정 후 저장해주세요.'; // 유효하지 않은 메뉴 이름 스낵바
}

// 음식 기록 화면 위젯 (StatefulWidget)
class MealRecord extends StatefulWidget {
  final XFile? initialImageFile; // 이전 화면(예: 대시보드)에서 전달받을 수 있는 초기 이미지 파일

  const MealRecord({super.key, this.initialImageFile});

  @override
  State<MealRecord> createState() => _MealRecordState();
}

class _MealRecordState extends State<MealRecord> {
  // 이미지 관련 멤버변수
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImageFile; // 사용자가 선택하거나 촬영한 이미지 파일

  // 식사 정보 관련 멤버변수
  String? _selectedServing = '1'; // 선택된 섭취량 (기본값 '1')
  String? _selectedTime = 'Breakfast'; // 선택된 식사 시간 (기본값 'Breakfast')
  final List<String> _servingOptions = [
    '1',
    '0.5',
    '1.5',
    '2'
  ]; // 섭취량 옵션 (0.5 추가)
  final List<String> _timeOptions = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack'
  ]; // 식사 시간 옵션

  // 메뉴 분석 및 ID 관련 멤버변수
  String _menuName = ''; // 분석되거나 사용자가 수정한 메뉴 이름
  int? _mealId; // 서버로부터 받은 식사 ID
  bool _isAnalyzingMenu = false; // 메뉴 분석 중인지 여부
  bool _isEditingMenu = false; // 메뉴 이름 수정 모드인지 여부
  final TextEditingController _menuNameController =
      TextEditingController(); // 메뉴 이름 입력 컨트롤러

  // 서비스 인스턴스
  final MealGptService _mealGptService = MealGptService(); // GPT 기반 분석 및 기록 서비스

  @override
  void initState() {
    super.initState();
    _menuNameController.text = _menuName; // 메뉴 이름 컨트롤러 초기화

    // 위젯이 빌드된 후 초기 이미지 파일 처리
    if (widget.initialImageFile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // 위젯이 여전히 화면에 있는지 확인
          setState(() {
            _pickedImageFile = widget.initialImageFile;
            _menuName = MealRecordStrings.statusAnalyzing; // 분석 중 상태로 설정
            _menuNameController.text = _menuName;
            _isEditingMenu = false; // 수정 모드 해제
          });
          if (_pickedImageFile != null) {
            _analyzeImageAndUpdateState(_pickedImageFile!.path); // 이미지 분석 시작
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _menuNameController.dispose(); // 컨트롤러 해제
    super.dispose();
  }

  // 이미지 선택(카메라only) 및 분석 실행
  Future<void> _pickImageAndAnalyze(ImageSource source) async {
    if (_isAnalyzingMenu) return; // 분석 중이면 중복 실행 방지

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source, // 카메라 또는 갤러리
        imageQuality: 80, // 이미지 품질 (0-100)
        maxWidth: 1000, // 이미지 최대 너비 (리사이징)
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _pickedImageFile = pickedFile;
          _menuName = MealRecordStrings.statusAnalyzing; // 분석 중 상태로 UI 업데이트
          _menuNameController.text = _menuName;
          _isEditingMenu = false;
        });
        await _analyzeImageAndUpdateState(pickedFile.path); // 실제 분석 로직 호출
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(MealRecordStrings.snackBarImageCancelled)),
          );
        }
      }
    } catch (e) {
      print('이미지 선택 오류: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${MealRecordStrings.snackBarImageError}$e')),
      );
      _resetMenuAnalysisStateOnError(); // 오류 발생 시 상태 초기화
    }
  }

  // 선택된 이미지를 GPT 서비스를 통해 분석하고 UI 상태 업데이트
  Future<void> _analyzeImageAndUpdateState(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      _resetMenuAnalysisStateOnError(
          errorMessage: MealRecordStrings.statusImagePathError);
      return;
    }
    if (mounted) {
      setState(() {
        _isAnalyzingMenu = true; // 분석 시작 상태
        _isEditingMenu = false; // 분석 중에는 수정 모드 해제
      });
    }
    try {
      final File imageFile = File(imagePath);
      // MealGptService의 sendMealImageAndAnalyze 호출
      final Map<String, dynamic> analysisResult =
          await _mealGptService.sendMealImageAndAnalyze(imageFile);

      if (!mounted) return;

      if (analysisResult.containsKey('error')) {
        // 서비스에서 오류 반환 시
        _resetMenuAnalysisStateOnError(errorMessage: analysisResult['error']);
        if (analysisResult.containsKey('mealId')) {
          _mealId = analysisResult['mealId']; // 오류가 발생했더라도 mealId가 있으면 저장 (삭제용)
        }
      } else {
        // 분석 성공 시
        setState(() {
          _mealId = analysisResult['mealId'] as int?;
          _menuName = analysisResult['menuName'] as String? ??
              MealRecordStrings.statusNoMenuName;
          _menuNameController.text = _menuName;
          _isAnalyzingMenu = false;
        });
      }
    } catch (e) {
      print('GPT 분석 중 예외 발생: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${MealRecordStrings.snackBarAnalysisError}$e')),
      );
      _resetMenuAnalysisStateOnError(
          errorMessage: MealRecordStrings.statusAnalysisFailed);
    }
  }

  // 메뉴 분석 관련 상태를 오류 발생 시 초기화하는 함수
  void _resetMenuAnalysisStateOnError({String? errorMessage}) {
    if (mounted) {
      setState(() {
        _menuName = errorMessage ?? MealRecordStrings.statusAnalysisFailed;
        _menuNameController.text = _menuName;
        _isAnalyzingMenu = false;
      });
    }
  }

  // 식단 최종 기록 (서버로 전송)
  Future<void> _saveData() async {
    if (_isAnalyzingMenu) return; // 분석 중이면 저장 방지
    if (_pickedImageFile == null) {
      // 사진이 없으면 저장 방지
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(MealRecordStrings.snackBarNoPhotoToSave)),
      );
      return;
    }
    if (_mealId == null) {
      // mealId가 없으면 (이미지 업로드/분석 실패 시) 저장 방지
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("메뉴 분석 정보가 없어 저장할 수 없습니다.")),
      );
      return;
    }

    // 현재 메뉴 이름 (수정 중이면 컨트롤러 값, 아니면 _menuName)
    final String currentMenuName =
        _isEditingMenu ? _menuNameController.text.trim() : _menuName.trim();
    // 유효한 메뉴 이름인지 확인 (상태 메시지가 아닌 실제 메뉴 이름이어야 함)
    if (currentMenuName.isEmpty ||
        currentMenuName == MealRecordStrings.statusAnalyzing ||
        currentMenuName == MealRecordStrings.statusAnalysisFailed ||
        currentMenuName == MealRecordStrings.statusImagePathError ||
        currentMenuName == MealRecordStrings.statusNoMenuName ||
        currentMenuName == MealRecordStrings.statusSelectPhotoFirst) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(MealRecordStrings.snackBarInvalidMenuNameToSave)),
      );
      return;
    }
    // TODO: 실제로는 _menuName을 서버에 업데이트하는 로직이 필요할 수 있음 (현재는 섭취량, 시간만 업데이트)

    // 섭취량 파싱 (문자열 "0.5" 등을 double로 변환)
    final double servingAmount =
        double.tryParse(_selectedServing ?? "1") ?? 1.0;
    // API는 int를 기대하므로, g 단위로 변환하거나 API 스펙에 맞춰야 함. 여기서는 임시로 int로 변환.
    // 예: 1인분 = 200g 가정 시 servingAmount * 200
    final double amountForApi = servingAmount; // ✅ 인분 그대로 저장

    // MealGptService를 통해 식단 기록
    String result = await _mealGptService.recordMeal(_mealId!, amountForApi,
        diary: "식사 시간: $_selectedTime"); // 다이어리 내용에 식사 시간 포함

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
      if (result.startsWith("✅")) {
        // 성공 메시지 시작 확인
        Navigator.of(context).pop(); // 성공 시 이전 화면으로 돌아가기
      }
    }
  }

  // 메뉴 이름 수정 모드 토글
  void _toggleEditMenu() {
    if (_isAnalyzingMenu) return; // 분석 중에는 수정 불가

    if (mounted) {
      setState(() {
        if (_isEditingMenu) {
          // 수정 완료: 텍스트 필드에서 변경된 내용을 _menuName에 저장
          _menuName = _menuNameController.text.trim();
          if (_menuName.isEmpty) {
            // 비어있으면 기본값으로 설정
            _menuName = MealRecordStrings.statusNoMenuName;
            _menuNameController.text = _menuName;
          }
          _isEditingMenu = false; // 수정 모드 종료
        } else {
          // 수정 시작: 이미지와 메뉴 이름이 있고, 분석/오류 상태가 아닐 때만 수정 모드 진입
          if (_pickedImageFile != null &&
              _menuName.isNotEmpty &&
              _menuName != MealRecordStrings.statusAnalyzing &&
              _menuName != MealRecordStrings.statusSelectPhotoFirst) {
            // 오류 메시지 상태일 경우, 텍스트 필드를 비워서 사용자 입력을 유도
            _menuNameController.text =
                (_menuName == MealRecordStrings.statusAnalysisFailed ||
                        _menuName == MealRecordStrings.statusImagePathError ||
                        _menuName == MealRecordStrings.statusNoMenuName)
                    ? ''
                    : _menuName;
            _isEditingMenu = true; // 수정 모드 시작
          }
        }
      });
    }
  }

  // 기록 취소 및 이전 화면으로 돌아가기 (서버에 생성된 mealId 삭제 요청 포함)
  void _deleteRecordAndExit() async {
    if (_mealId != null) {
      // mealId가 있는 경우 (이미지 업로드/분석이 한 번이라도 성공한 경우)
      String result = await _mealGptService.deleteMeal(_mealId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      }
    }
    if (mounted) {
      Navigator.of(context).pop(); // 이전 화면으로 돌아가기
    }
  }

  // 저장 버튼 활성화 조건
  bool get _canEnableSaveButton {
    if (_isAnalyzingMenu || _pickedImageFile == null || _mealId == null) {
      return false; // 분석 중, 사진 없음, mealId 없음
    }
    final currentMenuName =
        _isEditingMenu ? _menuNameController.text.trim() : _menuName.trim();
    // 메뉴 이름이 비어있거나, 분석/오류 상태 메시지가 아니어야 함
    return currentMenuName.isNotEmpty &&
        currentMenuName != MealRecordStrings.statusAnalyzing &&
        currentMenuName != MealRecordStrings.statusAnalysisFailed &&
        currentMenuName != MealRecordStrings.statusImagePathError &&
        currentMenuName != MealRecordStrings.statusNoMenuName &&
        currentMenuName != MealRecordStrings.statusSelectPhotoFirst;
  }

  // --- UI 빌더 메소드들 ---

  // 이미지 선택 영역 UI 빌드
  Widget _buildImagePickerArea(double height) {
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias, // 내부 컨텐츠가 경계를 넘어가지 않도록
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _pickedImageFile == null
          ? Center(
              // 이미지가 없을 때 카메라/갤러리 버튼 표시
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 50, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_camera),
                        label: const Text(MealRecordStrings.cameraButtonText),
                        onPressed: () =>
                            _pickImageAndAnalyze(ImageSource.camera),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text(MealRecordStrings.galleryButtonText),
                        onPressed: () =>
                            _pickImageAndAnalyze(ImageSource.gallery),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    MealRecordStrings.hintAddPhoto,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            )
          : Image.file(
              // 선택된 이미지 표시
              File(_pickedImageFile!.path),
              fit: BoxFit.cover,
              width: double.infinity,
              height: height,
            ),
    );
  }

  // 메뉴 이름 표시 및 수정 영역 UI 빌드
  Widget _buildMenuSection() {
    String displayMenuName;
    // 상태에 따른 메뉴 이름 설정
    if (_menuName.isEmpty && _pickedImageFile == null) {
      displayMenuName = MealRecordStrings.statusSelectPhotoFirst;
    } else if (_menuName.isEmpty &&
        _pickedImageFile != null &&
        !_isAnalyzingMenu) {
      displayMenuName = MealRecordStrings.statusNoMenuName;
    } else {
      displayMenuName = _menuName;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          MealRecordStrings.menuLabel,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.lightGreen[100]?.withAlpha(153), // 연한 녹색 배경
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: _isAnalyzingMenu // 분석 중일 때 로딩 인디케이터 표시
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.0, color: Colors.teal),
                        )
                      : _isEditingMenu // 수정 모드일 때 텍스트 필드 표시
                          ? TextField(
                              controller: _menuNameController,
                              textAlign: TextAlign.center,
                              autofocus: true,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: MealRecordStrings.hintEditMenu,
                                border: InputBorder.none, // 테두리 없음
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8.0),
                              ),
                              onSubmitted: (_) =>
                                  _toggleEditMenu(), // 엔터 시 수정 완료
                            )
                          : Text(
                              // 일반 상태일 때 메뉴 이름 표시
                              displayMenuName,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis, // 길면 말줄임표
                              textAlign: TextAlign.center,
                            ),
                ),
              ),
              // 이미지 있고 분석 중 아닐 때만 수정/확인 버튼 표시
              if (_pickedImageFile != null && !_isAnalyzingMenu)
                IconButton(
                  icon: Icon(
                    _isEditingMenu
                        ? Icons.check_circle_outline
                        : Icons.edit_note, // 수정 모드에 따라 아이콘 변경
                    color: _isEditingMenu ? Colors.teal : Colors.black54,
                  ),
                  onPressed: _toggleEditMenu,
                  tooltip: _isEditingMenu
                      ? MealRecordStrings.confirmEditTooltip
                      : MealRecordStrings.editTooltip,
                  constraints: const BoxConstraints(), // 버튼 크기 최소화
                  padding: EdgeInsets.zero, // 내부 패딩 제거
                ),
            ],
          ),
        ),
      ],
    );
  }

  // 섭취량 및 식사 시간 드롭다운 영역 UI 빌드
  Widget _buildDropdownsSection() {
    return Row(
      children: [
        Expanded(
          // 섭취량 드롭다운
          child: _buildDropdownContainer(
            label: MealRecordStrings.servingLabel,
            value: _selectedServing,
            items: _servingOptions,
            onChanged: _isAnalyzingMenu // 분석 중에는 비활성화
                ? null
                : (newValue) {
                    if (mounted) setState(() => _selectedServing = newValue);
                  },
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          // 식사 시간 드롭다운
          child: _buildDropdownContainer(
            label: MealRecordStrings.timeLabel,
            value: _selectedTime,
            items: _timeOptions,
            onChanged: _isAnalyzingMenu // 분석 중에는 비활성화
                ? null
                : (newValue) {
                    if (mounted) setState(() => _selectedTime = newValue);
                  },
          ),
        ),
      ],
    );
  }

  // 개별 드롭다운 컨테이너 UI 빌드 헬퍼 메소드
  Widget _buildDropdownContainer({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.lightGreen[100]?.withAlpha(153),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: DropdownButtonHideUnderline(
            // 드롭다운 기본 밑줄 숨김
            child: DropdownButton<String>(
              value: value,
              isExpanded: true, // 드롭다운 너비 확장
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
              items: items.map((String val) {
                return DropdownMenuItem<String>(
                    value: val, child: Center(child: Text(val)));
              }).toList(),
              onChanged: onChanged,
              // 비활성화 시 힌트 (현재 선택된 값 표시)
              disabledHint: Center(
                  child: Text(value ?? '',
                      style: TextStyle(color: Colors.grey[600]))),
            ),
          ),
        ),
      ],
    );
  }

  // 재촬영, 저장, 취소 버튼 영역 UI 빌드
  Widget _buildActionButtons(double horizontalPadding, Size screenSize) {
     return Row(
        children: [
          // 재촬영 버튼
          Tooltip(
            message: MealRecordStrings.retakeTooltip,
            child: OutlinedButton(
              onPressed: _isAnalyzingMenu ? null : () => _pickImageAndAnalyze(ImageSource.camera), // 분석 중 비활성화
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal,
                backgroundColor: Colors.teal.shade50,
                side: BorderSide(color: Colors.teal.shade200),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: max(15, screenSize.width * 0.04)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ).copyWith( // 비활성화 시 스타일
                foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) => states.contains(WidgetState.disabled) ? Colors.grey : Colors.teal),
                backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) => states.contains(WidgetState.disabled) ? Colors.grey.shade200 : Colors.teal.shade50),
                side: WidgetStateProperty.resolveWith<BorderSide?>((states) => states.contains(WidgetState.disabled) ? BorderSide(color: Colors.grey.shade300) : BorderSide(color: Colors.teal.shade200)),
              ),
              child: const Icon(Icons.camera_alt, size: 24),
            ),
          ),
          const SizedBox(width: 16.0),
          // 저장하기 버튼
          Expanded(
            child: ElevatedButton(
              onPressed: _canEnableSaveButton ? _saveData : null, // 저장 가능할 때만 활성화
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                disabledBackgroundColor: Colors.orange.shade200, // 비활성화 시 배경색
                disabledForegroundColor: Colors.white70, // 비활성화 시 글자색
              ),
              child: const Text(
                MealRecordStrings.saveButtonText,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
            const SizedBox(width: 16.0),
            // 기록 취소 (휴지통) 버튼
            Tooltip(
              message: MealRecordStrings.cancelTooltip,
              child: OutlinedButton(
                // 분석 중에도 취소는 가능하도록 할 수 있으나, mealId가 없을 수 있음에 유의
                onPressed: _deleteRecordAndExit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent.shade700,
                  backgroundColor: Colors.red.shade50,
                  side: BorderSide(color: Colors.redAccent.shade200),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: max(15, screenSize.width * 0.04)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ).copyWith( // 비활성화 시 스타일 (필요시 추가)
                  foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) => states.contains(WidgetState.disabled) ? Colors.grey : Colors.redAccent.shade700),
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) => states.contains(WidgetState.disabled) ? Colors.grey.shade200 : Colors.red.shade50),
                  side: WidgetStateProperty.resolveWith<BorderSide?>((states) => states.contains(WidgetState.disabled) ? BorderSide(color: Colors.grey.shade300) : BorderSide(color: Colors.redAccent.shade200)),
                ),
                child: const Icon(Icons.delete_outline, size: 24),
              ),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // 화면 너비에 따른 가로 패딩 동적 조절
    final horizontalPadding = max(16.0, screenSize.width * 0.04);
    // 이미지 선택 영역 높이 (화면 높이의 40%)
    final imageAreaHeight = screenSize.height * 0.4;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios), // iOS 스타일 뒤로가기 아이콘
          onPressed: _deleteRecordAndExit, // 뒤로가기 시 기록 취소 로직 실행
        ),
        title: const Text(
          MealRecordStrings.appBarTitle,
          style:
              TextStyle(fontSize: 22, fontWeight: FontWeight.bold), // 글꼴 크기 조정
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0, // 앱바 그림자 제거
      ),
      body: Column(
        // 화면 전체를 Column으로 구성
        children: [
          Expanded(
            // 상단 (이미지, 메뉴 이름) 영역이 남은 공간을 차지하도록
            child: SingleChildScrollView(
              // 내용이 길어지면 스크롤 가능
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePickerArea(imageAreaHeight), // 이미지 선택 영역
                    const SizedBox(height: 24.0),
                    _buildMenuSection(), // 메뉴 이름 표시/수정 영역
                  ],
                ),
              ),
            ),
          ),
          // 하단 (드롭다운, 액션 버튼) 영역
          Padding(
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              top: 16.0, // 드롭다운 위쪽 여백
              // 하단 시스템 SafeArea 영역 고려한 패딩
              bottom: max(16.0, MediaQuery.of(context).padding.bottom + 8.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 내용물 크기만큼만 차지
              children: [
                _buildDropdownsSection(), // 섭취량, 식사 시간 드롭다운
                const SizedBox(height: 24.0),
                _buildActionButtons(horizontalPadding, screenSize), // 액션 버튼들
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// lib/nutrientintakePage/widgets/nutrient_selector_button.dart
import 'package:flutter/material.dart';

class NutrientSelectorButton extends StatelessWidget {
  final String selectedNutrientName; // 현재 선택된 영양소의 이름
  final VoidCallback onPressed; // 버튼을 눌렀을 때 실행될 콜백 함수
  final double? buttonWidth; // 버튼의 너비 (선택 사항)

  const NutrientSelectorButton({
    super.key,
    required this.selectedNutrientName,
    required this.onPressed,
    this.buttonWidth,
  });

  @override
  Widget build(BuildContext context) {
    // 화면 너비를 기준으로 기본 버튼 너비 설정 (양쪽 패딩 16.0 * 2 제외)
    final double defaultWidth = MediaQuery.of(context).size.width - (16.0 * 2);

    return SizedBox(
      width: buttonWidth ?? defaultWidth, // 제공된 너비가 있으면 사용, 없으면 기본 너비
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, // 배경색
          foregroundColor: Colors.orange.shade800, // 텍스트 및 아이콘 색상
          side: BorderSide(color: Colors.orange.shade600, width: 1.5), // 테두리
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // 내부 패딩
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // 모서리 둥글게
          ),
          elevation: 2, // 약간의 그림자 효과
        ),
        child: Row( // 아이콘과 텍스트를 가로로 배열
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              selectedNutrientName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8), // 텍스트와 아이콘 사이 간격
            Icon(Icons.sync_alt_rounded, size: 20, color: Colors.orange.shade700), // 변경 아이콘
          ],
        ),
      ),
    );
  }
}

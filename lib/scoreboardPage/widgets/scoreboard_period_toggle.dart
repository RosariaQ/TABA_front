import 'package:flutter/material.dart';
import '../scoreboard_constants.dart'; // 상수 파일 import (색상 등)

class ScoreboardPeriodToggle extends StatelessWidget {
  final List<bool> isSelected; // 각 버튼의 선택 상태 리스트 (예: [true, false, false, false])
  final Function(int) onPressed; // 버튼 클릭 시 호출될 콜백 함수 (선택된 인덱스 전달)

  const ScoreboardPeriodToggle({
    super.key,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center( // 토글 버튼 그룹을 화면 중앙에 배치
      child: ToggleButtons(
        isSelected: isSelected, // 외부에서 전달받은 선택 상태 적용
        onPressed: onPressed, // 버튼 클릭 이벤트 핸들러 연결
        borderRadius: BorderRadius.circular(10.0), // 버튼 모서리 둥글게
        selectedColor: Colors.white, // 선택된 버튼의 텍스트/아이콘 색상
        color: Colors.black54, // 선택되지 않은 버튼의 텍스트/아이콘 색상
        fillColor: primaryScoreboardColor, // 선택된 버튼의 배경색 (상수 사용)
        borderColor: Colors.grey.shade300, // 버튼 테두리 색상
        selectedBorderColor: primaryScoreboardColor, // 선택된 버튼의 테두리 색상 (상수 사용)
        borderWidth: 1.5, // 테두리 두께
        constraints: const BoxConstraints(minHeight: 38.0, minWidth: 60.0), // 각 버튼의 최소 크기
        children: const [
          // 각 토글 버튼의 내용 (주간, 월간, 분기별, 연간)
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.0), // 버튼 내부 좌우 패딩
              child: Text("주간", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.0),
              child: Text("월간", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.0),
              child: Text("분기", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))), // "분기별" -> "분기"
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.0),
              child: Text("연간", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

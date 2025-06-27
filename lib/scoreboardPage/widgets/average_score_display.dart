import 'package:flutter/material.dart';
import '../scoreboard_constants.dart'; // 상수 파일 import (색상 등)

class AverageScoreDisplay extends StatelessWidget {
  final double averageScore; // 표시할 평균 점수
  final String dateRangeFormatted; // 표시할 날짜 범위 문자열 (예: "5월 1일 ~ 5월 7일")
  final VoidCallback onDetailPressed; // "detail" 버튼 클릭 시 호출될 콜백 함수

  const AverageScoreDisplay({
    super.key,
    required this.averageScore,
    required this.dateRangeFormatted,
    required this.onDetailPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0), // 좌우 패딩 약간 추가, 상하 패딩
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 내용물 왼쪽 정렬
        children: [
          // "avr" 텍스트 (평균 점수를 나타내는 레이블)
          const Text("평균 점수", // "avr" -> "평균 점수"로 변경
              style: TextStyle(
                  color: Colors.black54, // 색상 약간 진하게
                  fontSize: 13, // 폰트 크기 약간 줄임
                  fontWeight: FontWeight.w600)), // 두께 조정
          const SizedBox(height: 4), // 레이블과 점수 사이 간격
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // 점수와 버튼을 양 끝으로 정렬
            crossAxisAlignment: CrossAxisAlignment.end, // 점수와 버튼 하단 정렬
            children: [
              // 평균 점수 및 날짜 범위 표시
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 평균 점수 (예: "85 point")
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                          fontSize: 38, // 점수 폰트 크기 키움
                          fontWeight: FontWeight.bold,
                          color: Colors.black87), // 점수 색상
                      children: [
                        TextSpan(text: averageScore.toStringAsFixed(0)), // 소수점 없이 표시
                        const TextSpan(
                          text: ' 점', // "point" -> "점"으로 변경
                          style: TextStyle(
                              fontSize: 17, // 단위 폰트 크기 조정
                              fontWeight: FontWeight.normal,
                              color: Colors.black54, // 단위 색상
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5), // 점수와 날짜 범위 사이 간격
                  // 날짜 범위 (예: "5월 1일 ~ 5월 7일")
                  Text(dateRangeFormatted,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13.5, // 폰트 크기 조정
                          fontWeight: FontWeight.w500)), // 두께 조정
                ],
              ),
              // "detail" 버튼
              OutlinedButton(
                onPressed: onDetailPressed, // 상세 보기 콜백 연결
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryScoreboardColor, // 버튼 텍스트/아이콘 색상 (상수 사용)
                  side: const BorderSide(color: primaryScoreboardColor, width: 1.5), // 버튼 테두리 (상수 사용, 두께 조정)
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 버튼 내부 패딩 조정
                  minimumSize: Size.zero, // 버튼 최소 크기 (내용에 맞게)
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0)), // 버튼 모서리 둥글게 (반경 증가)
                ),
                child: const Text("상세보기", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), // "detail" -> "상세보기"
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ScoreCommentDisplay extends StatelessWidget {
  // TODO: 실제 앱에서는 이 코멘트 내용을 동적으로 생성하거나 외부(예: API, 서비스)에서 주입받아야 합니다.
  // 현재는 하드코딩된 예시 텍스트를 사용합니다.
  final String comment; // 외부에서 코멘트를 받을 수 있도록 수정 (선택 사항)

  const ScoreCommentDisplay({
    super.key,
    this.comment = "", // 기본 코멘트 (비어있거나, 기본 메시지)
  });

  @override
  Widget build(BuildContext context) {
    // 기본 코멘트 (외부에서 comment가 제공되지 않았을 경우 사용)
    const String defaultCommentPart1 = "이번 주는 전반적으로 양호한 점수를 기록했습니다. 특히 ";
    const String defaultCommentNutrients = "단백질과 식이섬유 ";
    const String defaultCommentPart2 = "섭취가 잘 이루어졌습니다. ";
    const String defaultCommentPart3 = "다만, ";
    const String defaultCommentCautionNutrients = "탄수화물과 나트륨 ";
    const String defaultCommentPart4 = "섭취량에 조금 더 주의가 필요해 보입니다. 다음 주에는 균형 잡힌 식단을 유지해 보세요!";

    // 외부에서 코멘트가 제공되면 해당 코멘트를 사용, 아니면 기본 코멘트 사용
    bool useCustomComment = comment.isNotEmpty;

    return Flexible( // 부모 위젯(Column) 내에서 남은 공간을 유동적으로 차지
      flex: 1, // 다른 Expanded 또는 Flexible 위젯과의 비율에 따라 공간 할당 조절
      fit: FlexFit.loose, // 내용이 적으면 최소한의 공간만, 많으면 최대한 차지
      child: Container(
        width: double.infinity, // 가로로 꽉 채우기
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // 내부 패딩
        margin: const EdgeInsets.only(top: 8.0), // 위쪽 여백
        decoration: BoxDecoration( // 배경 스타일
          color: Colors.grey.shade100, // 연한 배경색
          borderRadius: BorderRadius.circular(12.0), // 모서리 둥글게
        ),
        child: SingleChildScrollView( // 내용이 길어질 경우 스크롤 가능
          child: useCustomComment
              ? Text( // 외부에서 제공된 코멘트 사용
                  comment,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13.5, // 폰트 크기 조정
                      fontWeight: FontWeight.normal,
                      color: Colors.black87,
                      height: 1.5, // 줄 간격
                  ),
                )
              : Text.rich( // 기본 코멘트 (TextSpan으로 스타일 다양하게 적용)
                  TextSpan(
                    style: const TextStyle(
                        fontSize: 13.5, // 폰트 크기 조정
                        fontWeight: FontWeight.normal,
                        color: Colors.black87,
                        height: 1.5, // 줄 간격
                    ),
                    children: const [
                      TextSpan(text: defaultCommentPart1),
                      TextSpan(
                          text: defaultCommentNutrients, // "단백질과 식이섬유 "
                          style: TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold)),
                      TextSpan(text: defaultCommentPart2),
                      TextSpan(text: "\n"), // 줄바꿈
                      TextSpan(text: defaultCommentPart3),
                      TextSpan(
                          text: defaultCommentCautionNutrients, // "탄수화물과 나트륨 "
                          style: TextStyle(
                              color: Colors.deepOrangeAccent, fontWeight: FontWeight.bold)),
                      TextSpan(text: defaultCommentPart4),
                    ],
                  ),
                  textAlign: TextAlign.center, // 텍스트 중앙 정렬
                ),
        ),
      ),
    );
  }
}

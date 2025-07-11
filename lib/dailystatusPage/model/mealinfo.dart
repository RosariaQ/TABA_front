// lib/dailystatusPage/model/mealinfo.dart

class MealInfo {
  // 영양 정보
  final double carbonhydrate_g;
  final double protein_g;
  final double fat_g;
  final double sodium_mg;
  final double cellulose_g;
  final double sugar_g;
  final double cholesterol_mg;
  final double Kcal_g;

  // 식사 관련 메타데이터
  final DateTime intaketime;
  final String mealtype;
  final double intakeamount; // ✅ int → double 로 수정
  final List<String> meals;
  final String imagepath;

  MealInfo({
    required this.Kcal_g,
    required this.carbonhydrate_g,
    required this.protein_g,
    required this.fat_g,
    required this.sodium_mg,
    required this.cellulose_g,
    required this.sugar_g,
    required this.cholesterol_mg,
    required this.intaketime,
    required this.mealtype,
    required this.intakeamount, // ✅ double
    required this.meals,
    required this.imagepath,
  });

  factory MealInfo.fromJson(Map<String, dynamic> json) {
    // json 으로부터 전달받는 data 정리
    double totalCarbon=0 ,totalenergyKcal=0, totalProtein=0, totalFat=0, totalSodium=0, totalCellulose=0, totalSugar=0, totalCholesterol=0;
    final List<String> menuNames = [];
    // 메뉴 이미지 불러오기
    final String imageBaseUrl = 'http://healthymeal.kro.kr:4912/uploads/';
    final String imagePath = (json['imgPath'] as String? ?? '');
    final menus = json['mealInfoFoodLinks'] as List<dynamic>;
    final double menuLength = menus.length.toDouble();
    for(var data in menus) {
      final menu = data['food'];
      //print("menu : $menu & $menuLength");
      menu['energyKcal'] == null ? totalenergyKcal += 0 :
      totalenergyKcal += ((menu['energyKcal'] as num).toDouble() / menuLength);
      //print("menu : $menu & $menuLength");
      menu['carbohydrateG'] == null ? totalCarbon += 0 :
      totalCarbon += ((menu['carbohydrateG'] as num).toDouble() / menuLength);
      //print(totalCarbon);
       menu['proteinG'] == null ? totalProtein += 0 :
      totalProtein += ((menu['proteinG'] as num).toDouble() / menuLength);
      //print(totalProtein);
       menu['fatG'] == null ? totalFat += 0 :
      totalFat += ((menu['fatG'] as num).toDouble() / menuLength);
      //print(totalFat);
       menu['sodiumMg'] == null ? totalSodium += 0 :
      totalSodium += ((menu['sodiumMg'] as num).toDouble() / menuLength);
      //print(totalSodium);
       menu['celluloseG'] == null ? totalCellulose += 0 :
      totalCellulose += ((menu['celluloseG'] as num).toDouble() / menuLength);
      //print(totalCellulose);
       menu['sugarsG'] == null ? totalSugar += 0 :
      totalSugar += ((menu['sugarsG'] as num).toDouble() / menuLength);
      //print(totalSugar);
       menu['cholesterolMg'] == null ? totalCholesterol += 0 :
      totalCholesterol += ((menu['cholesterolMg'] as num).toDouble() / menuLength);
      //print(totalCholesterol);
      menuNames.add(menu['name'] as String);
    }
    //print(json['intakeAmount']);
    return MealInfo(
      carbonhydrate_g: totalCarbon,
      protein_g: totalProtein,
      fat_g: totalFat,
      sodium_mg: totalSodium,
      cellulose_g: totalCellulose,
      sugar_g: totalSugar,
      cholesterol_mg: totalCholesterol,
      Kcal_g:totalenergyKcal,
      // 날짜/시간 문자열을 DateTime 객체로 파싱
      intaketime: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      mealtype: "식사",
      intakeamount: json['intakeAmount'] == null ? 1 : ((json['intakeAmount']) as num).toDouble(), // 기본값 설정
      // 문자열 리스트로 변환 (API 응답이 List<dynamic>일 수 있으므로 캐스팅)
      meals: menuNames,
      imagepath: imageBaseUrl + imagePath,
    );
  }
}

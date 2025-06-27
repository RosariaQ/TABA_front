import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 다국어 지원 (특히 DatePicker 한국어)
import 'package:healthymeal/dashboardPage/dashboard.dart'; // 대시보드 페이지
import 'package:healthymeal/loginPage/login.dart'; // 로그인 페이지
import 'package:intl/date_symbol_data_local.dart'; // DatePicker 한국어 지원을 위한 초기화
import 'package:shared_preferences/shared_preferences.dart'; // 로컬 저장소 (로그인 상태 확인)

// RouteObserver: 화면 전환 감지를 위해 사용 (예: 특정 화면으로 돌아왔을 때 데이터 새로고침)
// 이 Observer는 MaterialApp의 navigatorObservers에 등록되어야 합니다.
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  // Flutter 엔진과 위젯 바인딩이 초기화되었는지 확인
  // main 함수가 async로 선언되었고, runApp 전에 await 키워드를 사용하려면 필수입니다.
  WidgetsFlutterBinding.ensureInitialized();

  // DatePicker 등에서 한국어 로케일을 올바르게 사용하기 위해 초기화
  await initializeDateFormatting('ko_KR', null);

  // SharedPreferences를 사용하여 저장된 사용자 ID 확인 (로그인 상태 유지)
  final prefs = await SharedPreferences.getInstance();
  final String? userId = prefs.getString('userId');

  // 앱 실행: 로그인 상태에 따라 초기 라우트 결정
  runApp(MyApp(initialRoute: userId == null ? '/' : '/dashboard'));
}

class MyApp extends StatelessWidget {
  final String initialRoute; // 앱 시작 시 보여줄 초기 화면 경로

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Healthy Meal', // 앱의 제목 (예: 앱 스위처에 표시됨)
      theme: ThemeData(
        fontFamily: 'korfont1', // TODO: 'korfont1' 폰트가 pubspec.yaml에 정의되어 있고 에셋에 포함되어 있는지 확인 필요
        useMaterial3: true, // Material 3 디자인 시스템 사용 (권장)
        // 앱 전체 테마 색상, 텍스트 스타일 등 추가 설정 가능
        // 예:
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        // appBarTheme: const AppBarTheme(
        //   backgroundColor: Colors.white,
        //   foregroundColor: Colors.black87,
        //   elevation: 1,
        // ),
      ),
      initialRoute: initialRoute, // 로그인 상태에 따라 결정된 초기 화면 경로
      // 앱 내 주요 화면들에 대한 라우트 정의
      // 여기서 정의된 라우트 이름으로 Navigator.pushNamed(context, '/routeName') 등을 사용하여 페이지 이동 가능
      routes: {
        '/': (context) => const LoginPage(), // 루트 경로는 로그인 페이지
        '/dashboard': (context) => const Dashboard(), // '/dashboard' 경로는 대시보드 페이지
        // TODO: 다른 주요 페이지들도 여기에 라우트로 정의하는 것을 고려 (예: '/profile', '/settings')
      },
      debugShowCheckedModeBanner: false, // 개발 중 표시되는 디버그 배너 숨김
      navigatorObservers: [routeObserver], // 화면 전환 감지를 위한 RouteObserver 등록
      // 다국어 지원 설정 (DatePicker 한국어 표시 등)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate, // Material 위젯들의 지역화된 문자열 및 레이아웃 제공
        GlobalWidgetsLocalizations.delegate,  // 일반 위젯들의 지역화된 문자열 및 레이아웃 제공
        GlobalCupertinoLocalizations.delegate, // Cupertino (iOS 스타일) 위젯들의 지역화
      ],
      // 지원하는 로케일 목록
      supportedLocales: const [
        Locale('ko', 'KR'), // 한국어
        Locale('en', 'US'), // 영어 (기본값 또는 대체 언어로 포함하는 것이 좋음)
      ],
      // 현재 앱의 로케일 (별도 설정 없으면 시스템 로케일 따름, DatePicker 등에서 한국어 우선 적용)
      locale: const Locale('ko', 'KR'),
    );
  }
}

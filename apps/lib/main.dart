// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_diet_app/providers/user_provider.dart';
import 'package:flutter_diet_app/screens/main_screen.dart';

import 'package:flutter_diet_app/api/api_client.dart';
import 'package:flutter_diet_app/auth_repo.dart';
import 'package:flutter_diet_app/pages/login_page.dart';
import 'package:flutter_diet_app/pages/signup_page.dart';
import 'package:flutter_diet_app/notifications/notification_service.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  final api = ApiClient.devAndroid();     // Android 에뮬레이터
  // final api = ApiClient.devIOS(userId: 1);      // iOS 시뮬레이터/맥
  runApp(MyApp(api: api));
}

class MyApp extends StatelessWidget {
  final ApiClient api;
  const MyApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 앱 전역에서 ApiClient/AuthRepo 접근 가능
        Provider<ApiClient>.value(value: api),
        Provider<AuthRepo>(create: (_) => AuthRepo(api)),

        // 기존 사용자 프로바이더 유지 (필요시 ApiClient 주입하도록 변경 가능)
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // TODO: WorkoutProvider, BadgeProvider 등 추가 시 여기에 등록
      ],
      child: MaterialApp(
        title: 'Diet & Workout App',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: Colors.grey[50],
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
          ),
          // 기존 주석 유지
          cardTheme: CardThemeData(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // 초기 라우팅: 토큰 있으면 MainScreen, 없으면 LoginPage
        home: const AuthGate(),

        // 라우트에서 ApiClient가 필요하므로 빌더 클로저에서 Provider로 꺼냄
        routes: {
          '/login': (ctx) => LoginPage(api: ctx.read<ApiClient>()),
          '/signup': (ctx) => SignupPage(api: ctx.read<ApiClient>()),
          '/home': (ctx) => MainScreen(api: ctx.read<ApiClient>()),
        },
      ),
    );
  }
}

/// 토큰(or devUserId) 존재 여부로 초기 화면 분기
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiClient>();
    return FutureBuilder<String?>(
      future: api.auth.getToken(),
      builder: (ctx, snap) {
        // 로딩 중
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasToken = (snap.data != null && snap.data!.isNotEmpty);
        // 개발 편의를 위해 devUserId가 설정된 경우 로그인 없이 바로 진입 가능
        final hasDevUser = api.devUserId != null;

        if (hasToken || hasDevUser) {
          return MainScreen(api: api);
        } else {
          return LoginPage(api: api);
        }
      },
    );
  }
}
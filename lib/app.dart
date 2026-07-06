import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';
import 'package:loop_app/features/auth/login_screen.dart';
import 'package:loop_app/features/home/home_screen.dart';
import 'package:loop_app/features/home/premium_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoopApp extends StatelessWidget {
  const LoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LOOP',
      debugShowCheckedModeBanner: false,
      // 마우스로도 터치처럼 스크롤(드래그) 할 수 있게 설정
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, // 기본 밝기를 어둡게 설정
        // 기본 폰트를 구글 폰트(Noto Sans)로 설정 (나중에 Pretendard로 교체 가능)
        textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.cyan, // 시안 시드 -> 시스템 액센트(커서/포커스) 일치
          brightness: Brightness.dark,
          primary: AppColors.cyan,
          surface: const Color(0xFF17171C), // 카드나 바텀시트 배경색 (살짝 밝은 검정)
        ),
        scaffoldBackgroundColor: AppColors.page, // 폰 프레임 안 배경
      ),
      // 모든 라우트를 폰 프레임 안에서 렌더/전환 (웹 미리보기 폰 재현).
      builder: (context, child) => PhoneFrame(child: child ?? const SizedBox.shrink()),
      // [Preview] 새 프리미엄 홈 디자인을 바로 보여주기 위해 임시로 랜딩.
      // 인증 흐름으로 되돌리려면 아래 home 한 줄을 지우고 _authGate() 주석을 풀면 됩니다.
      home: const PremiumHomeScreen(),
      // home: _authGate(),
    );
  }

  // AuthGate: 로그인 상태에 따라 화면을 분기합니다.
  // ignore: unused_element
  Widget _authGate() {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // 로딩 중이거나 데이터가 준비 안 됐을 때 (보통 아주 짧음)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 세션이 있으면(로그인 상태) 홈으로, 없으면 로그인 화면으로
        final session = snapshot.data?.session;
        return session != null ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loop_app/features/auth/identity_verification_screen.dart';
import 'package:loop_app/features/auth/sign_in_screen.dart';
import 'package:loop_app/features/home/loop_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 10초에 한 바퀴 회전 (아주 천천히, 우아하게)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 배경색은 app.dart 테마에서 설정한 색상(회색조)을 따름
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // 로고 및 앱 이름 영역
              Center(
                child: Column(
                  children: [
                    // Loop 브랜드 로고
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return LoopLogo(size: 80, animationValue: _controller.value);
                      },
                    ),
                    const Gap(24),
                    Text(
                      'LOOP',
                      style: GoogleFonts.montserrat(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white, // 다크 테마용 흰색
                      ),
                    ),
                    const Gap(8),
                    Text(
                      '금융의 모든 것을 잇다',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400], // 어두운 배경에서 잘 보이도록 밝은 회색으로 변경
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // 로그인 버튼 영역
              _LoginButton(
                text: '카카오로 시작하기',
                textColor: const Color(0xFF191F28),
                backgroundColor: const Color(0xFFFEE500), // 카카오 옐로우
                icon: Icons.chat_bubble, // 카카오 아이콘 대신 말풍선 아이콘
                onPressed: () {
                  // TODO: 카카오 로그인 로직 연결
                },
              ),
              const Gap(12),
              _LoginButton(
                text: '이메일로 시작하기',
                textColor: Colors.white,
                backgroundColor: const Color(0xFF3182F6), // 브랜드 블루
                icon: Icons.email_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const IdentityVerificationScreen(),
                    ),
                  );
                },
              ),
              const Gap(24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '이미 회원가입을 하셨나요? ',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SignInScreen()),
                      );
                    },
                    child: const Text(
                      '로그인',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(48), // 하단 여백
            ],
          ),
        ),
      ),
    );
  }
}

// 중복되는 버튼 스타일을 위젯으로 분리 (재사용성 UP)
class _LoginButton extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onPressed;

  const _LoginButton({
    required this.text,
    required this.textColor,
    required this.backgroundColor,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0, // 그림자 제거 (플랫 디자인)
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const Gap(8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
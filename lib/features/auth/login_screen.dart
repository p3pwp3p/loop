import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';
import 'package:loop_app/features/auth/identity_verification_screen.dart';
import 'package:loop_app/features/auth/sign_in_screen.dart';
import 'package:loop_app/features/home/loop_logo.dart';

/// 로그인 진입 (새 테마). 궤도 로고 + 시안 액센트.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: Stack(
        children: [
          const GlowBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 3),
                  Center(
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) => LoopLogo(size: 84, animationValue: _controller.value),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'LOOP',
                          style: GoogleFonts.montserrat(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '자산과 혜택의 무한 순환',
                          style: TextStyle(fontSize: 15, color: AppColors.gray400, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 4),
                  _authButton(
                    text: '카카오로 시작하기',
                    bg: const Color(0xFFFEE500),
                    fg: const Color(0xFF191F28),
                    icon: PhosphorIcons.chatCircle(PhosphorIconsStyle.fill),
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _authButton(
                    text: '이메일로 시작하기',
                    bg: AppColors.cyan,
                    fg: AppColors.onCyan,
                    icon: PhosphorIcons.envelopeSimple(),
                    glow: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const IdentityVerificationScreen()),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('이미 회원이신가요? ',
                          style: TextStyle(color: AppColors.gray400, fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignInScreen()),
                        ),
                        child: const Text('로그인',
                            style: TextStyle(
                                color: AppColors.cyan, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _authButton({
    required String text,
    required Color bg,
    required Color fg,
    required IconData icon,
    required VoidCallback onTap,
    bool glow = false,
  }) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: glow ? [BoxShadow(color: bg.withOpacity(0.3), blurRadius: 30, spreadRadius: -8)] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }
}

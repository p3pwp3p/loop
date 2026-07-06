import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:loop_app/core/theme/app_colors.dart';

/// 화면 뒤에 깔리는 시안 글로우 (모든 탭 공통 배경).
class GlowBackground extends StatelessWidget {
  const GlowBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -40,
              right: -40,
              height: 430,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x1A083344), Color(0x0D083344), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: 50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.cyan.withOpacity(0.10), AppColors.cyan.withOpacity(0.0)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 글래스 카드 (반투명 + 블러 + 얇은 흰 테두리).
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double opacityFill;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.radius = 24,
    this.opacityFill = 0.03,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacityFill),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.glassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 탭 상단 타이틀 바 (LOOP 톤의 큰 제목 + 우측 액션 슬롯).
class TabTitleBar extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const TabTitleBar({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 56, 28, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 작은 시안 알약 버튼 (혜택/금액 강조용).
class CyanPill extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const CyanPill({super.key, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cyan.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.cyan.withOpacity(0.25), width: 1),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.cyan300,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:loop_app/core/theme/app_colors.dart';

/// 앱 전체를 감싸는 폰 프레임 (웹 미리보기에서 400×867 폰을 그대로 재현).
///
/// 모든 라우트가 이 프레임 안에서 렌더/전환되도록 [MaterialApp.builder]에서 사용.
/// 홈 인디케이터 바도 여기(앱 레벨 크롬)에 둔다.
class PhoneFrame extends StatelessWidget {
  final Widget child;
  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.black,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            width: 400,
            height: 867,
            decoration: BoxDecoration(
              color: AppColors.page,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withOpacity(0.10), width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Stack(
                children: [
                  Positioned.fill(child: child),
                  // 홈 인디케이터 바
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 400 / 3,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

/// 탭 시 살짝 눌리는 공용 래퍼 (오버슈트 없는 매끈한 프레스).
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleTo;
  const Pressable({super.key, required this.child, this.onTap, this.scaleTo = 0.97});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _scale = widget.scaleTo),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// 글래스 원형 아이콘 버튼 (뒤로/닫기 등).
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const GlassIconButton({super.key, required this.icon, required this.onTap, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, size: size * 0.5, color: AppColors.gray300),
      ),
    );
  }
}

/// 상단 바 (뒤로/닫기 버튼 + 타이틀).
class LoopTopBar extends StatelessWidget {
  final String title;
  final IconData leadingIcon;
  final VoidCallback? onLeading;
  final List<Widget> actions;

  const LoopTopBar({
    super.key,
    this.title = '',
    this.leadingIcon = Icons.arrow_back, // 실제로는 아래에서 phosphor로 대체
    this.onLeading,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
      child: Row(
        children: [
          GlassIconButton(
            icon: leadingIcon,
            onTap: onLeading ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// 하단 기본 버튼 (풀 너비). filledCyan=true면 시안 그라데이션, false면 글래스 화이트.
class LoopPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool loading;
  final bool filledCyan;

  const LoopPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.enabled = true,
    this.loading = false,
    this.filledCyan = true,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !loading;
    final Color bg = filledCyan
        ? (active ? AppColors.cyan : Colors.white.withOpacity(0.06))
        : Colors.white.withOpacity(active ? 0.9 : 0.06);
    final Color fg = filledCyan
        ? (active ? AppColors.onCyan : AppColors.gray500)
        : (active ? Colors.black : AppColors.gray500);

    return Pressable(
      onTap: active ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: (filledCyan && active)
              ? [BoxShadow(color: AppColors.cyan.withOpacity(0.25), blurRadius: 30, spreadRadius: -8)]
              : null,
        ),
        child: loading
            ? SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg))
            : Text(label, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: fg)),
      ),
    );
  }
}

/// 숫자 키패드 (송금/결제/비밀번호 공용).
///
/// [biometric]가 true면 좌하단이 지문 버튼([onBiometric]), 아니면 '00' 입력.
class LoopKeypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  final bool biometric;
  final VoidCallback? onBiometric;
  final IconData deleteIcon;
  final IconData bioIcon;

  const LoopKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.biometric = false,
    this.onBiometric,
    this.deleteIcon = Icons.backspace_outlined,
    this.bioIcon = Icons.fingerprint,
  });

  @override
  Widget build(BuildContext context) {
    Widget num(String n) => _KeypadKey(child: Text(n, style: _digitStyle), onTap: () => onDigit(n));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [num('1'), num('2'), num('3')]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [num('4'), num('5'), num('6')]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [num('7'), num('8'), num('9')]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              biometric
                  ? _KeypadKey(child: Icon(bioIcon, size: 26, color: Colors.white), onTap: onBiometric ?? () {})
                  : num('00'),
              num('0'),
              _KeypadKey(child: Icon(deleteIcon, size: 24, color: Colors.white), onTap: onDelete),
            ],
          ),
        ],
      ),
    );
  }

  static const TextStyle _digitStyle =
      TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: Colors.white);
}

class _KeypadKey extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _KeypadKey({required this.child, required this.onTap});

  @override
  State<_KeypadKey> createState() => _KeypadKeyState();
}

class _KeypadKeyState extends State<_KeypadKey> {
  double _scale = 1.0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _scale = 0.88),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Container(width: 84, height: 62, alignment: Alignment.center, child: widget.child),
      ),
    );
  }
}

/// 단계별 입력 위저드의 한 스텝 (본인인증/회원가입 공용).
///
/// 등장 애니메이션 → 현재 스텝만 제목/버튼 표시, 완료된 스텝은 접히고
/// 탭하면 되돌아간다.
class LoopWizardStep extends StatelessWidget {
  final int index;
  final int currentStep;
  final int furthestStep;
  final String title;
  final TextEditingController? controller;
  final String? hint;
  final bool obscure;
  final TextInputType keyboardType;
  final bool autoFocus;
  final String? errorText;
  final Widget? customInput;
  final String buttonLabel;
  final bool loading;
  final VoidCallback onNext;
  final ValueChanged<int> onTapCompleted;

  const LoopWizardStep({
    super.key,
    required this.index,
    required this.currentStep,
    required this.furthestStep,
    required this.title,
    required this.buttonLabel,
    required this.onNext,
    required this.onTapCompleted,
    this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.autoFocus = false,
    this.errorText,
    this.customInput,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (index > furthestStep) return const SizedBox.shrink();
    final isCurrent = index == currentStep;
    final isCompleted = !isCurrent;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 40 * (1 - value)), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1.0,
                child: FadeTransition(
                  opacity: CurvedAnimation(
                      parent: animation, curve: const Interval(0.5, 1.0, curve: Curves.easeInOutCubic)),
                  child: child,
                ),
              ),
              child: isCompleted
                  ? const SizedBox.shrink()
                  : Column(
                      key: ValueKey('title_$index'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Text(title,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white, height: 1.4)),
                        const SizedBox(height: 28),
                      ],
                    ),
            ),
            GestureDetector(
              onTap: isCompleted ? () => onTapCompleted(index) : null,
              child: AbsorbPointer(
                absorbing: isCompleted,
                child: customInput ??
                    TextFormField(
                      controller: controller,
                      obscureText: obscure,
                      keyboardType: keyboardType,
                      autofocus: autoFocus && isCurrent,
                      cursorColor: AppColors.cyan,
                      style: TextStyle(
                        color: isCompleted ? AppColors.gray500 : Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        errorText: errorText,
                        hintStyle: const TextStyle(color: Color(0xFF3A3A42), fontSize: 22, fontWeight: FontWeight.w600),
                        contentPadding: const EdgeInsets.fromLTRB(4, 18, 0, 18),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.cyan, width: 1.5)),
                        errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.down)),
                        focusedErrorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.down)),
                      ),
                      onFieldSubmitted: (_) {
                        if (isCurrent) onNext();
                      },
                    ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              alignment: Alignment.topCenter,
              child: isCurrent
                  ? Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: LoopPrimaryButton(label: buttonLabel, loading: loading, onTap: onNext),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
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

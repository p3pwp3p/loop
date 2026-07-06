import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoopLogo extends StatelessWidget {
  final double size;
  final double animationValue; // 0.0 ~ 1.0 사이의 값 (애니메이션 진행도)

  const LoopLogo({super.key, this.size = 50, this.animationValue = 0.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AsymmetricOrbitPainter(animationValue),
      ),
    );
  }
}

// Design 3: 비대칭 궤도 (Asymmetric Orbit)
// 크기가 다른 두 개의 타원이 비대칭으로 배치됨 (가면 느낌 완전 제거)
class _AsymmetricOrbitPainter extends CustomPainter {
  final double animationValue;
  _AsymmetricOrbitPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Paint 객체를 분리하여 생성 (Web CanvasKit 호환성 향상 및 에러 방지)
    final mainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..color = Colors.white;

    final subPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..color = Colors.white.withOpacity(0.7);

    // 큰 궤도 (가로)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // 바깥 고리는 1배속으로 회전
    canvas.rotate(animationValue * 2 * math.pi);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: size.width * 0.9, height: size.height * 0.4),
      mainPaint,
    );
    canvas.restore();

    // 작은 궤도 (세로, 약간 기울어짐)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // 안쪽 고리는 2배속으로 회전 (서로 엇갈리며 이끄는 느낌)
    // 기본 각도(60도) + 회전 각도
    canvas.rotate((math.pi / 3) + (animationValue * 2 * math.pi * 2));
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: size.width * 0.8, height: size.height * 0.3),
      subPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AsymmetricOrbitPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

// [Component] 공통 새로고침 로고 애니메이션
// 홈 화면, 내역 화면 등 모든 곳에서 동일한 UX를 제공하기 위해 분리함
class RefreshLogo extends StatefulWidget {
  final RefreshIndicatorMode mode;
  final double pulledExtent;
  final double triggerDistance;

  const RefreshLogo({
    super.key,
    required this.mode,
    required this.pulledExtent,
    required this.triggerDistance,
  });

  @override
  State<RefreshLogo> createState() => _RefreshLogoState();
}

class _RefreshLogoState extends State<RefreshLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // 2초에 한 바퀴
    );
    if (widget.mode == RefreshIndicatorMode.refresh) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(RefreshLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode == RefreshIndicatorMode.refresh &&
        oldWidget.mode != RefreshIndicatorMode.refresh) {
      // 당겨진 각도에서 자연스럽게 회전 시작
      double startValue = (widget.pulledExtent / widget.triggerDistance) % 1.0;
      _controller.value = startValue;
      _controller.repeat();
    } else if (widget.mode != RefreshIndicatorMode.refresh &&
        oldWidget.mode == RefreshIndicatorMode.refresh) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: widget.mode == RefreshIndicatorMode.refresh
          ? AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return LoopLogo(size: 28, animationValue: _controller.value);
              },
            )
          : Opacity(
              opacity: (widget.pulledExtent / widget.triggerDistance).clamp(0.0, 1.0),
              child: LoopLogo(
                size: 28,
                animationValue: (widget.pulledExtent / widget.triggerDistance),
              ),
            ),
    );
  }
}
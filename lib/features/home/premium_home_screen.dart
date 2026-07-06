import 'dart:math' as math;
import 'dart:ui' show ImageFilter, FontFeature;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/features/home/tabs/benefit_tab.dart';
import 'package:loop_app/features/home/tabs/invest_tab.dart';
import 'package:loop_app/features/home/tabs/menu_tab.dart';
import 'package:loop_app/features/home/tabs/merchant_tab.dart';
import 'package:loop_app/features/payment/my_qr_screen.dart';
import 'package:loop_app/features/payment/qr_payment_screen.dart';
import 'package:loop_app/features/transfer/transfer_search_screen.dart';

/// 프리미엄 홈 화면.
///
/// 제공된 High-end Points App 디자인을 그대로 옮긴 화면.
/// 검정 베이스(#050507) + 단일 시안 액센트 + 잔액을 감싸는 루프 궤도.
/// 웹 미리보기에서 디자인(400×867 폰)을 그대로 보여주기 위해 고정 프레임을
/// [FittedBox]로 감싸 뷰포트에 맞춰 스케일한다. 실제 모바일에서는 프레임을
/// 화면 크기로 키우면 된다.
class PremiumHomeScreen extends StatefulWidget {
  const PremiumHomeScreen({super.key});

  @override
  State<PremiumHomeScreen> createState() => _PremiumHomeScreenState();
}

class _PremiumHomeScreenState extends State<PremiumHomeScreen>
    with TickerProviderStateMixin {
  // '적립' 버튼의 샤인(빛 쓸기) 애니메이션
  late final AnimationController _shine;

  // 궤도 회전 (LOOP = 무한 순환). 시안 호·점이 잔액 주위를 돈다.
  late final AnimationController _orbit;

  // 현재 탭 (0:홈 1:가맹점 2:투자 3:혜택 4:전체)
  int _selectedIndex = 0;
  int _previousIndex = 0; // 전환 방향 판별용

  // 최근 활동 더미 데이터
  static const List<_Activity> _activities = [
    _Activity(
      icon: _PhIcon.recycle,
      title: '플라스틱 투입 보상',
      time: '오늘 09:41',
      amount: '+450',
      kind: _ActivityKind.reward, // 흰색 강조 + 시안 아이콘 틴트
    ),
    _Activity(
      icon: _PhIcon.coffee,
      title: '스타벅스 강남R점',
      time: '어제 14:20',
      amount: '-4,500',
      kind: _ActivityKind.spend,
    ),
    _Activity(
      icon: _PhIcon.storefront,
      title: 'GS25 편의점',
      time: '2일 전',
      amount: '-1,200',
      kind: _ActivityKind.spend,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    // 3.5초마다 한 번씩 빛이 쓸고 지나가도록 반복
    _shine.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) _shine.forward(from: 0);
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _shine.forward(from: 0);
    });

    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _shine.dispose();
    _orbit.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
  }

  // 인덱스 → 탭 위젯
  Widget _getPage(int index) {
    switch (index) {
      case 1:
        return const MerchantTab();
      case 2:
        return const InvestTab();
      case 3:
        return const BenefitTab();
      case 4:
        return const MenuTab();
      default:
        return _buildHomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
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
                  _buildBackgroundGlow(),
                  // 탭 전환: 방향성 슬라이드 + 페이드 (옛 홈 화면 전환감 그대로)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutQuad,
                    switchOutCurve: Curves.easeInQuad,
                    transitionBuilder: (child, animation) {
                      final isNew = child.key == ValueKey(_selectedIndex);
                      final movingRight = _selectedIndex > _previousIndex;
                      final start = movingRight
                          ? (isNew ? 0.08 : -0.08)
                          : (isNew ? -0.08 : 0.08);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(start, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      fit: StackFit.expand,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: _getPage(_selectedIndex),
                    ),
                  ),
                  _buildBottomNav(),
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

  // ── 홈 탭 (헤더 + 히어로 + 액션 + 최근활동) ──────────────────
  Widget _buildHomeTab() {
    return Column(
      children: [
        _buildHeader(),
        _buildHero(),
        _buildActions(),
        Expanded(child: _buildActivity()),
      ],
    );
  }

  // ── 배경 글로우 (시안 라디얼) ────────────────────────────────
  Widget _buildBackgroundGlow() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // 상단에서 내려오는 옅은 시안 그라데이션
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
                    colors: [
                      Color(0x1A083344), // cyan-900/10
                      Color(0x0D083344),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // 중앙 시안 블롭
            Positioned(
              top: 120,
              left: 50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.cyan.withOpacity(0.10),
                      AppColors.cyan.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 헤더 ─────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 56, 28, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // 시안 아톰 로고 + 글로우
              SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cyan.withOpacity(0.20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyan.withOpacity(0.20),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    RotationTransition(
                      turns: _orbit,
                      child: Icon(PhosphorIcons.atom(), color: AppColors.cyan, size: 30),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'LOOP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.8,
                  fontSize: 14,
                  color: AppColors.gray100,
                ),
              ),
            ],
          ),
          _Pressable(
            onTap: () => _select(4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.glassFill,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.glassBorder, width: 1),
                  ),
                  child: Icon(PhosphorIcons.user(), size: 20, color: AppColors.gray300),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 히어로 (궤도 + 잔액 + 칩) ────────────────────────────────
  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 40),
      child: SizedBox(
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 궤도 (500x500, opacity .8) — 천천히 회전
            Positioned(
              child: Opacity(
                opacity: 0.8,
                child: SizedBox(
                  width: 500,
                  height: 500,
                  child: AnimatedBuilder(
                    animation: _orbit,
                    builder: (context, _) => CustomPaint(
                      painter: _OrbitPainter(rotation: _orbit.value),
                    ),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '내 포인트',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.gray400,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '84,291',
                      style: TextStyle(
                        fontSize: 72,
                        height: 1.0,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -2.5,
                        color: Colors.white,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.10),
                            blurRadius: 24,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '.50',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'LP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        color: AppColors.gray400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // 적립 칩
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.cyan.withOpacity(0.20), width: 1),
                    boxShadow: [
                      BoxShadow(color: AppColors.cyan.withOpacity(0.10), blurRadius: 20),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.trendUp(), size: 14, color: AppColors.cyan),
                      const SizedBox(width: 8),
                      const Text(
                        '+2,450 적립 이번 주',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          color: AppColors.cyan300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 액션 그리드 (보내기 / 받기 / 적립) ───────────────────────
  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: PhosphorIcons.arrowUpRight(),
              label: '보내기',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TransferSearchScreen()),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _ActionButton(
              icon: PhosphorIcons.arrowDownLeft(),
              label: '받기',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyQrScreen()),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _EarnButton(
              icon: PhosphorIcons.recycle(),
              label: '적립',
              shine: _shine,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QrPaymentScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 최근 활동 ────────────────────────────────────────────────
  Widget _buildActivity() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최근 활동',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.65,
                    color: AppColors.gray500,
                  ),
                ),
                Text(
                  '더보기',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cyan.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              itemCount: _activities.length,
              itemBuilder: (context, i) => _ActivityRow(activity: _activities[i]),
            ),
          ),
        ],
      ),
    );
  }

  // ── 하단 글래스 네비게이션 ───────────────────────────────────
  Widget _buildBottomNav() {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.navBar.withOpacity(0.80),
              borderRadius: BorderRadius.circular(32),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.10), width: 1)),
              boxShadow: const [
                BoxShadow(color: Color(0x80000000), blurRadius: 40, offset: Offset(0, 20)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavItem(
                  icon: _selectedIndex == 0
                      ? PhosphorIcons.house(PhosphorIconsStyle.fill)
                      : PhosphorIcons.house(),
                  active: _selectedIndex == 0,
                  onTap: () => _select(0),
                ),
                _NavItem(
                  icon: PhosphorIcons.mapPin(),
                  active: _selectedIndex == 1,
                  onTap: () => _select(1),
                ),
                _NavItem(
                  icon: PhosphorIcons.chartLineUp(),
                  active: _selectedIndex == 2,
                  onTap: () => _select(2),
                ),
                _NavItem(
                  icon: PhosphorIcons.gift(),
                  active: _selectedIndex == 3,
                  onTap: () => _select(3),
                ),
                _NavItem(
                  icon: PhosphorIcons.list(),
                  active: _selectedIndex == 4,
                  onTap: () => _select(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  활동 데이터
// ════════════════════════════════════════════════════════════════

enum _ActivityKind { reward, spend }

/// 더미 데이터를 const로 두기 위해 아이콘을 enum으로 우회 (Phosphor 함수는
/// const가 아니라 const 리스트에 직접 못 넣음).
enum _PhIcon { recycle, coffee, storefront }

class _Activity {
  final _PhIcon icon;
  final String title;
  final String time;
  final String amount;
  final _ActivityKind kind;

  const _Activity({
    required this.icon,
    required this.title,
    required this.time,
    required this.amount,
    required this.kind,
  });

  IconData get iconData {
    switch (icon) {
      case _PhIcon.recycle:
        return PhosphorIcons.recycle();
      case _PhIcon.coffee:
        return PhosphorIcons.coffee();
      case _PhIcon.storefront:
        return PhosphorIcons.storefront();
    }
  }
}

// ════════════════════════════════════════════════════════════════
//  재사용 위젯
// ════════════════════════════════════════════════════════════════

/// 탭하면 살짝 줄어드는(active:scale-95) 공통 래퍼.
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Pressable({required this.child, this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..value = 1.0;
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  void _press(bool down) {
    if (down) {
      _scale.animateTo(0.92, duration: const Duration(milliseconds: 120), curve: Curves.easeInOut);
    } else {
      // 띠요옹~ 튕김 (ElasticOut)
      _scale.animateTo(1.0, duration: const Duration(milliseconds: 700), curve: Curves.elasticOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _press(true),
      onTapUp: (_) => _press(false),
      onTapCancel: () => _press(false),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// 글래스 액션 버튼 (보내기 / 받기)
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder, width: 1),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.gray300),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// '적립' 버튼 (시안 그라데이션 + 빛 쓸기 샤인)
class _EarnButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Animation<double> shine;
  final VoidCallback? onTap;
  const _EarnButton({required this.icon, required this.label, required this.shine, this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.cyan, AppColors.teal],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cyan300.withOpacity(0.40), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: -10,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.10),
                      ),
                      child: Icon(icon, size: 20, color: Colors.black),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              // 빛 쓸기
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: shine,
                    builder: (context, child) {
                      if (shine.value == 0) return const SizedBox.shrink();
                      return LayoutBuilder(
                        builder: (context, c) {
                          final w = c.maxWidth;
                          final x = -w + shine.value * (3 * w);
                          return Transform.translate(
                            offset: Offset(x, 0),
                            child: Transform(
                              transform: Matrix4.skewX(-0.35),
                              child: Container(
                                width: w * 0.5,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0),
                                      Colors.white.withOpacity(0.30),
                                      Colors.white.withOpacity(0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 최근 활동 한 줄
class _ActivityRow extends StatelessWidget {
  final _Activity activity;
  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final isReward = activity.kind == _ActivityKind.reward;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.iconTile,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isReward ? AppColors.cyan.withOpacity(0.20) : Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Icon(
              activity.iconData,
              size: 20,
              color: isReward ? AppColors.cyan : AppColors.gray400,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray100,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.time,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity.amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isReward ? FontWeight.w600 : FontWeight.w300,
              letterSpacing: 0.5,
              color: isReward ? Colors.white : AppColors.gray400,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// 하단 네비 아이템 — 옛 홈의 젤리 프레스(꾹 눌림 → elasticOut 튕김) 이식.
class _NavItem extends StatefulWidget {
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;
  const _NavItem({required this.icon, this.active = false, this.onTap});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late final AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..value = 1.0;
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  void _onHighlight(bool pressed) {
    // 오버슈트(탄성) 없이 매끈하게 — 진동/흔들림 방지.
    if (pressed) {
      _scale.animateTo(0.85, duration: const Duration(milliseconds: 110), curve: Curves.easeOut);
    } else {
      _scale.animateTo(1.0, duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: _onHighlight,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.cyan.withOpacity(0.10),
        highlightColor: Colors.white.withOpacity(0.04),
        child: SizedBox(
          width: 44,
          height: 40,
          // 아이콘은 항상 정중앙(스케일 축이 아이콘 중심에 오도록),
          // 활성 점은 스케일 밖에서 위에 띄움 → 위아래 흔들림 없음.
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.active)
                Positioned(
                  top: 2,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cyan,
                      boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(0.8), blurRadius: 8)],
                    ),
                  ),
                ),
              ScaleTransition(
                scale: _scale,
                child: Icon(
                  widget.icon,
                  size: 24,
                  color: widget.active ? AppColors.cyan : AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  궤도 페인터 (디자인 SVG를 그대로 옮김, 500×500 논리 좌표)
// ════════════════════════════════════════════════════════════════

class _OrbitPainter extends CustomPainter {
  static const Offset _center = Offset(250, 250);

  /// 0.0~1.0 회전 진행도 (전체 궤도를 한 바퀴 돌린다).
  final double rotation;
  _OrbitPainter({this.rotation = 0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 500.0, size.height / 500.0);

    // 전체 궤도를 회전 (무한 순환)
    canvas.translate(_center.dx, _center.dy);
    canvas.rotate(rotation * 2 * math.pi);
    canvas.translate(-_center.dx, -_center.dy);

    // 흐릿한 궤도 두 개
    _faintOval(canvas, rx: 180, ry: 70, deg: 30, opacity: 0.03);
    _faintOval(canvas, rx: 200, ry: 60, deg: -40, opacity: 0.02);

    // 시안 호(arc) + 글로우 점 (그룹 -15도 회전)
    canvas.save();
    canvas.translate(_center.dx, _center.dy);
    canvas.rotate(-15 * math.pi / 180);
    canvas.translate(-_center.dx, -_center.dy);

    // "M 70 250 A 180 80 0 0 1 430 250" → 중심(250,250) rx180 ry80 의 윗 반원
    final arcRect = Rect.fromCenter(center: _center, width: 360, height: 160);
    final arcPath = Path()..addArc(arcRect, math.pi, -math.pi);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [
          Color(0x0022D3EE),
          Color(0xCC22D3EE),
          Color(0xFF22D3EE),
          Color(0x0022D3EE),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ).createShader(arcRect);
    canvas.drawPath(arcPath, arcPaint);

    // 글로우 점 (410, 195)
    const dot = Offset(410, 195);
    canvas.drawCircle(
      dot,
      3.5,
      Paint()
        ..color = AppColors.cyan
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(dot, 3.5, Paint()..color = AppColors.cyan);

    canvas.restore();
    canvas.restore();
  }

  void _faintOval(Canvas canvas,
      {required double rx, required double ry, required double deg, required double opacity}) {
    canvas.save();
    canvas.translate(_center.dx, _center.dy);
    canvas.rotate(deg * math.pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(opacity),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}

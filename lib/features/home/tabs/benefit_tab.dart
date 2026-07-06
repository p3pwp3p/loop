import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';

/// 혜택 탭 — 승부예측 / 랜덤박스 (게임화, 새 테마).
class BenefitTab extends StatelessWidget {
  const BenefitTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TabTitleBar(title: '혜택'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 4, 28, 110),
            physics: const BouncingScrollPhysics(),
            children: [
              // 승부예측
              GlassContainer(
                radius: 20,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('승부예측',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.down.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('LIVE',
                              style: TextStyle(color: AppColors.down, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('내일 GBP/USD가 오를까 내릴까?',
                        style: TextStyle(fontSize: 15, color: Colors.white)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _predictButton('오른다', PhosphorIcons.trendUp(), AppColors.up)),
                        const SizedBox(width: 12),
                        Expanded(child: _predictButton('내린다', PhosphorIcons.trendDown(), AppColors.down)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // 랜덤박스
              GlassContainer(
                radius: 20,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(PhosphorIcons.gift(), color: AppColors.cyan, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('랜덤박스 열기',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 4),
                          Text('1,000P로 최대 10만P 당첨 기회!',
                              style: TextStyle(fontSize: 13, color: AppColors.gray400)),
                        ],
                      ),
                    ),
                    Icon(PhosphorIcons.caretRight(), color: AppColors.gray500, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // 출석/미션 (placeholder, 게임화 확장 자리)
              GlassContainer(
                radius: 20,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(PhosphorIcons.trophy(), color: AppColors.gray300, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('오늘의 수익왕',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 4),
                          Text('랭킹 1위에게 대량 포인트 지급',
                              style: TextStyle(fontSize: 13, color: AppColors.gray400)),
                        ],
                      ),
                    ),
                    Icon(PhosphorIcons.caretRight(), color: AppColors.gray500, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _predictButton(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

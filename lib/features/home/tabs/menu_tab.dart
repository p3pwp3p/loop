import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';
import 'package:loop_app/features/history/transaction_history_screen.dart';

/// 전체 메뉴 탭 — 내 정보 / 거래내역 / 설정 / 고객센터 + 로그아웃 (새 테마).
class MenuTab extends StatelessWidget {
  const MenuTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TabTitleBar(title: '전체'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 4, 28, 110),
            physics: const BouncingScrollPhysics(),
            children: [
              _item(context, PhosphorIcons.user(), '내 정보'),
              _item(context, PhosphorIcons.clockCounterClockwise(), '거래 내역', onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                );
              }),
              _item(context, PhosphorIcons.gearSix(), '설정'),
              _item(context, PhosphorIcons.headset(), '고객센터'),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Supabase.instance.client.auth.signOut(),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text('로그아웃', style: TextStyle(color: AppColors.gray500, fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _item(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: GlassContainer(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.gray300, size: 20),
              ),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontSize: 16, color: Colors.white)),
              const Spacer(),
              Icon(PhosphorIcons.caretRight(), color: AppColors.gray500, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

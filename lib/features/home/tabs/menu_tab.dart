import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';
import 'package:loop_app/features/auth/login_screen.dart';
import 'package:loop_app/features/history/history_screen.dart';
import 'package:loop_app/features/menu/notifications_screen.dart';
import 'package:loop_app/features/menu/profile_screen.dart';
import 'package:loop_app/features/menu/settings_screen.dart';

/// 전체 메뉴 탭 (새 테마).
class MenuTab extends StatelessWidget {
  const MenuTab({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

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
              _item(context, PhosphorIcons.user(), '내 정보', () => _push(context, const ProfileScreen())),
              _item(context, PhosphorIcons.clockCounterClockwise(), '거래 내역',
                  () => _push(context, const HistoryScreen())),
              _item(context, PhosphorIcons.bell(), '알림', () => _push(context, const NotificationsScreen())),
              _item(context, PhosphorIcons.gearSix(), '설정', () => _push(context, const SettingsScreen())),
              _item(context, PhosphorIcons.headset(), '고객센터',
                  () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('고객센터 (준비 중)')),
                      )),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                  }
                },
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

  Widget _item(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: onTap,
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

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';
import 'package:loop_app/features/auth/login_screen.dart';

/// 설정 (새 테마).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _push = true;
  bool _biometric = true;
  bool _marketing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: Stack(
        children: [
          const GlowBackground(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LoopTopBar(title: '설정', leadingIcon: PhosphorIcons.caretLeft()),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _section('알림'),
                    _toggle('푸시 알림', _push, (v) => setState(() => _push = v)),
                    _toggle('마케팅 정보 수신', _marketing, (v) => setState(() => _marketing = v)),
                    const SizedBox(height: 24),
                    _section('보안'),
                    _toggle('생체 인증 (Face ID / 지문)', _biometric, (v) => setState(() => _biometric = v)),
                    _link('비밀번호 변경', PhosphorIcons.lockKey()),
                    const SizedBox(height: 24),
                    _section('정보'),
                    _link('이용약관', PhosphorIcons.fileText()),
                    _link('개인정보 처리방침', PhosphorIcons.shieldCheck()),
                    _linkValue('버전', '1.0.0'),
                    const SizedBox(height: 28),
                    LoopPrimaryButton(
                      label: '로그아웃',
                      filledCyan: false,
                      onTap: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(title,
            style: const TextStyle(color: AppColors.gray500, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      );

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.onCyan,
            activeTrackColor: AppColors.cyan,
            inactiveThumbColor: AppColors.gray400,
            inactiveTrackColor: Colors.white.withOpacity(0.08),
          ),
        ],
      ),
    );
  }

  Widget _link(String label, IconData icon) {
    return Pressable(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label (준비 중)')),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.gray300),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
            const Spacer(),
            Icon(PhosphorIcons.caretRight(), size: 18, color: AppColors.gray500),
          ],
        ),
      ),
    );
  }

  Widget _linkValue(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.gray500, fontSize: 14)),
        ],
      ),
    );
  }
}

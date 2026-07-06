import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';

/// 내 정보 (새 테마). 프로필 + 포인트 요약.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'LOOP 회원';
  String _username = 'loop_user';
  int _balance = 84291;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('full_name, username, balance')
          .eq('id', user.id)
          .single();
      if (mounted) {
        setState(() {
          _name = data['full_name'] ?? data['username'] ?? 'LOOP 회원';
          _username = data['username'] ?? 'loop_user';
          _balance = data['balance'] ?? 0;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

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
              LoopTopBar(title: '내 정보', leadingIcon: PhosphorIcons.caretLeft()),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // 프로필 헤더
                          Column(
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.cyan.withOpacity(0.12),
                                  border: Border.all(color: AppColors.cyan.withOpacity(0.25), width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: Text(_name[0],
                                    style: const TextStyle(
                                        color: AppColors.cyan, fontSize: 36, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(height: 16),
                              Text(_name,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('@$_username', style: const TextStyle(color: AppColors.gray500, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 28),
                          // 포인트 요약 카드
                          GlassContainer(
                            radius: 24,
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('보유 포인트',
                                    style: TextStyle(color: AppColors.gray400, fontSize: 13)),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      NumberFormat('#,###').format(_balance),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -1,
                                        fontFeatures: [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('LP',
                                        style: TextStyle(
                                            color: AppColors.gray400, fontSize: 15, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // 통계 3분할
                          Row(
                            children: [
                              _stat('이번 주 적립', '+2,450'),
                              const SizedBox(width: 12),
                              _stat('가맹점 방문', '12곳'),
                              const SizedBox(width: 12),
                              _stat('등급', 'GOLD'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          LoopPrimaryButton(
                            label: '프로필 편집',
                            filledCyan: false,
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('프로필 편집 (준비 중)')),
                            ),
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

  Widget _stat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.gray500, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

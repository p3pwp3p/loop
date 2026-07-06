import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';

/// 알림 (새 테마).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static final List<Map<String, dynamic>> _items = [
    {
      'icon': PhosphorIcons.recycle(),
      'title': '플라스틱 투입 보상 지급',
      'body': '450 LP가 적립되었어요.',
      'time': '방금 전',
      'unread': true,
      'accent': true,
    },
    {
      'icon': PhosphorIcons.arrowDownLeft(),
      'title': '송금을 받았어요',
      'body': '김루프님이 30,000 LP를 보냈어요.',
      'time': '3일 전',
      'unread': true,
      'accent': false,
    },
    {
      'icon': PhosphorIcons.gift(),
      'title': '랜덤박스 기회 도착',
      'body': '오늘의 랜덤박스를 열어보세요.',
      'time': '5일 전',
      'unread': false,
      'accent': false,
    },
    {
      'icon': PhosphorIcons.megaphone(),
      'title': '새로운 가맹점 오픈',
      'body': '내 주변에 3개의 가맹점이 추가됐어요.',
      'time': '1주 전',
      'unread': false,
      'accent': false,
    },
  ];

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
              LoopTopBar(title: '알림', leadingIcon: PhosphorIcons.caretLeft()),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _row(_items[i]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(Map<String, dynamic> n) {
    final accent = n['accent'] as bool;
    final unread = n['unread'] as bool;
    return GlassContainer(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent ? AppColors.cyan.withOpacity(0.12) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(n['icon'] as IconData, size: 20, color: accent ? AppColors.cyan : AppColors.gray300),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(n['title'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                    if (unread) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: AppColors.cyan, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(n['body'] as String,
                    style: const TextStyle(color: AppColors.gray400, fontSize: 13, height: 1.3)),
                const SizedBox(height: 6),
                Text(n['time'] as String,
                    style: const TextStyle(color: AppColors.gray500, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

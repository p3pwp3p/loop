import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';

/// 가맹점 탭 — 내 주변 가맹점 검색/리스트 (새 테마).
class MerchantTab extends StatelessWidget {
  const MerchantTab({super.key});

  static const List<Map<String, String>> _merchants = [
    {'name': '스타벅스 강남R점', 'category': '카페', 'distance': '150m', 'benefit': '5% 적립'},
    {'name': 'GS25 역삼센터점', 'category': '편의점', 'distance': '320m', 'benefit': '3% 적립'},
    {'name': '레브로 트레이딩 센터', 'category': '오피스', 'distance': '1.2km', 'benefit': '월세 결제'},
    {'name': '파리바게뜨 강남대로점', 'category': '베이커리', 'distance': '1.5km', 'benefit': '5% 적립'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TabTitleBar(title: '가맹점'),
        // 검색창 (글래스)
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
          child: GlassContainer(
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(PhosphorIcons.magnifyingGlass(), color: AppColors.gray500, size: 20),
                const SizedBox(width: 12),
                const Text('가맹점, 지역 검색', style: TextStyle(color: AppColors.gray500, fontSize: 15)),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(28, 4, 28, 110),
            physics: const BouncingScrollPhysics(),
            itemCount: _merchants.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final m = _merchants[i];
              return GlassContainer(
                radius: 20,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.iconTile,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Icon(PhosphorIcons.storefront(), color: AppColors.gray400, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['name']!,
                              style: const TextStyle(color: AppColors.gray100, fontWeight: FontWeight.w500, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('${m['category']} · ${m['distance']}',
                              style: const TextStyle(color: AppColors.gray500, fontSize: 12)),
                        ],
                      ),
                    ),
                    CyanPill(text: m['benefit']!),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

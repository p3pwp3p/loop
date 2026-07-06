import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';

/// 투자 탭 — 라이브 캔들차트 + VIP 시그널 + 프리미엄 뉴스 (새 테마).
class InvestTab extends StatefulWidget {
  const InvestTab({super.key});

  @override
  State<InvestTab> createState() => _InvestTabState();
}

class _InvestTabState extends State<InvestTab> {
  String _selectedAsset = 'BTC/USD';
  late List<_Candle> _candles;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _generate();
    _startLive();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generate() {
    final List<_Candle> data = [];
    double price = 65000.0;
    final now = DateTime.now();
    final random = math.Random();
    for (int i = 0; i < 60; i++) {
      final time = now.subtract(Duration(minutes: 60 - i));
      final movement = (random.nextDouble() - 0.5) * 200;
      final open = price;
      final close = price + movement;
      final high = math.max(open, close) + random.nextDouble() * 50;
      final low = math.min(open, close) - random.nextDouble() * 50;
      data.add(_Candle(time: time, open: open, high: high, low: low, close: close));
      price = close;
    }
    _candles = data;
  }

  void _startLive() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) return;
      setState(() {
        final last = _candles.last;
        final random = math.Random();
        double volatility = 50.0;
        if (_selectedAsset.contains('EUR')) {
          volatility = 0.0005;
        } else if (_selectedAsset.contains('AAPL')) {
          volatility = 0.5;
        } else if (_selectedAsset.contains('XAU')) {
          volatility = 2.0;
        }
        final move = (random.nextDouble() - 0.5) * volatility;
        final newClose = last.close + move;
        _candles.last = _Candle(
          time: last.time,
          open: last.open,
          high: math.max(last.high, newClose),
          low: math.min(last.low, newClose),
          close: newClose,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final last = _candles.last;
    final isUp = last.close >= last.open;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TabTitleBar(title: '투자'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 자산 선택 칩
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['BTC/USD', 'XAU/USD', 'AAPL', 'EUR/USD'].map((asset) {
                          final selected = _selectedAsset == asset;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedAsset = asset;
                              _generate();
                            }),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.cyan : Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected ? AppColors.cyan : Colors.white.withOpacity(0.06),
                                ),
                              ),
                              child: Text(
                                asset,
                                style: TextStyle(
                                  color: selected ? AppColors.onCyan : AppColors.gray400,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 차트 카드
                    GlassContainer(
                      radius: 24,
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        height: 280,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_selectedAsset,
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  NumberFormat('#,##0.00').format(last.close),
                                  style: TextStyle(
                                    color: isUp ? AppColors.up : AppColors.down,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFeatures: const [],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: _CandlePainter(_candles),
                                  size: Size.infinite,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // VIP 시그널 (시안 그라데이션)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.cyan, AppColors.teal],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: AppColors.cyan.withOpacity(0.20), blurRadius: 30, spreadRadius: -8),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.lockKey(), color: AppColors.onCyan, size: 30),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('VIP 트레이딩 시그널',
                                    style: TextStyle(
                                        fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.onCyan)),
                                SizedBox(height: 4),
                                Text('상위 1% 트레이더의 포지션 공개',
                                    style: TextStyle(fontSize: 13, color: Color(0xCC062E33))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('프리미엄 뉴스',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 110),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final titles = ['GBP/USD 급등 가능성 분석', '이번 주 주요 경제 지표 정리', '비트코인 반감기 이후 전망'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titles[index],
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(PhosphorIcons.lockSimple(), size: 13, color: AppColors.cyan),
                          const SizedBox(width: 4),
                          const Text('500P로 전체 보기',
                              style: TextStyle(
                                  color: AppColors.cyan, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                );
              },
              childCount: 3,
            ),
          ),
        ),
      ],
    );
  }
}

class _Candle {
  final DateTime time;
  final double open, high, low, close;
  _Candle({required this.time, required this.open, required this.high, required this.low, required this.close});
}

class _CandlePainter extends CustomPainter {
  final List<_Candle> data;
  _CandlePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final candleWidth = size.width / data.length;
    final maxPrice = data.map((e) => e.high).reduce(math.max);
    final minPrice = data.map((e) => e.low).reduce(math.min);
    final range = (maxPrice - minPrice).clamp(0.0001, double.infinity);
    final paint = Paint()..style = PaintingStyle.fill;

    double getY(double price) => size.height - ((price - minPrice) / range * size.height);

    for (int i = 0; i < data.length; i++) {
      final c = data[i];
      final up = c.close >= c.open;
      paint.color = up ? AppColors.up : AppColors.down;
      final x = i * candleWidth + candleWidth * 0.1;
      final w = candleWidth * 0.8;
      canvas.drawLine(Offset(x + w / 2, getY(c.high)), Offset(x + w / 2, getY(c.low)), paint..strokeWidth = 1);
      final top = getY(math.max(c.open, c.close));
      final bottom = getY(math.min(c.open, c.close));
      canvas.drawRect(Rect.fromLTWH(x, top, w, math.max(1.0, bottom - top)), paint);
    }

    final lastY = getY(data.last.close);
    canvas.drawLine(
      Offset(0, lastY),
      Offset(size.width, lastY),
      Paint()
        ..color = AppColors.cyan.withOpacity(0.6)
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) => true;
}

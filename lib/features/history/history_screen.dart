import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';

/// 거래/이체 내역 (새 테마).
///
/// 로그인 상태면 Supabase `transactions`에서 불러오고, 아니면(미리보기)
/// 더미 데이터로 동작한다. 상단 필터: 전체 / 적립 / 결제 / 송금.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum _Filter { all, reward, spend, transfer }

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // 미리보기(비로그인): 더미 데이터
      setState(() {
        _all = _dummy();
        _loading = false;
      });
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('transactions')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);
      setState(() {
        _all = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      debugPrint('history load failed: $e');
      setState(() {
        _all = _dummy();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _dummy() {
    final now = DateTime.now();
    List<Map<String, dynamic>> mk(int id, int amount, String desc, Duration ago) => [
          {
            'id': id,
            'amount': amount,
            'description': desc,
            'created_at': now.subtract(ago).toIso8601String(),
          }
        ];
    return [
      ...mk(1024, 450, '플라스틱 투입 보상', const Duration(minutes: 5)),
      ...mk(1023, -4500, '스타벅스 강남R점', const Duration(hours: 21)),
      ...mk(1022, -1200, 'GS25 편의점', const Duration(days: 2)),
      ...mk(1021, 30000, '송금 받음: 김루프', const Duration(days: 3)),
      ...mk(1020, -15000, '송금 보냄: 이순환', const Duration(days: 4)),
      ...mk(1019, 1000, '출석 보상', const Duration(days: 6)),
      ...mk(1018, -2500, '파리바게뜨 강남대로점', const Duration(days: 8)),
      ...mk(1017, 50000, '신규 회원 유치 보상', const Duration(days: 10)),
    ];
  }

  String _kindOf(String desc, int amount) {
    if (desc.contains('송금')) return 'transfer';
    if (amount > 0) return 'reward';
    return 'spend';
  }

  IconData _iconOf(String kind, bool positive) {
    switch (kind) {
      case 'reward':
        return PhosphorIcons.recycle();
      case 'transfer':
        return positive ? PhosphorIcons.arrowDownLeft() : PhosphorIcons.arrowUpRight();
      default:
        return PhosphorIcons.storefront();
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == _Filter.all) return _all;
    return _all.where((tx) {
      final kind = _kindOf(tx['description'] ?? '', tx['amount'] as int);
      switch (_filter) {
        case _Filter.reward:
          return kind == 'reward';
        case _Filter.spend:
          return kind == 'spend';
        case _Filter.transfer:
          return kind == 'transfer';
        case _Filter.all:
          return true;
      }
    }).toList();
  }

  String _title(String desc) {
    if (desc.startsWith('송금 보냄: ')) return desc.replaceFirst('송금 보냄: ', '');
    if (desc.startsWith('송금 받음: ')) return desc.replaceFirst('송금 받음: ', '');
    return desc;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: AppColors.page,
      body: Stack(
        children: [
          const GlowBackground(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 헤더 (뒤로 + 타이틀)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 28, 12),
                child: Row(
                  children: [
                    _GlassIconButton(
                      icon: PhosphorIcons.caretLeft(),
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 8),
                    const Text('거래 내역',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
              // 필터 칩
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  children: [
                    _chip('전체', _Filter.all),
                    _chip('적립', _Filter.reward),
                    _chip('결제', _Filter.spend),
                    _chip('송금', _Filter.transfer),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
                    : list.isEmpty
                        ? const Center(
                            child: Text('내역이 없습니다.', style: TextStyle(color: AppColors.gray500)))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 4),
                            itemBuilder: (context, i) => _row(list[i]),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _Filter value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.cyan : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.cyan : Colors.white.withOpacity(0.06)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.onCyan : AppColors.gray400,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _row(Map<String, dynamic> tx) {
    final amount = tx['amount'] as int;
    final desc = tx['description'] as String? ?? '거래';
    final createdAt = DateTime.parse(tx['created_at']).toLocal();
    final positive = amount > 0;
    final kind = _kindOf(desc, amount);
    final isReward = kind == 'reward';
    final amt = '${positive ? '+' : '-'}${NumberFormat('#,###').format(amount.abs())}';
    final dateStr = _relative(createdAt);

    return _Pressable(
      onTap: () => _showDetail(tx),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
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
                ),
              ),
              child: Icon(
                _iconOf(kind, positive),
                size: 20,
                color: isReward ? AppColors.cyan : AppColors.gray400,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title(desc),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.gray100)),
                  const SizedBox(height: 4),
                  Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amt,
              style: TextStyle(
                fontSize: 16,
                fontWeight: positive ? FontWeight.w600 : FontWeight.w300,
                color: positive ? Colors.white : AppColors.gray400,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('MM.dd HH:mm').format(dt);
  }

  void _showDetail(Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HistoryDetailSheet(transaction: tx),
    );
  }
}

/// 거래 상세 바텀시트 (새 테마).
class HistoryDetailSheet extends StatelessWidget {
  final Map<String, dynamic> transaction;
  const HistoryDetailSheet({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final amount = transaction['amount'] as int;
    final desc = transaction['description'] as String? ?? '거래';
    final createdAt = DateTime.parse(transaction['created_at']).toLocal();
    final positive = amount > 0;
    final formatted = NumberFormat('#,###').format(amount.abs());

    String title = desc;
    if (desc.startsWith('송금 보냄: ')) title = desc.replaceFirst('송금 보냄: ', '');
    if (desc.startsWith('송금 받음: ')) title = desc.replaceFirst('송금 받음: ', '');

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E12),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Colors.white24, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 14),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: positive ? AppColors.cyan.withOpacity(0.15) : Colors.white.withOpacity(0.06),
                ),
                child: Icon(
                  positive ? PhosphorIcons.arrowDownLeft() : PhosphorIcons.arrowUpRight(),
                  color: positive ? AppColors.cyan : Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              Text(positive ? '적립/입금 완료' : '사용/출금 완료',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                '${positive ? '+' : '-'}$formatted LP',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  color: positive ? AppColors.cyan : Colors.white,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 32),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 24),
              _detailRow('거래 대상', title),
              const SizedBox(height: 16),
              _detailRow('거래 일시', DateFormat('yyyy.MM.dd HH:mm').format(createdAt)),
              const SizedBox(height: 16),
              _detailRow('거래 유형', positive ? '적립/입금' : '사용/출금'),
              const SizedBox(height: 16),
              _detailRow('거래 번호', '#${transaction['id']}'),
              const SizedBox(height: 32),
              _Pressable(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  alignment: Alignment.center,
                  child: const Text('확인',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.gray500, fontSize: 15)),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

/// 글래스 원형 아이콘 버튼 (뒤로가기 등).
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, size: 20, color: AppColors.gray300),
      ),
    );
  }
}

/// 탭 시 살짝 눌리는 래퍼 (이 화면 전용, 매끈한 프레스).
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Pressable({required this.child, this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

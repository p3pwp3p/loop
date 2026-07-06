import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';
import 'package:loop_app/features/transfer/transfer_password_screen.dart';

/// 송금 금액 입력 (새 테마). 잔액 부족 시 흔들림. 비로그인 미리보기는 더미 잔액.
class TransferAmountScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String recipientUsername;

  const TransferAmountScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    required this.recipientUsername,
  });

  @override
  State<TransferAmountScreen> createState() => _TransferAmountScreenState();
}

class _TransferAmountScreenState extends State<TransferAmountScreen> with SingleTickerProviderStateMixin {
  String _amount = '';
  int _balance = 84291; // 미리보기 기본값
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fetchBalance();
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _fetchBalance() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('balance')
          .eq('id', user.id)
          .single();
      if (mounted) setState(() => _balance = data['balance'] ?? 0);
    } catch (_) {}
  }

  void _digit(String n) {
    if (_amount.length >= 10) return;
    HapticFeedback.lightImpact();
    setState(() => _amount = _amount == '0' ? n : _amount + n);
    if ((int.tryParse(_amount) ?? 0) > _balance) {
      HapticFeedback.mediumImpact();
      _shake.forward(from: 0);
    }
  }

  void _delete() {
    if (_amount.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _amount = _amount.substring(0, _amount.length - 1));
  }

  void _next() {
    final amount = int.tryParse(_amount);
    if (amount == null || amount <= 0) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransferPasswordScreen(
          recipientId: widget.recipientId,
          recipientName: widget.recipientName,
          recipientUsername: widget.recipientUsername,
          amount: amount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = int.tryParse(_amount) ?? 0;
    final insufficient = current > _balance;
    final formatted = _amount.isEmpty ? '0' : NumberFormat('#,###').format(current);

    return Scaffold(
      backgroundColor: AppColors.page,
      body: Stack(
        children: [
          const GlowBackground(),
          Column(
            children: [
              LoopTopBar(leadingIcon: PhosphorIcons.caretLeft()),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('얼마를 보낼까요?',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 10),
                    Text('받는 사람  ${widget.recipientName}',
                        style: const TextStyle(fontSize: 15, color: AppColors.gray500)),
                    const SizedBox(height: 40),
                    AnimatedBuilder(
                      animation: _shake,
                      builder: (context, child) {
                        final dx = math.sin(_shake.value * math.pi * 4) * 5;
                        return Transform.translate(offset: Offset(dx, 0), child: child);
                      },
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                formatted,
                                style: TextStyle(
                                  fontSize: 54,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: -1.5,
                                  color: _amount.isEmpty ? AppColors.gray500 : Colors.white,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('LP',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.gray400)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            insufficient
                                ? '잔액이 부족해요 (보유 ${NumberFormat('#,###').format(_balance)} LP)'
                                : '보유 ${NumberFormat('#,###').format(_balance)} LP',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: insufficient ? AppColors.down : AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LoopPrimaryButton(
                  label: '다음',
                  enabled: current > 0 && !insufficient,
                  onTap: _next,
                ),
              ),
              const SizedBox(height: 16),
              LoopKeypad(onDigit: _digit, onDelete: _delete),
              const SizedBox(height: 28),
            ],
          ),
        ],
      ),
    );
  }
}

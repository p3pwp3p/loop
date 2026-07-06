import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';
import 'package:loop_app/features/history/history_screen.dart';

/// 가맹점 결제 (새 테마). 스캔한 소비자에게 charge_point.
/// 비로그인 미리보기에서는 결제를 시뮬레이션한다.
class MerchantPaymentScreen extends StatefulWidget {
  final String consumerId;
  const MerchantPaymentScreen({super.key, required this.consumerId});

  @override
  State<MerchantPaymentScreen> createState() => _MerchantPaymentScreenState();
}

class _MerchantPaymentScreenState extends State<MerchantPaymentScreen> {
  String _amount = '';
  bool _loading = true;
  bool _paying = false;
  String _consumerName = '고객';
  String? _merchantName;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // 미리보기
      setState(() {
        _consumerName = '데모 고객';
        _merchantName = 'LOOP 가맹점';
        _loading = false;
      });
      return;
    }
    try {
      final consumer = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', widget.consumerId)
          .single();
      final me = await Supabase.instance.client
          .from('profiles')
          .select('full_name, username')
          .eq('id', user.id)
          .single();
      if (mounted) {
        setState(() {
          _consumerName = consumer['full_name'] ?? consumer['username'] ?? '고객';
          _merchantName = me['full_name'] ?? me['username'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _consumerName = '고객';
          _loading = false;
        });
      }
    }
  }

  void _digit(String n) {
    if (_paying || _amount.length >= 10) return;
    HapticFeedback.lightImpact();
    setState(() => _amount = _amount == '0' ? n : _amount + n);
  }

  void _delete() {
    if (_paying || _amount.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _amount = _amount.substring(0, _amount.length - 1));
  }

  Future<void> _pay() async {
    final amount = int.tryParse(_amount);
    if (amount == null || amount <= 0) return;
    setState(() => _paying = true);
    final user = Supabase.instance.client.auth.currentUser;
    try {
      if (user == null) {
        await Future.delayed(const Duration(milliseconds: 700));
      } else {
        await Supabase.instance.client.rpc('charge_point', params: {
          'consumer_id': widget.consumerId,
          'amount': amount,
          'description': _merchantName ?? '가맹점 결제',
        });
      }
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => HistoryDetailSheet(transaction: {
          'amount': amount,
          'description': _consumerName,
          'created_at': DateTime.now().toIso8601String(),
          'id': 'NEW',
        }),
      );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on PostgrestException catch (e) {
      if (mounted) _fail(e.message);
    } catch (e) {
      if (mounted) _fail('알 수 없는 오류가 발생했어요.');
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _fail(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('결제 실패: $msg'), backgroundColor: AppColors.down),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = int.tryParse(_amount) ?? 0;
    final formatted = _amount.isEmpty ? '0' : NumberFormat('#,###').format(current);

    return Scaffold(
      backgroundColor: AppColors.page,
      body: Stack(
        children: [
          const GlowBackground(),
          _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
              : Column(
                  children: [
                    LoopTopBar(leadingIcon: PhosphorIcons.caretLeft()),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('얼마를 결제할까요?',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                          const SizedBox(height: 10),
                          Text('대상  $_consumerName',
                              style: const TextStyle(fontSize: 15, color: AppColors.gray500)),
                          const SizedBox(height: 40),
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
                                  style: TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.gray400)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: LoopPrimaryButton(
                        label: '결제하기',
                        enabled: current > 0,
                        loading: _paying,
                        onTap: _pay,
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

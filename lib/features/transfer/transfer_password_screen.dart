import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';

/// 송금 비밀번호 (새 테마). 6자리 입력 → 확인 시트 → transfer_point RPC.
/// 비로그인 미리보기에서는 송금을 시뮬레이션한다.
class TransferPasswordScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String recipientUsername;
  final int amount;

  const TransferPasswordScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    required this.recipientUsername,
    required this.amount,
  });

  @override
  State<TransferPasswordScreen> createState() => _TransferPasswordScreenState();
}

class _TransferPasswordScreenState extends State<TransferPasswordScreen> {
  String _pin = '';
  bool _busy = false;

  void _digit(String n) {
    if (_busy || _pin.length >= 6) return;
    HapticFeedback.lightImpact();
    setState(() => _pin += n);
    if (_pin.length == 6) _verify();
  }

  void _delete() {
    if (_busy || _pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _pin = '';
    });
    _showConfirmSheet();
  }

  void _showConfirmSheet() {
    final nf = NumberFormat('#,###');
    const fee = 500;
    final total = widget.amount + fee;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0E0E12),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Colors.white24, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 28),
                const Center(
                  child: Text('송금 정보를 확인하세요',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cyan.withOpacity(0.12),
                        border: Border.all(color: AppColors.cyan.withOpacity(0.2)),
                      ),
                      alignment: Alignment.center,
                      child: Text(widget.recipientName[0],
                          style: const TextStyle(color: AppColors.cyan, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.recipientName,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('@${widget.recipientUsername}',
                            style: const TextStyle(color: AppColors.gray500, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _row('보낼 금액', '${nf.format(widget.amount)} LP'),
                const SizedBox(height: 12),
                _row('수수료', '${nf.format(fee)} LP'),
                const SizedBox(height: 20),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 20),
                _row('총 출금', '${nf.format(total)} LP', total: true),
                const SizedBox(height: 28),
                LoopPrimaryButton(label: '보내기', onTap: _process),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool total = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.gray400, fontSize: 15)),
        Text(value,
            style: TextStyle(
              color: total ? AppColors.cyan : Colors.white,
              fontSize: total ? 19 : 15,
              fontWeight: total ? FontWeight.bold : FontWeight.w500,
            )),
      ],
    );
  }

  Future<void> _process() async {
    final user = Supabase.instance.client.auth.currentUser;
    Navigator.of(context).pop(); // 시트 닫기
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
    );
    try {
      if (user == null) {
        await Future.delayed(const Duration(milliseconds: 700)); // 미리보기 시뮬레이션
      } else {
        await Supabase.instance.client.rpc('transfer_point', params: {
          'recipient_id': widget.recipientId,
          'amount': widget.amount,
          'description': widget.recipientName,
        });
      }
      if (!mounted) return;
      Navigator.of(context).pop(); // 로딩 닫기
      Navigator.of(context).popUntil((r) => r.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('송금이 완료되었어요'),
          backgroundColor: const Color(0xFF0E0E12),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.down),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('송금 실패: $e'), backgroundColor: AppColors.down),
      );
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
            children: [
              LoopTopBar(leadingIcon: PhosphorIcons.caretLeft()),
              const SizedBox(height: 24),
              const Text('비밀번호를 입력하세요',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 9),
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.cyan : Colors.white.withOpacity(0.10),
                      boxShadow: filled
                          ? [BoxShadow(color: AppColors.cyan.withOpacity(0.5), blurRadius: 8)]
                          : null,
                    ),
                  );
                }),
              ),
              const Spacer(),
              LoopKeypad(
                onDigit: _digit,
                onDelete: _delete,
                biometric: true,
                onBiometric: () {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('생체 인증 (데모)')),
                  );
                },
              ),
              const SizedBox(height: 36),
            ],
          ),
        ],
      ),
    );
  }
}

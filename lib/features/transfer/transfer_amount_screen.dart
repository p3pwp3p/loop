import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loop_app/features/transfer/transfer_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String _amountString = '';
  int _myBalance = 0;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _fetchMyBalance();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400), // 0.4초 동안 흔들림
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyBalance() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final data = await Supabase.instance.client
        .from('profiles')
        .select('balance')
        .eq('id', userId)
        .single();
    if (mounted) setState(() => _myBalance = data['balance'] ?? 0);
  }

  // 키패드 입력 처리
  void _onNumberTap(String number) {
    if (_amountString.length >= 10) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      if (_amountString == '0') {
        _amountString = number;
      } else {
        _amountString += number;
      }
    });

    // [Added] 잔액 부족 시 진동 피드백 (경고 느낌)
    final currentAmount = int.tryParse(_amountString) ?? 0;
    if (currentAmount > _myBalance) {
      HapticFeedback.mediumImpact();
      _shakeController.forward(from: 0); // 시각적 진동(흔들림) 시작
    }
  }

  void _onDeleteTap() {
    if (_amountString.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _amountString = _amountString.substring(0, _amountString.length - 1);
    });
  }

  void _onNext() {
    final amount = int.tryParse(_amountString);
    if (amount == null || amount <= 0) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransferPasswordScreen(
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
    final formattedAmount = _amountString.isEmpty ? '0' : NumberFormat('#,###').format(int.parse(_amountString));
    final currentAmount = int.tryParse(_amountString) ?? 0;
    final isInsufficient = currentAmount > _myBalance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0), // [UI Update] 뒤로가기 버튼 여백 확보
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Spacer(flex: 2), // [UI Update] 상단 여백 축소 (제목을 더 위로)
                  Text(
                    '얼마를\n보낼까요?',
                    style: GoogleFonts.notoSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(
                    '받는 사람: ${widget.recipientName}',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(flex: 3), // [UI Update] 중간 여백 확대 (금액창을 더 아래로)
                  // [UI Update] 금액과 경고 문구를 감싸서 흔들림 효과 적용
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      // Sine 파동을 이용해 좌우로 흔들리는 오프셋 계산 (4px 범위로 축소)
                      final dx = math.sin(_shakeController.value * math.pi * 4) * 4;
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: Column(
                      children: [
                        // 금액 표시 영역
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    formattedAmount,
                                    style: GoogleFonts.manrope(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: _amountString.isEmpty ? Colors.grey[700] : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                'Loopoint',
                                style: GoogleFonts.manrope(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 잔액 부족 경고 문구
                        Container(
                          height: 30,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(top: 12.0),
                          child: isInsufficient
                              ? Text(
                                  '잔액이 부족합니다 (보유: ${NumberFormat('#,###').format(_myBalance)} P)',
                                  style: const TextStyle(color: Color(0xFFFF5252), fontSize: 14, fontWeight: FontWeight.w600),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 4), // [UI Update] 하단 여백 확보
                ],
              ),
            ),
            // 하단 영역 (버튼 + 키패드)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ElevatedButton(
                // 잔액 부족 시 버튼 비활성화
                onPressed: _amountString.isEmpty || currentAmount == 0 || isInsufficient ? null : _onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20), // [UI Update] 버튼 높이 확장
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  minimumSize: const Size.fromHeight(56),
                  disabledBackgroundColor: Colors.grey[800],
                  disabledForegroundColor: Colors.grey[500],
                ),
                child: const Text('보내기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const Gap(24),
            _buildKeypad(),
            const Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildKeyRow(['1', '2', '3']),
          const Gap(16),
          _buildKeyRow(['4', '5', '6']),
          const Gap(16),
          _buildKeyRow(['7', '8', '9']),
          const Gap(16),
          _buildKeyRow(['00', '0', 'del']),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key == 'del') {
          return _buildKey(icon: Icons.backspace_outlined, onTap: _onDeleteTap);
        } else {
          return _buildKey(text: key, onTap: () => _onNumberTap(key));
        }
      }).toList(),
    );
  }

  Widget _buildKey({String? text, IconData? icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: 80,
        height: 60,
        alignment: Alignment.center,
        child: text != null
            ? Text(
                text,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.white),
              )
            : Icon(icon, size: 24, color: Colors.white),
      ),
    );
  }
}
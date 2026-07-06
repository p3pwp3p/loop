import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String _password = '';
  bool _isLoading = false;

  // 숫자 입력 처리
  void _onNumberTap(String number) {
    if (_isLoading) return;
    if (_password.length < 6) {
      HapticFeedback.lightImpact(); // 가벼운 진동 피드백
      setState(() {
        _password += number;
      });

      // 6자리가 다 차면 자동으로 검증 시작
      if (_password.length == 6) {
        _verifyPassword();
      }
    }
  }

  // 지우기 버튼 처리
  void _onDeleteTap() {
    if (_isLoading) return;
    if (_password.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _password = _password.substring(0, _password.length - 1);
      });
    }
  }

  // 생체 인증 버튼 처리
  void _onBiometricTap() {
    HapticFeedback.mediumImpact();
    // TODO: 실제 local_auth 패키지 연동 필요
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Face ID / 지문 인증을 시도합니다.')),
    );
  }

  // 비밀번호 검증 (임시)
  Future<void> _verifyPassword() async {
    setState(() => _isLoading = true);
    
    // 검증하는 척 딜레이
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isLoading = false);
      _showConfirmationSheet();
    }
  }

  // 송금 확인 바텀시트 표시
  void _showConfirmationSheet() {
    final numberFormat = NumberFormat('#,###');
    const fee = 500;
    final totalAmount = widget.amount + fee;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF202025),
      isScrollControlled: true, // 화면 높이에 따라 유동적으로 조절
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '송금 정보를 확인해주세요',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const Gap(32),
                // 받는 사람 정보
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF333338),
                      child: Text(
                        widget.recipientName[0],
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Gap(16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recipientName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '@${widget.recipientUsername}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
                const Gap(32),
                _buildInfoRow('보낼 금액', '${numberFormat.format(widget.amount)} Loopoint'),
                const Gap(12),
                _buildInfoRow('수수료', '${numberFormat.format(fee)} Loopoint'),
                const Gap(24),
                const Divider(color: Color(0xFF333338)),
                const Gap(24),
                _buildInfoRow('총 출금 금액', '${numberFormat.format(totalAmount)} Loopoint', isTotal: true),
                const Gap(32),
                ElevatedButton(
                  onPressed: _processTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // 프리미엄 화이트
                    foregroundColor: Colors.black, // 검은 글씨
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('보내기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? const Color(0xFF3182F6) : Colors.white,
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // 실제 송금 처리 (DB 연동)
  Future<void> _processTransfer() async {
    try {
      // 로딩 표시 (바텀시트 닫지 않고 버튼만 비활성화하거나, 로딩 다이얼로그 표시 등)
      // 여기서는 간단히 진행
      Navigator.of(context).pop(); // 바텀시트 닫기

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Supabase RPC 호출 (안전한 트랜잭션 처리)
      await Supabase.instance.client.rpc('transfer_point', params: {
        'recipient_id': widget.recipientId,
        'amount': widget.amount,
        'description': widget.recipientName, // 거래 내역에 표시될 이름
      });

      if (mounted) {
        Navigator.of(context).pop(); // 로딩 닫기
        // 홈 화면으로 이동 (모든 스택 제거)
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('송금이 완료되었습니다!'),
            backgroundColor: Color(0xFF3182F6),
          ),
        );
      }
    } on PostgrestException catch (e) {
      // DB 에러 발생 시 깔끔한 메시지만 표시 (예: "잔액이 부족합니다.")
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('송금 실패: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const Gap(40),
            const Text(
              '비밀번호를 입력해주세요',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Gap(40),
            // 비밀번호 6자리 점 (Dots)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final isFilled = index < _password.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? Colors.white : const Color(0xFF333338),
                  ),
                );
              }),
            ),
            const Spacer(),
            // 커스텀 키패드
            _buildKeypad(),
            const Gap(40),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          _buildKeyRow(['1', '2', '3']),
          const Gap(24),
          _buildKeyRow(['4', '5', '6']),
          const Gap(24),
          _buildKeyRow(['7', '8', '9']),
          const Gap(24),
          _buildKeyRow(['bio', '0', 'del']),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key == 'bio') {
           return _buildIconKey(Icons.fingerprint, _onBiometricTap);
        } else if (key == 'del') {
           return _buildIconKey(Icons.backspace_outlined, _onDeleteTap);
        } else {
           return _buildNumberKey(key);
        }
      }).toList(),
    );
  }

  Widget _buildNumberKey(String number) {
    return GestureDetector(
      onTap: () => _onNumberTap(number),
      behavior: HitTestBehavior.translucent, // 터치 영역 확장
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: Text(
          number,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: Colors.white),
        ),
      ),
    );
  }
  
  Widget _buildIconKey(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: Icon(icon, size: 28, color: Colors.white),
      ),
    );
  }
}
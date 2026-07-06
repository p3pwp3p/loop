import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loop_app/features/history/transaction_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MerchantPaymentScreen extends StatefulWidget {
  final String consumerId; // 스캔된 소비자 ID

  const MerchantPaymentScreen({super.key, required this.consumerId});

  @override
  State<MerchantPaymentScreen> createState() => _MerchantPaymentScreenState();
}

class _MerchantPaymentScreenState extends State<MerchantPaymentScreen> {
  String _amountString = ''; // 입력된 금액 문자열 (콤마 제외)
  bool _isLoading = true;
  bool _isPaying = false;
  Map<String, dynamic>? _consumerProfile;
  String? _merchantName; // 가맹점(나) 이름

  @override
  void initState() {
    super.initState();
    _fetchConsumerProfile();
    _fetchMerchantProfile();
  }

  // 소비자 정보 가져오기 (이름 확인용)
  Future<void> _fetchConsumerProfile() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', widget.consumerId)
          .single();

      if (mounted) {
        setState(() {
          _consumerProfile = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching consumer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자 정보를 불러올 수 없습니다.')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  // 가맹점(나) 정보 가져오기
  Future<void> _fetchMerchantProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('profiles')
          .select('full_name, username')
          .eq('id', userId)
          .single();
      
      if (mounted) {
        setState(() => _merchantName = data['full_name'] ?? data['username']);
      }
    } catch (e) {
      debugPrint('Error fetching merchant profile: $e');
    }
  }

  // 키패드 입력 처리
  void _onNumberTap(String number) {
    if (_isPaying) return;
    if (_amountString.length >= 10) return; // 최대 10자리 제한 (약 100억)
    
    HapticFeedback.lightImpact(); // 쫀득한 진동
    setState(() {
      if (_amountString == '0') {
        _amountString = number; // 0만 있을 땐 교체
      } else {
        _amountString += number;
      }
    });
  }

  void _onDeleteTap() {
    if (_isPaying || _amountString.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _amountString = _amountString.substring(0, _amountString.length - 1);
    });
  }

  // 결제 실행
  Future<void> _processPayment() async {
    final amount = int.tryParse(_amountString);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 금액을 입력해주세요.')),
      );
      return;
    }

    setState(() => _isPaying = true);

    try {
      await Supabase.instance.client.rpc('charge_point', params: {
        'consumer_id': widget.consumerId,
        'amount': amount,
        'description': _merchantName ?? '가맹점 결제', // 소비자의 내역에 뜰 가게 이름
      });

      if (mounted) {
        // 결제 성공 시 영수증 화면을 바텀시트로 띄움 (애니메이션 효과)
        final consumerName = _consumerProfile?['full_name'] ?? _consumerProfile?['username'] ?? '구매자';
        
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => TransactionDetailScreen(
            transaction: {
              'amount': amount, // 받은 금액 (양수)
              'description': consumerName, // 상대방 이름
              'created_at': DateTime.now().toIso8601String(),
              'id': 'Now', // 방금 발생한 거래
            },
          ),
        );

        // 영수증을 닫으면 홈으로 복귀
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        _showFailureSheet(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showFailureSheet('알 수 없는 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  // [UI Update] 결제 실패 시 보여줄 바텀 시트
  void _showFailureSheet(String error) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF202025),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const Gap(16),
              const Text(
                '결제 실패',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Gap(8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              ),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final consumerName = _consumerProfile?['full_name'] ?? _consumerProfile?['username'] ?? '사용자';
    final formattedAmount = _amountString.isEmpty ? '0' : NumberFormat('#,###').format(int.parse(_amountString));

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                  children: [
                    const Spacer(flex: 2), // [UI Update] 상단 여백 축소 (제목을 더 위로)
                    Text(
                      '얼마를\n결제할까요?',
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
                      '대상: $consumerName',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                    const Spacer(flex: 3), // [UI Update] 중간 여백 확대 (금액창을 더 아래로)
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
                    const Spacer(flex: 4), // [UI Update] 하단 여백 확보
                  ],
                ),
              ),
                  // 하단 영역 (버튼 + 키패드)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ElevatedButton(
                      onPressed: _isPaying || _amountString.isEmpty ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 20), // [UI Update] 버튼 높이 확장
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        minimumSize: const Size.fromHeight(56),
                        disabledBackgroundColor: Colors.grey[800],
                        disabledForegroundColor: Colors.grey[500],
                      ),
                      child: _isPaying
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text('결제하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final amount = transaction['amount'] as int;
    final rawDescription = transaction['description'] as String? ?? '거래';
    final createdAt = DateTime.parse(transaction['created_at']).toLocal();
    final isPositive = amount > 0;
    final formattedAmount = NumberFormat('#,###').format(amount.abs());

    // 상세 화면에서도 이름만 깔끔하게 보여주기 위해 파싱
    String displayTitle = rawDescription;
    if (rawDescription.startsWith('송금 보냄: ')) {
      displayTitle = rawDescription.replaceFirst('송금 보냄: ', '');
    } else if (rawDescription.startsWith('송금 받음: ')) {
      displayTitle = rawDescription.replaceFirst('송금 받음: ', '');
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF202025), // 바텀시트 배경색
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 내용물만큼만 높이 차지
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Gap(16),
              // 상단 핸들바 (드래그 유도)
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(32),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isPositive ? const Color(0xFF3182F6).withOpacity(0.2) : Colors.grey[800],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: isPositive ? const Color(0xFF3182F6) : Colors.white,
                  size: 32,
                ),
              ),
              const Gap(24),
              Text(
                isPositive ? '입금 완료' : '송금 완료',
                style: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Gap(8),
              Text(
                '${isPositive ? '+' : '-'}$formattedAmount Loopoint',
                style: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.w800, // 숫자는 더 굵게(ExtraBold)
                  color: isPositive ? const Color(0xFF3182F6) : Colors.white,
                  letterSpacing: -1.0, // 자간을 좁혀서 숫자가 흩어지지 않고 단단해 보이게
                ),
              ),
              const Gap(40),
              const Divider(color: Color(0xFF333338)),
              const Gap(24),
              _buildDetailRow('거래 대상', displayTitle),
              const Gap(16),
              _buildDetailRow('거래 일시', DateFormat('yyyy.MM.dd HH:mm').format(createdAt)),
              const Gap(16),
              _buildDetailRow('거래 유형', isPositive ? '입금' : '출금'),
              const Gap(16),
              _buildDetailRow('거래 번호', '#${transaction['id']}'),
              const Gap(40),
              
              // [UI Update] 쫀득한 터치감의 확인 버튼 추가
              _ScaleButton(
                text: '확인',
                onTap: () => Navigator.of(context).pop(),
              ),
              const Gap(24), // 하단 안전 여백
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.notoSans(color: Colors.grey[500], fontSize: 16)),
        Text(
          value,
          style: GoogleFonts.notoSans(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2, // 한글 자간 미세 조정
          ),
        ),
      ],
    );
  }
}

// [Component] 눌렀을 때 살짝 작아지는 쫀득한 버튼 (받는 사람 찾기 UI와 동일)
class _ScaleButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _ScaleButton({
    required this.text,
    required this.onTap,
  });

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.96); // 4% 정도 살짝 축소
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    // 버튼이 다시 커지는 모션을 보여준 뒤 실행 (쫀득함 극대화)
    Future.delayed(const Duration(milliseconds: 80), widget.onTap);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100), // 쫀득한 반응 속도
        curve: Curves.easeInOut,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24), // [UI Update] 버튼 높이 확장
          decoration: BoxDecoration(
            color: const Color(0xFF333338), // 버튼 배경색 (카드보다 살짝 밝게)
            borderRadius: BorderRadius.circular(24), // 둥근 모서리
          ),
          alignment: Alignment.center,
          child: Text(
            widget.text,
            style: GoogleFonts.notoSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
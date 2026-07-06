import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';
import 'package:loop_app/features/payment/merchant_payment_screen.dart';

/// QR 스캔 결제 (새 테마). 상대 QR을 비추면 가맹점 결제 화면으로 이동.
/// 카메라 사용 불가(웹 미리보기 등) 시 수동 입력 폴백 제공.
class QrPaymentScreen extends StatefulWidget {
  const QrPaymentScreen({super.key});

  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends State<QrPaymentScreen> {
  bool _handled = false;

  void _go(String code) {
    if (_handled) return;
    _handled = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MerchantPaymentScreen(consumerId: code)),
    );
  }

  void _manualInput() {
    final controller = TextEditingController(text: 'LOOP-DEMO-USER');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0E0E12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('사용자 ID 입력', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: AppColors.cyan,
          decoration: const InputDecoration(
            hintText: 'User ID',
            hintStyle: TextStyle(color: AppColors.gray500),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.cyan)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isNotEmpty) {
                Navigator.pop(context);
                _go(v);
              }
            },
            child: const Text('확인', style: TextStyle(color: AppColors.cyan)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 카메라 (실패 시 폴백)
          Positioned.fill(
            child: MobileScanner(
              onDetect: (capture) {
                for (final b in capture.barcodes) {
                  if (b.rawValue != null) {
                    _go(b.rawValue!);
                    break;
                  }
                }
              },
              errorBuilder: (context, error, child) => _cameraFallback(),
            ),
          ),
          // 스캔 프레임 + 안내
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cyan, width: 2),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(0.4), blurRadius: 24, spreadRadius: -4)],
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 120,
            child: Text('상대방의 QR 코드를 비춰주세요',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          // 상단 버튼들
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GlassIconButton(icon: PhosphorIcons.x(), onTap: () => Navigator.of(context).pop()),
                GlassIconButton(icon: PhosphorIcons.keyboard(), onTap: _manualInput),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraFallback() {
    return Container(
      color: AppColors.page,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.cameraSlash(), size: 56, color: AppColors.gray500),
          const SizedBox(height: 16),
          const Text('카메라를 사용할 수 없어요',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('수동으로 사용자 ID를 입력해 진행하세요.',
              style: TextStyle(color: AppColors.gray500, fontSize: 13)),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: LoopPrimaryButton(label: '수동 입력', onTap: _manualInput),
          ),
        ],
      ),
    );
  }
}

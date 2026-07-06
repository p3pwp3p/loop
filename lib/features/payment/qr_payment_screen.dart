import 'package:flutter/material.dart';
import 'package:loop_app/features/payment/merchant_payment_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrPaymentScreen extends StatefulWidget {
  const QrPaymentScreen({super.key});

  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends State<QrPaymentScreen> {
  bool _isScanning = true;
  
  // [Debug] UID 직접 입력 다이얼로그 (카메라 없는 환경 테스트용)
  void _showDebugInput() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF202025),
        title: const Text('Debug: 소비자 ID 입력', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'User ID (UUID)',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _navigateToPayment(controller.text.trim());
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _navigateToPayment(String code) {
    setState(() => _isScanning = false); // 스캔 중지
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MerchantPaymentScreen(consumerId: code),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // 카메라와 가이드라인이 화면 정중앙에 오도록 설정
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0), // [UI Update] 닫기 버튼 여백 확보
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          // 디버그용 수동 입력 버튼
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.keyboard, color: Colors.white),
              onPressed: _showDebugInput,
            ),
          ),
        ],
      ),
      body: Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            if (!_isScanning) return;
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                final String code = barcode.rawValue!;
                _navigateToPayment(code);
                break; 
              }
            }
          },
        ),
        // 스캔 가이드 라인
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Icon(Icons.add, color: Colors.white54, size: 40),
            ),
          ),
        ),
        const Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Text(
            '상대방의 QR코드를 비춰주세요',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyQrScreen extends StatelessWidget {
  const MyQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 현재 로그인한 사용자의 고유 ID 가져오기
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? '';

    return Scaffold(
      extendBodyBehindAppBar: true, // 앱바 뒤로 내용이 확장되어 정중앙 배치 가능
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0), // [UI Update] 닫기 버튼 여백 확보
          child: IconButton(
            icon: const Icon(Icons.close),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '결제 시 매장 직원에게\n이 코드를 보여주세요',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              const Gap(40),
              // QR 코드 카드
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 실제 QR 코드 생성 (내 ID 포함)
                    QrImageView(
                      data: userId, // 스캔 시 이 ID가 읽힘
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
              ),
              const Gap(40),
              Text(
                '상대방이 스캔할 때까지\n화면을 켜두세요',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
    );
  }
}
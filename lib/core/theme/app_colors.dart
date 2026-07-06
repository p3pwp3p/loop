import 'package:flutter/material.dart';

/// LOOP 디자인 토큰.
///
/// 방향성: 검정 베이스 + 모노크롬 + 단일 시안 액센트. 로고의 궤도를 시그니처로.
/// 상승/하락 같은 금융 기능색은 브랜드 액센트(시안)와 분리해서 둔다.
class AppColors {
  AppColors._();

  // ── Surfaces ──────────────────────────────────────────────
  static const Color black = Color(0xFF030303); // 최외곽 배경
  static const Color page = Color(0xFF050507); // 메인 화면 배경
  static const Color navBar = Color(0xFF0F0F13); // 하단 글래스 네비
  static const Color iconTile = Color(0xFF121215); // 리스트 아이콘 타일
  static const Color iconTileHover = Color(0xFF151518);

  // ── Accent (단일) ─────────────────────────────────────────
  static const Color cyan = Color(0xFF22D3EE); // cyan-400, 시그니처
  static const Color cyan300 = Color(0xFF67E8F9);
  static const Color teal = Color(0xFF14B8A6); // teal-500, '적립' 그라데이션 끝
  static const Color onCyan = Color(0xFF062E33); // 시안 위에 올리는 어두운 텍스트

  // ── Text ──────────────────────────────────────────────────
  static const Color white = Colors.white;
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);

  // ── 기능색 (브랜드 액센트와 분리) ──────────────────────────
  static const Color up = Color(0xFF34D399); // 상승/적립
  static const Color down = Color(0xFFF0556B); // 하락/소비

  // ── Glass ─────────────────────────────────────────────────
  static Color glassFill = Colors.white.withOpacity(0.02);
  static Color glassBorder = Colors.white.withOpacity(0.05);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loop_app/app.dart';
import 'package:loop_app/core/constants/supabase_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // 1. 플러터 엔진 초기화 (비동기 작업 전 필수)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Supabase 초기화 (나중에 API 키 발급받으면 여기에 넣을 예정)
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  // 3. 앱 실행 (Riverpod 사용을 위해 ProviderScope로 감싸기)
  runApp(
    const ProviderScope(
      child: LoopApp(),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';

/// 회원가입 (새 테마). 이메일 → 비밀번호 → 닉네임(중복확인).
class SignUpScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String carrier;

  const SignUpScreen({super.key, required this.name, required this.phone, required this.carrier});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _scroll = ScrollController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nickname = TextEditingController();

  String? _nicknameError;
  String? _passwordError;
  int _step = 0;
  int _furthest = 0;
  bool _loading = false;

  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _scroll.dispose();
    _email.dispose();
    _password.dispose();
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_loading) return;
    if (_step == 0 && _email.text.isEmpty) return;
    if (_step == 1) {
      if (_password.text.length < 6) {
        setState(() => _passwordError = '비밀번호는 6자 이상이어야 해요.');
        return;
      }
      setState(() => _passwordError = null);
    }
    if (_step == 2) {
      if (_nickname.text.isEmpty) return;
      setState(() => _loading = true);
      try {
        final taken = await _supabase.rpc('is_username_taken', params: {
          'username_input': _nickname.text.trim(),
        });
        if (taken == true) {
          setState(() => _nicknameError = '이미 사용 중인 닉네임이에요.');
          return;
        }
        setState(() => _nicknameError = null);
      } catch (_) {
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
    if (_step < 2) {
      setState(() {
        _step++;
        if (_step > _furthest) _furthest = _step;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      });
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final res = await _supabase.auth.signUp(
        email: _email.text.trim(),
        password: _password.text.trim(),
        data: {
          'full_name': widget.name,
          'username': _nickname.text.trim(),
          'phone': widget.phone,
          'carrier': widget.carrier,
        },
      );
      if (mounted && res.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공! 환영해요.')),
        );
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } on AuthException catch (e) {
      if (mounted) {
        var msg = e.message;
        if (e.message.contains('rate limit')) msg = '잠시 후 다시 시도해주세요.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.down),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했어요: $e'), backgroundColor: AppColors.down),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
              LoopTopBar(title: '회원가입', leadingIcon: PhosphorIcons.caretLeft()),
              LinearProgressIndicator(
                value: (_step + 1) / 3,
                backgroundColor: Colors.white.withOpacity(0.06),
                valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                minHeight: 2,
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: [
                      LoopWizardStep(
                        index: 0, currentStep: _step, furthestStep: _furthest,
                        title: '이메일을 입력해주세요', controller: _email, hint: 'example@email.com',
                        keyboardType: TextInputType.emailAddress, autoFocus: true,
                        buttonLabel: '다음', onNext: _next, onTapCompleted: (i) => setState(() => _step = i),
                      ),
                      LoopWizardStep(
                        index: 1, currentStep: _step, furthestStep: _furthest,
                        title: '비밀번호를 입력해주세요', controller: _password, hint: '비밀번호 (6자리 이상)',
                        obscure: true, autoFocus: true, errorText: _passwordError,
                        buttonLabel: '다음', onNext: _next, onTapCompleted: (i) => setState(() => _step = i),
                      ),
                      LoopWizardStep(
                        index: 2, currentStep: _step, furthestStep: _furthest,
                        title: '사용하실 닉네임을 입력해주세요', controller: _nickname, hint: '레브로',
                        autoFocus: true, errorText: _nicknameError,
                        buttonLabel: '가입 완료', loading: _loading, onNext: _next,
                        onTapCompleted: (i) => setState(() => _step = i),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

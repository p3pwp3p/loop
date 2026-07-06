import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';

/// 이메일 가입 위저드 (새 테마). 이메일 → 비밀번호 → 통신사 → 전화 → 인증번호.
class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _scroll = ScrollController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();

  final _carriers = ['SKT', 'KT', 'LG U+', '알뜰폰'];
  String? _carrier;
  String? _otpError;
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
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<bool> _sendCode() async {
    setState(() => _loading = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증번호가 발송됐어요. (테스트 코드: 123456)')),
        );
      }
      return true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _next() async {
    if (_step == 0 && _email.text.isEmpty) return;
    if (_step == 1) {
      if (_password.text.length < 6) {
        setState(() => _passwordError = '비밀번호는 6자 이상이어야 해요.');
        return;
      }
      setState(() => _passwordError = null);
    }
    if (_step == 2 && _carrier == null) return;
    if (_step == 3 && _phone.text.isEmpty) return;
    if (_step == 3) {
      final ok = await _sendCode();
      if (!ok) return;
    }
    if (_step < 4) {
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
    setState(() => _otpError = null);
    if (_otp.text.trim() != '123456') {
      setState(() => _otpError = '인증번호가 올바르지 않아요.');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _supabase.auth.signUp(
        email: _email.text.trim(),
        password: _password.text.trim(),
        data: {'phone': _phone.text.replaceAll('-', ''), 'carrier': _carrier},
      );
      if (mounted && res.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공! 환영해요.')),
        );
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.down),
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
              LoopTopBar(leadingIcon: PhosphorIcons.caretLeft()),
              LinearProgressIndicator(
                value: (_step + 1) / 5,
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
                        title: '통신사를 선택해주세요', buttonLabel: '다음', onNext: _next,
                        onTapCompleted: (i) => setState(() => _step = i),
                        customInput: _carrierDropdown(),
                      ),
                      LoopWizardStep(
                        index: 3, currentStep: _step, furthestStep: _furthest,
                        title: '휴대전화 번호를 입력해주세요', controller: _phone, hint: '010-1234-5678',
                        keyboardType: TextInputType.phone, autoFocus: true,
                        buttonLabel: '인증번호 받기', loading: _loading, onNext: _next,
                        onTapCompleted: (i) => setState(() => _step = i),
                      ),
                      LoopWizardStep(
                        index: 4, currentStep: _step, furthestStep: _furthest,
                        title: '문자로 전송된\n인증번호를 입력해주세요', controller: _otp, hint: '6자리 숫자',
                        keyboardType: TextInputType.number, autoFocus: true, errorText: _otpError,
                        buttonLabel: '완료', onNext: _next, onTapCompleted: (i) => setState(() => _step = i),
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

  Widget _carrierDropdown() {
    return DropdownButtonFormField<String>(
      value: _carrier,
      items: _carriers.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) => setState(() => _carrier = v),
      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600, height: 1.2),
      dropdownColor: const Color(0xFF16161B),
      borderRadius: BorderRadius.circular(16),
      icon: Icon(PhosphorIcons.caretDown(), color: AppColors.gray400, size: 18),
      isDense: true,
      hint: const Text('선택', style: TextStyle(color: Color(0xFF3A3A42), fontSize: 22, fontWeight: FontWeight.w600)),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.fromLTRB(4, 18, 0, 18),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.cyan, width: 1.5)),
      ),
    );
  }
}

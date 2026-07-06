import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String carrier;

  const SignUpScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.carrier,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _scrollController = ScrollController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();

  String? _nicknameErrorText;
  String? _passwordErrorText;
  int _currentStep = 0; // 0:이메일, 1:비밀번호, 2:닉네임
  int _furthestStep = 0;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _scrollController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_isLoading) return; // 중복 실행 방지
    if (_currentStep == 0 && _emailController.text.isEmpty) return;
    
    if (_currentStep == 1) {
      if (_passwordController.text.length < 6) {
        setState(() => _passwordErrorText = '비밀번호는 6자 이상이어야 합니다.');
        return;
      }
      setState(() => _passwordErrorText = null);
    }

    if (_currentStep == 2) {
      if (_nicknameController.text.isEmpty) return;

      // 닉네임 중복 확인 (Supabase RPC 호출)
      setState(() => _isLoading = true);
      try {
        final isTaken = await supabase.rpc('is_username_taken', params: {
          'username_input': _nicknameController.text.trim(),
        });

        if (isTaken == true) {
          setState(() {
            _nicknameErrorText = '이미 사용 중인 닉네임입니다.';
          });
          return; // 중복이면 진행 중단
        }
        setState(() => _nicknameErrorText = null);
      } catch (e) {
        // 에러 발생 시 일단 진행하거나 스낵바 표시 (여기선 finally에서 로딩 해제됨)
      } finally {
        setState(() => _isLoading = false);
      }
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
        if (_currentStep > _furthestStep) _furthestStep = _currentStep;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      });
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      // Supabase 회원가입 요청
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': widget.name,
          'username': _nicknameController.text.trim(), // 닉네임 저장
          'phone': widget.phone,
          'carrier': widget.carrier,
        },
      );

      if (mounted) {
        if (res.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입 성공! 환영합니다.')),
          );
          // 메인 화면으로 이동 (모든 이전 화면 제거)
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        String message = e.message;
        // 에러 메시지 한글화
        if (e.message.contains('rate limit')) {
          message = '잠시 후 다시 시도해주세요. (요청 횟수 초과)';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("회원가입", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              minHeight: 2,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    _buildStep(
                      index: 0,
                      title: '이메일을 입력해주세요',
                      controller: _emailController,
                      hint: 'example@email.com',
                      keyboardType: TextInputType.emailAddress,
                      autoFocus: true,
                    ),
                    _buildStep(
                      index: 1,
                      title: '비밀번호를 입력해주세요',
                      controller: _passwordController,
                      hint: '비밀번호 (6자리 이상)',
                      obscureText: true,
                      autoFocus: true,
                      errorText: _passwordErrorText,
                    ),
                    _buildStep(
                      index: 2,
                      title: '사용하실 닉네임을 입력해주세요',
                      controller: _nicknameController,
                      hint: '레브로',
                      isLastStep: true,
                      autoFocus: true,
                      errorText: _nicknameErrorText,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // (IdentityVerificationScreen과 동일한 UI 로직 재사용)
  Widget _buildStep({
    required int index,
    required String title,
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool isLastStep = false,
    bool autoFocus = false,
    String? errorText,
  }) {
    if (index > _furthestStep) return const SizedBox.shrink();
    final isCurrent = index == _currentStep;
    final isCompleted = !isCurrent;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1.0,
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: animation, curve: const Interval(0.5, 1.0, curve: Curves.easeInOutCubic)),
                  child: child,
                ),
              ),
              child: isCompleted
                  ? const SizedBox.shrink()
                  : Column(
                      key: ValueKey('title_$index'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Gap(24),
                        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.4)),
                        const Gap(32),
                      ],
                    ),
            ),
            GestureDetector(
              onTap: isCompleted ? () => setState(() => _currentStep = index) : null,
              child: AbsorbPointer(
                absorbing: isCompleted,
                child: TextFormField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  autofocus: autoFocus && isCurrent,
                  style: TextStyle(color: isCompleted ? Colors.grey[500] : Colors.white, fontSize: 22, fontWeight: FontWeight.w600, height: 1.2),
                  decoration: InputDecoration(
                    hintText: hint,
                    errorText: errorText,
                    hintStyle: TextStyle(color: Colors.grey[800], fontSize: 22, fontWeight: FontWeight.w600),
                    contentPadding: const EdgeInsets.fromLTRB(12, 20, 0, 20),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                  ),
                  onFieldSubmitted: (_) { if (isCurrent) _nextStep(); },
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              alignment: Alignment.topCenter,
              child: isCurrent
                  ? Column(
                      children: [
                        const Gap(24),
                        ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: Text(
                            _isLoading
                                ? '확인 중...' // 로딩 중 텍스트 변경
                                : isLastStep
                                    ? '가입 완료'
                                    : '다음',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

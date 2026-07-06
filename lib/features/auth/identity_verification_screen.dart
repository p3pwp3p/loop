import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:loop_app/features/auth/sign_up_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> {
  final _scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  final _carriers = ['SKT', 'KT', 'LG U+', '알뜰폰'];
  String? _selectedCarrier;
  String? _otpErrorText;
  
  int _currentStep = 0; // 0:이름, 1:통신사, 2:전화번호, 3:인증번호
  int _furthestStep = 0;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // 인증번호 발송 (개발용)
  Future<bool> _sendVerificationCode() async {
    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 1)); // 1초 딜레이
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증번호가 발송되었습니다. (테스트 코드: 123456)')),
        );
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _nextStep() async {
    if (_currentStep == 0 && _nameController.text.isEmpty) return;
    if (_currentStep == 1 && _selectedCarrier == null) return;
    if (_currentStep == 2 && _phoneController.text.isEmpty) return;

    // 전화번호 입력 후 인증번호 발송
    if (_currentStep == 2) {
      final success = await _sendVerificationCode();
      if (!success) return;
    }

    if (_currentStep < 3) {
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
    setState(() => _otpErrorText = null);

    if (_otpController.text.trim() != '123456') {
      setState(() => _otpErrorText = '인증번호가 올바르지 않습니다.');
      return;
    }

    // 인증 성공! 회원가입 화면으로 이동 (전화번호 정보 전달)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SignUpScreen(
          name: _nameController.text.trim(),
          phone: _phoneController.text.replaceAll('-', ''),
          carrier: _selectedCarrier!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("본인인증", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / 4,
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
                      title: '이름을 입력해주세요',
                      controller: _nameController,
                      hint: '이름',
                      autoFocus: true,
                    ),
                    _buildStep(
                      index: 1,
                      title: '통신사를 선택해주세요',
                      customInput: DropdownButtonFormField<String>(
                        value: _selectedCarrier,
                        items: _carriers.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _selectedCarrier = v),
                        style: const TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600, fontFamily: 'Noto Sans KR', height: 1.2,
                        ),
                        dropdownColor: const Color(0xFF202025),
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
                        isDense: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.fromLTRB(12, 20, 0, 20),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                        ),
                      ),
                    ),
                    _buildStep(
                      index: 2,
                      title: '휴대전화 번호를 입력해주세요',
                      controller: _phoneController,
                      hint: '010-1234-5678',
                      keyboardType: TextInputType.phone,
                      autoFocus: true,
                    ),
                    _buildStep(
                      index: 3,
                      title: '문자로 전송된\n인증번호를 입력해주세요',
                      controller: _otpController,
                      hint: '6자리 숫자',
                      keyboardType: TextInputType.number,
                      isLastStep: true,
                      autoFocus: true,
                      errorText: _otpErrorText,
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

  Widget _buildStep({
    required int index,
    required String title,
    TextEditingController? controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool isLastStep = false,
    bool autoFocus = false,
    Widget? customInput,
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
                child: customInput ?? TextFormField(
                  controller: controller,
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
                            isLastStep ? '인증 완료' : index == 2 ? '인증번호 받기' : '다음',
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

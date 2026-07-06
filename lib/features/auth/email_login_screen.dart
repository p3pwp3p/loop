import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _scrollController = ScrollController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  final _carriers = ['SKT', 'KT', 'LG U+', '알뜰폰'];
  String? _selectedCarrier;
  String? _otpErrorText;
  String? _passwordErrorText;
  int _currentStep = 0; // 0:이메일, 1:비밀번호, 2:통신사, 3:전화번호, 4:인증번호
  int _furthestStep = 0; // 사용자가 도달한 최대 단계 (이전으로 돌아가도 유지됨)
  bool _isLoading = false;

  // Supabase 클라이언트 가져오기
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _scrollController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // 인증번호 발송 (개발용 무료 모드)
  Future<bool> _sendVerificationCode() async {
    setState(() => _isLoading = true);
    try {
      // 실제 SMS 발송은 비용이 발생하므로, 개발 중에는 1초 딜레이로 흉내만 냅니다.
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증번호가 발송되었습니다. (테스트 코드: 123456)')),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS 발송 중 오류가 발생했습니다.'), backgroundColor: Colors.red),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 다음 단계로 이동
  Future<void> _nextStep() async {
    // 간단한 유효성 검사 (빈칸 방지)
    if (_currentStep == 0 && _emailController.text.isEmpty) return;
    
    // 비밀번호 유효성 검사 (6자리 이상)
    if (_currentStep == 1) {
      if (_passwordController.text.length < 6) {
        setState(() => _passwordErrorText = '비밀번호는 6자 이상이어야 합니다.');
        return;
      }
      setState(() => _passwordErrorText = null); // 통과하면 에러 초기화
    }

    if (_currentStep == 2 && _selectedCarrier == null) return;
    if (_currentStep == 3 && _phoneController.text.isEmpty) return;

    // 3단계(전화번호 입력)에서 다음 버튼을 누르면 SMS 발송 시도
    if (_currentStep == 3) {
      final success = await _sendVerificationCode();
      if (!success) return; // 발송 실패 시 다음 단계로 넘어가지 않음
    }

    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
        if (_currentStep > _furthestStep) _furthestStep = _currentStep;
      });
      // 화면이 그려진 후 스크롤을 맨 아래로 부드럽게 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      });
    } else {
      // 마지막 단계: 제출
      _submit();
    }
  }

  // 최종 제출 (회원가입/로그인 로직)
  Future<void> _submit() async {
    setState(() => _otpErrorText = null); // 기존 에러 초기화

    // 테스트용 인증번호 검증 (123456이 아니면 막음)
    if (_otpController.text.trim() != '123456') {
      setState(() => _otpErrorText = '인증번호가 올바르지 않습니다.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. 회원가입 시도 (이메일 + 비밀번호)
      // 실제로는 여기서 OTP 검증 로직이 추가되어야 할 수 있습니다.
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'phone': _phoneController.text.replaceAll('-', ''),
          'carrier': _selectedCarrier,
        },
      );

      if (mounted) {
        if (res.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입 성공! 환영합니다.')),
          );
          // 로그인 화면이나 홈으로 이동
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 진행바 (Progress Bar)
            LinearProgressIndicator(
              value: (_currentStep + 1) / 5,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              minHeight: 2,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 100), // 하단 여백 확보
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
                    title: '통신사를 선택해주세요',
                    // 드롭다운 위젯을 customInput으로 전달
                    customInput: DropdownButtonFormField<String>(
                      value: _selectedCarrier,
                      items: _carriers.map((carrier) {
                        return DropdownMenuItem(
                          value: carrier,
                          child: Text(carrier),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCarrier = value);
                        // 선택하자마자 다음 단계로 넘어가고 싶다면 아래 주석 해제
                        // _nextStep();
                      },
                      style: const TextStyle(
                        color: Colors.white, // 활성화 여부는 아래 _buildStep에서 처리됨 (여기선 기본값)
                        fontSize: 22, // 폰트 크기 축소 (잘림 방지 및 균형)
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Noto Sans KR', // 폰트 일관성 유지
                        height: 1.2, // 줄높이 조절
                      ),
                      dropdownColor: const Color(0xFF202025), // 드롭다운 배경색 (다크 테마)
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
                      isDense: true, // 높이 제약을 풀어 잘림 방지
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.fromLTRB(12, 20, 0, 20), // 왼쪽으로 12px 이동
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[800]!),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).primaryColor),
                        ),
                      ),
                    ),
                  ),
                  _buildStep(
                    index: 3,
                    title: '휴대전화 번호를 입력해주세요',
                    controller: _phoneController,
                    hint: '010-1234-5678',
                    keyboardType: TextInputType.phone,
                    autoFocus: true,
                  ),
                  _buildStep(
                    index: 4,
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
    TextEditingController? controller, // 선택사항으로 변경
    String? hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool isLastStep = false,
    bool autoFocus = false,
    Widget? customInput, // 커스텀 입력 위젯 (드롭다운 등)
    String? errorText,
  }) {
    // 아직 도달하지 않은 단계는 숨김
    if (index > _furthestStep) return const SizedBox.shrink();

    final isCurrent = index == _currentStep;
    final isCompleted = !isCurrent; // 현재 단계가 아니면 모두 '완료/대기' 상태로 처리

    // 등장 애니메이션 (새로운 단계가 나올 때만 발동)
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500), // 속도감을 높여 경쾌하게
      curve: Curves.easeInOutCubic, // 천천히 시작해서 가속도가 붙었다가 부드럽게 멈춤
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - value)), // 이동 거리를 살짝 줄여서 밀도 있게
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 제목: 완료되면 사라짐 (애니메이션)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500), // 닫히는 속도도 빠르게
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (child, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1.0, // 위쪽을 기준으로 닫힘
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      // 공간이 50% 남았을 때 이미 글자는 사라지도록 설정 (더 빨리 사라짐)
                      curve: const Interval(0.5, 1.0, curve: Curves.easeInOutCubic),
                    ),
                    child: child,
                  ),
                );
              },
              child: isCompleted
                  ? const SizedBox.shrink()
                  : Column(
                      key: ValueKey('title_$index'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Gap(24),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                        const Gap(32),
                      ],
                    ),
            ),
            
            // 입력창
            GestureDetector(
              onTap: isCompleted
                  ? () {
                      // 완료된 단계를 누르면 해당 단계로 돌아가고, 이후 단계는 숨김
                      setState(() => _currentStep = index);
                    }
                  : null,
              child: AbsorbPointer(
                absorbing: isCompleted, // 완료된 상태면 입력 막고 탭 이벤트만 받음
                child: customInput ??
                    TextFormField(
                      controller: controller,
                      obscureText: obscureText,
                      keyboardType: keyboardType,
                      autofocus: autoFocus && isCurrent, // 현재 단계일 때만 포커스
                      enabled: true, // 수정은 가능하게 유지
                      style: TextStyle(
                        color: isCompleted ? Colors.grey[500] : Colors.white,
                        fontSize: 22, // 폰트 크기 축소
                        fontWeight: FontWeight.w600,
                        height: 1.2, // 줄높이 조절
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        errorText: errorText,
                        hintStyle: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 22, // 폰트 크기 축소
                            fontWeight: FontWeight.w600),
                        contentPadding: const EdgeInsets.fromLTRB(12, 20, 0, 20), // 왼쪽으로 12px 이동
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[800]!),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                        ),
                      ),
                      onFieldSubmitted: (_) {
                        if (isCurrent) _nextStep();
                      },
                    ),
              ),
            ),
            
            // 버튼: 현재 단계에만 표시
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: Text(
                            isLastStep
                                ? '완료'
                                : index == 3
                                    ? '인증번호 받기'
                                    : '다음',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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
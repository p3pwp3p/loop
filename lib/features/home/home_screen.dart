import 'dart:async'; // [Added] 타이머 사용을 위해 추가
import 'dart:math' as math; // 차트 데이터 계산용
import 'dart:ui'; // ImageFilter 사용을 위해 추가

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loop_app/features/history/transaction_history_screen.dart';
import 'package:loop_app/features/home/loop_logo.dart';
import 'package:loop_app/features/payment/my_qr_screen.dart';
import 'package:loop_app/features/payment/qr_payment_screen.dart';
import 'package:loop_app/features/transfer/transfer_search_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _userId = Supabase.instance.client.auth.currentUser!.id;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  int _selectedIndex = 2; // [Change] 홈(Home)을 중앙(인덱스 2)으로 배치하기 위해 기본값 변경
  int _previousIndex = 2; // [Added] 이동 방향 판별을 위한 이전 인덱스

  // [Logic] 투자 탭 관련 인덱스인지 확인 (1:투자, 5:피드, 6:준비중1, 7:준비중2)
  bool get _isInvestMode => [1, 5, 6, 7].contains(_selectedIndex);
  
  // [Data] 피드 게시글 리스트 (DateTime 포함)
  late List<Map<String, dynamic>> _feedPosts;
  String _feedSortOption = '최신순'; // 정렬 기준 (최신순, 오늘, 이번 주, 이번 달)

  // [Data] 관심 종목 리스트
  final List<Map<String, dynamic>> _watchlist = [];

  @override
  void initState() {
    super.initState();
    _initFeedData(); // 더미 데이터 초기화
    _fetchProfile();
  }

  void _initFeedData() {
    final now = DateTime.now();
    _feedPosts = [
      {
        'author': 'CryptoKing',
        'dateTime': now.subtract(const Duration(minutes: 5)),
        'content': '비트코인 1억 가즈아! 🚀 지금이 저점 매수 기회입니다.',
        'likes': 124,
        'comments': 42,
        'isLiked': true,
      },
      {
        'author': '주식초보',
        'dateTime': now.subtract(const Duration(hours: 2)),
        'content': '테슬라 실적 발표 보고 들어갈까요? 아니면 좀 더 기다릴까요?',
        'likes': 15,
        'comments': 8,
        'isLiked': false,
      },
      {
        'author': '익명',
        'dateTime': now.subtract(const Duration(days: 1)), // 어제
        'content': '오늘 장 분위기 왜 이러나요... 파란불 파티네 ㅠㅠ',
        'likes': 45,
        'comments': 12,
        'isLiked': false,
      },
      {
        'author': '존버맨',
        'dateTime': now.subtract(const Duration(days: 3)),
        'content': '3년째 물려있습니다. 구조대 언제 오나요?',
        'likes': 230,
        'comments': 150,
        'isLiked': true,
      },
      {
        'author': '단타장인',
        'dateTime': now.subtract(const Duration(days: 10)),
        'content': '단타로 월 30% 수익 인증합니다. 질문 받습니다.',
        'likes': 88,
        'comments': 56,
        'isLiked': false,
      },
    ];
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', _userId)
          .single();

      if (mounted) {
        setState(() {
          _profile = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('프로필 로딩 실패: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _fetchProfile();
  }

  @override
  // 탭 변경 처리
  void _onItemTapped(int index) {
    setState(() {
      _previousIndex = _selectedIndex; // 변경 전 인덱스 저장
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 전체 배경색
      extendBody: true, // [UI Update] 바디가 네비게이션 바 뒤까지 확장되도록 설정 (플로팅 효과 필수)
      // [UI Update] AnimatedSwitcher로 변경하여 미세하고 빠른 전환 효과 구현
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 100), // [UI Update] 더 빠르게 (약 6프레임)
        switchInCurve: Curves.easeOutQuad,
        switchOutCurve: Curves.easeInQuad,
        transitionBuilder: (Widget child, Animation<double> animation) {
          // 이동 방향 판별 (오른쪽 탭으로 가면 true)
          final bool isMovingRight = _selectedIndex > _previousIndex;
          
          final isNewPage = child.key == ValueKey(_selectedIndex);
          
          // [Logic] 방향에 따른 오프셋 설정
          // 오른쪽 이동: 새 창은 오른쪽(+0.05)에서 등장, 헌 창은 왼쪽(-0.05)으로 퇴장
          // 왼쪽 이동: 새 창은 왼쪽(-0.05)에서 등장, 헌 창은 오른쪽(+0.05)으로 퇴장
          double startOffset = isMovingRight
              ? (isNewPage ? 0.08 : -0.08) // [UI Update] 이동 거리(Offset)를 늘려서 속도감(Velocity) 증가
              : (isNewPage ? -0.08 : 0.08);

          final offsetAnimation = Tween<Offset>(
            begin: Offset(startOffset, 0.0),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: offsetAnimation,
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex), // 키가 바뀌면 애니메이션 발동
          child: _getPage(_selectedIndex),
        ),
      ),
      // [UI Update] 하단 고정 네비게이션 바 (Docked)
      bottomNavigationBar: _buildDockedNavBar(),
      // [New] 피드 탭(5)일 때만 글쓰기 버튼 표시
      floatingActionButton: _selectedIndex == 5 ? _buildWriteFab() : null,
    );
  }

  // 인덱스에 따른 페이지 반환
  Widget _getPage(int index) {
    switch (index) {
      case 0: return KeepAliveWrapper(child: _buildMapTab());
      case 1: return KeepAliveWrapper(child: _buildInvestTab());
      case 2: return KeepAliveWrapper(child: _buildHomeTab());
      case 3: return KeepAliveWrapper(child: _buildBenefitTab());
      case 4: return KeepAliveWrapper(child: _buildMenuTab());
      case 5: return KeepAliveWrapper(child: _buildFeedTab()); // [New] 피드
      case 6: return KeepAliveWrapper(child: _buildWatchlistTab()); // [New] 관심 종목 (Watchlist)
      case 7: return KeepAliveWrapper(child: _buildPlaceholderTab('준비중인 기능입니다')); // [New] TBD
      default: return Container();
    }
  }

  Widget _buildDockedNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withOpacity(0.95), // 거의 불투명한 다크 배경
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), // [UI Update] 양쪽 꼭짓점 둥글게
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), // 블러 효과도 둥글게 잘림
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 블러 효과 (Glassmorphism)
          child: SafeArea(
            child: SizedBox(
              height: 74, // [Fix] 높이를 64 -> 74로 늘려 오버플로우 해결
              child: Material(
                color: Colors.transparent,
                // [UI Update] Stack을 사용하여 자유로운 애니메이션 구현 (샤라락 + 뿅뿅뿅)
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / 5; // 화면을 5등분
                    
                    return Stack(
                      children: [
                        // 1. 메인 모드 아이템들 (투자 버튼 제외)
                        // 사라질 때 작아지며 사라짐 (Scale 1.0 -> 0.0)
                        ..._buildAnimatedItems(
                          isVisible: !_isInvestMode,
                          itemWidth: itemWidth,
                          items: [
                            _NavItemData(0, 0, Icons.map_rounded, '가맹점', _selectedIndex == 0, (i) => _onItemTapped(i)),
                            _NavItemData(2, 2, Icons.home_rounded, '홈', _selectedIndex == 2, (i) => _onItemTapped(i)),
                            _NavItemData(3, 3, Icons.card_giftcard_rounded, '혜택', _selectedIndex == 3, (i) => _onItemTapped(i)),
                            _NavItemData(4, 4, Icons.menu_rounded, '전체', _selectedIndex == 4, (i) => _onItemTapped(i)),
                          ],
                        ),

                        // 2. 투자 모드 아이템들 (투자 버튼 제외)
                        // 나타날 때 뿅! 하고 나타남 (Scale 0.0 -> 1.0)
                        ..._buildAnimatedItems(
                          isVisible: _isInvestMode,
                          itemWidth: itemWidth,
                          items: [
                            _NavItemData(0, 0, Icons.arrow_back_rounded, '뒤로', false, (_) => _onItemTapped(2)), // 뒤로가기 -> 홈
                            _NavItemData(1, 6, Icons.star_rounded, '관심', _selectedIndex == 6, (i) => _onItemTapped(i)), // [UI Update] 관심 탭 아이콘 변경
                            _NavItemData(2, 7, Icons.pending_rounded, '준비중', _selectedIndex == 7, (i) => _onItemTapped(i)),
                            _NavItemData(4, 5, Icons.forum_rounded, '피드', _selectedIndex == 5, (i) => _onItemTapped(i)),
                          ],
                        ),

                        // 3. 주인공: '투자' 버튼 (샤라락 이동)
                        // 메인 모드일 땐 1번 위치, 투자 모드일 땐 3번 위치로 이동
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutBack, // 살짝 지나쳤다 돌아오는 쫀득한 이동
                          left: _isInvestMode ? itemWidth * 3 : itemWidth * 1,
                          top: 0,
                          bottom: 0,
                          width: itemWidth,
                          child: _BouncyNavItem(
                            index: 1,
                            icon: Icons.candlestick_chart_rounded,
                            label: '투자',
                            isSelected: _selectedIndex == 1,
                            onTap: (_) => _onItemTapped(1),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // [Helper] 애니메이션 아이템 리스트 생성
  List<Widget> _buildAnimatedItems({
    required bool isVisible,
    required double itemWidth,
    required List<_NavItemData> items,
  }) {
    return items.map((item) {
      // [UI Update] 순차적 등장을 위한 딜레이 계산 (Interval 사용)
      // 왼쪽(index 0)부터 오른쪽(index 4)으로 순서대로 뿅뿅뿅
      final double start = item.positionIndex * 0.1; // 0.0, 0.1, 0.2 ...
      final double end = start + 0.6; // 애니메이션 길이 확보 (Interval은 0.0 ~ 1.0 사이여야 함)

      return Positioned(
        left: item.positionIndex * itemWidth,
        top: 0,
        bottom: 0,
        width: itemWidth,
        child: AnimatedScale(
          scale: isVisible ? 1.0 : 0.0, // 보일 땐 1, 안 보일 땐 0
          // [UI Update] 전체 시간을 늘리고 Interval로 개별 타이밍 조절
          duration: isVisible ? const Duration(milliseconds: 800) : const Duration(milliseconds: 200),
          curve: isVisible 
              ? Interval(start, end, curve: Curves.elasticOut) // 나타날 땐 순차적으로 뿅!
              : Curves.easeIn, // 사라질 땐 빠르게 슥
          child: AnimatedOpacity(
            opacity: isVisible ? 1.0 : 0.0,
            duration: isVisible ? const Duration(milliseconds: 800) : const Duration(milliseconds: 200),
            curve: isVisible 
                ? Interval(start, end, curve: Curves.easeOut) 
                : Curves.easeIn,
            child: _BouncyNavItem(
              index: item.targetIndex,
              icon: item.icon,
              label: item.label,
              isSelected: item.isSelected,
              onTap: item.onTap,
            ),
          ),
        ),
      );
    }).toList();
  }

  // [UI Component] 글쓰기 버튼 (FAB)
  Widget _buildWriteFab() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80.0), // 네비게이션 바 위로 띄움
      child: FloatingActionButton(
        onPressed: _showWritePostSheet,
        backgroundColor: Colors.white, // [UI Update] 흰색 배경 (Black & White 테마)
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.edit, color: Colors.black), // [UI Update] 검은색 아이콘
      ),
    );
  }

  // [Logic] 글쓰기 바텀 시트 표시
  void _showWritePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 키보드 올라왔을 때 화면 조정
      backgroundColor: Colors.transparent, // [UI Update] 배경 투명하게 (플로팅 효과)
      builder: (context) => _WritePostSheet(
        authorName: _profile?['username'] ?? '익명',
        onPost: (newPost) {
          setState(() {
            _feedPosts.insert(0, newPost);
          });
        },
      ),
    );
  }

  // [Tab 1] 홈 화면 (기존 내용)
  Widget _buildHomeTab() {
    return SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _profile == null
                ? const Center(child: Text('정보를 불러올 수 없습니다.'))
                : CustomScrollView(
                    // 안드로이드에서도 iOS처럼 쫀득하게 당겨지는 물리 효과 적용
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      // iOS 스타일의 당겨서 새로고침 컨트롤 (화면이 같이 내려옴)
                      CupertinoSliverRefreshControl(
                        refreshTriggerPullDistance: 120.0, // 120만큼 당겨야 새로고침 발동 (쫀득한 느낌)
                        refreshIndicatorExtent: 70.0,      // 로고가 돌 때 70 높이에서 딱 고정됨
                        onRefresh: _onRefresh,
                        builder: (context, refreshState, pulledExtent,
                            refreshTriggerPullDistance, refreshIndicatorExtent) {
                          return RefreshLogo(
                            mode: refreshState,
                            pulledExtent: pulledExtent,
                            triggerDistance: refreshTriggerPullDistance,
                          );
                        },
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100), // [UI Update] 하단 여백 추가 (네비게이션 바 가림 방지)
                        sliver: SliverToBoxAdapter(
                          child: _buildHomeContent(_profile!),
                        ),
                      ),
                    ],
                  ),
    );
  }

  Widget _buildHomeContent(Map<String, dynamic> profile) {
    final fullName = profile['full_name'];
    final username = profile['username'] ?? '사용자';
    final balance = profile['balance'] ?? 0;

    // 숫자 포맷팅 (예: 10,000)
    final formattedBalance = NumberFormat('#,###').format(balance);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                  // 1. 상단 헤더 (인사말 + 설정 버튼)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        fullName ?? username, // 실명이 있으면 실명, 없으면 닉네임 표시
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[400],
                          height: 1.3,
                        ),
                      ),
                      // 우측 상단 아이콘 모음 (QR 스캔 + 알림)
                      Row(
                        children: [
                          // [Restored] 내 QR 코드 보기 버튼
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: IconButton(
                              icon: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 26),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const MyQrScreen()),
                                );
                              },
                            ),
                          ),
                          const Gap(0), // 패딩이 추가되었으므로 간격 조정
                          // QR 스캔 버튼
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: IconButton(
                              icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const QrPaymentScreen()),
                                );
                              },
                            ),
                          ),
                          const Gap(0),
                          // 알림 아이콘 (Red Dot 포함)
                          Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IconButton(
                                  icon: const Icon(Icons.notifications, color: Colors.white, size: 28),
                                  onPressed: () async {
                                    // 임시: 로그아웃 기능
                                    await Supabase.instance.client.auth.signOut();
                                  },
                                ),
                              ),
                              // 읽지 않은 알림 점
                              Positioned(
                                right: 14,
                                top: 14,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Gap(32),

                  // 2. 자산 카드 (잔액 + 버튼)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF202025), // 배경보다 살짝 밝은 카드색
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // [Rollback] 터치 효과 제거 (기본 GestureDetector 사용)
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const TransactionHistoryScreen(),
                              ),
                            );
                          },
                          behavior: HitTestBehavior.translucent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '내 포인트',
                                    style: TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                                  const Gap(4),
                                  Icon(Icons.chevron_right, color: Colors.grey[600], size: 16),
                                ],
                              ),
                              const Gap(8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    formattedBalance,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Gap(6),
                                  const Text(
                                    'Loopoint',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Gap(16),
                        // 버튼 영역 (송금만 남김 - QR은 상단으로 이동)
                        Align(
                          alignment: Alignment.centerRight,
                          child: 
                            _SmallActionButton(
                              text: '송금',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const TransferSearchScreen()),
                                );
                              },
                            ),
                        ),
                      ],
                    ),
                  ),
      ],
    );
  }

  // [Tab 2] 지도 (가맹점 찾기) - [New Feature]
  Widget _buildMapTab() {
    // 가맹점 더미 데이터
    final merchants = [
      {'name': '스타벅스 강남R점', 'category': '카페', 'distance': '150m', 'benefit': '5% 적립'},
      {'name': 'GS25 역삼센터점', 'category': '편의점', 'distance': '320m', 'benefit': '3% 적립'},
      {'name': '레브로 트레이딩 센터', 'category': '오피스', 'distance': '1.2km', 'benefit': '월세 결제'},
      {'name': '파리바게뜨 강남대로점', 'category': '베이커리', 'distance': '1.5km', 'benefit': '5% 적립'},
    ];

    return Stack(
      children: [
        // 1. 지도 배경 (Placeholder)
        Container(
          color: const Color(0xFF1C1C1E),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 64, color: Colors.grey[800]),
                const Gap(16),
                Text('지도 데이터를 불러오는 중...', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ),
        // 2. 상단 검색창
        Positioned(
          top: 60,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C35),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white70),
                const Gap(12),
                Text('가맹점, 지역 검색', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              ],
            ),
          ),
        ),
        // 3. 하단 가맹점 리스트 (Bottom Sheet 스타일)
        Positioned(
          bottom: 120, // [UI Fix] 네비게이션 바 위로 띄움 (가림 방지)
          left: 16,
          right: 16,
          child: Container(
            height: 260,
            decoration: const BoxDecoration(
              color: Color(0xFF202025),
              borderRadius: BorderRadius.all(Radius.circular(24)), // 둥근 카드 형태
              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, -5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Gap(20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text('내 주변 가맹점', style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const Gap(12),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), // [UI Update] 인피니티 스크롤
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 100), // [UI Update] 하단 여백 추가
                    itemCount: merchants.length,
                    separatorBuilder: (_, __) => const Gap(16),
                    itemBuilder: (context, index) {
                      final m = merchants[index];
                      return Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.store_mall_directory_rounded, color: Colors.white70),
                          ),
                          const Gap(16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                const Gap(4),
                                Text('${m['category']} · ${m['distance']}', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                              ],
                            ),
                          ),
                          _SmallActionButton(text: m['benefit']!, onTap: () {}),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // [Tab 2] 투자 화면 (News & Signal)
  Widget _buildInvestTab() {
    // [UI Update] 차트와 복합적인 UI를 위해 별도 위젯으로 분리
    return const _InvestTabContent();
  }

  // [Tab 3] 혜택 화면 (Gamification)
  Widget _buildBenefitTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('혜택 & 게임', style: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const Gap(24),
            // 승부예측 게임
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF202025),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('승부예측', style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Text('LIVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const Gap(12),
                  Text('내일 GBP/USD가 오를까 내릴까?', style: GoogleFonts.notoSans(fontSize: 16, color: Colors.white)),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(child: _SmallActionButton(text: '오른다 (Up)', onTap: () {})),
                      const Gap(12),
                      Expanded(child: _SmallActionButton(text: '내린다 (Down)', onTap: () {})),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(16),
            // 랜덤박스
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF202025),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard, color: Colors.amber, size: 32),
                  const Gap(16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('랜덤박스 열기', style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Gap(4),
                      Text('1,000P로 최대 10만P 당첨 기회!', style: GoogleFonts.notoSans(fontSize: 14, color: Colors.grey[400])),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(100), // [UI Update] 하단 여백 확보
          ],
        ),
      ),
    );
  }

  // [Tab 4] 전체 메뉴 (Menu)
  Widget _buildMenuTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // [UI Update] 하단 여백 추가
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('전체 메뉴', style: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const Gap(32),
            _buildMenuItem(Icons.person_outline, '내 정보'),
            _buildMenuItem(Icons.history, '거래 내역', onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()));
            }),
            _buildMenuItem(Icons.settings_outlined, '설정'),
            _buildMenuItem(Icons.headset_mic_outlined, '고객센터'),
            const Spacer(),
            TextButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
              },
              child: const Text('로그아웃', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  // [Tab 5] 피드 화면 (투자 커뮤니티)
  Widget _buildFeedTab() {
    // [Logic] 정렬 및 필터링 로직
    final now = DateTime.now();
    List<Map<String, dynamic>> filteredPosts;

    if (_feedSortOption == '최신순') {
      // [Logic] 최신순: 모든 글을 시간 역순으로 정렬
      filteredPosts = List.from(_feedPosts);
      filteredPosts.sort((a, b) {
        final dtA = a['dateTime'] as DateTime;
        final dtB = b['dateTime'] as DateTime;
        return dtB.compareTo(dtA); // 최신순
      });
    } else {
      // [Logic] 기간별 인기순: 기간 필터링 + (좋아요+댓글) 순 정렬
      filteredPosts = _feedPosts.where((post) {
        final dt = post['dateTime'] as DateTime;
        if (_feedSortOption == '오늘') {
          return dt.year == now.year && dt.month == now.month && dt.day == now.day;
        } else if (_feedSortOption == '이번 주') {
          return dt.isAfter(now.subtract(const Duration(days: 7)));
        } else {
          // 이번 달
          return dt.year == now.year && dt.month == now.month;
        }
      }).toList();

      filteredPosts.sort((a, b) {
        final scoreA = (a['likes'] as int) + (a['comments'] as int);
        final scoreB = (b['likes'] as int) + (b['comments'] as int);
        return scoreB.compareTo(scoreA); // 인기순 내림차순
      });
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('투자 피드', style: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const Gap(24),
            // [New] 정렬 필터 탭 (Chips)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['최신순', '오늘', '이번 주', '이번 달'].map((option) {
                  final isSelected = _feedSortOption == option;
                  return GestureDetector(
                    onTap: () => setState(() => _feedSortOption = option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : const Color(0xFF2C2C35),
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? null : Border.all(color: Colors.white10),
                        boxShadow: isSelected ? [
                          BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))
                        ] : [],
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.grey[400],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Gap(16),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150), // [UI Update] 더 빠르게 전환 (300ms -> 150ms)
                switchInCurve: Curves.easeOutQuad,
                switchOutCurve: Curves.easeInQuad,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.05), // 아래에서 살짝 올라옴
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: ListView.separated(
                  key: ValueKey(_feedSortOption), // 정렬 기준이 바뀌면 애니메이션 발동
                  padding: const EdgeInsets.only(bottom: 100),
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), // [UI Update] 인피니티 스크롤
                  itemCount: filteredPosts.length,
                  separatorBuilder: (_, __) => const Gap(16),
                  itemBuilder: (context, index) => _buildFeedItem(filteredPosts[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedItem(Map<String, dynamic> post) {
    final dt = post['dateTime'] as DateTime;
    final diff = DateTime.now().difference(dt);
    String timeString;
    if (diff.inMinutes < 60) {
      timeString = '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      timeString = '${diff.inHours}시간 전';
    } else {
      timeString = '${diff.inDays}일 전';
    }

    final isLiked = post['isLiked'] as bool;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF202025),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: Colors.grey[800], child: const Icon(Icons.person, size: 16, color: Colors.white)),
              const Gap(8),
              Text('@${post['author']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // [UI Update] @닉네임 포맷
              const Spacer(),
              Text(timeString, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const Gap(8),
          Text(post['content'], style: const TextStyle(color: Colors.white70, height: 1.4)),
          const Gap(12),
          Row(
            children: [
              // [Interaction] 좋아요 버튼
              GestureDetector(
                onTap: () {
                  setState(() {
                    post['isLiked'] = !isLiked;
                    if (post['isLiked']) {
                      post['likes']++;
                    } else {
                      post['likes']--;
                    }
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isLiked ? Colors.redAccent : Colors.grey[500],
                    ),
                    const Gap(4),
                    Text('${post['likes']}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              const Gap(16),
              // [Interaction] 댓글 버튼 (간단히 카운트 증가 시뮬레이션)
              GestureDetector(
                onTap: () {
                  setState(() => post['comments']++);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글을 달았습니다! (Demo)'), duration: Duration(milliseconds: 500)));
                },
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey[500]),
                    const Gap(4),
                    Text('${post['comments']}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // [Tab 6] 관심 종목 (Watchlist)
  Widget _buildWatchlistTab() {
    final username = _profile?['username'] ?? '사용자';

    return SafeArea(
      child: DefaultTabController(
        length: 4, // 최근 본, 주식, 외환, 코인
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Text('관심', style: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Gap(12),
                  // [New] 자물쇠처럼 돌아가는 시세 티커
                  Container(
                    height: 36,
                    alignment: Alignment.centerLeft,
                    child: const _RollingTickerWidget(),
                  ),
                ],
              ),
            ),
            const Gap(16),
            // [New] 서브 탭 (최근 본, 주식, 외환, 코인)
            TabBar(
              isScrollable: true,
              indicatorColor: Colors.white, // [Fix] 흰색 언더바 복구
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 16),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: '전체'),
                Tab(text: '주식'),
                Tab(text: '외환'),
                Tab(text: '코인'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // 1. 전체
                  _buildWatchlist(username, null),
                  // 2. 주식
                  _buildWatchlist(username, '주식'),
                  // 3. 외환
                  _buildWatchlist(username, '외환'),
                  // 4. 코인
                  _buildWatchlist(username, '코인'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [Component] 관심 종목 리스트
  Widget _buildWatchlist(String username, String? category) {
    // [Logic] 카테고리 필터링
    final filteredList = category == null
        ? _watchlist
        : _watchlist.where((item) => item['category'] == category).toList();

    if (filteredList.isEmpty) {
      return _buildEmptyWatchlist(username, category);
    }

    // [UX Update] Footer를 사용하여 리스트 끝에 버튼 부착 (스크롤 함께 이동, 드래그 간섭 없음)
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      buildDefaultDragHandles: false, // [Fix] 기본 핸들(가로선) 제거 -> 커스텀 핸들(점6개)만 사용
      itemCount: filteredList.length,
      
      // [UI Update] 드래그 애니메이션 다듬기 (부드러운 Lift & Drop)
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            // [UI Update] 쫀득하고 부드러운 애니메이션 커브 적용
            final double animValue = Curves.easeOutCubic.transform(animation.value);
            final double scale = lerpDouble(1.0, 1.05, animValue)!;
            
            // [Fix] 어색한 그림자(Margin 영역 표시)를 제거하고 깔끔하게 크기만 조절
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: child,
        );
      },

      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }

          if (category == null) {
            // 전체 탭: 단순 이동
            final item = _watchlist.removeAt(oldIndex);
            _watchlist.insert(newIndex, item);
          } else {
            // 카테고리 탭: 해당 카테고리 아이템들만 추출하여 순서 변경 후 원본에 반영
            List<int> originalIndices = [];
            List<Map<String, dynamic>> categoryItems = [];
            
            for (int i = 0; i < _watchlist.length; i++) {
              if (_watchlist[i]['category'] == category) {
                originalIndices.add(i);
                categoryItems.add(_watchlist[i]);
              }
            }

            // 서브 리스트에서 순서 변경
            final item = categoryItems.removeAt(oldIndex);
            categoryItems.insert(newIndex, item);

            // 원본 리스트에 변경된 순서대로 다시 배치 (원래 있던 자리들에 덮어쓰기)
            for (int i = 0; i < originalIndices.length; i++) {
              _watchlist[originalIndices[i]] = categoryItems[i];
            }
          }
        });
      },

      // [UI Update] 리스트 맨 아래에 '종목 추가하기' 버튼 (Footer)
      footer: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: TextButton.icon(
          onPressed: () => _openSymbolSearch(category),
          icon: const Icon(Icons.add, color: Colors.grey),
          label: const Text('종목 추가하기', style: TextStyle(color: Colors.grey)),
        ),
      ),

      itemBuilder: (context, index) {
        final item = filteredList[index];
        final isUp = item['isUp'] as bool;
        final color = isUp ? const Color(0xFFF04452) : const Color(0xFF3182F6);

        return Container(
          key: Key(item['symbol']), // ReorderableListView 필수 키
          margin: const EdgeInsets.only(bottom: 12), // 아이템 간격
          child: Dismissible(
            key: Key(item['symbol']),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              // [Logic] 실제 리스트에서 삭제
              final originalIndex = _watchlist.indexOf(item);
              setState(() {
                _watchlist.remove(item);
              });
              
              // [UI Update] 트렌디한 삭제 알림 (Floating SnackBar)
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
                      const Gap(12),
                      Text('${item['name']} 삭제됨', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF333338),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 100), // 네비게이션 바 위로 띄움
                  action: SnackBarAction(
                    label: '실행 취소',
                    textColor: const Color(0xFF3182F6),
                    onPressed: () => setState(() => _watchlist.insert(originalIndex, item)),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withOpacity(0.2), // 은은한 빨간 배경
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF202025),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // 로고 (더미)
                  CircleAvatar(
                    backgroundColor: Colors.grey[800],
                    child: Text(item['symbol'][0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['symbol'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(item['name'], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(item['price'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(item['change'], style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12)),
                    ],
                  ),
                  const Gap(16),
                  // [UI Update] 드래그 핸들 아이콘 (시각적 힌트)
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(Icons.drag_indicator, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // [Component] 관심 종목 빈 화면 (Empty State)
  Widget _buildEmptyWatchlist(String username, String? category) {
    final categoryText = category != null ? '$category ' : '';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF202025),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Icon(Icons.add_rounded, size: 40, color: Colors.grey[600]),
          ),
          const Gap(24),
          Text(
            '$username님이\n눈여겨 보던 ${categoryText}종목을 추가해 주세요.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const Gap(32),
          ElevatedButton(
            onPressed: () => _openSymbolSearch(category),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('찾아보기', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Gap(80), // 하단 네비게이션 바 공간 확보
        ],
      ),
    );
  }

  // [Logic] 종목 검색 화면 열기
  Future<void> _openSymbolSearch(String? category) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => SymbolSearchScreen(initialCategory: category)),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        // 중복 체크 후 추가
        if (!_watchlist.any((item) => item['symbol'] == result['symbol'])) {
          _watchlist.add(result);
        }
      });
    }
  }

  // [Tab 6, 7] 준비중 화면
  Widget _buildPlaceholderTab(String text) {
    return Center(
      child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 16)),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const Gap(16),
            Text(title, style: GoogleFonts.notoSans(fontSize: 18, color: Colors.white)),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}

// [Screen] 종목 검색 화면
class SymbolSearchScreen extends StatefulWidget {
  final String? initialCategory; // [New] 초기 카테고리 필터

  const SymbolSearchScreen({super.key, this.initialCategory});

  @override
  State<SymbolSearchScreen> createState() => _SymbolSearchScreenState();
}

class _SymbolSearchScreenState extends State<SymbolSearchScreen> {
  final _searchController = TextEditingController();
  
  // 더미 데이터 (실제 API 대신 사용)
  final List<Map<String, dynamic>> _allSymbols = [
    {'symbol': 'BTC/USD', 'name': 'Bitcoin', 'price': '98,240.50', 'change': '+3.5%', 'isUp': true, 'category': '코인'},
    {'symbol': 'ETH/USD', 'name': 'Ethereum', 'price': '3,500.20', 'change': '-1.2%', 'isUp': false, 'category': '코인'},
    {'symbol': 'AAPL', 'name': 'Apple Inc.', 'price': '182.40', 'change': '+0.5%', 'isUp': true, 'category': '주식'},
    {'symbol': 'TSLA', 'name': 'Tesla', 'price': '175.30', 'change': '-2.5%', 'isUp': false, 'category': '주식'},
    {'symbol': 'XAU/USD', 'name': 'Gold', 'price': '2,340.10', 'change': '+0.8%', 'isUp': true, 'category': '외환'},
    {'symbol': 'NVDA', 'name': 'NVIDIA', 'price': '880.10', 'change': '+5.2%', 'isUp': true, 'category': '주식'},
    {'symbol': 'USD/KRW', 'name': 'US Dollar', 'price': '1,350.00', 'change': '+0.1%', 'isUp': true, 'category': '외환'},
    {'symbol': 'SOL/USD', 'name': 'Solana', 'price': '145.20', 'change': '+10.5%', 'isUp': true, 'category': '코인'},
  ];

  List<Map<String, dynamic>> _filteredSymbols = [];

  @override
  void initState() {
    super.initState();
    // [Logic] 초기 카테고리가 있으면 해당 카테고리만 먼저 보여줌
    if (widget.initialCategory != null) {
      _filteredSymbols = _allSymbols.where((item) => item['category'] == widget.initialCategory).toList();
    } else {
      _filteredSymbols = _allSymbols;
    }
  }

  void _filterSymbols(String query) {
    setState(() {
      if (query.isEmpty) {
        // 검색어 없으면 초기 카테고리 필터 유지
        if (widget.initialCategory != null) {
          _filteredSymbols = _allSymbols.where((item) => item['category'] == widget.initialCategory).toList();
        } else {
          _filteredSymbols = _allSymbols;
        }
      } else {
        _filteredSymbols = _allSymbols.where((item) {
          final symbol = item['symbol'].toString().toLowerCase();
          final name = item['name'].toString().toLowerCase();
          final q = query.toLowerCase();
          
          // 카테고리 필터가 있다면 그것도 만족해야 함 (선택 사항: 검색 시엔 전체에서 찾게 할 수도 있음. 여기선 전체 검색 허용)
          // 사용자가 '주식' 탭에서 왔더라도 검색하면 '코인'도 찾을 수 있게 하는 것이 UX상 더 유연함.
          // 하지만 탭의 목적성을 위해 필터를 유지하고 싶다면 아래 주석 해제
          // if (widget.initialCategory != null && item['category'] != widget.initialCategory) return false;

          return (symbol.contains(q) || name.contains(q));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('종목 검색', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: _filterSymbols,
              decoration: InputDecoration(
                hintText: '심볼 또는 이름 검색 (예: BTC, Apple)',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF202025),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _filteredSymbols.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xFF202025), height: 1),
              itemBuilder: (context, index) {
                final item = _filteredSymbols[index];
                return ListTile(
                  onTap: () {
                    Navigator.pop(context, item); // 선택한 종목 전달하며 닫기
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF202025),
                    child: Text(item['symbol'][0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(item['symbol'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(item['name'], style: TextStyle(color: Colors.grey[500])),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(item['price'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(
                        item['change'],
                        style: TextStyle(
                          color: item['isUp'] ? const Color(0xFFF04452) : const Color(0xFF3182F6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// [New Feature] 투자 탭 컨텐츠 (차트 + 뉴스)
class _InvestTabContent extends StatefulWidget {
  const _InvestTabContent();

  @override
  State<_InvestTabContent> createState() => _InvestTabContentState();
}

class _InvestTabContentState extends State<_InvestTabContent> {
  String _selectedAsset = 'BTC/USD';
  late List<CandleData> _candles;
  Timer? _timer; // [New] 실시간 차트 시뮬레이션용 타이머

  @override
  void initState() {
    super.initState();
    _generateDummyData();
    _startLiveSimulation(); // [New] 차트 움직임 시작
  }

  @override
  void dispose() {
    _timer?.cancel(); // [New] 타이머 해제
    super.dispose();
  }

  // [Logic] 그럴듯한 랜덤 차트 데이터 생성
  void _generateDummyData() {
    final List<CandleData> data = [];
    double price = 65000.0;
    final now = DateTime.now();
    final random = math.Random();

    for (int i = 0; i < 60; i++) {
      final time = now.subtract(Duration(minutes: 60 - i));
      final movement = (random.nextDouble() - 0.5) * 200;
      final open = price;
      final close = price + movement;
      final high = math.max(open, close) + random.nextDouble() * 50;
      final low = math.min(open, close) - random.nextDouble() * 50;
      
      data.add(CandleData(
        time: time,
        open: open,
        high: high,
        low: low,
        close: close,
      ));
      price = close;
    }
    _candles = data;
  }

  // [Logic] 실시간 가격 변동 시뮬레이션 (Ticking)
  void _startLiveSimulation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) return;
      setState(() {
        final last = _candles.last;
        final random = math.Random();
        
        // 자산별 변동성 조정 (비트코인은 크게, 달러는 작게)
        double volatility = 50.0;
        if (_selectedAsset.contains('EUR')) volatility = 0.0005;
        else if (_selectedAsset.contains('AAPL')) volatility = 0.5;
        else if (_selectedAsset.contains('XAU')) volatility = 2.0;

        // 랜덤 워크 (Random Walk)
        final move = (random.nextDouble() - 0.5) * volatility;
        double newClose = last.close + move;
        
        // 고가/저가 갱신 로직
        double newHigh = math.max(last.high, newClose);
        double newLow = math.min(last.low, newClose);

        // 마지막 캔들 업데이트
        _candles.last = CandleData(
          time: last.time,
          open: last.open,
          high: newHigh,
          low: newLow,
          close: newClose,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), // [UI Update] 인피니티 스크롤
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('투자 인사이트', style: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Gap(24),
                  // 자산 선택 탭
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['BTC/USD', 'XAU/USD', 'AAPL', 'EUR/USD'].map((asset) {
                        final isSelected = _selectedAsset == asset;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAsset = asset;
                              _generateDummyData(); // 자산 변경 시 데이터 재생성 시뮬레이션
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : const Color(0xFF2C2C35),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              asset,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.grey[400],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Gap(24),
                  // [New] 캔들 차트 영역
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_selectedAsset, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              NumberFormat('#,##0.00').format(_candles.last.close),
                              style: TextStyle(
                                color: _candles.last.close >= _candles.last.open ? const Color(0xFF3182F6) : const Color(0xFFFF5252),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const Gap(16),
                        Expanded(
                          // [Performance] RepaintBoundary로 차트 렌더링 격리 (렉 방지 핵심)
                          child: RepaintBoundary(
                            child: _CandleChart(data: _candles),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),
                  // VIP 시그널 카드 (기존 유지)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3182F6), Color(0xFF0B4898)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, color: Colors.white, size: 32),
                        const Gap(16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('VIP 트레이딩 시그널', style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const Gap(4),
                            Text('상위 1% 트레이더의 포지션 공개', style: GoogleFonts.notoSans(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),
                  Text('프리미엄 뉴스', style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Gap(16),
                ],
              ),
            ),
          ),
          // 뉴스 리스트
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25252B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ['GBP/USD 급등 가능성 분석', '이번 주 주요 경제 지표 정리', '비트코인 반감기 이후 전망'][index],
                          style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const Gap(8),
                        const Text('500P로 전체 보기', style: TextStyle(color: Color(0xFF3182F6), fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
                childCount: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// [Component] 고성능 캔들 차트 위젯 (CustomPainter 사용)
class _CandleChart extends StatelessWidget {
  final List<CandleData> data;

  const _CandleChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CandlePainter(data),
      size: Size.infinite,
    );
  }
}

class _CandlePainter extends CustomPainter {
  final List<CandleData> data;
  _CandlePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // 1. 스케일 계산
    final double candleWidth = size.width / data.length;
    final double maxPrice = data.map((e) => e.high).reduce(math.max);
    final double minPrice = data.map((e) => e.low).reduce(math.min);
    final double priceRange = maxPrice - minPrice;

    final paint = Paint()..style = PaintingStyle.fill;

    // 2. 캔들 그리기
    for (int i = 0; i < data.length; i++) {
      final candle = data[i];
      final isUp = candle.close >= candle.open;
      
      // 색상: 상승(파랑), 하락(빨강) - Loop 테마에 맞춤
      paint.color = isUp ? const Color(0xFF3182F6) : const Color(0xFFFF5252);

      final x = i * candleWidth + (candleWidth * 0.1); // 약간의 간격
      final w = candleWidth * 0.8;

      // Y좌표 변환 (가격 -> 픽셀)
      double getY(double price) => size.height - ((price - minPrice) / priceRange * size.height);

      // 꼬리 (High - Low)
      canvas.drawLine(
        Offset(x + w / 2, getY(candle.high)),
        Offset(x + w / 2, getY(candle.low)),
        paint..strokeWidth = 1,
      );

      // 몸통 (Open - Close)
      final top = getY(math.max(candle.open, candle.close));
      final bottom = getY(math.min(candle.open, candle.close));
      // 몸통 높이가 0이어도 최소 1픽셀은 보이게
      final height = math.max(1.0, bottom - top);

      canvas.drawRect(Rect.fromLTWH(x, top, w, height), paint);
    }

    // 3. 현재가 라인 (점선 효과 시뮬레이션)
    final lastCloseY = size.height - ((data.last.close - minPrice) / priceRange * size.height);
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(Offset(0, lastCloseY), Offset(size.width, lastCloseY), linePaint);
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) => true; // 데이터가 바뀌면 다시 그림
}

class CandleData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  CandleData({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });
}

// [Component] 자물쇠처럼 돌아가는 시세 티커
class _RollingTickerWidget extends StatefulWidget {
  const _RollingTickerWidget();

  @override
  State<_RollingTickerWidget> createState() => _RollingTickerWidgetState();
}

class _RollingTickerWidgetState extends State<_RollingTickerWidget> {
  int _currentIndex = 0;
  Timer? _timer;

  // 더미 시세 데이터
  final List<Map<String, dynamic>> _tickers = [
    {'symbol': 'BTC/USD', 'price': '98,240.50', 'change': '+3.5%', 'isUp': true},
    {'symbol': 'AAPL', 'price': '182.40', 'change': '-1.2%', 'isUp': false},
    {'symbol': 'EUR/USD', 'price': '1.0845', 'change': '+0.1%', 'isUp': true},
    {'symbol': 'XAU/USD', 'price': '2,340.10', 'change': '+0.8%', 'isUp': true},
    {'symbol': 'TSLA', 'price': '175.30', 'change': '-2.5%', 'isUp': false},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _tickers.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticker = _tickers[_currentIndex];
    final isUp = ticker['isUp'] as bool;
    final color = isUp ? const Color(0xFFF04452) : const Color(0xFF3182F6); // 빨강(상승), 파랑(하락)

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200), // [UI Update] 더 빠르게 (샥)
      // [Fix] 애니메이션 중 텍스트가 가운데로 쏠리는 현상 방지 (왼쪽 정렬 고정)
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.centerLeft,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        // [UI Update] 정육각형이 굴러가는 듯한 3D Rolling 효과
        final rotateAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOutQuad), // 부드럽고 빠른 회전
        );

        return AnimatedBuilder(
          animation: rotateAnim,
          child: child,
          builder: (context, child) {
            // 들어오는 위젯인지 나가는 위젯인지 판별
            final isNew = child!.key == ValueKey(_currentIndex);
            final value = rotateAnim.value;
            // [Fix] Opacity는 0.0 ~ 1.0 사이여야 함 (Curve가 범위를 벗어날 수 있으므로 clamp 처리)
            final opacity = value.clamp(0.0, 1.0);
            
            // 육각형 회전 각도 (60도) 및 이동 거리
            final angle = math.pi / 3;
            final offset = 20.0;

            if (isNew) {
              // [In] 밑에서 올라옴 (Bottom -> Center)
              // 시작: 아래에 위치, 위쪽이 앞으로 기울어짐 (-60도)
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002) // 원근감 강화
                  ..translate(0.0, (1 - value) * offset, 0.0) // 아래에서 위로
                  ..rotateX(-(1 - value) * angle), // 누워있다가 서서히 일어남
                alignment: Alignment.bottomLeft, // [Fix] 회전 축도 왼쪽으로 고정
                child: Opacity(opacity: opacity, child: child),
              );
            } else {
              // [Out] 위로 올라감 (Center -> Top)
              // 끝: 위에 위치, 위쪽이 뒤로 넘어감 (+60도)
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..translate(0.0, (1 - value) * -offset, 0.0) // 위로 이동
                  ..rotateX((1 - value) * angle), // 서있다가 뒤로 넘어감
                alignment: Alignment.topLeft, // [Fix] 회전 축도 왼쪽으로 고정
                child: Opacity(opacity: opacity, child: child),
              );
            }
          },
        );
      },
      child: Row(
        key: ValueKey<int>(_currentIndex), // 키가 바뀌면 애니메이션 발동
        mainAxisSize: MainAxisSize.min, // [UI Update] 옹기종기 모으기
        crossAxisAlignment: CrossAxisAlignment.baseline, // [UI Update] 글자 라인 맞추기
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(ticker['symbol'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, height: 1.2)),
          const Gap(8),
          Text(ticker['price'], style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 15, height: 1.2)),
          const Gap(6),
          Text(ticker['change'], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15, height: 1.2)), // [UI Update] 크기 및 줄간격 통일
        ],
      ),
    );
  }
}

// [Component] 글쓰기 바텀 시트 (StatefulWidget으로 분리하여 상태 관리 및 멈춤 현상 방지)
class _WritePostSheet extends StatefulWidget {
  final String authorName;
  final Function(Map<String, dynamic>) onPost;

  const _WritePostSheet({
    required this.authorName,
    required this.onPost,
  });

  @override
  State<_WritePostSheet> createState() => _WritePostSheetState();
}

class _WritePostSheetState extends State<_WritePostSheet> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // 키보드 높이만큼 패딩
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E), // 깊은 다크 그레이
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SingleChildScrollView(
          // [Fix] 스크롤 뷰로 감싸서 키보드 올라왔을 때 레이아웃 오버플로우 및 멈춤 현상 방지
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 핸들바
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(24),
              // 헤더 (취소 - 제목 - 등록)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('취소', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                  ),
                  Text('새 게시글', style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  GestureDetector(
                    onTap: () {
                      if (_textController.text.isNotEmpty) {
                        widget.onPost({
                          'author': widget.authorName,
                          'dateTime': DateTime.now(),
                          'content': _textController.text,
                          'likes': 0,
                          'comments': 0,
                          'isLiked': false,
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '등록',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(24),
              // 입력창
              TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                maxLines: 8,
                minLines: 4,
                decoration: InputDecoration(
                  hintText: '투자에 대한 생각을 자유롭게 나누세요.\n#비트코인 #테슬라 #매수타이밍',
                  hintStyle: TextStyle(color: Colors.grey[700], fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const Gap(16),
            ],
          ),
        ),
      ),
    );
  }
}

// [Data Class] 네비게이션 아이템 정보
class _NavItemData {
  final int positionIndex; // 화면상 위치 (0~4)
  final int targetIndex;   // 실제 탭 인덱스
  final IconData icon;
  final String label;
  final bool isSelected;
  final Function(int) onTap;

  _NavItemData(this.positionIndex, this.targetIndex, this.icon, this.label, this.isSelected, this.onTap);
}

// [Component] 찰랑거리는(Boing) 애니메이션 탭 버튼
class _BouncyNavItem extends StatefulWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isSelected;
  final Function(int) onTap;

  const _BouncyNavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_BouncyNavItem> createState() => _BouncyNavItemState();
}

class _BouncyNavItemState extends State<_BouncyNavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _controller.value = 1.0; // 기본 크기 (1.0)
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHighlight(bool isPressed) {
    if (isPressed) {
      // 눌렀을 때: 젤리처럼 꾹 눌림 (0.75배)
      _controller.animateTo(0.75, duration: const Duration(milliseconds: 150), curve: Curves.easeInOut);
    } else {
      // 뗐을 때: 띠요옹~ 하고 튕김 (ElasticOut)
      _controller.animateTo(1.0, duration: const Duration(milliseconds: 800), curve: Curves.elasticOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    // [UI Update] Expanded 제거 (Stack 내부에서 크기 제어)
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onTap(widget.index),
          onHighlightChanged: _handleHighlight,
          borderRadius: BorderRadius.circular(16), // 하이라이트 모양을 둥글게
          splashColor: Colors.white.withOpacity(0.1), // 은은한 물결
          highlightColor: Colors.white.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // [Fix] 오버플로우 방지를 위해 패딩 미세 조정
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _controller.value,
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    color: widget.isSelected ? Colors.white : Colors.grey[600],
                    size: 26,
                  ),
                  const Gap(4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.isSelected ? Colors.white : Colors.grey[600],
                      fontSize: 10,
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// [Component] 눌렀을 때 살짝 작아지는 쫀득한 터치 위젯 (공용)
class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleTap({
    required this.child,
    required this.onTap,
  });

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.96); // 4% 축소
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    // 애니메이션을 눈으로 확인할 수 있도록 아주 짧은 딜레이 후 실행
    Future.delayed(const Duration(milliseconds: 80), widget.onTap);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.translucent,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}

// [Component] 탭 상태 유지를 위한 래퍼
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

class _SmallActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // [UI Update] 버튼 내부 여백 확장
        decoration: BoxDecoration(
          color: const Color(0xFF333338), // 은은한 버튼색
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
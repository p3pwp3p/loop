import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection; // TextDirection 충돌 방지
import 'package:loop_app/features/history/transaction_detail_screen.dart';
import 'package:loop_app/features/home/loop_logo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _userId = Supabase.instance.client.auth.currentUser!.id;
  final _scrollController = ScrollController();
  
  final List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  final int _limit = 20; // 한 번에 불러올 개수

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 스크롤이 바닥에서 200px 남았을 때 다음 데이터 로드
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchTransactions();
    }
  }

  Future<void> _fetchTransactions({bool isRefresh = false}) async {
    if (!isRefresh && (_isLoading || !_hasMore)) return;

    if (!isRefresh) setState(() => _isLoading = true);

    try {
      final start = _transactions.length;
      final end = start + _limit - 1;

      final data = await Supabase.instance.client
          .from('transactions')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false)
          .range(start, end); // 범위 지정 (Pagination)
      
      final List<Map<String, dynamic>> newTransactions = List<Map<String, dynamic>>.from(data);

      if (mounted) {
        setState(() {
          _transactions.addAll(newTransactions);
          if (newTransactions.length < _limit) {
            _hasMore = false; // 더 이상 불러올 데이터가 없음
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _transactions.clear();
      _hasMore = true; 
      _isLoading = true; // 즉시 로딩 상태로 변경하여 스켈레톤 UI 표시 (끊김 방지)
    });
    await _fetchTransactions(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('최근 내역', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0), // [UI Update] 뒤로가기 버튼 여백 확보
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            splashColor: Colors.transparent, // 물결 효과 제거
            highlightColor: Colors.transparent, // 하이라이트 제거
            hoverColor: Colors.transparent, // 호버 잔상 제거
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverRefreshControl(
                  refreshTriggerPullDistance: 120.0,
                  refreshIndicatorExtent: 70.0,
                  onRefresh: _refresh,
                  builder: (context, refreshState, pulledExtent,
                      refreshTriggerPullDistance, refreshIndicatorExtent) {
                    return RefreshLogo(
                      mode: refreshState,
                      pulledExtent: pulledExtent,
                      triggerDistance: refreshTriggerPullDistance,
                    );
                  },
                ),
                // [UI Update] 로딩 중이거나 데이터가 없을 때 처리
                if (_transactions.isEmpty)
                  if (_isLoading)
                    // 1. 로딩 중일 때: 스켈레톤(Shimmer) 애니메이션 표시 (토스 스타일)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const _SkeletonTransactionItem(),
                          childCount: 10, // 화면을 꽉 채울 만큼 충분한 개수 생성
                        ),
                      ),
                    )
                  else
                    // 2. 데이터가 없을 때: 안내 문구 표시
                    const SliverFillRemaining(
                      child: Center(
                        child: Text('거래 내역이 없습니다.', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                else
                  // 3. 데이터가 있을 때: 실제 리스트 표시
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == _transactions.length) {
                            return const Center(
                                child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator()));
                          }

                          final tx = _transactions[index];
              final amount = tx['amount'] as int;
              final rawDescription = tx['description'] as String? ?? '거래';
              final createdAt = DateTime.parse(tx['created_at']).toLocal();
              
              final isPositive = amount > 0;
              final formattedAmount = NumberFormat('#,###').format(amount.abs());
              final dateStr = DateFormat('MM.dd HH:mm').format(createdAt);

              // "송금 보냄: 홍길동" -> "홍길동"으로 파싱
              String displayTitle = rawDescription;
              if (rawDescription.startsWith('송금 보냄: ')) {
                displayTitle = rawDescription.replaceFirst('송금 보냄: ', '');
              } else if (rawDescription.startsWith('송금 받음: ')) {
                displayTitle = rawDescription.replaceFirst('송금 받음: ', '');
              }

              return Column(
                children: [
                  _ScaleTransactionItem(
                    title: displayTitle,
                    subtitle: dateStr,
                    amount: '${isPositive ? '+' : '-'}$formattedAmount P',
                    isPositive: isPositive,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true, // 내용물 크기에 맞게 높이 조절
                        backgroundColor: Colors.transparent, // 배경 투명 (라운딩 처리를 위해)
                        builder: (context) => TransactionDetailScreen(transaction: tx),
                      );
                    },
                  ),
                  if (index < _transactions.length - 1)
                    const Divider(color: Color(0xFF333338), height: 32),
                ],
              );
                        },
                        childCount: _transactions.length + (_hasMore ? 1 : 0),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ScaleTransactionItem extends StatefulWidget {
  final String title;
  final String subtitle;
  final String amount;
  final bool isPositive;
  final VoidCallback onTap;

  const _ScaleTransactionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isPositive,
    required this.onTap,
  });

  @override
  State<_ScaleTransactionItem> createState() => _ScaleTransactionItemState();
}

class _ScaleTransactionItemState extends State<_ScaleTransactionItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.04, // 4% 축소
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        // 쫀득한 모션을 눈으로 확인할 수 있도록 약간의 딜레이 후 실행
        Future.delayed(const Duration(milliseconds: 80), widget.onTap);
      },
      onTapCancel: () => _controller.reverse(),
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - _controller.value,
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                widget.amount,
                style: TextStyle(
                  color: widget.isPositive ? const Color(0xFF3182F6) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// [Component] 로딩 중일 때 보여줄 스켈레톤 아이템 (Shimmer Effect)
class _SkeletonTransactionItem extends StatefulWidget {
  const _SkeletonTransactionItem();

  @override
  State<_SkeletonTransactionItem> createState() => _SkeletonTransactionItemState();
}

class _SkeletonTransactionItemState extends State<_SkeletonTransactionItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 물결이 지나가는 애니메이션 (무한 반복)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0), // Divider 높이 고려하여 간격 조정
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  Color(0xFF202025), // 기본 배경색 (어두운 회색)
                  Color(0xFF333338), // 하이라이트 색 (조금 더 밝은 회색)
                  Color(0xFF202025),
                ],
                stops: const [0.1, 0.5, 0.9],
                // 애니메이션 값에 따라 그라데이션 위치 이동 (-1.0 ~ 2.0 범위로 이동하여 자연스럽게)
                transform: _ShimmerTransform(_controller.value),
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: child,
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 스켈레톤
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF202025),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 날짜 스켈레톤
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF202025),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // 금액 스켈레톤
            Container(
              width: 100,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF202025),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerTransform extends GradientTransform {
  final double percent;
  const _ShimmerTransform(this.percent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      (bounds.width * 2) * percent - bounds.width,
      0.0,
      0.0,
    );
  }
}
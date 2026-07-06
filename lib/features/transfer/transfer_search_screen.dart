import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:loop_app/features/transfer/transfer_amount_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransferSearchScreen extends StatefulWidget {
  const TransferSearchScreen({super.key});

  @override
  State<TransferSearchScreen> createState() => _TransferSearchScreenState();
}

class _TransferSearchScreenState extends State<TransferSearchScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  final _myUserId = Supabase.instance.client.auth.currentUser!.id;

  // 검색 로직
  Future<void> _searchUser(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // profiles 테이블에서 닉네임이 포함된 유저 검색 (나 자신은 제외)
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,full_name.ilike.%$query%') // 닉네임 또는 실명으로 검색
          .neq('id', _myUserId) // 나 자신은 제외
          .limit(10); // 최대 10명까지만 표시

      if (mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      // 에러 처리 (조용히 넘어가거나 로그 출력)
      debugPrint('검색 에러: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('받는 사람 찾기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0), // 홈(24)보다 살짝 더 안쪽으로 모음 (표준 여백)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 검색창
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: '닉네임 입력',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF202025),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: _searchUser, // 입력할 때마다 검색
            ),
            const Gap(24),
            
            // 검색 결과 리스트
            const Text('검색 결과', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const Gap(12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty ? '닉네임을 입력해보세요.' : '검색 결과가 없습니다.',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            final username = user['username'] as String;
                            final fullName = user['full_name'] as String?;

                            return _SearchResultItem(
                              user: user,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => TransferAmountScreen(
                                      recipientId: user['id'],
                                      recipientName: fullName ?? username,
                                      recipientUsername: username,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultItem extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;

  const _SearchResultItem({
    required this.user,
    required this.onTap,
  });

  @override
  State<_SearchResultItem> createState() => _SearchResultItemState();
}

class _SearchResultItemState extends State<_SearchResultItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0, // 색상 보간을 위해 0~1 범위 사용
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final username = user['username'] as String;
    final fullName = user['full_name'] as String?;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // 평소엔 투명(배경색과 동일), 눌렀을 때 살짝 밝은색(0xFF202025)으로 변함
          final backgroundColor = Color.lerp(
            Colors.transparent,
            const Color(0xFF202025),
            _controller.value,
          );

          return Transform.scale(
            scale: 1.0 - (_controller.value * 0.05), // 5%로 키워서 확실한 클릭감 제공
            child: Container(
              width: double.infinity, // 내용이 짧아도 버튼은 가로로 꽉 차게
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), // [UI Update] 리스트 아이템 높이 확장
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16), // 24 -> 16으로 더 각지게 변경
              ),
              child: child,
            ),
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF333338),
              child: Text(
                (fullName ?? username)[0],
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Gap(16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName ?? username,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Gap(4),
                Text(
                  fullName != null ? '@$username' : '실명 정보 없음',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loop_app/core/theme/app_colors.dart';
import 'package:loop_app/core/theme/app_widgets.dart';
import 'package:loop_app/features/transfer/transfer_amount_screen.dart';

/// 받는 사람 찾기 (새 테마). 비로그인 미리보기에서는 더미 유저로 동작.
class TransferSearchScreen extends StatefulWidget {
  const TransferSearchScreen({super.key});

  @override
  State<TransferSearchScreen> createState() => _TransferSearchScreenState();
}

class _TransferSearchScreenState extends State<TransferSearchScreen> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _touched = false;
  final String? _myId = Supabase.instance.client.auth.currentUser?.id;

  static const List<Map<String, dynamic>> _dummy = [
    {'id': 'u1', 'username': 'kimloop', 'full_name': '김루프'},
    {'id': 'u2', 'username': 'soonhwan', 'full_name': '이순환'},
    {'id': 'u3', 'username': 'trader_pro', 'full_name': '박트레이더'},
    {'id': 'u4', 'username': 'jenny', 'full_name': '최제니'},
    {'id': 'u5', 'username': 'anon2024', 'full_name': null},
  ];

  Future<void> _search(String q) async {
    setState(() => _touched = true);
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    if (_myId == null) {
      final lower = q.toLowerCase();
      setState(() {
        _results = _dummy.where((u) {
          final name = (u['full_name'] ?? u['username']).toString().toLowerCase();
          return name.contains(lower) || u['username'].toString().toLowerCase().contains(lower);
        }).toList();
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .or('username.ilike.%$q%,full_name.ilike.%$q%')
          .neq('id', _myId)
          .limit(10);
      if (mounted) setState(() => _results = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('search error: $e');
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LoopTopBar(title: '받는 사람', leadingIcon: PhosphorIcons.caretLeft()),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
                child: GlassContainer(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.magnifyingGlass(), color: AppColors.gray500, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          onChanged: _search,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          cursorColor: AppColors.cyan,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: '닉네임 또는 이름 검색',
                            hintStyle: TextStyle(color: AppColors.gray500),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              _touched && _controller.text.isNotEmpty ? '검색 결과가 없습니다.' : '보낼 상대를 검색하세요.',
                              style: const TextStyle(color: AppColors.gray500),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (context, i) => _resultRow(_results[i]),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultRow(Map<String, dynamic> user) {
    final username = user['username'] as String;
    final fullName = user['full_name'] as String?;
    final display = fullName ?? username;
    return Pressable(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransferAmountScreen(
              recipientId: user['id'].toString(),
              recipientName: display,
              recipientUsername: username,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withOpacity(0.12),
                border: Border.all(color: AppColors.cyan.withOpacity(0.2)),
              ),
              alignment: Alignment.center,
              child: Text(display[0],
                  style: const TextStyle(color: AppColors.cyan, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(display,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 3),
                Text('@$username', style: const TextStyle(color: AppColors.gray500, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

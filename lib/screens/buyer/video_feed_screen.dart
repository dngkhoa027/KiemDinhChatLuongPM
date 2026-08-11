import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../data/mock_data.dart';
import 'live_watch_screen.dart';
import 'live_feed_screen.dart';
import 'live_screen.dart';

/// Feed dọc kiểu Shopee Video / Cho bạn — dùng 4 file mp4 trong assets/videos.
class VideoFeedScreen extends StatefulWidget {
  /// 0=Video, 1=Live, 2=Drama, 3=Cho bạn
  final int initialTab;
  const VideoFeedScreen({super.key, this.initialTab = 0});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  static const Color orange = Color(0xFFEE4D2D);
  late int _tab;
  late PageController _pageCtrl;
  int _page = 0;

  late List<Map<String, dynamic>> _videos;
  late List<int> _likes;
  late List<int> _comments;
  late List<bool> _liked;
  late List<List<String>> _commentLists;

  final Map<int, VideoPlayerController> _controllers = {};
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _pageCtrl = PageController();
    _videos = List<Map<String, dynamic>>.from(MockData.shopeeVideos);
    // Cycle all 4 assets if list shorter
    if (_videos.isEmpty) {
      _videos = [
        for (final p in [
          'assets/videos/video_1.mp4',
          'assets/videos/video_2.mp4',
          'assets/videos/live_1.mp4',
          'assets/videos/live_2.mp4',
        ])
          {
            'video': p,
            'user': 'Shopee User',
            'caption': 'Video Shopee',
            'likes': 100,
            'comments': 10,
            'shares': 5,
          }
      ];
    }
    _likes = _videos.map((v) => (v['likes'] as int?) ?? 0).toList();
    _comments = _videos.map((v) => (v['comments'] as int?) ?? 0).toList();
    _liked = List.filled(_videos.length, false);
    _commentLists = List.generate(_videos.length, (i) {
      final base = <String>[
        'Sản phẩm đẹp quá ạ 😍',
        'Shop ơi còn size L không?',
        'Mình vừa chốt đơn!',
        'Giá này quá hời',
        'Video hay quá',
      ];
      // Different comment sets per video
      return base.sublist(0, (2 + i).clamp(1, base.length));
    });
    _initController(0);
    if (_videos.length > 1) _initController(1);
  }

  Future<void> _initController(int index) async {
    if (index < 0 || index >= _videos.length) return;
    if (_controllers.containsKey(index)) return;
    final path = _videos[index]['video'] as String? ?? 'assets/videos/video_1.mp4';
    final c = VideoPlayerController.asset(path);
    _controllers[index] = c;
    try {
      await c.initialize();
      c.setLooping(true);
      if (mounted && _page == index) {
        c.play();
        setState(() {});
      } else {
        if (mounted) setState(() {});
      }
    } catch (_) {
      // asset missing — still show UI
      if (mounted) setState(() {});
    }
  }

  void _onPageChanged(int index) {
    // pause old
    _controllers[_page]?.pause();
    _page = index;
    _initController(index);
    _initController(index + 1);
    _initController(index - 1);
    _controllers[index]?.play();
    // dispose far controllers
    for (final k in _controllers.keys.toList()) {
      if ((k - index).abs() > 1) {
        _controllers[k]?.dispose();
        _controllers.remove(k);
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _pageCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) {
      final v = n / 1000;
      return v >= 10 ? '${v.toStringAsFixed(0)}k' : '${v.toStringAsFixed(1).replaceAll('.0', '')}k';
    }
    return '$n';
  }

  void _toggleLike(int i) {
    setState(() {
      if (_liked[i]) {
        _liked[i] = false;
        _likes[i] = (_likes[i] - 1).clamp(0, 1 << 30);
      } else {
        _liked[i] = true;
        _likes[i]++;
      }
    });
  }

  void _openComments(int i) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.55,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${_comments[i]} bình luận',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _commentLists[i].length,
                    itemBuilder: (_, j) {
                      final text = _commentLists[i][j];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.primaries[j % Colors.primaries.length].shade200,
                              child: Text(
                                text.isNotEmpty ? text[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    j == 0 && text.startsWith('Bạn:') ? 'Bạn' : 'user_${1000 + j + i * 10}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(text.replaceFirst('Bạn: ', ''), style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          decoration: InputDecoration(
                            hintText: 'Thêm bình luận...',
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          final t = _commentCtrl.text.trim();
                          if (t.isEmpty) return;
                          setState(() {
                            _commentLists[i].insert(0, 'Bạn: $t');
                            _comments[i]++;
                          });
                          _commentCtrl.clear();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã gửi bình luận'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.send, color: orange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _switchTab(int index) {
    // Live / Cho bạn → quay lại livestream (pop nếu vào từ live, không nhảy lung tung)
    if (index == 1 || index == 3) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return;
      }
      final streams = MockData.liveStreams;
      if (streams.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const LiveFeedScreen(),
            fullscreenDialog: true,
          ),
        );
      }
      return;
    }
    if (index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drama — sắp ra mắt'), duration: Duration(seconds: 1)),
      );
      return;
    }
    // Tab Video
    setState(() => _tab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vertical video pages
          PageView.builder(
            controller: _pageCtrl,
            scrollDirection: Axis.vertical,
            itemCount: _videos.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) => _buildPage(index),
          ),
          // Top nav
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: Colors.white, size: 23),
                  const SizedBox(width: 14),
                  const Icon(Icons.search, color: Colors.white, size: 23),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _tabItem('Video', 0),
                        const SizedBox(width: 18),
                        _tabItem('Live', 1),
                        const SizedBox(width: 18),
                        _tabItem('Drama', 2, badge: 'Mới'),
                        const SizedBox(width: 18),
                        _tabItem('Cho bạn', 3),
                      ],
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.videocam_outlined, color: Colors.white, size: 25),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: orange, shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: Colors.white, size: 9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int index, {String? badge}) {
    final selected = _tab == index;
    return GestureDetector(
      onTap: () => _switchTab(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontStyle: label == 'Drama' ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              if (badge != null)
                Positioned(
                  top: -6,
                  right: -18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFFFF424F), borderRadius: BorderRadius.circular(6)),
                    child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (selected)
            Container(
              width: 20,
              height: 2.5,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
            )
          else
            const SizedBox(height: 2.5),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    final v = _videos[index];
    final c = _controllers[index];
    final ready = c != null && c.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video
        if (ready)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: c.value.size.width,
              height: c.value.size.height,
              child: VideoPlayer(c),
            ),
          )
        else
          Container(
            color: Colors.black,
            child: Center(
              child: c == null
                  ? const CircularProgressIndicator(color: Colors.white54)
                  : const Icon(Icons.videocam_off, color: Colors.white38, size: 48),
            ),
          ),

        // Gradient bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 220,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
              ),
            ),
          ),
        ),

        // Right actions
        Positioned(
          right: 10,
          bottom: 120,
          child: Column(
            children: [
              // Avatar + follow
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade400,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/100?u=${v['user']}',
                    ),
                    onBackgroundImageError: (_, _) {},
                  ),
                  if (v['following'] != true)
                    Positioned(
                      bottom: -6,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(color: orange, shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => _toggleLike(index),
                child: Column(
                  children: [
                    Icon(
                      _liked[index] ? Icons.favorite : Icons.favorite_border,
                      color: _liked[index] ? const Color(0xFFFF2D55) : Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 2),
                    Text(_fmtCount(_likes[index]), style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _openComments(index),
                child: Column(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 30),
                    const SizedBox(height: 2),
                    Text(_fmtCount(_comments[index]), style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Column(
                children: [
                  Icon(Icons.share, color: Colors.white, size: 28),
                  SizedBox(height: 2),
                  Text('Chia sẻ', style: TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  'https://i.pravatar.cc/80?u=music_${v['id']}',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 36,
                    height: 36,
                    color: Colors.grey.shade700,
                    child: const Icon(Icons.music_note, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom left info
        Positioned(
          left: 12,
          right: 80,
          bottom: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product tag
              if (v['product'] != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_bag, color: orange, size: 16),
                      const SizedBox(width: 6),
                      if (v['discount'] != null) ...[
                        Text(
                          '${v['discount']} | ',
                          style: const TextStyle(color: orange, fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                      Flexible(
                        child: Text(
                          '${v['product']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 12.5),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              // User
              Row(
                children: [
                  Text(
                    '@${v['user']}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  if (v['verified'] == true) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: Color(0xFF1DA1F2), size: 16),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${v['caption'] ?? ''}  Xem thêm',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.3),
              ),
              const SizedBox(height: 8),
              // Comment bar
              GestureDetector(
                onTap: () => _openComments(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Text('Thêm bình luận', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tap center to play/pause
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              final ctrl = _controllers[index];
              if (ctrl == null || !ctrl.value.isInitialized) return;
              if (ctrl.value.isPlaying) {
                ctrl.pause();
              } else {
                ctrl.play();
              }
              setState(() {});
            },
            onDoubleTap: () => _toggleLike(index),
          ),
        ),
      ],
    );
  }
}

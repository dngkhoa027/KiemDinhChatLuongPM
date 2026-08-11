import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import 'live_watch_screen.dart';

/// Feed livestream vuốt dọc kiểu TikTok — mỗi trang 1 live demo.
class LiveFeedScreen extends StatefulWidget {
  final int initialIndex;

  const LiveFeedScreen({super.key, this.initialIndex = 0});

  @override
  State<LiveFeedScreen> createState() => _LiveFeedScreenState();
}

class _LiveFeedScreenState extends State<LiveFeedScreen> {
  late final PageController _pageCtrl;
  late int _page;

  List<Map<String, dynamic>> get _streams => MockData.liveStreams;

  @override
  void initState() {
    super.initState();
    final max = _streams.isEmpty ? 0 : _streams.length - 1;
    _page = widget.initialIndex.clamp(0, max);
    _pageCtrl = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_streams.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('Chưa có livestream', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageCtrl,
        scrollDirection: Axis.vertical,
        allowImplicitScrolling: true,
        itemCount: _streams.length,
        onPageChanged: (i) => setState(() => _page = i),
        itemBuilder: (context, index) {
          return LiveWatchScreen(
            key: ValueKey('live_page_$index'),
            stream: _streams[index],
            isActive: index == _page,
            embeddedInFeed: true,
          );
        },
      ),
    );
  }
}

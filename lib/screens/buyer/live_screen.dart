import 'package:flutter/material.dart';
import '../../data/mock_data.dart';

class ShopeeLivePage extends StatefulWidget {
  const ShopeeLivePage({super.key});

  @override
  State<ShopeeLivePage> createState() => _ShopeeLivePageState();
}

class _ShopeeLivePageState extends State<ShopeeLivePage> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);
  static const Color liveRed = Color(0xFFFF424F);

  int _selectedFilter = 0;
  final List<String> _filters = MockData.liveFilters;

  // ============== DATA: LIVESTREAMS ==============
  final List<Map<String, dynamic>> _liveStreams = MockData.liveStreams;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterChips(),
            Expanded(child: _buildLiveGrid()),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill, color: Colors.white, size: 22),
          const SizedBox(width: 6),
          const Text(
            "Shopee Live",
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          const Spacer(),
          const Icon(Icons.search, color: Colors.white, size: 22),
          const SizedBox(width: 16),
          const Icon(Icons.notifications_none, color: Colors.white, size: 22),
        ],
      ),
    );
  }

  // ================= FILTER CHIPS =================
  Widget _buildFilterChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final bool selected = index == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? shopeeOrange : Colors.white12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _filters[index],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= LIVE GRID =================
  Widget _buildLiveGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _liveStreams.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) => _buildLiveCard(_liveStreams[index]),
    );
  }

  Widget _buildLiveCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đang vào livestream của ${item["shop"]}..."),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.black87,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              item["thumb"] as String,
              fit: BoxFit.cover,
            ),
            // Gradient overlay for readability
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
                    Colors.black.withOpacity(0.75),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            // LIVE badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: liveRed,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 6),
                    SizedBox(width: 3),
                    Text(
                      "LIVE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Viewer count
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.remove_red_eye, color: Colors.white, size: 11),
                    const SizedBox(width: 3),
                    Text(
                      "${item["viewers"]}",
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom info
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item["title"] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.storefront, size: 10, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item["shop"] as String,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: shopeeOrange,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      "₫${item["price"]}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

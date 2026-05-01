import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loading skeleton that mimics a list of cards.
class ShimmerListLoading extends StatelessWidget {
  final int itemCount;
  const ShimmerListLoading({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    final highlightColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (_, i) => _ShimmerCard(index: i),
      ),
    );
  }
}

/// Shimmer loading skeleton that mimics a KPI grid.
class ShimmerDashboardLoading extends StatelessWidget {
  const ShimmerDashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    final highlightColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // KPI grid (2x2)
          Row(children: [
            Expanded(child: _ShimmerBox(height: 100)),
            const SizedBox(width: 12),
            Expanded(child: _ShimmerBox(height: 100)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ShimmerBox(height: 100)),
            const SizedBox(width: 12),
            Expanded(child: _ShimmerBox(height: 100)),
          ]),
          const SizedBox(height: 20),
          // Chart placeholder
          _ShimmerBox(height: 200),
          const SizedBox(height: 20),
          // List items
          for (int i = 0; i < 4; i++) ...[
            _ShimmerCard(index: i),
          ],
        ]),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final int index;
  const _ShimmerCard({required this.index});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 12, width: 120 + (index * 10 % 60).toDouble(), color: Colors.white),
          const SizedBox(height: 8),
          Container(height: 10, width: 180 + (index * 15 % 40).toDouble(), color: Colors.white),
        ])),
        Container(width: 50, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
      ]),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  const _ShimmerBox({required this.height});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    );
  }
}

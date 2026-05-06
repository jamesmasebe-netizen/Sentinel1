import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: 200, height: 32),
          const SizedBox(height: 8),
          const SkeletonLoader(width: 150, height: 16),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 120,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    SkeletonLoader(
                      width: double.infinity,
                      height: 54,
                      borderRadius: 12,
                    ),
                    const SizedBox(height: 12),
                    SkeletonLoader(
                      width: double.infinity,
                      height: 54,
                      borderRadius: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 100,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 100,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 100,
                  borderRadius: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const SkeletonLoader(width: 180, height: 24),
          const SizedBox(height: 16),
          const SkeletonLoader(
            width: double.infinity,
            height: 60,
            borderRadius: 12,
          ),
          const SizedBox(height: 8),
          const SkeletonLoader(
            width: double.infinity,
            height: 60,
            borderRadius: 12,
          ),
          const SizedBox(height: 8),
          const SkeletonLoader(
            width: double.infinity,
            height: 60,
            borderRadius: 12,
          ),
        ],
      ),
    );
  }
}

class HubSkeleton extends StatelessWidget {
  const HubSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: 150, height: 28),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 80,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 80,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 80,
                  borderRadius: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SkeletonLoader(width: 200, height: 24),
          const SizedBox(height: 16),
          const SkeletonLoader(
            width: double.infinity,
            height: 72,
            borderRadius: 12,
          ),
          const SizedBox(height: 8),
          const SkeletonLoader(
            width: double.infinity,
            height: 72,
            borderRadius: 12,
          ),
          const SizedBox(height: 8),
          const SkeletonLoader(
            width: double.infinity,
            height: 72,
            borderRadius: 12,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../shared/widgets/tindog_shimmer.dart';

/// Filas fantasma de la lista Chats.
class ChatsListSkeleton extends StatelessWidget {
  const ChatsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return TindogShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        children: [
          const TindogSkeletonBox(width: 120, height: 16, radius: 8),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => const Column(
                children: [
                  TindogSkeletonBox(width: 64, height: 64, radius: 999),
                  SizedBox(height: 8),
                  TindogSkeletonBox(width: 56, height: 12, radius: 6),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const TindogSkeletonBox(width: 140, height: 16, radius: 8),
          const SizedBox(height: 12),
          for (var i = 0; i < 6; i++) ...[
            const _ChatRowSkeleton(),
            if (i < 5) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _ChatRowSkeleton extends StatelessWidget {
  const _ChatRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          TindogSkeletonBox(width: 56, height: 56, radius: 999),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TindogSkeletonBox(width: 120, height: 14, radius: 6),
                SizedBox(height: 8),
                TindogSkeletonBox(
                  width: double.infinity,
                  height: 12,
                  radius: 6,
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          TindogSkeletonBox(width: 36, height: 12, radius: 6),
        ],
      ),
    );
  }
}

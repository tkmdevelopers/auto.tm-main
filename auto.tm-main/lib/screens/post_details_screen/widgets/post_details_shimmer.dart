import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PostDetailsShimmer extends StatelessWidget {
  const PostDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Shimmer.fromColors(
        baseColor: isDark
            ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
            : theme.colorScheme.surfaceVariant.withOpacity(0.5),
        highlightColor: isDark
            ? theme.colorScheme.surfaceVariant.withOpacity(0.5)
            : theme.colorScheme.surface.withOpacity(0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel shimmer
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            const SizedBox(height: 16),

            // Title and post date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _roundedBox(width: 200, height: 20),
                  const SizedBox(height: 8),
                  _roundedBox(width: 120, height: 14),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Characteristics shimmer (2 columns)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(4, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(child: _roundedBox(height: 20)),
                        const SizedBox(width: 16),
                        Expanded(child: _roundedBox(height: 20)),
                      ],
                    ),
                  );
                }),
              ),
            ),

            const Divider(thickness: 1, height: 32),

            // Seller's comment title and box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _roundedBox(width: 150, height: 20),
                  const SizedBox(height: 12),
                  _roundedBox(width: double.infinity, height: 40),
                ],
              ),
            ),

            const Divider(thickness: 1, height: 32),

            // Comment box shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _roundedBox(width: double.infinity, height: 80),
            ),

            const SizedBox(height: 40),

            // Bottom price + button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _roundedBox(width: 100, height: 24),
                  const Spacer(),
                  _roundedBox(width: 80, height: 36),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _roundedBox({double width = double.infinity, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final ShapeBorder shape;

  const ShimmerPlaceholder({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
    this.shape = const RoundedRectangleBorder(),
  });

  factory ShimmerPlaceholder.rectangular({
    double width = double.infinity,
    double height = 20,
    double borderRadius = 8,
  }) => ShimmerPlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
      );

  factory ShimmerPlaceholder.circular({
    required double size,
  }) => ShimmerPlaceholder(
        width: size,
        height: size,
        shape: const CircleBorder(),
      );

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDarkMode
        ? AppColors.shimmerBase
        : Colors.grey[350]!;
    final highlightColor = isDarkMode
        ? AppColors.shimmerHighlight
        : Colors.grey[100]!;

    if (shape is CircleBorder) {
      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

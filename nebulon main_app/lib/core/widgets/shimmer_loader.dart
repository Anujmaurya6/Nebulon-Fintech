import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ShimmerLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const ShimmerLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
    this.shape = BoxShape.rectangle,
  });

  const ShimmerLoader.circle({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = size / 2,
      shape = BoxShape.circle;

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.rectangle
                ? BorderRadius.circular(widget.borderRadius)
                : null,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                0.0,
                (_animation.value + 1) / 4,
                (_animation.value + 2) / 4,
                1.0,
              ],
              colors: [
                AppTheme.surface,
                AppTheme.divider.withOpacity(0.2),
                AppTheme.divider.withOpacity(0.5),
                AppTheme.surface,
              ],
            ),
          ),
        );
      },
    );
  }
}

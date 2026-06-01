import 'package:flutter/material.dart';

enum FadeInDirection { bottomToTop, topToBottom, leftToRight, rightToLeft }

class FadeInSlide extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final FadeInDirection direction;

  const FadeInSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.direction = FadeInDirection.bottomToTop,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

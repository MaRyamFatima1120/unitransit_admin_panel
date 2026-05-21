import 'package:flutter/material.dart';

enum FadeInDirection { bottomToTop, topToBottom, leftToRight, rightToLeft }

class FadeInSlide extends StatefulWidget {
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
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Offset startOffset;
    switch (widget.direction) {
      case FadeInDirection.bottomToTop:
        startOffset = const Offset(0.0, 0.2);
        break;
      case FadeInDirection.topToBottom:
        startOffset = const Offset(0.0, -0.2);
        break;
      case FadeInDirection.leftToRight:
        startOffset = const Offset(-0.1, 0.0);
        break;
      case FadeInDirection.rightToLeft:
        startOffset = const Offset(0.1, 0.0);
        break;
    }

    _offset = Tween<Offset>(begin: startOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

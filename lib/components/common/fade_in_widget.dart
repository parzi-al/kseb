import 'package:flutter/material.dart';

import '../../utils/animation_constants.dart';

/// Wrapper that fades in its child on first build.
///
/// Used for content-loading transition (FR-013).
/// Respects [MediaQuery.disableAnimations] — shows instantly when active.
///
/// ```dart
/// _isLoading
///   ? const AppLoading()
///   : FadeInWidget(child: _buildContent())
/// ```
class FadeInWidget extends StatefulWidget {
  /// The content to fade in.
  final Widget child;

  /// Override the default [AnimationConstants.contentFadeInDuration].
  final Duration? duration;

  const FadeInWidget({
    required this.child,
    this.duration,
    super.key,
  });

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? AnimationConstants.contentFadeInDuration,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
    );
  }
}

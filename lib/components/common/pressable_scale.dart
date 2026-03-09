import 'package:flutter/material.dart';

import '../../utils/animation_constants.dart';

/// Wrapper widget that adds a press-scale animation to its child.
///
/// On press: scales to [scaleFactor]. On release: springs back to 1.0.
/// Respects reduce-motion accessibility setting.
///
/// Composes outside existing [InkWell] ripple — no conflict.
///
/// ```dart
/// PressableScale(
///   onTap: () => navigateSomewhere(),
///   child: MyCardWidget(),
/// )
/// ```
class PressableScale extends StatefulWidget {
  /// The content to wrap with press-scale behavior.
  final Widget child;

  /// Tap handler (forwarded from the gesture).
  final VoidCallback? onTap;

  /// Target scale on press (default 0.96 = 4% shrink).
  final double scaleFactor;

  /// Whether the animation and tap are enabled.
  final bool enabled;

  const PressableScale({
    required this.child,
    this.onTap,
    this.scaleFactor = AnimationConstants.pressScaleFactor,
    this.enabled = true,
    super.key,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConstants.pressScaleDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationConstants.pressScaleCurve,
      ),
    );
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    if (MediaQuery.of(context).disableAnimations) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (!widget.enabled) return;
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (!widget.enabled) return;
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? _onTapDown : null,
      onTapUp: widget.enabled ? _onTapUp : null,
      onTapCancel: widget.enabled ? _onTapCancel : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

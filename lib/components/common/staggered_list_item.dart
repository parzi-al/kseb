import 'package:flutter/material.dart';

import '../../utils/animation_constants.dart';

/// Wrapper that animates a single list item with staggered fade + slide-up
/// entrance.
///
/// The delay is computed from [index]: `min(index, staggerMaxIndex) *
/// staggerDelayPerItem`. The animation plays once per widget lifecycle.
///
/// Respects [MediaQuery.disableAnimations] — shows instantly when active.
///
/// ```dart
/// ListView.builder(
///   itemBuilder: (context, index) => StaggeredListItem(
///     index: index,
///     child: MyListItem(item: items[index]),
///   ),
/// )
/// ```
class StaggeredListItem extends StatefulWidget {
  /// Position in the list — determines stagger delay.
  final int index;

  /// The content to animate.
  final Widget child;

  const StaggeredListItem({
    required this.index,
    required this.child,
    super.key,
  });

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConstants.staggerItemDuration,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationConstants.staggerCurve,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, AnimationConstants.staggerSlideOffset),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationConstants.staggerCurve,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1.0;
      return;
    }

    final clampedIndex =
        widget.index.clamp(0, AnimationConstants.staggerMaxIndex);
    final delay = AnimationConstants.staggerDelayPerItem * clampedIndex;

    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
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
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

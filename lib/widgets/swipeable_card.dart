import 'package:flutter/material.dart';

/// A lightweight swipeable card widget that provides a custom pan/animation
/// for smoother interactions compared to Dismissible. Swiping right will call
/// `onMoveToEnd`; swiping left will call `onRemove` after an animated slide-out.
class SwipeableCard extends StatefulWidget {
  const SwipeableCard({
    Key? key,
    required this.cardId,
    required this.width,
    required this.height,
    this.allowSwipe = true,
    required this.child,
    required this.onRemove,
    required this.onMoveToEnd,
    this.borderColor = Colors.grey,
    this.borderWidth = 2.0,
    this.whiteOverlayOpacity = 0.0,
  }) : super(key: key);

  final String cardId;
  final double width;
  final double height;
  final bool allowSwipe;
  final Widget child;
  final VoidCallback onRemove;
  final VoidCallback onMoveToEnd;
  final Color borderColor;
  final double borderWidth;
  final double whiteOverlayOpacity;

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _offsetX = 0.0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target, VoidCallback? onCompleted) {
    _animation = Tween(begin: _offsetX, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.reset();
    _isAnimating = true;
    _animation.addListener(() {
      setState(() {
        _offsetX = _animation.value;
      });
    });
    _controller.forward().whenComplete(() {
      _animation.removeListener(() {});
      _isAnimating = false;
      if (onCompleted != null) onCompleted();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.width;
    final double threshold = width * 0.35;

    // Hint opacity proportional to drag distance
    final double hintOpacity = (_offsetX.abs() / (width * 0.5)).clamp(0.0, 1.0);

    return Stack(
      children: [
        // Left hint (Move to end) shown when swiping right
        Positioned.fill(
          child: Opacity(
            opacity: _offsetX > 0 ? hintOpacity : 0.0,
            child: Container(
              padding: const EdgeInsets.only(left: 20.0),
              alignment: Alignment.centerLeft,
              color: Colors.blueGrey.withOpacity(0.12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.loop, color: Colors.greenAccent),
                  SizedBox(width: 8.0),
                  Text('Got it', style: TextStyle(color: Colors.greenAccent)),
                ],
              ),
            ),
          ),
        ),
        // Right hint (Remove) shown when swiping left
        Positioned.fill(
          child: Opacity(
            opacity: _offsetX < 0 ? hintOpacity : 0.0,
            child: Container(
              padding: const EdgeInsets.only(right: 20.0),
              alignment: Alignment.centerRight,
              color: Colors.redAccent.withOpacity(0.12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text("Study Again", style: TextStyle(color: Colors.redAccent)),
                  SizedBox(width: 8.0),
                  Icon(Icons.delete, color: Colors.redAccent),
                ],
              ),
            ),
          ),
        ),

        // The draggable card content
        Transform.translate(
          offset: Offset(_offsetX, 0),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (details) {
              if (_isAnimating) return;
              if (!widget.allowSwipe) return;
              setState(() {
                _offsetX += details.delta.dx;
                // limit to a reasonable range
                _offsetX = _offsetX.clamp(-width * 1.2, width * 1.2);
              });
            },
            onPanEnd: (details) {
              if (_isAnimating) return;
              if (!widget.allowSwipe) return;
              if (_offsetX.abs() > threshold) {
                if (_offsetX > 0) {
                  // Swiped right -> move to end. Animate out to the right.
                  _animateTo(width * 1.2, () {
                    widget.onMoveToEnd();
                  });
                } else {
                  // Swiped left -> remove from line. Animate out to the left then callback.
                  _animateTo(-width * 1.2, () {
                    widget.onRemove();
                  });
                }
              } else {
                // Not far enough: animate back
                _animateTo(0.0, null);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Stack(
                children: [
                  Container(
                    width: widget.width,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: widget.child,
                  ),
                  // White overlay gradient for depth effect
                  if (widget.whiteOverlayOpacity > 0.0)
                    Container(
                      width: widget.width,
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(widget.whiteOverlayOpacity),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import '/card/back_card.dart';
import '/card/front_card.dart';
import 'package:flutter/material.dart';
import 'dart:math' show pi;

class CardContainer extends StatefulWidget {
  /// Optional height to force the displayed card to. If null, the container
  /// will measure the front/back card and use the maximum measured height.
  const CardContainer({
    super.key,
    this.forcedHeight,
    this.cardNumber,
    this.frontText,
    this.backText,
    this.onShowBack,
    this.onShowFront,
  });

  final double? forcedHeight;
  final int? cardNumber;
  final String? frontText;
  final String? backText;
  final ValueChanged<String?>? onShowBack;
  final VoidCallback? onShowFront;

  @override
  State<CardContainer> createState() => _CardContainerState();
}

class _CardContainerState extends State<CardContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _cardFlipController;
  late Animation<double> _cardFlipAnimation;
  bool isFront = true;

  @override
  void initState() {
    super.initState();

    _cardFlipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _cardFlipAnimation = Tween(
      begin: 0.0,
      end: pi,
    ).animate(_cardFlipController);

    _cardFlipController.addListener(() {
      if (_cardFlipController.value >= 0.5 && isFront) {
        setState(() {
          isFront = false;
        });
        // Notify parent that the back is now visible
        try {
          widget.onShowBack?.call(widget.backText);
        } catch (_) {}
      } else if (_cardFlipController.value < 0.5 && !isFront) {
        setState(() {
          isFront = true;
        });
        // Notify parent that the front is now visible
        try {
          widget.onShowFront?.call();
        } catch (_) {}
      }
    });

    // Measure the heights after the first layout phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      measureHeights();
    });
  }

  final GlobalKey _frontCardKey = GlobalKey(); // GlobalKey for FrontCard
  final GlobalKey _backCardKey = GlobalKey(); // GlobalKey for BackCard

  late double frontCardHeight;
  late double backCardHeight;
  double? maxHeight;

  @override
  void dispose() {
    _cardFlipController.dispose();
    super.dispose();
  }

  // Function to measure heights of FrontCard and BackCard
  void measureHeights() {
    final frontRenderBox =
        _frontCardKey.currentContext?.findRenderObject() as RenderBox?;
    final backRenderBox =
        _backCardKey.currentContext?.findRenderObject() as RenderBox?;

    if (frontRenderBox != null && backRenderBox != null) {
      setState(() {
        frontCardHeight = frontRenderBox.size.height;
        backCardHeight = backRenderBox.size.height;
        maxHeight =
            (frontCardHeight > backCardHeight ? frontCardHeight : backCardHeight);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Decide the height to display: prefer the `forcedHeight` passed from
    // the parent (FlashcardPage). If not provided, use the measured
    // `maxHeight` (from front/back), and finally fall back to a sensible
    // minimum so the UI doesn't collapse while measuring.
    final double displayHeight = (widget.forcedHeight ?? maxHeight ?? 150.0) - 80.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Offstage(
          child: FrontCard(
            key: _frontCardKey, // Attach the GlobalKey here
            number: widget.cardNumber,
            text: widget.frontText,
          ),
        ),
        Offstage(
            child: BackCard(
              key: _backCardKey, // Attach the GlobalKey here
              number: widget.cardNumber,
              text: widget.backText,
            ),
        ),
        SizedBox(
          height: displayHeight,
          child: GestureDetector(
            onTap: () {
              if (isFront) {
                _cardFlipController.forward();
              } else {
                _cardFlipController.reverse();
              }
            },
              child: AnimatedBuilder(
              animation: _cardFlipAnimation,
              builder: (context, child) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(
                      _cardFlipAnimation.value,
                    ),
                  child: child,
                );
              },
              child: isFront
                  ? FrontCard(number: widget.cardNumber, text: widget.frontText)
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateY(pi),
                      child: BackCard(number: widget.cardNumber, text: widget.backText),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
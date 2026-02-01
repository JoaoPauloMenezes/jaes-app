import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/flashcard.dart';
import 'dart:math';

class MatchingTestOverlay extends StatefulWidget {
  final List<Flashcard> flashcards;
  final Function(Map<String, bool> results) onComplete;

  const MatchingTestOverlay({
    super.key,
    required this.flashcards,
    required this.onComplete,
  });

  @override
  State<MatchingTestOverlay> createState() => _MatchingTestOverlayState();
}

class _MatchingTestOverlayState extends State<MatchingTestOverlay> {
  late List<Flashcard> _leftColumn;
  late List<Flashcard> _rightColumn;
  final Map<String, String> _connections =
      {}; // Maps left cardId to right cardId
  String? _selectedLeftId;
  int _errors = 0;
  final Map<String, GlobalKey> _leftKeys = {};
  final Map<String, GlobalKey> _rightKeys = {};
  final GlobalKey _paintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _setupGame();
  }

  void _setupGame() {
    // Shuffle all available flashcards first, then take up to 5 for more randomization
    final shuffledCards = List.from(widget.flashcards);
    shuffledCards.shuffle(Random());
    final cardsToUse = shuffledCards.take(5).toList();

    // Shuffle both columns independently for more randomization
    _leftColumn = List.from(cardsToUse);
    _leftColumn.shuffle(Random());

    _rightColumn = List.from(cardsToUse);
    _rightColumn.shuffle(Random());

    // Ensure both columns are shuffled differently from each other
    if (_rightColumn.length > 1) {
      while (_areListsInSameOrder(_leftColumn, _rightColumn)) {
        _rightColumn.shuffle(Random());
      }
    }

    // Create GlobalKeys for each card
    for (var card in _leftColumn) {
      _leftKeys[card.id] = GlobalKey();
    }
    for (var card in _rightColumn) {
      _rightKeys[card.id] = GlobalKey();
    }
  }

  bool _areListsInSameOrder(List<Flashcard> list1, List<Flashcard> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  void _onLeftCardTap(String cardId) {
    setState(() {
      if (_selectedLeftId == cardId) {
        _selectedLeftId = null; // Deselect if tapping the same card
      } else {
        _selectedLeftId = cardId;
      }
    });
  }

  void _onRightCardTap(String cardId) {
    if (_selectedLeftId == null) return;

    final leftId = _selectedLeftId!;

    setState(() {
      // Add connection from this left card to right card
      _connections[leftId] = cardId;
      _selectedLeftId = null;
    });

    // Check if this specific connection is correct
    if (!_isCorrectMatch(leftId, cardId)) {
      // Wrong match - increment error counter and show briefly then clear
      setState(() {
        _errors++;
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() {
            _connections.remove(leftId);
          });
        }
      });
    } else {
      // Check if all cards are matched
      if (_connections.length == _leftColumn.length) {
        _checkAllMatches();
      }
    }
  }

  void _checkAllMatches() {
    // All connections should be correct at this point since wrong ones are cleared immediately
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    final int total = _leftColumn.length;

    // Create a map of flashcard ID -> whether it was answered correctly (all are correct)
    final Map<String, bool> results = {};
    for (var leftCard in _leftColumn) {
      results[leftCard.id] = true; // All are correct at this point
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Perfect! 🎉'),
        content: Text(
          'Great job! All $total matches are correct!\n\n'
          'Number of errors: $_errors',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onComplete(results);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  bool _isCorrectMatch(String leftId, String rightId) {
    final leftCard = _leftColumn.firstWhere((c) => c.id == leftId);
    final rightCard = _rightColumn.firstWhere((c) => c.id == rightId);
    return leftCard.id == rightCard.id;
  }

  Color _getConnectionColor(String leftId, String rightId) {
    if (_isCorrectMatch(leftId, rightId)) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Matching Test',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_connections.length}/${_leftColumn.length}',
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect the matching cards',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Game Grid
              Expanded(
                child: Row(
                  children: [
                    // Left Column (Front)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _leftColumn.map((card) {
                          final isSelected = _selectedLeftId == card.id;
                          final isConnected = _connections.containsKey(card.id);

                          return GestureDetector(
                            key: _leftKeys[card.id],
                            onTap: isConnected
                                ? null
                                : () => _onLeftCardTap(card.id),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: isConnected
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.grey.shade600,
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                              child: Text(
                                card.frontText,
                                style: TextStyle(
                                  color: isConnected
                                      ? Colors.white54
                                      : Colors.white,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Connection Lines
                    SizedBox(
                      key: _paintKey,
                      width: 60,
                      child: CustomPaint(
                        painter: ConnectionPainter(
                          connections: _connections,
                          leftColumn: _leftColumn,
                          rightColumn: _rightColumn,
                          leftKeys: _leftKeys,
                          rightKeys: _rightKeys,
                          paintKey: _paintKey,
                          getColor: _getConnectionColor,
                        ),
                      ),
                    ),

                    // Right Column (Back)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _rightColumn.map((card) {
                          final isConnected = _connections.containsValue(
                            card.id,
                          );

                          return GestureDetector(
                            key: _rightKeys[card.id],
                            onTap: _selectedLeftId != null && !isConnected
                                ? () => _onRightCardTap(card.id)
                                : null,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: isConnected
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade600,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                card.backText,
                                style: TextStyle(
                                  color: isConnected
                                      ? Colors.white54
                                      : Colors.white,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Instructions
              const Text(
                'Tap a card on the left, then tap its match on the right',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConnectionPainter extends CustomPainter {
  final Map<String, String> connections;
  final List<Flashcard> leftColumn;
  final List<Flashcard> rightColumn;
  final Map<String, GlobalKey> leftKeys;
  final Map<String, GlobalKey> rightKeys;
  final GlobalKey paintKey;
  final Color Function(String, String) getColor;

  ConnectionPainter({
    required this.connections,
    required this.leftColumn,
    required this.rightColumn,
    required this.leftKeys,
    required this.rightKeys,
    required this.paintKey,
    required this.getColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    connections.forEach((leftId, rightId) {
      final leftKey = leftKeys[leftId];
      final rightKey = rightKeys[rightId];

      if (leftKey?.currentContext != null &&
          rightKey?.currentContext != null &&
          paintKey.currentContext != null) {
        try {
          final RenderBox? leftBox =
              leftKey!.currentContext!.findRenderObject() as RenderBox?;
          final RenderBox? rightBox =
              rightKey!.currentContext!.findRenderObject() as RenderBox?;
          final RenderBox? paintBox =
              paintKey.currentContext!.findRenderObject() as RenderBox?;

          if (leftBox != null &&
              rightBox != null &&
              paintBox != null &&
              leftBox.hasSize &&
              rightBox.hasSize &&
              paintBox.hasSize) {
            // Get the painter's global position
            final painterGlobalPos = paintBox.localToGlobal(Offset.zero);

            // Get cards' global positions
            final leftGlobalPos = leftBox.localToGlobal(Offset.zero);
            final rightGlobalPos = rightBox.localToGlobal(Offset.zero);

            // Calculate center Y of each card
            final leftCenterY = leftGlobalPos.dy + (leftBox.size.height / 2);
            final rightCenterY = rightGlobalPos.dy + (rightBox.size.height / 2);

            // Convert to painter's local coordinates
            final startY = leftCenterY - painterGlobalPos.dy;
            final endY = rightCenterY - painterGlobalPos.dy;

            paint.color = getColor(leftId, rightId);

            // Draw line
            canvas.drawLine(Offset(0, startY), Offset(size.width, endY), paint);

            // Draw circles at endpoints
            canvas.drawCircle(
              Offset(0, startY),
              4,
              paint..style = PaintingStyle.fill,
            );
            canvas.drawCircle(Offset(size.width, endY), 4, paint);
            paint.style = PaintingStyle.stroke;
          }
        } catch (e) {
          // Skip if rendering hasn't completed yet
        }
      }
    });
  }

  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) {
    return connections != oldDelegate.connections;
  }
}

import 'package:flutter/material.dart';

class FrontCard extends StatelessWidget {
  const FrontCard({super.key, this.number, this.text});

  final int? number;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('front'),
      elevation: 8,
      color: Colors.blue,
      child: SizedBox(
        width: 250,
        height: 50,
        child: Stack(
          children: [
            Center(
              child: Text(
                text ?? 'Front Side',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (number != null)
              Positioned(
                right: 8.0,
                bottom: 8.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    number!.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
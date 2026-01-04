import 'package:flutter/material.dart';

class BackCard extends StatelessWidget {
  const BackCard({super.key, this.number, this.text});

  final int? number;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('back'),
      elevation: 8,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500.0, // Set your desired maximum width here
            minWidth: 250,
            minHeight: 150,
          ),
          child: Stack(
          children: [
            // Display the back text without internal scrolling so the
            // parent `CardContainer` handles overall layout and avoids
            // nested scroll interactions.
            Center(
              child: Text(
                text ?? "Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: 12,
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
      ),
    );
  }
}
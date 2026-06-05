import 'package:flutter/material.dart';

class VideoSeekOverlay extends StatelessWidget {
  final bool isLeft;
  final String label;

  const VideoSeekOverlay({super.key, required this.isLeft, required this.label});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: isLeft ? 20 : null,
      right: isLeft ? null : 20,
      top: 0,
      bottom: 0,
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLeft ? Icons.fast_rewind : Icons.fast_forward,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
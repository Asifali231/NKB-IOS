import 'package:flutter/material.dart';

class IOSLoginBlobDecoration extends StatelessWidget {
  const IOSLoginBlobDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: const [
            Positioned(
              top: 4,
              left: -22,
              child: _LoginBlob(
                width: 112,
                height: 96,
                color: Color(0x24FF6B6B),
                rotation: -0.18,
              ),
            ),
            Positioned(
              top: 8,
              right: -24,
              child: _LoginBlob(
                width: 112,
                height: 96,
                color: Color(0x24E17055),
                rotation: 0.22,
              ),
            ),
            Positioned(
              bottom: -34,
              right: 12,
              child: _LoginBlob(
                width: 112,
                height: 96,
                color: Color(0x1FFF6B6B),
                rotation: -0.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginBlob extends StatelessWidget {
  const _LoginBlob({
    required this.width,
    required this.height,
    required this.color,
    required this.rotation,
  });

  final double width;
  final double height;
  final Color color;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: CustomPaint(
        size: Size(width, height),
        painter: _BlobPainter(color),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  const _BlobPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.48, size.height * 0.02)
      ..cubicTo(
        size.width * 0.78,
        size.height * -0.02,
        size.width * 1.02,
        size.height * 0.22,
        size.width * 0.94,
        size.height * 0.51,
      )
      ..cubicTo(
        size.width * 1.08,
        size.height * 0.78,
        size.width * 0.76,
        size.height * 1.02,
        size.width * 0.51,
        size.height * 0.94,
      )
      ..cubicTo(
        size.width * 0.22,
        size.height * 1.08,
        size.width * -0.02,
        size.height * 0.78,
        size.width * 0.07,
        size.height * 0.50,
      )
      ..cubicTo(
        size.width * -0.02,
        size.height * 0.22,
        size.width * 0.21,
        size.height * 0.04,
        size.width * 0.48,
        size.height * 0.02,
      )
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BlobPainter oldDelegate) => oldDelegate.color != color;
}

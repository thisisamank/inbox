import 'package:flutter/widgets.dart';

class InLogo extends StatelessWidget {
  const InLogo({
    super.key,
    this.size = 64,
    this.semanticLabel = 'Agentic Inbox',
  });

  final double size;
  final String semanticLabel;

  static const Color tile = Color(0xFFC2410C);
  static const Color envelope = Color(0xFFFFFFFF);
  static const Color spark = Color(0xFFFDEBDD);

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    image: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.225),
      child: CustomPaint(
        size: Size.square(size),
        painter: const _LogoPainter(),
      ),
    ),
  );
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  static Path sparkPath() => Path()
    ..moveTo(73, 17)
    ..cubicTo(74.7, 26, 77, 28.3, 86, 30)
    ..cubicTo(77, 31.7, 74.7, 34, 73, 43)
    ..cubicTo(71.3, 34, 69, 31.7, 60, 30)
    ..cubicTo(69, 28.3, 71.3, 26, 73, 17)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..scale(size.width / 100, size.height / 100)
      ..drawRect(
        const Rect.fromLTWH(0, 0, 100, 100),
        Paint()..color = InLogo.tile,
      )
      ..translate(-3, 4)
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(22, 34, 54, 38),
          const Radius.circular(7),
        ),
        Paint()..color = InLogo.envelope,
      )
      ..drawPath(
        Path()
          ..moveTo(27.5, 42.5)
          ..lineTo(49, 56.5)
          ..lineTo(70.5, 42.5),
        Paint()
          ..color = InLogo.tile
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(
        sparkPath(),
        Paint()
          ..color = InLogo.tile
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(sparkPath(), Paint()..color = InLogo.spark);
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}

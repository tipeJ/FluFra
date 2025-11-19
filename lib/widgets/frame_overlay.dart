import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crop_state.dart';

class FrameOverlay extends StatelessWidget {
  const FrameOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<CropState>(context);
    return IgnorePointer(
      child: CustomPaint(painter: _FramePainter(state), size: Size.infinite),
    );
  }
}

class _FramePainter extends CustomPainter {
  final CropState state;
  _FramePainter(this.state);

  @override
  void paint(Canvas c, Size s) {
    final border = state.borderThickness.clamp(0.0, s.shortestSide / 2);
    final border2 = state.borderThickness2.clamp(0.0, s.shortestSide / 2);
    final paint = Paint()..color = state.borderColor;

    switch (state.frame) {
      case FrameMode.uniform:
        _drawUniform(c, s, border, paint);
        break;
      case FrameMode.variable:
        _drawVariable(c, s, border, border2, paint);
        break;
      case FrameMode.polaroid:
        _drawPolaroid(c, s, border, paint);
        break;
      case FrameMode.free:
        break;
    }
  }

  void _drawUniform(Canvas c, Size s, double t, Paint p) {
    final outer = Rect.fromLTWH(0, 0, s.width, s.height);
    final inner = Rect.fromLTWH(t, t, s.width - 2 * t, s.height - 2 * t);
    final innerRRect = RRect.fromRectAndCorners(
      inner,
      topLeft: state.roundedCorners
          ? Radius.circular(state.cornerRadius)
          : Radius.zero,
      topRight: state.roundedCorners
          ? Radius.circular(state.cornerRadius)
          : Radius.zero,
      bottomLeft: state.roundedCorners
          ? Radius.circular(state.cornerRadius)
          : Radius.zero,
      bottomRight: state.roundedCorners
          ? Radius.circular(state.cornerRadius)
          : Radius.zero,
    );
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(outer),
      Path()..addRRect(innerRRect),
    );
    c.drawPath(path, p);
  }

  // Borders with t on left/right and t2 on top/bottom
  void _drawVariable(Canvas c, Size s, double t, double t2, Paint p) {
    final outer = Rect.fromLTWH(0, 0, s.width, s.height);
    final inner = Rect.fromLTWH(t, t2, s.width - 2 * t, s.height - 2 * t2);
    final innerRRect = RRect.fromRectAndCorners(
      inner,
      topLeft: state.roundedCorners
          ? Radius.circular(state.cornerRadius)
          : Radius.zero,
      topRight: state.roundedCorners
          ? Radius.circular(state.cornerRadius)
          : Radius.zero,
      bottomLeft: state.roundedCorners
          ? Radius.circular(state.cornerRadius)
          : Radius.zero,
      bottomRight: state.roundedCorners
          ? Radius.circular(state.cornerRadius)
          : Radius.zero,
    );
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(outer),
      Path()..addRRect(innerRRect),
    );
    c.drawPath(path, p);
  }

  void _drawPolaroid(Canvas c, Size s, double t, Paint p) {
    final bottomExtra = s.height * 0.26 - t;
    final inner = Rect.fromLTWH(
      t,
      t,
      s.width - 2 * t,
      s.height - 2 * t - bottomExtra,
    );
    final innerRRect = RRect.fromRectAndCorners(
      inner,
      topLeft: state.roundedCorners
          ? Radius.circular(state.cornerRadius)
          : Radius.zero,
      topRight: state.roundedCorners
          ? Radius.circular(state.cornerRadius)
          : Radius.zero,
      bottomLeft: state.roundedCorners
          ? Radius.circular(state.cornerRadius)
          : Radius.zero,
      bottomRight: state.roundedCorners
          ? Radius.circular(state.cornerRadius)
          : Radius.zero,
    );
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, s.width, s.height)),
      Path()..addRRect(innerRRect),
    );
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) =>
      oldDelegate.state != state;
}

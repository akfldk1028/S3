import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../workspace/theme.dart';

// ============================================================
// 시안 1: Segmented S
// 컨셉: S자를 세그멘테이션 조각으로 분할 — SAM3 핵심 기능 암시
// ============================================================
class SegmentedSPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final unit = size.width / 10;

    // 배경: 다크 네이비 라운드 사각형
    final bgPaint = Paint()..color = WsColors.bg;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.22),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // S자를 구성하는 세그먼트 조각들
    // 각 조각은 다른 색상으로 "세그멘테이션" 느낌
    final segments = <_Segment>[
      // 상단 곡선 (3조각)
      _Segment(
        path: _createArcPath(center.dx - unit * 0.5, center.dy - unit * 2.2,
            unit * 2.5, -math.pi * 0.8, math.pi * 0.6, unit * 1.2),
        color: WsColors.accent1,
      ),
      _Segment(
        path: _createArcPath(center.dx + unit * 0.3, center.dy - unit * 1.8,
            unit * 1.8, -math.pi * 0.3, math.pi * 0.5, unit * 1.0),
        color: Color.lerp(WsColors.accent1, WsColors.accent2, 0.33)!,
      ),
      // 중간 대각선 (2조각)
      _Segment(
        path: _createDiagonalPath(
            center.dx + unit * 0.8, center.dy - unit * 0.8,
            center.dx - unit * 0.8, center.dy + unit * 0.8, unit * 0.9),
        color: Color.lerp(WsColors.accent1, WsColors.accent2, 0.5)!,
      ),
      // 하단 곡선 (3조각)
      _Segment(
        path: _createArcPath(center.dx + unit * 0.5, center.dy + unit * 2.2,
            unit * 2.5, math.pi * 0.2, math.pi * 0.6, unit * 1.2),
        color: Color.lerp(WsColors.accent1, WsColors.accent2, 0.66)!,
      ),
      _Segment(
        path: _createArcPath(center.dx - unit * 0.3, center.dy + unit * 1.8,
            unit * 1.8, math.pi * 0.7, math.pi * 0.5, unit * 1.0),
        color: WsColors.accent2,
      ),
    ];

    // 각 세그먼트를 약간의 간격(갭)으로 분리하여 그리기
    for (final seg in segments) {
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.fill;
      canvas.drawPath(seg.path, paint);

      // 글로우 효과
      final glowPaint = Paint()
        ..color = seg.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * 0.15
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.3);
      canvas.drawPath(seg.path, glowPaint);
    }
  }

  Path _createArcPath(
      double cx, double cy, double radius, double startAngle, double sweep,
      double thickness) {
    final path = Path();
    final outer = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    final inner =
        Rect.fromCircle(center: Offset(cx, cy), radius: radius - thickness);
    path.addArc(outer, startAngle, sweep);
    path.arcTo(inner, startAngle + sweep, -sweep, false);
    path.close();
    return path;
  }

  Path _createDiagonalPath(
      double x1, double y1, double x2, double y2, double width) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final len = math.sqrt(dx * dx + dy * dy);
    final nx = -dy / len * width / 2;
    final ny = dx / len * width / 2;

    return Path()
      ..moveTo(x1 + nx, y1 + ny)
      ..lineTo(x2 + nx, y2 + ny)
      ..lineTo(x2 - nx, y2 - ny)
      ..lineTo(x1 - nx, y1 - ny)
      ..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Segment {
  final Path path;
  final Color color;
  const _Segment({required this.path, required this.color});
}

// ============================================================
// 시안 2: Palette Lens
// 컨셉: 카메라 렌즈 안에 팔레트 색상 조각 — 촬영→변환 암시
// ============================================================
class PaletteLensPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final unit = size.width / 10;

    // 배경
    final bgPaint = Paint()..color = WsColors.bg;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.22),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // 렌즈 외곽 링 (그라데이션)
    final outerRadius = unit * 3.5;
    final ringWidth = unit * 0.45;
    final ringPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          WsColors.accent1,
          WsColors.accent2,
          WsColors.accent1,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth;
    canvas.drawCircle(center, outerRadius, ringPaint);

    // 렌즈 글로우
    final glowPaint = Paint()
      ..color = WsColors.accent1.withValues(alpha: 0.15)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 1.0);
    canvas.drawCircle(center, outerRadius, glowPaint);

    // 렌즈 내부: 6개 팔레트 섹터 (파이 조각)
    final innerRadius = outerRadius - ringWidth - unit * 0.2;
    final sectorColors = [
      WsColors.accent1, // 퍼플
      Color.lerp(WsColors.accent1, WsColors.accent2, 0.25)!, // 퍼플-핑크
      WsColors.accent2, // 핑크
      SellerColors.accent1, // 골드
      SellerColors.accent2, // 로즈골드
      WsColors.surface, // 다크 (빈 슬롯 느낌)
    ];
    final gapAngle = 0.04; // 섹터 간 갭
    final sectorSweep = (2 * math.pi - gapAngle * 6) / 6;

    for (int i = 0; i < 6; i++) {
      final startAngle = -math.pi / 2 + i * (sectorSweep + gapAngle);
      final sectorPaint = Paint()
        ..color = sectorColors[i]
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerRadius),
          startAngle,
          sectorSweep,
          false,
        )
        ..close();
      canvas.drawPath(path, sectorPaint);
    }

    // 중앙 원 (렌즈 코어)
    final corePaint = Paint()
      ..color = WsColors.bg
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, unit * 0.9, corePaint);

    // 중앙 하이라이트
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: unit * 0.7));
    canvas.drawCircle(center, unit * 0.7, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// 시안 3: Gradient Gem
// 컨셉: 다이아몬드/보석 형태 + 그라데이션 — 프리미엄/럭셔리
// ============================================================
class GradientGemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final unit = size.width / 10;

    // 배경
    final bgPaint = Paint()..color = WsColors.bg;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.22),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // 보석 형태: 여러 삼각형 패싯으로 구성
    final gemSize = unit * 3.2;

    // 상단 삼각형 (크라운)
    _drawFacet(canvas, center, [
      Offset(center.dx, center.dy - gemSize * 1.1),
      Offset(center.dx - gemSize * 0.9, center.dy - gemSize * 0.2),
      Offset(center.dx + gemSize * 0.9, center.dy - gemSize * 0.2),
    ], WsColors.accent1, WsColors.accent1.withValues(alpha: 0.8));

    // 좌상단 패싯
    _drawFacet(canvas, center, [
      Offset(center.dx, center.dy - gemSize * 1.1),
      Offset(center.dx - gemSize * 0.9, center.dy - gemSize * 0.2),
      Offset(center.dx - gemSize * 0.5, center.dy + gemSize * 0.1),
    ], Color.lerp(WsColors.accent1, WsColors.accent2, 0.3)!,
        WsColors.accent1.withValues(alpha: 0.6));

    // 우상단 패싯
    _drawFacet(canvas, center, [
      Offset(center.dx, center.dy - gemSize * 1.1),
      Offset(center.dx + gemSize * 0.9, center.dy - gemSize * 0.2),
      Offset(center.dx + gemSize * 0.5, center.dy + gemSize * 0.1),
    ], Color.lerp(WsColors.accent1, WsColors.accent2, 0.5)!,
        WsColors.accent2.withValues(alpha: 0.7));

    // 중앙 패싯
    _drawFacet(canvas, center, [
      Offset(center.dx - gemSize * 0.5, center.dy + gemSize * 0.1),
      Offset(center.dx + gemSize * 0.5, center.dy + gemSize * 0.1),
      Offset(center.dx, center.dy - gemSize * 0.3),
    ], Color.lerp(WsColors.accent1, WsColors.accent2, 0.5)!,
        Colors.white.withValues(alpha: 0.15));

    // 좌하단 패싯
    _drawFacet(canvas, center, [
      Offset(center.dx - gemSize * 0.9, center.dy - gemSize * 0.2),
      Offset(center.dx - gemSize * 0.5, center.dy + gemSize * 0.1),
      Offset(center.dx, center.dy + gemSize * 1.1),
    ], WsColors.accent2,
        WsColors.accent2.withValues(alpha: 0.7));

    // 우하단 패싯
    _drawFacet(canvas, center, [
      Offset(center.dx + gemSize * 0.9, center.dy - gemSize * 0.2),
      Offset(center.dx + gemSize * 0.5, center.dy + gemSize * 0.1),
      Offset(center.dx, center.dy + gemSize * 1.1),
    ], WsColors.accent2.withValues(alpha: 0.85),
        Color.lerp(WsColors.accent2, WsColors.accent1, 0.3)!);

    // 하단 패싯 (포인트)
    _drawFacet(canvas, center, [
      Offset(center.dx - gemSize * 0.5, center.dy + gemSize * 0.1),
      Offset(center.dx + gemSize * 0.5, center.dy + gemSize * 0.1),
      Offset(center.dx, center.dy + gemSize * 1.1),
    ], Color.lerp(WsColors.accent1, WsColors.accent2, 0.7)!,
        WsColors.accent2);

    // 전체 글로우
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          WsColors.accent1.withValues(alpha: 0.2),
          WsColors.accent2.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: gemSize * 1.5))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.8);
    canvas.drawCircle(center, gemSize * 1.3, glowPaint);
  }

  void _drawFacet(Canvas canvas, Offset center, List<Offset> points,
      Color color1, Color color2) {
    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..close();

    // 면 채우기
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color1, color2],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(
          Rect.fromPoints(points[0], points[2]))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // 엣지 라인
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(path, edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// 시안 4: Minimal Glow S
// 컨셉: 미니멀 S + 글로우 링 — 깔끔하고 모던
// ============================================================
class MinimalGlowSPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final unit = size.width / 10;

    // 배경
    final bgPaint = Paint()..color = WsColors.bg;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.22),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // 외곽 글로우 링
    final ringRadius = unit * 3.3;
    final ringGlowPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          WsColors.accent1.withValues(alpha: 0.6),
          WsColors.accent2.withValues(alpha: 0.6),
          WsColors.accent1.withValues(alpha: 0.6),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: ringRadius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit * 0.25
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.5);
    canvas.drawCircle(center, ringRadius, ringGlowPaint);

    // 얇은 링
    final ringPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          WsColors.accent1,
          WsColors.accent2,
          WsColors.accent1,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: ringRadius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit * 0.12;
    canvas.drawCircle(center, ringRadius, ringPaint);

    // S 글자 — 그라데이션 스트로크로 직접 그리기
    final sPath = _buildSPath(center, unit);

    // S 글로우
    final sGlowPaint = Paint()
      ..shader = LinearGradient(
        colors: [WsColors.accent1, WsColors.accent2],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: unit * 3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit * 0.7
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.4);
    canvas.drawPath(sPath, sGlowPaint);

    // S 본체
    final sPaint = Paint()
      ..shader = LinearGradient(
        colors: [WsColors.accent1, WsColors.accent2],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: unit * 3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit * 0.55
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(sPath, sPaint);
  }

  Path _buildSPath(Offset center, double unit) {
    final path = Path();
    // S자 곡선: 상단 오른쪽에서 시작 → 왼쪽 아래로
    path.moveTo(center.dx + unit * 1.2, center.dy - unit * 1.8);

    // 상단 호
    path.cubicTo(
      center.dx + unit * 1.5, center.dy - unit * 2.5, // cp1
      center.dx - unit * 2.0, center.dy - unit * 2.5, // cp2
      center.dx - unit * 1.2, center.dy - unit * 0.8, // end
    );

    // 중간 연결
    path.cubicTo(
      center.dx - unit * 0.5, center.dy + unit * 0.2, // cp1
      center.dx + unit * 0.5, center.dy - unit * 0.2, // cp2
      center.dx + unit * 1.2, center.dy + unit * 0.8, // end
    );

    // 하단 호
    path.cubicTo(
      center.dx + unit * 2.0, center.dy + unit * 2.5, // cp1
      center.dx - unit * 1.5, center.dy + unit * 2.5, // cp2
      center.dx - unit * 1.2, center.dy + unit * 1.8, // end
    );

    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

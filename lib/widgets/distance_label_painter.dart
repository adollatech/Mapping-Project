import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:surveyapp/models/area.dart';
import 'package:surveyapp/services/location_service.dart';

class DistanceLabelPainter extends CustomPainter {
  final List<BoundaryPoint> boundaryPoints;
  final List<MappedArea> mappedAreas;
  final MappingMode currentMode;
  final MapController mapController;

  DistanceLabelPainter({
    required this.boundaryPoints,
    required this.mappedAreas,
    required this.currentMode,
    required this.mapController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw labels for current boundary points
    _drawBoundaryLabels(
        canvas, size, boundaryPoints, paint, textPainter, Colors.blue);

    // Draw labels for mapped areas
    for (final area in mappedAreas) {
      final color =
          area.mode == MappingMode.instant ? Colors.green : Colors.purple;
      _drawBoundaryLabels(
          canvas, size, area.boundaryPoints, paint, textPainter, color);
    }
  }

  void _drawBoundaryLabels(Canvas canvas, Size size, List<BoundaryPoint> points,
      Paint paint, TextPainter textPainter, Color color) {
    if (points.isEmpty) return;

    paint.color = color;

    for (int i = 0; i < points.length; i++) {
      final current = points[i];
      final next = i < points.length - 1
          ? points[i + 1]
          : (currentMode == MappingMode.instant && points.length > 2
              ? points.first
              : null);

      if (next != null) {
        final distance =
            LocationService.calculateDistance(current.position, next.position);

        // Convert LatLng to screen coordinates
        final currentScreen = _latLngToScreenPoint(current.position, size);
        final nextScreen = _latLngToScreenPoint(next.position, size);

        if (currentScreen != null && nextScreen != null) {
          // Calculate midpoint
          final midX = (currentScreen.dx + nextScreen.dx) / 2;
          final midY = (currentScreen.dy + nextScreen.dy) / 2;

          final text = '${distance.toStringAsFixed(1)} m';
          textPainter.text = TextSpan(
            text: text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();

          // Draw background
          final rect = Rect.fromLTWH(
            midX - textPainter.width / 2 - 4,
            midY - textPainter.height / 2 - 2,
            textPainter.width + 8,
            textPainter.height + 4,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            paint,
          );

          // Draw text
          textPainter.paint(
            canvas,
            Offset(
              midX - textPainter.width / 2,
              midY - textPainter.height / 2,
            ),
          );
        }
      }
    }
  }

  Offset? _latLngToScreenPoint(LatLng latLng, Size size) {
    try {
      final camera = mapController.camera;
      final offset = camera.latLngToScreenOffset(latLng);

      // Check if point is within screen bounds
      if (offset.dx >= 0 &&
          offset.dx <= size.width &&
          offset.dy >= 0 &&
          offset.dy <= size.height) {
        return offset;
      }
    } catch (e) {
      // Handle any conversion errors
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

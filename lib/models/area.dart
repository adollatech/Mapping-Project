import 'package:latlong2/latlong.dart';

enum MappingMode { instant, snap }

class BoundaryPoint {
  final LatLng position;
  final int index;
  final DateTime timestamp;
  final double? distanceToNext;

  BoundaryPoint({
    required this.position,
    required this.index,
    required this.timestamp,
    this.distanceToNext,
  });
}

class MappedArea {
  final String id;
  final List<BoundaryPoint> boundaryPoints;
  final MappingMode mode;
  final DateTime createdAt;
  final double? area;

  MappedArea({
    required this.id,
    required this.boundaryPoints,
    required this.mode,
    required this.createdAt,
    this.area,
  });

  List<LatLng> get polygon => boundaryPoints.map((p) => p.position).toList();
}

class SharedBoundary {
  final List<LatLng> points;
  final String originalAreaId;
  final String newAreaId;

  SharedBoundary({
    required this.points,
    required this.originalAreaId,
    required this.newAreaId,
  });
}
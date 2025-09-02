import 'package:latlong2/latlong.dart';

enum MappingMode { instant, snap }

class BoundaryPoint {
  final LatLng position;
  final int index;
  final DateTime timestamp;
  double? distanceToNext;

  BoundaryPoint({
    required this.position,
    required this.index,
    required this.timestamp,
    this.distanceToNext,
  });

  factory BoundaryPoint.fromJson(Map<String, dynamic> json) {
    return BoundaryPoint(
      position: LatLng(json['lat'], json['lng']),
      index: json['index'],
      timestamp: DateTime.parse(json['timestamp']),
      distanceToNext: json['distanceToNext'] != null
          ? (json['distanceToNext'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': position.latitude,
      'lng': position.longitude,
      'index': index,
      'timestamp': timestamp.toIso8601String(),
      'distanceToNext': distanceToNext,
    };
  }
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

  factory MappedArea.fromJson(Map<String, dynamic> json) {
    return MappedArea(
      id: json['id'],
      boundaryPoints: (json['boundaryPoints'] as List)
          .map((p) => BoundaryPoint.fromJson(p))
          .toList(),
      mode: MappingMode.values
          .firstWhere((m) => m.toString().split('.').last == json['mode']),
      createdAt: DateTime.parse(json['createdAt']),
      area: json['area'] != null ? (json['area'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'boundaryPoints': boundaryPoints.map((p) => p.toJson()).toList(),
      'mode': mode.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'area': area,
    };
  }
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

  factory SharedBoundary.fromJson(Map<String, dynamic> json) {
    return SharedBoundary(
      points: (json['points'] as List)
          .map((p) => LatLng(p['lat'], p['lng']))
          .toList(),
      originalAreaId: json['originalAreaId'],
      newAreaId: json['newAreaId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points':
          points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'originalAreaId': originalAreaId,
      'newAreaId': newAreaId,
    };
  }
}

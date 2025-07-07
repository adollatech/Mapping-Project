// widgets/distance_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:surveyapp/models/area.dart';
import '../services/location_service.dart';

class DistanceOverlay extends StatelessWidget {
  final List<BoundaryPoint> boundaryPoints;
  final MappingMode currentMode;
  final MapController mapController;

  const DistanceOverlay({
    super.key,
    required this.boundaryPoints,
    required this.currentMode,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _buildDistanceLabels(context),
    );
  }

  List<Widget> _buildDistanceLabels(BuildContext context) {
    final labels = <Widget>[];
    
    for (int i = 0; i < boundaryPoints.length; i++) {
      final current = boundaryPoints[i];
      final next = i < boundaryPoints.length - 1 
          ? boundaryPoints[i + 1]
          : (currentMode == MappingMode.instant && boundaryPoints.length > 2 
              ? boundaryPoints.first 
              : null);

      if (next != null) {
        final distance = LocationService.calculateDistance(current.position, next.position);
        
        // Calculate midpoint
        final midLat = (current.position.latitude + next.position.latitude) / 2;
        final midLng = (current.position.longitude + next.position.longitude) / 2;
        final midPoint = LatLng(midLat, midLng);

        labels.add(
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${distance.toStringAsFixed(1)} ft',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }
    }

    return labels;
  }
}
// widgets/instant_gps_mapping.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'dart:math';

import 'package:surveyapp/models/area.dart';
import 'package:surveyapp/services/location_service.dart';
import 'package:surveyapp/utils/utils.dart';
import 'package:surveyapp/widgets/map_markers.dart';

class InstantGpsMapping extends StatefulWidget {
  final LatLng? currentLocation;
  final List<BoundaryPoint> currentBoundaryPoints;
  final Function(BoundaryPoint) onPointAdded;
  final Function() onPointRemoved;
  final VoidCallback? onComplete;
  final List<MappedArea> mappedAreas;
  final bool showAllMappedAreas;
  final double minDistanceThreshold;

  const InstantGpsMapping({
    super.key,
    required this.currentLocation,
    required this.currentBoundaryPoints,
    required this.onPointAdded,
    required this.onPointRemoved,
    this.onComplete,
    required this.mappedAreas,
    required this.showAllMappedAreas,
    this.minDistanceThreshold = 1.0,
  });

  @override
  State<InstantGpsMapping> createState() => _InstantGpsMappingState();
}

class _InstantGpsMappingState extends State<InstantGpsMapping> {
  final MapController _mapController = MapController();
  double _currentZoom = 18.0;
  LatLng _mapCenter = LatLng(6.6745, -1.5716);

  @override
  void initState() {
    super.initState();
    if (widget.currentLocation != null) {
      _mapCenter = widget.currentLocation!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(widget.currentLocation!, _currentZoom);
      });
    }
  }

  void _captureLocation() {
    if (widget.currentLocation == null) return;

    bool isDuplicate = widget.currentBoundaryPoints.any((point) {
      final distance = LocationService.calculateDistance(
        point.position,
        widget.currentLocation!,
      );
      return distance < widget.minDistanceThreshold;
    });

    if (isDuplicate) {
      showSnackBar(
        context,
        'Location already captured. Move to a different location.',
        error: true,
      );
      return;
    }

    final point = BoundaryPoint(
      position: widget.currentLocation!,
      index: widget.currentBoundaryPoints.length + 1,
      timestamp: DateTime.now(),
    );

    widget.onPointAdded(point);
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (widget.currentLocation != null) {
      markers.add(
        Marker(
          point: widget.currentLocation!,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.my_location,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ),
      );
    }

    for (final point in widget.currentBoundaryPoints) {
      markers.add(
        Marker(
          point: point.position,
          child: NumberedMarker(
            number: point.index,
            backgroundColor: Colors.blue,
          ),
        ),
      );
    }

    if (widget.showAllMappedAreas) {
      for (final area in widget.mappedAreas) {
        for (final point in area.boundaryPoints) {
          markers.add(
            Marker(
              point: point.position,
              child: MapPinMarker(
                color: area.mode == MappingMode.instant
                    ? Colors.green
                    : Colors.purple,
              ),
            ),
          );
        }
      }
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    final polylines = <Polyline>[];

    if (widget.currentBoundaryPoints.length > 1) {
      final points =
          widget.currentBoundaryPoints.map((p) => p.position).toList();

      polylines.add(
        Polyline(
          points: points,
          strokeWidth: 3.0,
          color: Colors.blue,
        ),
      );

      if (points.length > 2) {
        polylines.add(
          Polyline(
            points: [points.last, points.first],
            strokeWidth: 3.0,
            color: Colors.blue,
            pattern: StrokePattern.dashed(segments: [10, 5]),
          ),
        );
      }
    }

    if (widget.showAllMappedAreas) {
      for (final area in widget.mappedAreas) {
        final points = area.polygon;
        if (points.length > 1) {
          polylines.add(
            Polyline(
              points: area.mode == MappingMode.instant
                  ? [...points, points.first]
                  : points,
              strokeWidth: 2.0,
              color: area.mode == MappingMode.instant
                  ? Colors.green.withOpacity(0.7)
                  : Colors.purple.withOpacity(0.7),
            ),
          );
        }
      }
    }

    return polylines;
  }

  List<Polygon> _buildPolygons() {
    final polygons = <Polygon>[];

    if (widget.showAllMappedAreas) {
      for (final area in widget.mappedAreas) {
        if (area.boundaryPoints.length >= 3) {
          polygons.add(
            Polygon(
              points: area.polygon,
              color: (area.mode == MappingMode.instant
                      ? Colors.green
                      : Colors.purple)
                  .withOpacity(0.2),
              borderColor: area.mode == MappingMode.instant
                  ? Colors.green
                  : Colors.purple,
              borderStrokeWidth: 2.0,
            ),
          );
        }
      }
    }

    return polygons;
  }

  double _calculateArea(List<LatLng> polygon) {
    if (polygon.length < 3) return 0.0;
    double area = 0.0;
    for (int i = 0; i < polygon.length; i++) {
      int j = (i + 1) % polygon.length;
      area += polygon[i].longitude * polygon[j].latitude;
      area -= polygon[j].longitude * polygon[i].latitude;
    }
    return (area.abs() / 2.0) * 111319.9 * 111319.9;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: ShadButton.outline(
                    leading: const Icon(Icons.add_location),
                    onPressed: _captureLocation,
                    child: const Text('Capture Location'),
                  ),
                ),
                if (widget.currentBoundaryPoints.length >= 3)
                  ShadButton(
                    onPressed: widget.onComplete,
                    child: const Text('Complete'),
                  ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _mapCenter,
                    initialZoom: _currentZoom,
                    onMapEvent: (event) {
                      if (event is MapEventMove) {
                        setState(() {
                          _currentZoom = event.camera.zoom;
                          _mapCenter = event.camera.center;
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.adollatech.latrace',
                    ),
                    PolygonLayer(polygons: _buildPolygons()),
                    PolylineLayer(polylines: _buildPolylines()),
                    MarkerLayer(markers: _buildMarkers()),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),

                // Control buttons
                Positioned(
                  right: 16,
                  top: 16,
                  child: Column(
                    spacing: 8,
                    children: [
                      // Zoom In
                      _buildControlButton(
                        icon: Icons.add,
                        tooltip: 'Zoom In',
                        onPressed: () {
                          final newZoom = (_currentZoom + 1).clamp(1.0, 22.0);
                          _mapController.move(_mapCenter, newZoom);
                          setState(() {
                            _currentZoom = newZoom;
                          });
                        },
                      ),

                      // Zoom Out
                      _buildControlButton(
                        icon: Icons.remove,
                        tooltip: 'Zoom Out',
                        onPressed: () {
                          final newZoom = (_currentZoom - 1).clamp(1.0, 22.0);
                          _mapController.move(_mapCenter, newZoom);
                          setState(() {
                            _currentZoom = newZoom;
                          });
                        },
                      ),

                      // Current Location
                      _buildControlButton(
                        icon: Icons.my_location,
                        tooltip: 'My Location',
                        onPressed: () {
                          if (widget.currentLocation != null) {
                            _mapController.move(
                                widget.currentLocation!, _currentZoom);
                            setState(() {
                              _mapCenter = widget.currentLocation!;
                            });
                          }
                        },
                      ),

                      // Undo Last Point
                      _buildControlButton(
                        icon: Icons.undo,
                        tooltip: 'Undo Last Point',
                        backgroundColor: widget.currentBoundaryPoints.isNotEmpty
                            ? Colors.orange
                            : null,
                        onPressed: widget.currentBoundaryPoints.isNotEmpty
                            ? widget.onPointRemoved
                            : null,
                      ),
                    ],
                  ),
                ),

                // Scale indicator
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(156 / pow(2, _currentZoom - 10)).toStringAsFixed(0)} m',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),

                // Info panel
                if (widget.currentBoundaryPoints.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withOpacity(0.9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Mode: INSTANT GPS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Points: ${widget.currentBoundaryPoints.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (widget.currentBoundaryPoints.length > 2)
                            Text(
                              'Area: ${(_calculateArea(widget.currentBoundaryPoints.map((p) => p.position).toList()) / 10000).toStringAsFixed(2)} ha',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          const Text(
                            'Tap "Capture Location" to add points',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? backgroundColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: backgroundColor != null &&
                    backgroundColor != Colors.white &&
                    backgroundColor != Colors.grey
                ? Colors.white
                : Colors.black,
          ),
          iconSize: 20,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'dart:async';
import 'dart:math';

import 'package:surveyapp/models/area.dart';
import 'package:surveyapp/services/location_service.dart';
import 'package:surveyapp/utils/utils.dart';
import 'package:surveyapp/widgets/distance_label_painter.dart';
import 'package:surveyapp/widgets/map_markers.dart';

class BoundaryMapping extends StatefulWidget {
  const BoundaryMapping({super.key, required this.onSubmitAreaMapped});
  final void Function(MappedArea area) onSubmitAreaMapped;

  @override
  State<BoundaryMapping> createState() => _BoundaryMappingState();
}

class _BoundaryMappingState extends State<BoundaryMapping> {
  final MapController _mapController = MapController();

  // State variables
  MappingMode _currentMode = MappingMode.instant;
  bool _isRecording = false;
  LatLng? _currentLocation;
  StreamSubscription<LatLng>? _locationSubscription;

  // Mapping data
  final List<BoundaryPoint> _currentBoundaryPoints = [];
  final List<MappedArea> _mappedAreas = [];
  final List<SharedBoundary> _sharedBoundaries = [];

  // UI state
  double _currentZoom = 18.0;
  bool _showAllMappedAreas = true;
  LatLng _mapCenter = LatLng(6.6745, -1.5716); // Kumasi, Ghana

  // Minimum distance threshold for duplicate detection (in meters)
  final double _minDistanceThreshold = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    final location = await LocationService.getCurrentLocation();
    if (location != null) {
      setState(() {
        _currentLocation = location;
        _mapCenter = location;
      });
      _mapController.move(location, _currentZoom);
    }
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    if (_currentLocation == null) return;

    setState(() {
      _isRecording = true;
      _currentBoundaryPoints.clear();
    });

    // Start listening to location updates
    _locationSubscription = LocationService.getLocationStream().listen(
      (location) {
        setState(() {
          _currentLocation = location;
        });
      },
    );
  }

  void _stopRecording() {
    _locationSubscription?.cancel();

    if (_currentBoundaryPoints.length >= 3) {
      _completeMappedArea();
    }

    setState(() {
      _isRecording = false;
    });
  }

  void _captureLocation() {
    if (!_isRecording || _currentLocation == null) return;

    // Check for duplicates
    bool isDuplicate = _currentBoundaryPoints.any((point) {
      final distance =
          LocationService.calculateDistance(point.position, _currentLocation!);
      return distance < _minDistanceThreshold;
    });

    if (isDuplicate) {
      showSnackBar(
          context, 'Location already captured. Move to a different location.',
          error: true);
      return;
    }

    _addBoundaryPoint(_currentLocation!);
  }

  void _addBoundaryPoint(LatLng location) {
    final point = BoundaryPoint(
      position: location,
      index: _currentBoundaryPoints.length + 1,
      timestamp: DateTime.now(),
    );

    setState(() {
      _currentBoundaryPoints.add(point);
    });
  }

  void _undoLastPoint() {
    if (_currentBoundaryPoints.isNotEmpty) {
      setState(() {
        _currentBoundaryPoints.removeLast();
      });
    }
  }

  void _completeMappedArea() {
    // Calculate distances between consecutive points
    final updatedPoints = <BoundaryPoint>[];
    for (int i = 0; i < _currentBoundaryPoints.length; i++) {
      final current = _currentBoundaryPoints[i];
      double? distance;

      if (i < _currentBoundaryPoints.length - 1) {
        distance = LocationService.calculateDistance(
          current.position,
          _currentBoundaryPoints[i + 1].position,
        );
      } else if (_currentMode == MappingMode.instant) {
        // Close the polygon for instant mode
        distance = LocationService.calculateDistance(
          current.position,
          _currentBoundaryPoints.first.position,
        );
      }

      updatedPoints.add(BoundaryPoint(
        position: current.position,
        index: current.index,
        timestamp: current.timestamp,
        distanceToNext: distance,
      ));
    }

    final mappedArea = MappedArea(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      boundaryPoints: updatedPoints,
      mode: _currentMode,
      createdAt: DateTime.now(),
      area: _calculateArea(updatedPoints.map((p) => p.position).toList()),
    );

    setState(() {
      _mappedAreas.add(mappedArea);
      _currentBoundaryPoints.clear();
    });

    _showCompletionDialog(mappedArea);
    widget.onSubmitAreaMapped(mappedArea);
  }

  double _calculateArea(List<LatLng> polygon) {
    if (polygon.length < 3) return 0.0;

    double area = 0.0;
    for (int i = 0; i < polygon.length; i++) {
      int j = (i + 1) % polygon.length;
      area += polygon[i].longitude * polygon[j].latitude;
      area -= polygon[j].longitude * polygon[i].latitude;
    }
    return (area.abs() / 2.0) * 111319.9 * 111319.9; // Convert to square meters
  }

  void _showCompletionDialog(MappedArea area) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Area Mapped Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mode: ${area.mode.name.toUpperCase()}'),
            Text('Points: ${area.boundaryPoints.length}'),
            Text('Area: ${(area.area! / 10000).toStringAsFixed(2)} hectares'),
            Text('Created: ${_formatDateTime(area.createdAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => widget.onSubmitAreaMapped(area),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showClearConfirmationDialog() {
    if (_mappedAreas.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Areas'),
        content: const Text('Are you sure you want to clear all mapped areas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _mappedAreas.clear();
                _sharedBoundaries.clear();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 20,
          height: 20,
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

    // Current boundary points (numbered markers)
    for (final point in _currentBoundaryPoints) {
      markers.add(
        Marker(
          point: point.position,
          width: 30,
          height: 30,
          child: NumberedMarker(
            number: point.index,
            backgroundColor: Colors.blue,
          ),
        ),
      );
    }

    // Previous mapped areas (map pins)
    if (_showAllMappedAreas) {
      for (final area in _mappedAreas) {
        for (final point in area.boundaryPoints) {
          markers.add(
            Marker(
              point: point.position,
              width: 25,
              height: 25,
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

    // Current boundary polyline
    if (_currentBoundaryPoints.length > 1) {
      final points = _currentBoundaryPoints.map((p) => p.position).toList();

      polylines.add(
        Polyline(
          points: points,
          strokeWidth: 3.0,
          color: Colors.blue,
        ),
      );

      // Close polygon for instant mode
      if (_currentMode == MappingMode.instant && points.length > 2) {
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

    // Mapped areas polylines
    if (_showAllMappedAreas) {
      for (final area in _mappedAreas) {
        final points = area.polygon;
        if (points.length > 1) {
          polylines.add(
            Polyline(
              points: area.mode == MappingMode.instant
                  ? [...points, points.first] // Close polygon
                  : points,
              strokeWidth: 2.0,
              color: area.mode == MappingMode.instant
                  ? Colors.green.withValues(alpha: 0.7)
                  : Colors.purple.withValues(alpha: 0.7),
            ),
          );
        }
      }
    }

    return polylines;
  }

  List<Polygon> _buildPolygons() {
    final polygons = <Polygon>[];

    // Add filled polygons for completed areas
    if (_showAllMappedAreas) {
      for (final area in _mappedAreas) {
        if (area.boundaryPoints.length >= 3) {
          polygons.add(
            Polygon(
              points: area.mode == MappingMode.instant
                  ? area.polygon
                  : area.polygon,
              color: (area.mode == MappingMode.instant
                      ? Colors.green
                      : Colors.purple)
                  .withValues(alpha: 0.2),
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

  @override
  Widget build(BuildContext context) {
    var tooltip = _isRecording ? 'Stop Recording' : 'Start Recording';
    return Scaffold(
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButton: FloatingActionButton.extended(
        shape: _isRecording
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
            : CircleBorder(),
        tooltip: tooltip,
        backgroundColor: _isRecording ? Colors.red : Colors.white,
        isExtended: _isRecording,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: _toggleRecording,
        icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
        extendedPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        label: Text(
          tooltip,
          style: TextStyle(color: _isRecording ? Colors.white : Colors.black87),
        ),
      ),
      body: Column(
        children: [
          // Mode selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: ShadSelect<MappingMode>(
                      placeholder: const Text('Select Mode'),
                      initialValue: _currentMode,
                      enabled: !_isRecording,
                      selectedOptionBuilder: (ctx, mode) {
                        return Text(
                          '${mode.name.characters.first.toUpperCase()}${mode.name.substring(1)} GPS',
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                      options: MappingMode.values.map((mappingMode) {
                        return ShadOption<MappingMode>(
                          value: mappingMode,
                          child: Text(
                            '${mappingMode.name.characters.first.toUpperCase()}${mappingMode.name.substring(1)} GPS',
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                      onChanged: _isRecording
                          ? null
                          : (value) {
                              setState(() {
                                _currentMode = value!;
                              });
                            }),
                ),
                ShadButton.outline(
                  leading: Icon(Icons.add_location),
                  onPressed: _isRecording ? _captureLocation : null,
                  child: Text('Capture'),
                )
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
                    // Distance labels overlay
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

                // Distance labels overlay
                if (_showAllMappedAreas || _currentBoundaryPoints.isNotEmpty)
                  _buildDistanceLabelsOverlay(),

                // Control buttons
                Positioned(
                  right: 16,
                  top: 16,
                  child: Column(
                    spacing: 44,
                    children: [
                      Column(
                        spacing: 8,
                        children: [
                          // Zoom In
                          _buildControlButton(
                            icon: Icons.add,
                            tooltip: 'Zoom In',
                            onPressed: () {
                              final newZoom =
                                  (_currentZoom + 1).clamp(1.0, 22.0);
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
                              final newZoom =
                                  (_currentZoom - 1).clamp(1.0, 22.0);
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
                              if (_currentLocation != null) {
                                _mapController.move(
                                    _currentLocation!, _currentZoom);
                                setState(() {
                                  _mapCenter = _currentLocation!;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      Column(
                        spacing: 8,
                        children: [
                          // Undo Last Point
                          _buildControlButton(
                            icon: Icons.undo,
                            tooltip: 'Undo Last Point',
                            backgroundColor: _currentBoundaryPoints.isNotEmpty
                                ? Colors.orange
                                : null,
                            onPressed: _currentBoundaryPoints.isNotEmpty
                                ? _undoLastPoint
                                : null,
                          ),

                          // Clear All Areas
                          _buildControlButton(
                            icon: Icons.delete_outline,
                            tooltip: 'Clear All Areas',
                            backgroundColor:
                                _mappedAreas.isNotEmpty ? Colors.red : null,
                            onPressed: _mappedAreas.isNotEmpty
                                ? _showClearConfirmationDialog
                                : null,
                          ),

                          // Toggle Visibility
                          _buildControlButton(
                            icon: _showAllMappedAreas
                                ? Icons.visibility
                                : Icons.visibility_off,
                            tooltip: _showAllMappedAreas
                                ? 'Hide Areas'
                                : 'Show Areas',
                            onPressed: _mappedAreas.isEmpty
                                ? null
                                : () {
                                    setState(() {
                                      _showAllMappedAreas =
                                          !_showAllMappedAreas;
                                    });
                                  },
                          ),
                        ],
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
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(156 / pow(2, _currentZoom - 10)).toStringAsFixed(0)} m',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),

                // Info panel
                if (_currentBoundaryPoints.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withValues(alpha: 1.0),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Points: ${_currentBoundaryPoints.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_currentBoundaryPoints.length > 2)
                            Text(
                              'Area: ${(_calculateArea(_currentBoundaryPoints.map((p) => p.position).toList()) / 10000).toStringAsFixed(2)} ha',
                              style: const TextStyle(fontSize: 12),
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
              color: Colors.black.withValues(alpha: 0.1),
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

  Widget _buildDistanceLabelsOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: DistanceLabelPainter(
            boundaryPoints: _currentBoundaryPoints,
            mappedAreas: _showAllMappedAreas ? _mappedAreas : [],
            currentMode: _currentMode,
            mapController: _mapController,
          ),
        ),
      ),
    );
  }
}

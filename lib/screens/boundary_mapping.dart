// boundary_mapping.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'dart:async';

import 'package:surveyapp/models/area.dart';
import 'package:surveyapp/services/location_service.dart';
import 'package:surveyapp/utils/utils.dart';
import 'package:surveyapp/widgets/instant_gps_mapping.dart';
import 'package:surveyapp/widgets/snap_gps_mapping.dart';

class BoundaryMapping extends StatefulWidget {
  const BoundaryMapping({super.key, required this.onSubmitAreaMapped});
  final void Function(MappedArea area) onSubmitAreaMapped;

  @override
  State<BoundaryMapping> createState() => _BoundaryMappingState();
}

class _BoundaryMappingState extends State<BoundaryMapping> {
  // State variables
  MappingMode _currentMode = MappingMode.instant;
  bool _isRecording = false;
  LatLng? _currentLocation;
  StreamSubscription<LatLng>? _locationSubscription;

  // Mapping data
  final List<BoundaryPoint> _currentBoundaryPoints = [];
  final List<MappedArea> _mappedAreas = [];

  // UI state
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
    if (_currentLocation == null) {
      showSnackBar(
          context, 'Location not available. Please enable location services.',
          error: true);
      return;
    }

    setState(() {
      _isRecording = true;
      _currentBoundaryPoints.clear();
    });

    // Start listening to location updates for instant mode
    if (_currentMode == MappingMode.instant) {
      _locationSubscription = LocationService.getLocationStream().listen(
        (location) {
          setState(() {
            _currentLocation = location;
          });
        },
      );
    }
  }

  void _stopRecording() {
    _locationSubscription?.cancel();

    setState(() {
      _isRecording = false;
    });

    // Auto-complete if we have enough points
    if (_currentBoundaryPoints.length >= 3) {
      _completeMappedArea();
    } else if (_currentBoundaryPoints.isNotEmpty) {
      showSnackBar(context, 'Need at least 3 points to create an area.');
    }
  }

  void _addBoundaryPoint(BoundaryPoint point) {
    setState(() {
      _currentBoundaryPoints.add(point);
    });
  }

  void _removeBoundaryPoint() {
    if (_currentBoundaryPoints.isNotEmpty) {
      setState(() {
        _currentBoundaryPoints.removeLast();
      });
    }
  }

  void _completeMappedArea() {
    if (_currentBoundaryPoints.length < 3) {
      showSnackBar(context, 'Need at least 3 points to create an area.',
          error: true);
      return;
    }

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
      _isRecording = false;
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showClearConfirmationDialog() {
    if (_mappedAreas.isEmpty && _currentBoundaryPoints.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'Are you sure you want to clear all mapped areas and current points?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _mappedAreas.clear();
                _currentBoundaryPoints.clear();
                _isRecording = false;
              });
              _locationSubscription?.cancel();
              Navigator.of(context).pop();
              showSnackBar(context, 'All data cleared.');
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boundary Mapping'),
        elevation: 1,
        actions: [
          // Toggle visibility button
          IconButton(
            onPressed: _mappedAreas.isEmpty
                ? null
                : () {
                    setState(() {
                      _showAllMappedAreas = !_showAllMappedAreas;
                    });
                  },
            icon: Icon(
                _showAllMappedAreas ? Icons.visibility : Icons.visibility_off),
            tooltip: _showAllMappedAreas
                ? 'Hide Previous Areas'
                : 'Show Previous Areas',
          ),

          // Clear all button
          IconButton(
            onPressed: (_mappedAreas.isEmpty && _currentBoundaryPoints.isEmpty)
                ? null
                : _showClearConfirmationDialog,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear All',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleRecording,
        backgroundColor: _isRecording ? null : null,
        icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
        label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
      ),
      body: Column(
        children: [
          // Mode selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: null,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ShadSelect<MappingMode>(
                    placeholder: const Text('Select Mapping Mode'),
                    initialValue: _currentMode,
                    enabled: !_isRecording,
                    selectedOptionBuilder: (ctx, mode) {
                      return Row(
                        children: [
                          Icon(
                            mode == MappingMode.instant
                                ? Icons.gps_fixed
                                : Icons.map,
                            size: 20,
                            color: null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${mode.name.characters.first.toUpperCase()}${mode.name.substring(1)} GPS',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    },
                    options: MappingMode.values.map((mappingMode) {
                      return ShadOption<MappingMode>(
                        value: mappingMode,
                        child: Row(
                          children: [
                            Icon(
                              mappingMode == MappingMode.instant
                                  ? Icons.gps_fixed
                                  : Icons.map,
                              size: 20,
                              color: null,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${mappingMode.name.characters.first.toUpperCase()}${mappingMode.name.substring(1)} GPS',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  mappingMode == MappingMode.instant
                                      ? 'Capture points using current location'
                                      : 'Select points from previous surveys',
                                  style: TextStyle(fontSize: 12, color: null),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _isRecording
                        ? null
                        : (value) {
                            setState(() {
                              _currentMode = value!;
                              _currentBoundaryPoints
                                  .clear(); // Clear points when switching modes
                            });
                          },
                  ),
                ),

                const SizedBox(width: 16),

                // Status indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: null,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: null,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isRecording ? 'Recording' : 'Stopped',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Current mapping widget
          Expanded(
            child: _isRecording
                ? (_currentMode == MappingMode.instant
                    ? InstantGpsMapping(
                        key: ValueKey('instant_${_currentMode.name}'),
                        currentLocation: _currentLocation,
                        currentBoundaryPoints: _currentBoundaryPoints,
                        onPointAdded: _addBoundaryPoint,
                        onPointRemoved: _removeBoundaryPoint,
                        onComplete: _completeMappedArea,
                        mappedAreas: _mappedAreas,
                        showAllMappedAreas: _showAllMappedAreas,
                        minDistanceThreshold: _minDistanceThreshold,
                      )
                    : SnapGpsMapping(
                        key: ValueKey('snap_${_currentMode.name}'),
                        currentLocation: _currentLocation,
                        currentBoundaryPoints: _currentBoundaryPoints,
                        onPointAdded: _addBoundaryPoint,
                        onPointRemoved: _removeBoundaryPoint,
                        onComplete: _completeMappedArea,
                        mappedAreas: _mappedAreas,
                        showAllMappedAreas: _showAllMappedAreas,
                      ))
                : _buildIdleState(),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _currentMode == MappingMode.instant ? Icons.gps_fixed : Icons.map,
            size: 80,
            color: null,
          ),
          const SizedBox(height: 24),
          Text(
            _currentMode == MappingMode.instant
                ? 'Instant GPS Mapping'
                : 'Snap GPS Mapping',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentMode == MappingMode.instant
                ? 'Capture boundary points using your current GPS location. Walk to each corner of the area and tap "Capture Location".'
                : 'Create boundaries by selecting points from previously surveyed areas. Choose points that form the boundary of your new area.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: null,
            ),
          ),
          const SizedBox(height: 32),

          // Summary cards
          if (_mappedAreas.isNotEmpty) ...[
            const Text(
              'Previous Areas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: null,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _mappedAreas.length,
                itemBuilder: (context, index) {
                  final area = _mappedAreas[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  area.mode == MappingMode.instant
                                      ? Icons.gps_fixed
                                      : Icons.map,
                                  size: 16,
                                  color: null,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${area.mode.name.toUpperCase()} GPS',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${area.boundaryPoints.length} points',
                              style: TextStyle(color: null),
                            ),
                            Text(
                              '${((area.area ?? 0) / 10000).toStringAsFixed(2)} ha',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, color: null),
                            ),
                            Text(
                              _formatDateTime(area.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: null),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap "Start Recording" to begin mapping with ${_currentMode.name.toUpperCase()} GPS mode.',
                    style: TextStyle(
                      color: null,
                      fontWeight: FontWeight.w500,
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
}

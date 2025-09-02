import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'dart:async';
import 'dart:math';

import 'package:surveyapp/models/area.dart';
import 'package:surveyapp/models/survey_response.dart';
import 'package:surveyapp/services/location_service.dart';
import 'package:surveyapp/utils/utils.dart';
import 'package:surveyapp/widgets/distance_label_painter.dart';
import 'package:surveyapp/widgets/map_markers.dart';
import 'package:surveyapp/widgets/selectable_survey_list.dart';
import 'package:surveyapp/widgets/survey_selection_sheet.dart';

class BoundaryMappingScreen extends StatefulWidget {
  const BoundaryMappingScreen(
      {super.key,
      required this.onSubmitAreaMapped,
      required this.onSaveAreaMappedOffline});
  final void Function(MappedArea area) onSubmitAreaMapped;
  final void Function(MappedArea area) onSaveAreaMappedOffline;

  @override
  State<BoundaryMappingScreen> createState() => _BoundaryMappingScreenState();
}

class _BoundaryMappingScreenState extends State<BoundaryMappingScreen> {
  final MapController _mapController = MapController();

  // State variables
  MappingMode _currentMode = MappingMode.instant;
  bool _isRecording = false;
  LatLng? _currentLocation;
  StreamSubscription<LatLng>? _locationSubscription;

  // Mapping data
  final List<BoundaryPoint> _currentBoundaryPoints = [];
  final List<MappedArea> _mappedAreas = [];

  // Snap GPS state
  SurveyResponse? _selectedSurveyForSnapping;
  final List<BoundaryPoint> _snappedPoints = [];

  // UI state
  double _currentZoom = 18.0;
  bool _showAllMappedAreas = true;
  LatLng _mapCenter = LatLng(6.6745, -1.5716); // Kumasi, Ghana

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
    if (location != null && mounted) {
      setState(() {
        _currentLocation = location;
        _mapCenter = location;
      });
      _mapController.move(location, _currentZoom);
    }
  }

  void _onModeChanged(MappingMode? value) {
    if (value == null || _isRecording) return;

    setState(() {
      _currentMode = value;
      _selectedSurveyForSnapping = null;
      _snappedPoints.clear();
      _currentBoundaryPoints.clear();
    });

    if (value == MappingMode.snap) {
      _showSurveySelectionSheet();
    }
  }

  void _showSurveySelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SurveySelectionSheet(
          title: 'Select Survey',
          onClose: () => context.pop(),
          listView: SelectableSurveyList(
            onSelect: (survey) {
              setState(() {
                _selectedSurveyForSnapping = survey;
              });
              Navigator.of(context).pop();
              if (survey.mappedArea.polygon.isNotEmpty) {
                _mapController.move(survey.mappedArea.polygon.first, 19);
              }
            },
          ),
        );
      },
    );
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    if (_currentMode == MappingMode.snap) {
      if (_snappedPoints.length < 2) {
        if (_selectedSurveyForSnapping == null) {
          _showSurveySelectionSheet();
          return;
        }
        showSnackBar(context,
            'Please select at least 2 points from the existing survey to start.',
            error: true);
        return;
      }
      // Re-index the snapped points and add them to the current session
      final newPoints = _snappedPoints.asMap().entries.map((entry) {
        int idx = entry.key;
        BoundaryPoint p = entry.value;
        return BoundaryPoint(
          position: p.position,
          index: idx + 1,
          timestamp: DateTime.now(),
        );
      }).toList();

      setState(() {
        _currentBoundaryPoints.addAll(newPoints);
        _selectedSurveyForSnapping = null; // Hide the selected survey overlay
        _snappedPoints.clear();
      });
    }

    if (_currentLocation == null) return;

    setState(() {
      _isRecording = true;
      if (_currentMode == MappingMode.instant) _currentBoundaryPoints.clear();
    });

    _locationSubscription =
        LocationService.getLocationStream().listen((location) {
      if (mounted) {
        setState(() => _currentLocation = location);
      }
    });
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
      // In snap mode, don't allow undoing the initial snapped points
      if (_currentMode == MappingMode.snap &&
          _currentBoundaryPoints.length <= _snappedPoints.length) {
        return;
      }
      setState(() {
        _currentBoundaryPoints.removeLast();
      });
    }
  }

  void _updateDistances(List<BoundaryPoint> points, MappingMode mode) {
    for (int i = 0; i < points.length; i++) {
      final current = points[i];
      double? distance;

      if (i < points.length - 1) {
        distance = LocationService.calculateDistance(
          current.position,
          points[i + 1].position,
        );
      } else if (mode == MappingMode.instant) {
        distance = LocationService.calculateDistance(
          current.position,
          points.first.position,
        );
      }
      current.distanceToNext = distance;
    }
  }

  void _completeMappedArea() {
    _updateDistances(_currentBoundaryPoints, _currentMode);

    final mappedArea = MappedArea(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      boundaryPoints: List.from(_currentBoundaryPoints),
      mode: _currentMode,
      createdAt: DateTime.now(),
      area: _calculateArea(
          _currentBoundaryPoints.map((p) => p.position).toList()),
    );

    setState(() {
      _mappedAreas.add(mappedArea);
      _currentBoundaryPoints.clear();
    });

    _showCompletionDialog(mappedArea);
  }

  double _calculateArea(List<LatLng> polygon) {
    if (polygon.length < 3) return 0.0;
    double area = 0.0;
    for (int i = 0; i < polygon.length; i++) {
      int j = (i + 1) % polygon.length;
      area += polygon[i].longitudeInRad * sin(polygon[j].latitudeInRad);
      area -= polygon[j].longitudeInRad * sin(polygon[i].latitudeInRad);
    }
    area = area * 6378137.0 * 6378137.0 / 2.0;
    return area.abs();
  }

  void _handleMapTap(TapPosition tapPosition, LatLng latlng) {
    if (_currentMode != MappingMode.snap ||
        _selectedSurveyForSnapping == null ||
        _isRecording) {
      return;
    }

    BoundaryPoint? tappedPoint;
    double minDistance = double.infinity;

    for (final point in _selectedSurveyForSnapping!.mappedArea.boundaryPoints) {
      final distance =
          LocationService.calculateDistance(point.position, latlng);
      if (distance < 20 && distance < minDistance) {
        // 20 meters tap radius
        minDistance = distance;
        tappedPoint = point;
      }
    }

    if (tappedPoint != null) {
      _onSnapPointSelected(tappedPoint);
    }
  }

  void _onSnapPointSelected(BoundaryPoint point) {
    setState(() {
      if (_snappedPoints.contains(point)) {
        _snappedPoints.remove(point);
      } else {
        // Here you could add logic to ensure selected points are contiguous
        // For simplicity, we allow any selection.
        _snappedPoints.add(point);
      }
    });
  }

  void _showCompletionDialog(MappedArea area) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Area Mapped Successfully'),
        actions: [
          ShadButton.secondary(
            onPressed: () {
              widget.onSaveAreaMappedOffline(area);
              context.pop();
            },
            child: const Text('Save'),
          ),
          ShadButton(
            onPressed: () {
              widget.onSubmitAreaMapped(area);
              context.pop();
            },
            child: const Text('Submit'),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mode: ${_currentMode.name.toUpperCase()}'),
            Text('Points: ${area.boundaryPoints.length}'),
            Text('Area: ${(area.area! / 10000).toStringAsFixed(4)} hectares'),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Current location marker
    if (_currentLocation != null) {
      markers.add(Marker(
        point: _currentLocation!,
        width: 20,
        height: 20,
        child: CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.my_location, color: Colors.white, size: 12)),
      ));
    }

    // Markers for the survey selected for snapping
    if (_selectedSurveyForSnapping != null && !_isRecording) {
      for (final point
          in _selectedSurveyForSnapping!.mappedArea.boundaryPoints) {
        final isSelected = _snappedPoints.contains(point);
        markers.add(Marker(
          point: point.position,
          width: 35,
          height: 35,
          child: NumberedMarker(
            number: point.index,
            backgroundColor: isSelected ? Colors.orange : Colors.purple,
          ),
        ));
      }
    }

    // Current boundary points being recorded
    for (final point in _currentBoundaryPoints) {
      markers.add(Marker(
        point: point.position,
        width: 30,
        height: 30,
        child:
            NumberedMarker(number: point.index, backgroundColor: Colors.blue),
      ));
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    final polylines = <Polyline>[];

    // Polyline for the survey selected for snapping
    if (_selectedSurveyForSnapping != null && !_isRecording) {
      final area = _selectedSurveyForSnapping!.mappedArea;
      final points = area.polygon;
      polylines.add(Polyline(
        points: area.mode == MappingMode.instant
            ? [...points, points.first]
            : points,
        strokeWidth: 4.0,
        color: Colors.purple.withValues(alpha: .7),
      ));
    }

    // Current boundary polyline
    if (_currentBoundaryPoints.length > 1) {
      final points = _currentBoundaryPoints.map((p) => p.position).toList();
      polylines
          .add(Polyline(points: points, strokeWidth: 3.0, color: Colors.blue));

      if (_currentMode == MappingMode.instant && points.length > 2) {
        polylines.add(Polyline(
          points: [points.last, points.first],
          strokeWidth: 3.0,
          color: Colors.blue,
          pattern: StrokePattern.dashed(segments: [10, 5]),
        ));
      }
    }

    // Previously mapped areas
    if (_showAllMappedAreas) {
      for (final area in _mappedAreas) {
        if (area.id == _selectedSurveyForSnapping?.mappedArea.id) continue;
        final points = area.polygon;
        if (points.length > 1) {
          polylines.add(Polyline(
            points: area.mode == MappingMode.instant
                ? [...points, points.first]
                : points,
            strokeWidth: 2.0,
            color: Colors.green.withValues(alpha: 0.6),
          ));
        }
      }
    }

    return polylines;
  }

  List<Polygon> _buildPolygons() {
    final polygons = <Polygon>[];
    if (_showAllMappedAreas) {
      for (final area in _mappedAreas) {
        if (area.boundaryPoints.length >= 3) {
          polygons.add(Polygon(
            points: area.polygon,
            color: (area.id == _selectedSurveyForSnapping?.mappedArea.id
                    ? Colors.purple
                    : Colors.green)
                .withValues(alpha: 0.15),
            borderColor: (area.id == _selectedSurveyForSnapping?.mappedArea.id
                    ? Colors.purple
                    : Colors.green)
                .withValues(alpha: 0.5),
            borderStrokeWidth: 2.0,
          ));
        }
      }
    }
    return polygons;
  }

  @override
  Widget build(BuildContext context) {
    var tooltip = _isRecording ? 'Stop Recording' : 'Start Recording';
    var itemColor = _isRecording
        ? Colors.white
        : Theme.of(context).primaryTextTheme.bodyMedium?.color;
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleRecording,
        label: Text(
          tooltip,
          style: TextStyle(color: itemColor),
        ),
        icon: Icon(
          _isRecording ? Icons.stop : Icons.play_arrow,
          color: itemColor,
        ),
        backgroundColor:
            _isRecording ? Colors.red : Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ShadSelect<MappingMode>(
                    placeholder: const Text('Select Mode'),
                    initialValue: _currentMode,
                    enabled: !_isRecording,
                    selectedOptionBuilder: (ctx, mode) => Text(
                        '${mode.name[0].toUpperCase()}${mode.name.substring(1)} GPS'),
                    options: MappingMode.values
                        .map((mode) => ShadOption<MappingMode>(
                              value: mode,
                              child: Text(
                                  '${mode.name[0].toUpperCase()}${mode.name.substring(1)} GPS'),
                            ))
                        .toList(),
                    onChanged: _onModeChanged,
                  ),
                ),
                const SizedBox(width: 8),
                ShadButton.secondary(
                  onPressed: _isRecording ? _captureLocation : null,
                  child: const Text('Capture'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _mapCenter,
                initialZoom: _currentZoom,
                onTap: _handleMapTap,
                onMapEvent: (event) {
                  if (event is MapEventMove) {
                    setState(() {
                      _mapCenter = event.camera.center;
                    });
                  } else if (event is MapEventRotate) {
                    // handle rotate
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                PolygonLayer(polygons: _buildPolygons()),
                PolylineLayer(polylines: _buildPolylines()),
                MarkerLayer(markers: _buildMarkers()),
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
                          OverlayMapButton(
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
                          OverlayMapButton(
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
                          OverlayMapButton(
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
                          OverlayMapButton(
                            icon: Icons.undo,
                            tooltip: 'Undo Last Point',
                            backgroundColor: _currentBoundaryPoints.isNotEmpty
                                ? Colors.orange
                                : null,
                            onPressed: _currentBoundaryPoints.isNotEmpty
                                ? _undoLastPoint
                                : null,
                          ),

                          // Toggle Visibility
                          OverlayMapButton(
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

                CustomPaint(
                  painter: DistanceLabelPainter(
                    boundaryPoints: _currentBoundaryPoints,
                    mappedAreas: _showAllMappedAreas ? _mappedAreas : [],
                    currentMode: _currentMode,
                    mapController: _mapController,
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

class OverlayMapButton extends StatelessWidget {
  final String tooltip;
  final Color? backgroundColor;
  final VoidCallback? onPressed;
  final IconData icon;

  const OverlayMapButton({
    super.key,
    required this.tooltip,
    this.backgroundColor,
    this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
}

// widgets/snap_gps_mapping.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'dart:async';

import 'package:surveyapp/models/area.dart';
import 'package:surveyapp/models/survey_response.dart';
import 'package:surveyapp/services/database_service.dart';
import 'package:surveyapp/services/location_service.dart';
import 'package:surveyapp/utils/utils.dart';
import 'package:surveyapp/widgets/map_markers.dart';
import 'package:surveyapp/widgets/distance_label_painter.dart';

class SnapGpsMapping extends StatefulWidget {
  final LatLng? currentLocation;
  final List<BoundaryPoint> currentBoundaryPoints;
  final Function(BoundaryPoint) onPointAdded;
  final Function() onPointRemoved;
  final VoidCallback? onComplete;
  final List<MappedArea> mappedAreas;
  final bool showAllMappedAreas;

  const SnapGpsMapping({
    super.key,
    required this.currentLocation,
    required this.currentBoundaryPoints,
    required this.onPointAdded,
    required this.onPointRemoved,
    this.onComplete,
    required this.mappedAreas,
    required this.showAllMappedAreas,
  });

  @override
  State<SnapGpsMapping> createState() => _SnapGpsMappingState();
}

class _SnapGpsMappingState extends State<SnapGpsMapping> {
  final MapController _mapController = MapController();
  List<SurveyResponse> _availableSurveys = [];
  SurveyResponse? _selectedSurvey;
  Set<int> _selectedPointIndices = {};
  bool _isLoading = false;
  bool _showSurveySelection = false;
  double _currentZoom = 18.0;
  LatLng _mapCenter = LatLng(6.6745, -1.5716);

  @override
  void initState() {
    super.initState();
    _loadAvailableSurveys();
    if (widget.currentLocation != null) {
      _mapCenter = widget.currentLocation!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(widget.currentLocation!, _currentZoom);
      });
    }
  }

  Future<void> _loadAvailableSurveys() async {
    setState(() => _isLoading = true);

    try {
      final surveys = await DatabaseService().getAll<SurveyResponse>(
        'responses',
        expand: 'form',
        fromMap: (map) => SurveyResponse.fromJson(map),
      );

      setState(() {
        _availableSurveys = surveys
            .where((survey) => survey.mappedArea.boundaryPoints.length >= 3)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showSnackBar(context, 'Failed to load surveys: $e', error: true);
      }
    }
  }

  void _showSurveySelectionSheet() {
    setState(() => _showSurveySelection = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSurveySelectionSheet(),
    ).then((_) {
      setState(() => _showSurveySelection = false);
    });
  }

  Widget _buildSurveySelectionSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Survey',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _availableSurveys.isEmpty
                        ? const Center(
                            child: Text(
                              'No surveys available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _availableSurveys.length,
                            itemBuilder: (context, index) {
                              final survey = _availableSurveys[index];
                              return _buildSurveyCard(survey);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSurveyCard(SurveyResponse survey) {
    final isSelected = _selectedSurvey?.id == survey.id;
    final area = survey.mappedArea;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectSurvey(survey),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border:
                isSelected ? Border.all(color: Colors.blue, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Survey ${survey.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Colors.blue),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${area.boundaryPoints.length} points',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.crop_free, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${((area.area ?? 0) / 10000).toStringAsFixed(2)} ha',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Created: ${_formatDate(survey.created)}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _selectSurvey(SurveyResponse survey) {
    setState(() {
      _selectedSurvey = survey;
      _selectedPointIndices.clear();
    });

    if (survey.mappedArea.boundaryPoints.isNotEmpty) {
      final bounds = _calculateBounds(survey.mappedArea.polygon);
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds));
    }

    Navigator.pop(context);

    showSnackBar(context,
        'Survey selected. Tap on boundary points to add them to your new area.');
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    if (points.isEmpty) return LatLngBounds(LatLng(0, 0), LatLng(0, 0));

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_selectedSurvey == null) {
      showSnackBar(context, 'Please select a survey first.', error: true);
      return;
    }

    final surveyPoints = _selectedSurvey!.mappedArea.boundaryPoints;
    int closestIndex = -1;
    double minDistance = double.infinity;

    for (int i = 0; i < surveyPoints.length; i++) {
      final distance = LocationService.calculateDistance(
        point,
        surveyPoints[i].position,
      );

      if (distance < minDistance && distance < 50) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    if (closestIndex == -1) return;

    final selectedPoint = surveyPoints[closestIndex];

    if (_selectedPointIndices.contains(closestIndex)) {
      setState(() {
        _selectedPointIndices.remove(closestIndex);
      });
      widget.onPointRemoved();
      return;
    }

    if (_wouldCreateOverlap(selectedPoint)) {
      showSnackBar(context,
          'Cannot select this point as it would create an overlap with the source survey.',
          error: true);
      return;
    }

    setState(() {
      _selectedPointIndices.add(closestIndex);
    });

    final newBoundaryPoint = BoundaryPoint(
      position: selectedPoint.position,
      index: widget.currentBoundaryPoints.length + 1,
      timestamp: DateTime.now(),
    );

    widget.onPointAdded(newBoundaryPoint);
  }

  bool _wouldCreateOverlap(BoundaryPoint newPoint) {
    if (widget.currentBoundaryPoints.length < 2) return false;

    final selectedPositions =
        widget.currentBoundaryPoints.map((p) => p.position).toSet();

    final sourcePolygon = _selectedSurvey!.mappedArea.polygon;

    int consecutiveCount = 0;
    for (int i = 0; i < sourcePolygon.length; i++) {
      if (selectedPositions.contains(sourcePolygon[i])) {
        consecutiveCount++;
        if (consecutiveCount > 2) return true;
      } else {
        consecutiveCount = 0;
      }
    }

    return false;
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
            backgroundColor: Colors.green,
          ),
        ),
      );
    }

    if (_selectedSurvey != null) {
      final surveyPoints = _selectedSurvey!.mappedArea.boundaryPoints;

      for (int i = 0; i < surveyPoints.length; i++) {
        final point = surveyPoints[i];
        final isSelected = _selectedPointIndices.contains(i);

        markers.add(
          Marker(
            point: point.position,
            child: GestureDetector(
              onTap: () => _onMapTap(
                TapPosition(Offset.zero,
                    Offset(point.position.latitude, point.position.longitude)),
                point.position,
              ),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
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
          color: Colors.green,
        ),
      );
    }

    if (_selectedSurvey != null) {
      final surveyPolygon = _selectedSurvey!.mappedArea.polygon;
      if (surveyPolygon.length > 1) {
        polylines.add(
          Polyline(
            points: [...surveyPolygon, surveyPolygon.first],
            strokeWidth: 2.0,
            color: Colors.orange.withOpacity(0.8),
            pattern: StrokePattern.dashed(segments: [8, 4]),
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
                    onPressed: _showSurveySelectionSheet,
                    child: Text(_selectedSurvey != null
                        ? 'Survey Selected'
                        : 'Select Survey'),
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
                    onTap: _onMapTap,
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
                            'Mode: SNAP GPS',
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
                            'Tap on orange points to select',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
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
}

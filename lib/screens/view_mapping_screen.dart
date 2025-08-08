import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

import 'package:surveyapp/models/area.dart';
import 'package:surveyapp/models/survey_response.dart';

class ButtonData {
  final String tag;
  final IconData iconData;
  final VoidCallback onTap;

  ButtonData({required this.tag, required this.iconData, required this.onTap});
}

class ViewMappingScreen extends StatefulWidget {
  final SurveyResponse survey;
  final bool showDistances;
  final bool showBoundaryPoints;

  const ViewMappingScreen({
    super.key,
    required this.survey,
    this.showDistances = true,
    this.showBoundaryPoints = true,
  });

  @override
  State<ViewMappingScreen> createState() => _ViewMappingScreenState();
}

class _ViewMappingScreenState extends State<ViewMappingScreen> {
  late MapController mapController;
  bool showDistances = true;
  bool showBoundaryPoints = true;
  bool showAreaInfo = true;
  int? selectedPointIndex;
  final Distance distance = Distance();

  final _buttonData = <ButtonData>[];

  // Colors for the mapping area
  final Color primaryColor = Colors.blue;
  final Color secondaryColor = Colors.blueAccent;
  final Color pointColor = Colors.red;
  final Color selectedPointColor = Colors.orange;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    showDistances = widget.showDistances;
    showBoundaryPoints = widget.showBoundaryPoints;
    _buttonData.add(ButtonData(
        tag: 'center',
        iconData: Icons.center_focus_strong_rounded,
        onTap: _centerOnArea));
    _buttonData.add(ButtonData(
        tag: 'fit', iconData: Icons.fit_screen_rounded, onTap: _zoomToFitArea));
    _buttonData.add(ButtonData(
      tag: 'toggle_distances',
      iconData: showDistances ? Icons.straighten : Icons.straighten_outlined,
      onTap: () {
        setState(() {
          showDistances = !showDistances;
        });
      },
    ));
    _buttonData.add(ButtonData(
      tag: 'show_boundary_points',
      iconData: showBoundaryPoints ? Icons.place : Icons.place_outlined,
      onTap: () {
        setState(() {
          showBoundaryPoints = !showBoundaryPoints;
        });
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.survey.response.sections.first.data.first.value,
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          SizedBox(
            width: 105,
            child: CheckboxMenuButton(
                onHover: (value) => true,
                value: showAreaInfo,
                style: ButtonStyle(
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                onChanged: (show) {
                  setState(() {
                    showAreaInfo = show == true;
                  });
                },
                child: Text(
                  '${showAreaInfo ? 'Hide' : 'Show'} area',
                  style: TextStyle(fontSize: 12),
                )),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: _calculateCenter(),
              initialZoom: 16.0,
              onTap: (tapPosition, point) {
                _handleMapTap(point);
              },
            ),
            children: [
              // Base map tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),

              // Main polygon
              _buildPolygonLayer(),

              // Distance lines and labels (if enabled)
              if (showDistances) ..._buildDistanceLayers(),

              // Boundary points (if enabled)
              if (showBoundaryPoints) _buildBoundaryPointsLayer(),
            ],
          ),

          // Area information panel
          if (showAreaInfo) _buildAreaInfoPanel(),

          // Point details panel (when a point is selected)
          if (selectedPointIndex != null) _buildPointDetailsPanel(),

          // Control buttons
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildPolygonLayer() {
    return PolygonLayer(
      polygons: [
        Polygon(
            points: widget.survey.mappedArea.polygon,
            color: primaryColor.withValues(alpha: 0.3),
            borderStrokeWidth: 3.0,
            borderColor: primaryColor,
            pattern: StrokePattern.solid()),
      ],
    );
  }

  List<Widget> _buildDistanceLayers() {
    List<Widget> layers = [];

    // Distance lines
    List<Polyline> distanceLines = [];
    for (int i = 0; i < widget.survey.mappedArea.boundaryPoints.length; i++) {
      int nextIndex = (i + 1) % widget.survey.mappedArea.boundaryPoints.length;
      distanceLines.add(
        Polyline(
          points: [
            widget.survey.mappedArea.boundaryPoints[i].position,
            widget.survey.mappedArea.boundaryPoints[nextIndex].position,
          ],
          strokeWidth: 2.0,
          color: secondaryColor,
          pattern: StrokePattern.dotted(),
        ),
      );
    }

    layers.add(PolylineLayer(polylines: distanceLines));

    // Distance labels
    List<Marker> distanceMarkers = [];
    for (int i = 0; i < widget.survey.mappedArea.boundaryPoints.length; i++) {
      int nextIndex = (i + 1) % widget.survey.mappedArea.boundaryPoints.length;
      LatLng point1 = widget.survey.mappedArea.boundaryPoints[i].position;
      LatLng point2 =
          widget.survey.mappedArea.boundaryPoints[nextIndex].position;

      // Calculate midpoint
      LatLng midpoint = LatLng(
        (point1.latitude + point2.latitude) / 2,
        (point1.longitude + point2.longitude) / 2,
      );

      // Calculate distance
      double dist = distance.as(LengthUnit.Meter, point1, point2);
      String distanceText = _formatDistance(dist);

      distanceMarkers.add(
        Marker(
          point: midpoint,
          width: 58,
          height: 30,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 4),
            decoration: BoxDecoration(
              color: secondaryColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
                child: Text(
              distanceText,
            )),
          ),
        ),
      );
    }

    layers.add(MarkerLayer(markers: distanceMarkers));
    return layers;
  }

  Widget _buildBoundaryPointsLayer() {
    List<Marker> pointMarkers = [];

    for (int i = 0; i < widget.survey.mappedArea.boundaryPoints.length; i++) {
      BoundaryPoint point = widget.survey.mappedArea.boundaryPoints[i];
      bool isSelected = selectedPointIndex == i;

      pointMarkers.add(
        Marker(
          point: point.position,
          width: 30,
          height: 30,
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedPointIndex = selectedPointIndex == i ? null : i;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? selectedPointColor : pointColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MarkerLayer(markers: pointMarkers);
  }

  Widget _buildAreaInfoPanel() {
    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.map, color: primaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  widget.survey.response.sections.first.data.first.value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            Divider(),
            _buildInfoRow(Icons.straighten, 'Points',
                '${widget.survey.mappedArea.boundaryPoints.length}'),
            if (widget.survey.mappedArea.area != null)
              _buildInfoRow(Icons.crop_free, 'Area',
                  '${widget.survey.mappedArea.area!.toStringAsFixed(2)} m²'),
            _buildInfoRow(Icons.access_time, 'Mode',
                widget.survey.mappedArea.mode.name.toUpperCase()),
            _buildInfoRow(Icons.calendar_today, 'Created',
                _formatDate(widget.survey.mappedArea.createdAt)),
            SizedBox(height: 8),
            _buildPerimeterInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildPointDetailsPanel() {
    if (selectedPointIndex == null) return SizedBox.shrink();

    BoundaryPoint selectedPoint =
        widget.survey.mappedArea.boundaryPoints[selectedPointIndex!];
    int nextIndex = (selectedPointIndex! + 1) %
        widget.survey.mappedArea.boundaryPoints.length;
    BoundaryPoint nextPoint =
        widget.survey.mappedArea.boundaryPoints[nextIndex];

    double distToNext = distance.as(
        LengthUnit.Meter, selectedPoint.position, nextPoint.position);

    return Positioned(
      bottom: 10,
      left: 10,
      right: 10,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: selectedPointColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      '${selectedPointIndex! + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Point ${selectedPointIndex! + 1} Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: selectedPointColor,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      selectedPointIndex = null;
                    });
                  },
                ),
              ],
            ),
            Divider(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coordinates:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        selectedPoint.position.latitude.toStringAsFixed(6),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      Text(
                        selectedPoint.position.longitude.toStringAsFixed(6),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distance to next:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        _formatDistance(distToNext),
                        style: TextStyle(fontSize: 12, color: primaryColor),
                      ),
                      Text(
                        'Recorded: ${_formatTime(selectedPoint.timestamp)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        children: _buttonData
            .map((ButtonData data) => FloatingActionButton(
                  mini: true,
                  onPressed: data.onTap,
                  heroTag: data.tag,
                  child: Icon(data.iconData),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerimeterInfo() {
    double totalPerimeter = _calculatePerimeter();
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.timeline, color: primaryColor, size: 16),
          SizedBox(width: 8),
          Text(
            'Perimeter: ${_formatDistance(totalPerimeter)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMapTap(LatLng point) {
    // Find the closest boundary point
    double minDistance = double.infinity;
    int? closestPointIndex;

    for (int i = 0; i < widget.survey.mappedArea.boundaryPoints.length; i++) {
      double dist = distance.as(
        LengthUnit.Meter,
        point,
        widget.survey.mappedArea.boundaryPoints[i].position,
      );

      if (dist < minDistance && dist < 50) {
        // 50 meter threshold
        minDistance = dist;
        closestPointIndex = i;
      }
    }

    setState(() {
      selectedPointIndex = closestPointIndex;
    });
  }

  LatLng _calculateCenter() {
    if (widget.survey.mappedArea.boundaryPoints.isEmpty) {
      return LatLng(0, 0);
    }

    List<LatLng> points = widget.survey.mappedArea.polygon;
    double sumLat = points.fold(0, (sum, point) => sum + point.latitude);
    double sumLng = points.fold(0, (sum, point) => sum + point.longitude);

    return LatLng(sumLat / points.length, sumLng / points.length);
  }

  double _calculatePerimeter() {
    double perimeter = 0;
    for (int i = 0; i < widget.survey.mappedArea.boundaryPoints.length; i++) {
      int nextIndex =
          ((i + 1) % widget.survey.mappedArea.boundaryPoints.length).toInt();
      perimeter += distance.as(
        LengthUnit.Meter,
        widget.survey.mappedArea.boundaryPoints[i].position,
        widget.survey.mappedArea.boundaryPoints[nextIndex].position,
      );
    }
    return perimeter;
  }

  void _zoomToFitArea() {
    List<LatLng> points = widget.survey.mappedArea.polygon;
    if (points.isEmpty) return;

    double minLat = points.map((p) => p.latitude).reduce(math.min);
    double maxLat = points.map((p) => p.latitude).reduce(math.max);
    double minLng = points.map((p) => p.longitude).reduce(math.min);
    double maxLng = points.map((p) => p.longitude).reduce(math.max);

    LatLngBounds bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(50)));
  }

  void _centerOnArea() {
    mapController.move(_calculateCenter(), 16.0);
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    } else if (meters >= 1) {
      return '${meters.toStringAsFixed(1)} m';
    } else {
      return '${(meters * 100).toStringAsFixed(0)} cm';
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

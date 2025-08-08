import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:surveyapp/models/area.dart';
import 'dart:math' as math;

import 'package:surveyapp/models/survey_response.dart';

class MappedAreasMapWidget extends StatefulWidget {
  final List<SurveyResponse> surveys;
  final LatLng? initialCenter;
  final double initialZoom;

  const MappedAreasMapWidget({
    super.key,
    required this.surveys,
    this.initialCenter,
    this.initialZoom = 15.0,
  });

  @override
  State<MappedAreasMapWidget> createState() => _MappedAreasMapWidgetState();
}

class _MappedAreasMapWidgetState extends State<MappedAreasMapWidget> {
  late MapController mapController;
  SurveyResponse? selectedArea;

  // Predefined colors for different areas
  final List<Color> areaColors = [
    Colors.blue.withValues(alpha: 0.3),
    Colors.red.withValues(alpha: 0.3),
    Colors.green.withValues(alpha: 0.3),
    Colors.orange.withValues(alpha: 0.3),
    Colors.purple.withValues(alpha: 0.3),
    Colors.cyan.withValues(alpha: 0.3),
    Colors.pink.withValues(alpha: 0.3),
    Colors.teal.withValues(alpha: 0.3),
    Colors.indigo.withValues(alpha: 0.3),
    Colors.amber.withValues(alpha: 0.3),
  ];

  final List<Color> borderColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter ?? _calculateCenter(),
              initialZoom: widget.initialZoom,
              onTap: (tapPosition, point) {
                _handleMapTap(point);
              },
            ),
            children: [
              // Base map tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.adollatech.survey.app',
              ),

              // Polygon layers for each mapped area
              ..._buildPolygonLayers(),

              // Marker layers for client names
              ..._buildMarkerLayers(),
            ],
          ),

          // Legend/Info panel
          _buildInfoPanel(),

          // Zoom to fit button
          _buildZoomToFitButton(),
        ],
      ),
    );
  }

  List<Widget> _buildPolygonLayers() {
    return widget.surveys.asMap().entries.map((entry) {
      int index = entry.key;
      MappedArea area = entry.value.mappedArea;

      Color fillColor = areaColors[index % areaColors.length];
      Color borderColor = borderColors[index % borderColors.length];

      // Highlight selected area
      if (selectedArea?.id == area.id) {
        fillColor = fillColor.withValues(alpha: 0.5);
        borderColor = borderColor.withValues(alpha: 1.0);
      }

      return PolygonLayer(
        polygons: [
          Polygon(
            points: area.polygon,
            color: fillColor,
            borderStrokeWidth: selectedArea?.id == area.id ? 3.0 : 2.0,
            borderColor: borderColor,
          ),
        ],
      );
    }).toList();
  }

  List<Widget> _buildMarkerLayers() {
    return widget.surveys.asMap().entries.map((entry) {
      int index = entry.key;
      MappedArea area = entry.value.mappedArea;
      LatLng centroid = _calculatePolygonCentroid(area.polygon);
      Color textColor = borderColors[index % borderColors.length];

      return MarkerLayer(
        markers: [
          Marker(
            point: centroid,
            width: 120,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: textColor, width: 1),
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
                  entry.value.response.sections.first.data.first.value,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildInfoPanel() {
    return Positioned(
      top: 50,
      right: 10,
      child: Container(
        width: 200,
        padding: EdgeInsets.all(12),
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
            Text(
              'Mapped Areas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            if (selectedArea != null) ...[
              _buildSelectedAreaInfo(),
              Divider(),
            ],
            Text(
              'Areas (${widget.surveys.length}):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 4),
            ...widget.surveys.asMap().entries.map((entry) {
              int index = entry.key;
              MappedArea area = entry.value.mappedArea;
              Color color = borderColors[index % borderColors.length];

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.3),
                        border: Border.all(color: color, width: 1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry.value.response.sections.first.data.first.value,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedAreaInfo() {
    if (selectedArea == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected: ${selectedArea!.response.sections.first.data.first.value}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        SizedBox(height: 4),
        if (selectedArea!.mappedArea.area != null)
          Text(
            'Area: ${selectedArea!.mappedArea.area!.toStringAsFixed(2)} m²',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
        Text(
          'Points: ${selectedArea!.mappedArea.boundaryPoints.length}',
          style: TextStyle(fontSize: 12, color: Colors.black87),
        ),
        Text(
          'Mode: ${selectedArea!.mappedArea.mode.name}',
          style: TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildZoomToFitButton() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
        mini: true,
        onPressed: _zoomToFitAllAreas,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: Icon(Icons.fit_screen),
      ),
    );
  }

  void _handleMapTap(LatLng point) {
    // Find if the tap is inside any polygon
    SurveyResponse? tappedArea;

    for (SurveyResponse area in widget.surveys) {
      if (_isPointInPolygon(point, area.mappedArea.polygon)) {
        tappedArea = area;
        break;
      }
    }

    setState(() {
      selectedArea = tappedArea;
    });
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int j = 0; j < polygon.length; j++) {
      LatLng vertex1 = polygon[j];
      LatLng vertex2 = polygon[(j + 1) % polygon.length];

      if (((vertex1.latitude > point.latitude) !=
              (vertex2.latitude > point.latitude)) &&
          (point.longitude <
              (vertex2.longitude - vertex1.longitude) *
                      (point.latitude - vertex1.latitude) /
                      (vertex2.latitude - vertex1.latitude) +
                  vertex1.longitude)) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1;
  }

  LatLng _calculateCenter() {
    if (widget.surveys.isEmpty) {
      return LatLng(0, 0);
    }

    List<LatLng> allPoints =
        widget.surveys.expand((area) => area.mappedArea.polygon).toList();

    double sumLat = allPoints.fold(0, (sum, point) => sum + point.latitude);
    double sumLng = allPoints.fold(0, (sum, point) => sum + point.longitude);

    return LatLng(sumLat / allPoints.length, sumLng / allPoints.length);
  }

  LatLng _calculatePolygonCentroid(List<LatLng> polygon) {
    double centroidLat = 0;
    double centroidLng = 0;
    double signedArea = 0;

    for (int i = 0; i < polygon.length; i++) {
      LatLng current = polygon[i];
      LatLng next = polygon[(i + 1) % polygon.length];

      double a =
          current.latitude * next.longitude - next.latitude * current.longitude;
      signedArea += a;
      centroidLat += (current.latitude + next.latitude) * a;
      centroidLng += (current.longitude + next.longitude) * a;
    }

    signedArea *= 0.5;
    centroidLat /= (6.0 * signedArea);
    centroidLng /= (6.0 * signedArea);

    return LatLng(centroidLat, centroidLng);
  }

  void _zoomToFitAllAreas() {
    if (widget.surveys.isEmpty) return;

    List<LatLng> allPoints =
        widget.surveys.expand((area) => area.mappedArea.polygon).toList();

    if (allPoints.isEmpty) return;

    double minLat = allPoints.map((p) => p.latitude).reduce(math.min);
    double maxLat = allPoints.map((p) => p.latitude).reduce(math.max);
    double minLng = allPoints.map((p) => p.longitude).reduce(math.min);
    double maxLng = allPoints.map((p) => p.longitude).reduce(math.max);

    LatLngBounds bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(50)));
  }
}

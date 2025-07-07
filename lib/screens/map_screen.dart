// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:hive_ce/hive.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:provider/provider.dart';
// import 'package:maps_toolkit/maps_toolkit.dart' as maps_toolkit;
// import 'package:uuid/uuid.dart';
// import 'package:surveyapp/models/geo_point.dart';
// import 'package:surveyapp/models/mapping_session.dart';
// import 'package:surveyapp/models/mapping_status_adapter.dart';
// import 'package:surveyapp/services/bluetooth_gps_service.dart';
// import 'package:surveyapp/services/hive_service.dart';
// import 'package:surveyapp/services/location_service.dart';
// import 'package:surveyapp/services/auth_service.dart';

// class MapScreen extends StatefulWidget {
//   const MapScreen({super.key});

//   @override
//   State<MapScreen> createState() => _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> {
//   final MapController _mapController = MapController();
//   MappingSession? _currentSession; // Holds the active mapping session
//   List<LatLng> _currentPolygonPoints =
//       []; // Points for the current polygon being drawn
//   Box<MappingSession>? _mappingBox;
//   Box<GeoPoint>? _geoPointBox;
//   final Uuid _uuid = const Uuid(); // For generating session IDs

//   @override
//   void initState() {
//     super.initState();
//     _openBoxes();
//     // Listen to location service for map centering/marker updates
//     // (Handled by Consumer/Selector below for efficiency)
//   }

//   Future<void> _openBoxes() async {
//     final hiveService = Provider.of<HiveService>(context, listen: false);
//     _mappingBox = await hiveService.getMappingSessionBox();
//     _geoPointBox =
//         await hiveService.openBox<GeoPoint>('geoPoints'); // Open points box
//     setState(() {}); // Rebuild after boxes are open
//   }

//   // --- Mapping Actions ---
//   void _startNewMapping() async {
//     if (_currentSession != null &&
//         _currentSession?.status == MappingStatus.inProgress) {
//       _showSnackBar("Mapping already in progress. Save or finalize first.");
//       return;
//     }
//     if (_mappingBox == null || _geoPointBox == null) {
//       _showSnackBar("Local storage not ready.");
//       return;
//     }

//     final userId = AuthService().userId;

//     dynamic selectedFarmerKey; // Replace with actual farmer key

//     final newSessionId = _uuid.v4();
//     final newSession = MappingSession(
//       sessionId: newSessionId,
//       startTime: DateTime.now(),
//       status: MappingStatus.inProgress,
//       farmerKey: selectedFarmerKey,
//       createdByUserId: userId,
//       // Initialize HiveList - requires the box to be open
//       mappedPoints: HiveList(_geoPointBox!),
//     );

//     await _mappingBox!
//         .put(newSessionId, newSession); // Save to Hive using sessionId as key

//     setState(() {
//       _currentSession = newSession;
//       _currentPolygonPoints = []; // Clear points for new session
//     });
//     _showSnackBar(
//         "New mapping started (ID: ${newSessionId.substring(0, 6)}...)");
//   }

//   // void _addPoint() {
//   //   if (_currentSession == null ||
//   //       _currentSession!.status != MappingStatus.inProgress) {
//   //     _showSnackBar("Start a mapping session first.");
//   //     return;
//   //   }
//   //   final locationService =
//   //       Provider.of<LocationService>(context, listen: false);
//   //   final currentLoc = locationService.currentLocation;

//   //   if (currentLoc != null) {
//   //     final newPoint = GeoPoint(
//   //       latitude: currentLoc.latitude,
//   //       longitude: currentLoc.longitude,
//   //       timestamp: DateTime.now(),
//   //       // altitude: locationService.currentAltitude, // If available
//   //     );

//   //     // Add point to the session's HiveList
//   //     _currentSession!.mappedPoints?.add(newPoint);
//   //     // IMPORTANT: Save the session object itself to persist the HiveList change
//   //     _currentSession!.save();

//   //     setState(() {
//   //       // Update the list used for drawing the polygon on the map
//   //       _currentPolygonPoints =
//   //           _currentSession!.mappedPoints?.map((p) => p.toLatLng()).toList() ??
//   //               [];
//   //     });
//   //     _showSnackBar("Point added (${_currentPolygonPoints.length})");
//   //   } else {
//   //     _showSnackBar("Current location not available.");
//   //   }
//   // }

//   void _saveAndPauseMapping() async {
//     if (_currentSession == null || _mappingBox == null) return;

//     if (_currentSession!.status == MappingStatus.inProgress ||
//         _currentSession!.status == MappingStatus.paused) {
//       _currentSession!.status = MappingStatus.paused;
//       await _currentSession!.save(); // Persist status change in Hive
//       setState(() {
//         // Keep _currentSession assigned so user knows which one was paused
//         // Optionally clear _currentPolygonPoints if you want the visual cleared
//       });
//       _showSnackBar("Mapping paused.");
//     } else {
//       _showSnackBar("Cannot pause a finalized mapping.");
//     }
//   }

//   void _finalizeMapping() async {
//     if (_currentSession == null || _mappingBox == null) return;
//     if (_currentSession!.status == MappingStatus.finalized) {
//       _showSnackBar("Mapping already finalized.");
//       return;
//     }
//     if ((_currentSession!.mappedPoints?.length ?? 0) < 3) {
//       _showSnackBar("Need at least 3 points to finalize polygon.");
//       return;
//     }

//     // Calculate Area
//     final pointsForAreaCalc = _currentPolygonPoints
//         .map((ll) => maps_toolkit.LatLng(ll.latitude, ll.longitude))
//         .toList();
//     // Ensure polygon is closed for calculation
//     if (pointsForAreaCalc.first.latitude != pointsForAreaCalc.last.latitude ||
//         pointsForAreaCalc.first.longitude != pointsForAreaCalc.last.longitude) {
//       pointsForAreaCalc.add(pointsForAreaCalc.first);
//     }
//     final area = maps_toolkit.SphericalUtil.computeArea(pointsForAreaCalc);

//     _currentSession!.calculatedArea = double.tryParse('$area');
//     _currentSession!.endTime = DateTime.now();
//     _currentSession!.status = MappingStatus.finalized;
//     await _currentSession!.save(); // Save final data

//     final areaHectares = area / 10000; // Convert sq meters to hectares

//     setState(() {
//       // Clear active session reference after finalizing
//       // _currentSession = null;
//       // _currentPolygonPoints = [];
//     });

//     _showSnackBar(
//         "Mapping finalized. Area: ${area.toStringAsFixed(2)} m² (${areaHectares.toStringAsFixed(4)} ha)");

//     // Optionally trigger upload here or navigate to sync screen
//     // _uploadCurrentSession();
//   }

//   // Helper to upload the finalized session
//   Future<void> _uploadCurrentSession() async {
//     if (_currentSession?.status == MappingStatus.finalized) {
//       try {
//         _currentSession!.status = MappingStatus.synced; // Update local status
//         await _currentSession!.save();
//         _showSnackBar("Mapping uploaded successfully.");
//         setState(() {
//           // Update UI if needed after sync
//         });
//       } catch (e) {
//         _showSnackBar("Upload failed: $e");
//       }
//     }
//   }

//   void _showSnackBar(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text(message),
//         duration: const Duration(seconds: 2),
//       ));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Use Consumer to listen to location changes
//     // return Consumer<LocationService>(
//     //   builder: (context, locationService, child) {
//     //     final currentLocation = locationService.currentLocation;
//     //     final bluetoothStatus = locationService.bluetoothStatus;

//     //     // Center map on first valid location or a default (Tamale, Ghana)
//     //     final initialCenter = currentLocation ?? const LatLng(9.4008, -0.8393);

//         // Move map center when location updates significantly (optional)
//         // Consider adding a button to manually center on current location instead
//         // if (_mapController.ready && currentLocation != null) {
//         //   _mapController.move(currentLocation, _mapController.zoom);
//         // }

//         return Scaffold(
//           appBar: AppBar(
//             title: const Text("Farm Map"),
//             actions: [
//               // Button to manually trigger Bluetooth connection attempt
//               IconButton(
//                 icon: Icon(
//                   Icons.bluetooth_searching,
//                   color:  Colors.grey,
//                 ),
//                 tooltip: "Connect External GPS",
//                 onPressed: (){},
//               ),
//               // Optional: Button to trigger upload of finalized session
//               if (_currentSession?.status == MappingStatus.finalized)
//                 IconButton(
//                   icon: const Icon(Icons.cloud_upload),
//                   tooltip: "Upload Mapping",
//                   onPressed: _uploadCurrentSession,
//                 ),
//             ],
//           ),
//           body: Stack(
//             children: [
//               FlutterMap(
//                 mapController: _mapController,
//                 options: MapOptions(
//                   initialZoom: 15.0, // Adjust initial zoom
//                   // onTap: (_, latLng) { // Optional: Allow manual point adding by tapping
//                   //   if (_currentSession?.status == MappingStatus.inProgress) {
//                   //      // _addManualPoint(latLng);
//                   //   }
//                   // },
//                 ),
//                 children: [
//                   // Base Map Layer (OpenStreetMap)
//                   TileLayer(
//                     urlTemplate:
//                         'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//                     userAgentPackageName: 'dev.flutter_map.example',
//                   ),

//                   // Polygon Layer (Shows the currently mapped area)
//                   if (_currentPolygonPoints.isNotEmpty)
//                     PolygonLayer(
//                       polygons: [
//                         Polygon(
//                           points: _currentPolygonPoints,
//                           color: Colors.blue.withValues(alpha: 0.5),
//                           borderColor: Colors.blue,
//                           borderStrokeWidth: 2,
//                         ),
//                       ],
//                     ),

//                   // Markers Layer (Points added during mapping)
//                   if (_currentPolygonPoints.isNotEmpty)
//                     MarkerLayer(
//                       markers: _currentPolygonPoints
//                           .map((point) => Marker(
//                                 point: point,
//                                 width: 10,
//                                 height: 10,
//                                 child: Container(
//                                   decoration: const BoxDecoration(
//                                     color: Colors.red,
//                                     shape: BoxShape.circle,
//                                   ),
//                                 ),
//                               ))
//                           .toList(),
//                     ),

//                   // Current Location Marker
//                   if (currentLocation != null)
//                     MarkerLayer(
//                       markers: [
//                         Marker(
//                           width: 80.0,
//                           height: 80.0,
//                           point: currentLocation,
//                           child: Icon(
//                             locationService.bluetoothStatus ==
//                                     BluetoothStatus.connected
//                                 ? Icons.gps_fixed // Different icon for BT GPS?
//                                 : Icons.my_location,
//                             color: Colors.redAccent,
//                             size: 30.0,
//                           ),
//                         ),
//                       ],
//                     ),
//                 ],
//               ),
//               // Status Overlay (Optional)
//               Positioned(
//                 top: 10,
//                 left: 10,
//                 right: 10,
//                 child: Card(
//                   color: Colors.white.withValues(alpha: 0.8),
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "GPS: ${currentLocation != null ? '${currentLocation.latitude.toStringAsFixed(6)}, ${currentLocation.longitude.toStringAsFixed(6)}' : 'Unavailable'}",
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                         Text(
//                           "Source: ${locationService.bluetoothStatus == BluetoothStatus.connected ? 'External BT' : (currentLocation != null ? 'Internal Device' : 'None')}",
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                         Text(
//                           "BT Status: ${locationService.bluetoothStatus.name}",
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                         if (_currentSession != null)
//                           Text(
//                             "Session: ${_currentSession!.sessionId.substring(0, 6)}... (${_currentSession!.status.name}) Points: ${_currentPolygonPoints.length}",
//                             style: const TextStyle(
//                                 fontSize: 12, fontWeight: FontWeight.bold),
//                           ),
//                         if (_currentSession?.status ==
//                                 MappingStatus.finalized &&
//                             _currentSession?.calculatedArea != null)
//                           Text(
//                             "Area: ${(_currentSession!.calculatedArea! / 10000).toStringAsFixed(4)} ha",
//                             style: const TextStyle(
//                                 fontSize: 12, fontWeight: FontWeight.bold),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           // Floating Action Buttons for Mapping Controls
//           floatingActionButton: Padding(
//             padding: const EdgeInsets.only(
//                 bottom: 60.0), // Adjust to avoid bottom nav
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 if (_currentSession == null ||
//                     _currentSession!.status != MappingStatus.inProgress)
//                   FloatingActionButton.extended(
//                     onPressed: _startNewMapping,
//                     label: const Text("Start New"),
//                     icon: const Icon(Icons.play_arrow),
//                     heroTag: 'fab_start', // Unique tag
//                   ),
//                 const SizedBox(height: 8),
//                 if (_currentSession?.status == MappingStatus.inProgress) ...[
//                   FloatingActionButton(
//                     onPressed: _addPoint,
//                     tooltip: 'Add Point',
//                     heroTag: 'fab_add', // Unique tag
//                     mini: true,
//                     child: const Icon(Icons.add_location),
//                   ),
//                   const SizedBox(height: 8),
//                   FloatingActionButton(
//                     onPressed: _saveAndPauseMapping,
//                     tooltip: 'Save/Pause',
//                     heroTag: 'fab_pause', // Unique tag
//                     mini: true,
//                     child: const Icon(Icons.pause),
//                   ),
//                   const SizedBox(height: 8),
//                   FloatingActionButton(
//                     onPressed: _finalizeMapping,
//                     tooltip: 'Finalize',
//                     heroTag: 'fab_finalize', // Unique tag
//                     mini: true,
//                     child: const Icon(Icons.check),
//                   ),
//                 ],
//                 // Button to resume a paused mapping (logic needed in list screen or here)
//                 // if (_currentSession?.status == MappingStatus.paused) ... [ ... ]
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

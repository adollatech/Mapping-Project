import 'package:hive_ce/hive.dart';

import 'geo_point.dart';
import 'mapping_status_adapter.dart';

// part 'mapping_session.g.dart'; // Generated file

@HiveType(typeId: 2)
class MappingSession extends HiveObject {
  @HiveField(0)
  String? pocketBaseId; // Store PocketBase record ID after sync

  @HiveField(1)
  String sessionId; // Unique ID generated locally (e.g., UUID)

  @HiveField(2)
  HiveList<GeoPoint>? mappedPoints; // Use HiveList for relationships

  @HiveField(3)
  double? calculatedArea; // In square meters, calculated on finalization

  @HiveField(4)
  DateTime startTime;

  @HiveField(5)
  DateTime? endTime; // Set when finalized

  @HiveField(6)
  DateTime? updatedAt;

  @HiveField(7)
  MappingStatus status;

  // Link to Farmer (Store Hive key or PocketBase ID)
  // Option 1: Store Hive Key (if Farmer is always local when mapping)
  @HiveField(8)
  dynamic farmerKey; // Can be int or String depending on Hive key type
  // Option 2: Store PocketBase ID (if syncing farmer first)
  // String? farmerPocketBaseId;

  @HiveField(9)
  String? notes;

  @HiveField(10)
  String createdByUserId; // Store PocketBase User ID

  MappingSession({
    this.pocketBaseId,
    required this.sessionId,
    this.mappedPoints,
    this.calculatedArea,
    required this.startTime,
    this.endTime,
    this.updatedAt,
    this.status = MappingStatus.inProgress,
    this.farmerKey,
    this.notes,
    required this.createdByUserId,
  });

  // For PocketBase sync (adjust field names)
  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        // Convert GeoPoints list to list of maps
        'mapped_points_json':
            mappedPoints?.map((p) => p.toJson()).toList() ?? [],
        'calculated_area': calculatedArea,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'status': status.name, // Store enum name as string
        // Include farmer relation ID based on your PocketBase schema
        // 'farmer': farmerPocketBaseId, // If using PocketBase ID
        'notes': notes,
        'user': createdByUserId, // Link to user record
      };

  // Factory to create from PocketBase RecordModel (adjust field names)
  factory MappingSession.fromRecordModel(
      dynamic record, Box<GeoPoint> pointsBox) {
    final data = record.data as Map<String, dynamic>? ?? {};
    final pointsList = (data['mapped_points_json'] as List<dynamic>?)
            ?.map((pJson) => GeoPoint.fromJson(pJson as Map<String, dynamic>))
            .toList() ??
        [];

    // Note: Re-linking HiveList on download is complex.
    // It might be simpler to store points directly in the session object
    // if not excessively large, or handle the relation differently.
    // This example assumes points are embedded in JSON for sync.
    final hivePoints = HiveList(pointsBox); // Create empty HiveList
    hivePoints.addAll(
        pointsList); // Add points (they aren't automatically saved to box here)

    return MappingSession(
      pocketBaseId: record.id as String?,
      sessionId: data['session_id'] as String? ?? 'unknown_${record.id}',
      // mappedPoints: hivePoints, // Assigning HiveList needs care
      calculatedArea: (data['calculated_area'] as num?)?.toDouble(),
      startTime: DateTime.tryParse(data['start_time'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(data['end_time'] ?? ''),
      updatedAt: DateTime.tryParse(data['updatedAt'] ?? ''),
      status: MappingStatus.values.firstWhere((e) => e.name == data['status'],
          orElse: () => MappingStatus.synced), // Default to synced on download
      // farmerKey: data['farmer'], // Get farmer relation ID
      notes: data['notes'] as String?,
      createdByUserId: data['user'] as String? ?? '',
    );
  }
}

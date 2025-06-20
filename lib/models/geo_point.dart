import 'package:hive_ce/hive.dart';
import 'package:latlong2/latlong.dart';

// Important: Run build_runner to generate the .g.dart files
// flutter pub run build_runner build --delete-conflicting-outputs

// part 'geo_point.g.dart'; // Generated file

@HiveType(typeId: 0) // Unique typeId for each HiveObject
class GeoPoint extends HiveObject {
  @HiveField(0)
  double latitude;

  @HiveField(1)
  double longitude;

  @HiveField(2)
  double? altitude; // Optional

  @HiveField(3)
  DateTime timestamp;

  GeoPoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    required this.timestamp,
  });

  // Convenience method to convert to LatLng
  LatLng toLatLng() => LatLng(latitude, longitude);

  // For PocketBase sync (adjust field names to match PocketBase collection)
  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'timestamp': timestamp.toIso8601String(),
      };

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        altitude: (json['altitude'] as num?)?.toDouble(),
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      );
}

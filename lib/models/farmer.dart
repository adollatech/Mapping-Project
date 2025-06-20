import 'package:hive_ce/hive.dart';

// part 'farmer.g.dart'; // Generated file

@HiveType(typeId: 1)
class Farmer extends HiveObject {
  @HiveField(0)
  String? pocketBaseId; // Store PocketBase record ID after sync

  @HiveField(1)
  String legalName;

  @HiveField(2)
  String? popularName;

  @HiveField(3)
  String community;

  @HiveField(4)
  String district;

  @HiveField(5)
  String region;

  @HiveField(6)
  String? traditionalArea;

  @HiveField(7)
  String? stool; // Not sure what this means, adjust type if needed

  @HiveField(8)
  String? farmCode;

  @HiveField(9)
  String? ethnicity; // e.g., "Migrant", "Native"

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  Farmer({
    this.pocketBaseId,
    required this.legalName,
    this.popularName,
    required this.community,
    required this.district,
    required this.region,
    this.traditionalArea,
    this.stool,
    this.farmCode,
    this.ethnicity,
    required this.createdAt,
    required this.updatedAt,
  });

  // For PocketBase sync (adjust field names)
  Map<String, dynamic> toJson() => {
        // Don't include 'id' when creating, PocketBase assigns it
        'legal_name': legalName,
        'popular_name': popularName,
        'community': community,
        'district': district,
        'region': region,
        'traditional_area': traditionalArea,
        'stool': stool,
        'farm_code': farmCode,
        'ethnicity': ethnicity,
        // PocketBase handles created/updated timestamps automatically
      };

  // Factory to create from PocketBase RecordModel (adjust field names)
  factory Farmer.fromRecordModel(dynamic record) {
    final data = record.data as Map<String, dynamic>? ?? {};
    return Farmer(
      pocketBaseId: record.id as String?,
      legalName: data['legal_name'] as String? ?? 'Unknown',
      popularName: data['popular_name'] as String?,
      community: data['community'] as String? ?? 'Unknown',
      district: data['district'] as String? ?? 'Unknown',
      region: data['region'] as String? ?? 'Unknown',
      traditionalArea: data['traditional_area'] as String?,
      stool: data['stool'] as String?,
      farmCode: data['farm_code'] as String?,
      ethnicity: data['ethnicity'] as String?,
      createdAt:
          DateTime.tryParse(record.created as String? ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(record.updated as String? ?? '') ?? DateTime.now(),
    );
  }
}

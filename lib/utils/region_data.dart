import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class RegionData {
  final List<dynamic> data;

  RegionData._(this.data);

  static Future<RegionData> create(String assetPath) async {
    final data = jsonDecode(await rootBundle.loadString(assetPath));
    return RegionData._(data);
  }

  List<String> getAllRegionLabels() {
    return data.map<String>((region) => region['label'] as String).toList();
  }

  List<String> searchRegionLabels(String searchTerm) {
    return getAllRegionLabels()
        .where((label) => label.toLowerCase().contains(searchTerm))
        .toList();
  }

  List<String> getDistrictsByRegion(String regionLabel) {
    for (var region in data) {
      if (region['label'] == regionLabel) {
        return (region['districts'] as List)
            .map<String>((district) => district['label'] as String)
            .toList();
      }
    }
    return [];
  }

  List<String> searchDistrictsByLabel(String regionLabel, String searchTerm) {
    List<String> districts = getDistrictsByRegion(regionLabel);
    return districts
        .where((district) => district.toLowerCase().contains(searchTerm))
        .toList();
  }
}

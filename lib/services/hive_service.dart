import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:surveyapp/models/farmer.dart';
import 'package:surveyapp/models/mapping_session.dart';

class HiveService {
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await Hive.initFlutter();
    _isInitialized = true;
  }

  void registerAdapters() {
    // IMPORTANT: Register all your Hive TypeAdapters here
    // Generate these adapters using build_runner (see models file)
    // Hive.registerAdapter(GeoPointAdapter()); // Example
    // Hive.registerAdapter(FarmerAdapter()); // Example
    // Hive.registerAdapter(MappingSessionAdapter()); // Example
    // print("Hive adapters registered.");
  }

  Future<Box<T>> openBox<T>(String name) async {
    if (!Hive.isBoxOpen(name)) {
      return await Hive.openBox<T>(name);
    }
    return Hive.box<T>(name);
  }

  // Add convenience methods for accessing specific boxes if desired
  Future<Box<MappingSession>> getMappingSessionBox() =>
      openBox<MappingSession>('mappingSessions');
  Future<Box<Farmer>> getFarmerBox() => openBox<Farmer>('farmers');

  Future<void> closeAllBoxes() async {
    await Hive.close();
    _isInitialized = false;
  }
}

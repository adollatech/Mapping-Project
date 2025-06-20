import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'bluetooth_gps_service.dart';

class LocationService extends ChangeNotifier {
  final BluetoothGpsService _bluetoothGpsService;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  LatLng? _currentLocation;
  bool _isDeviceLocationEnabled = false; // Phone's location service status
  bool _hasPermission = false;

  LocationService(this._bluetoothGpsService) {
    // Listen to the Bluetooth service for its coordinates
    _bluetoothGpsService.addListener(_updateLocation);
  }

  LatLng? get currentLocation => _currentLocation;
  bool get isDeviceLocationEnabled => _isDeviceLocationEnabled;
  bool get hasPermission => _hasPermission;
  BluetoothStatus get bluetoothStatus => _bluetoothGpsService.status;

  Future<void> init() async {
    await _checkPermissions();
    if (_hasPermission) {
      _checkServiceStatus();
      _startListeningToDeviceLocation();
    }
    _updateLocation(); // Initial update based on current BT state
  }

  Future<void> _checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _hasPermission = false;
        log("Location permission denied.");
        notifyListeners();
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _hasPermission = false;
      log("Location permission permanently denied.");
      // Optionally guide user to settings
      // await Geolocator.openAppSettings();
      notifyListeners();
      return;
    }
    _hasPermission = true;
    log("Location permission granted.");
    notifyListeners();
  }

  void _checkServiceStatus() {
    _serviceStatusSubscription =
        Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      _isDeviceLocationEnabled = (status == ServiceStatus.enabled);
      log("Device Location Service Status: $_isDeviceLocationEnabled");
      if (!_isDeviceLocationEnabled) {
        // If device location turns off, we might lose internal GPS fix
        // but external BT GPS might still work. Location update logic handles this.
        _updateLocation(); // Re-evaluate best location
      } else if (_positionStreamSubscription == null && _hasPermission) {
        // If service turns on and we weren't listening, start listening
        _startListeningToDeviceLocation();
      }
      notifyListeners();
    });
    // Check initial status
    Geolocator.isLocationServiceEnabled().then((enabled) {
      _isDeviceLocationEnabled = enabled;
      notifyListeners();
    });
  }

  void _startListeningToDeviceLocation() {
    if (!_hasPermission || !_isDeviceLocationEnabled) return;
    if (_positionStreamSubscription != null) return; // Already listening

    // Configure location settings
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // Use high accuracy
      distanceFilter: 5, // Notify only if moved 5 meters (adjust as needed)
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        log("Device GPS Update: ${position.latitude}, ${position.longitude}");
        // This update only matters if Bluetooth GPS isn't active/valid
        _updateLocation(devicePosition: position);
      },
      onError: (error) {
        log("Device Location Stream Error: $error");
        // Handle errors, maybe stop listening?
        _positionStreamSubscription?.cancel();
        _positionStreamSubscription = null;
        _updateLocation(); // Re-evaluate best location (might be null now)
      },
      cancelOnError:
          false, // Keep listening even after an error? Decide based on needs.
    );
    log("Started listening to device location updates.");
  }

  // Central method to decide which location source to use
  void _updateLocation({Position? devicePosition}) {
    LatLng? newLocation;

    // --- Prioritization Logic ---
    // 1. Use Bluetooth GPS if connected and has a valid coordinate
    if (_bluetoothGpsService.status == BluetoothStatus.connected &&
        _bluetoothGpsService.lastValidCoordinate != null) {
      newLocation = _bluetoothGpsService.lastValidCoordinate;
      log("Location Source: External Bluetooth GPS");
    }
    // 2. Fallback to Device GPS if available and BT GPS is not
    else if (devicePosition != null &&
        _hasPermission &&
        _isDeviceLocationEnabled) {
      newLocation = LatLng(devicePosition.latitude, devicePosition.longitude);
      log("Location Source: Internal Device GPS (from stream)");
    }
    // 3. Handle case where devicePosition wasn't passed but we need to check internal
    else if (_currentLocation == null &&
        _hasPermission &&
        _isDeviceLocationEnabled) {
      // Try getting last known or current position as a fallback start
      // This might be slightly out of date compared to the stream
      Geolocator.getCurrentPosition().then((pos) {
        if (_bluetoothGpsService.status != BluetoothStatus.connected) {
          // Check again in case BT connected while waiting
          _currentLocation = LatLng(pos.latitude, pos.longitude);
          log("Location Source: Internal Device GPS (fetched)");
          notifyListeners();
        }
      }).catchError((e) {
        log("Error getting initial device position: $e");
        _currentLocation = null; // Ensure it's null if fetch fails
        notifyListeners();
      });
      // Don't set newLocation directly here, let the async fetch handle it
    } else {
      log("Location Source: None Available");
      newLocation = null; // No valid source
    }
    // --- End Prioritization Logic ---

    // Update only if the location actually changed
    if (_currentLocation?.latitude != newLocation?.latitude ||
        _currentLocation?.longitude != newLocation?.longitude) {
      _currentLocation = newLocation;
      log("Current Location Updated: $_currentLocation");
      notifyListeners();
    }
  }

  // Method to attempt connecting to Bluetooth GPS manually if needed
  Future<void> connectBluetoothGps() async {
    await _bluetoothGpsService.startScanAndConnect();
  }

  // Method to disconnect Bluetooth GPS manually
  void disconnectBluetoothGps() {
    _bluetoothGpsService.disconnect();
  }

  // Method to request permissions again if needed
  Future<void> requestPermission() async {
    await _checkPermissions();
    if (_hasPermission && _positionStreamSubscription == null) {
      _checkServiceStatus();
      _startListeningToDeviceLocation();
    }
  }

  @override
  void dispose() {
    log("Disposing LocationService");
    _positionStreamSubscription?.cancel();
    _serviceStatusSubscription?.cancel();
    _bluetoothGpsService
        .removeListener(_updateLocation); // Stop listening to BT service
    super.dispose();
  }
}

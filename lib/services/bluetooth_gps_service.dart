import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:latlong2/latlong.dart';

enum BluetoothStatus { disconnected, scanning, connecting, connected, error }

class BluetoothGpsService extends ChangeNotifier {
  BluetoothStatus _status = BluetoothStatus.disconnected;
  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  LatLng?
      _lastValidCoordinate; // Store last known good coordinate from BT device

  // --- Configuration (Adjust these!) ---
  // Option 1: Connect to a specific known device name
  final String targetDeviceName = "Your_GPS_Device_Name"; // CHANGE THIS
  // Option 2: Connect based on service UUIDs (more reliable if name changes)
  // final Guid serviceUuid = Guid("YOUR_SERVICE_UUID"); // CHANGE THIS
  // final Guid characteristicUuid = Guid("YOUR_CHARACTERISTIC_UUID"); // CHANGE THIS
  // --- End Configuration ---

  BluetoothStatus get status => _status;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  LatLng? get lastValidCoordinate => _lastValidCoordinate;

  BluetoothGpsService() {
    // Listen to adapter state changes
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      log("Bluetooth Adapter State: $state");
      if (state == BluetoothAdapterState.off) {
        _updateStatus(BluetoothStatus.disconnected);
        _cleanupConnection();
      } else if (state == BluetoothAdapterState.on &&
          _status == BluetoothStatus.disconnected) {
        // If adapter turns on and we were disconnected, try scanning
        startScanAndConnect();
      }
    });
  }

  void _updateStatus(BluetoothStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      log("Bluetooth Status: $_status"); // Debug log
      notifyListeners();
    }
  }

  Future<void> startScanAndConnect() async {
    if (_status != BluetoothStatus.disconnected &&
        _status != BluetoothStatus.error) {
      log("Already scanning, connecting or connected.");
      return;
    }
    if (!await FlutterBluePlus.isSupported) {
      log("Bluetooth not supported on this device.");
      _updateStatus(BluetoothStatus.error);
      return;
    }
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      log("Bluetooth is off.");
      // Optionally prompt user to turn on Bluetooth
      _updateStatus(BluetoothStatus.disconnected); // Or maybe error?
      return;
    }

    _updateStatus(BluetoothStatus.scanning);

    // Start scanning
    try {
      await FlutterBluePlus.startScan(
          // withServices: [serviceUuid], // Uncomment if using UUIDs
          timeout: const Duration(seconds: 10) // Adjust timeout
          );

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        if (_status != BluetoothStatus.scanning) {
          return; // Stop if status changed
        }

        for (ScanResult r in results) {
          log('Found device: ${r.device.platformName} (${r.device.remoteId})');
          // --- Matching Logic (Choose one or combine) ---
          // 1. By Name
          if (r.device.platformName == targetDeviceName) {
            log("Target device found by name!");
            _connectToDevice(r.device);
            break; // Stop scanning once found
          }
          // 2. By Service UUID (if using)
          // if (r.advertisementData.serviceUuids.contains(serviceUuid)) {
          //   log("Target device found by service UUID!");
          //   _connectToDevice(r.device);
          //   break;
          // }
          // --- End Matching Logic ---
        }
      }, onError: (e) {
        log("Scan Error: $e");
        _updateStatus(BluetoothStatus.error);
        _cleanupConnection();
      });

      // Handle scan timeout
      await Future.delayed(
          const Duration(seconds: 11)); // Slightly longer than scan timeout
      if (_status == BluetoothStatus.scanning) {
        log("Scan timed out. Device not found.");
        _updateStatus(BluetoothStatus.disconnected); // Or error?
        await FlutterBluePlus.stopScan();
      }
    } catch (e) {
      log("Error starting scan: $e");
      _updateStatus(BluetoothStatus.error);
      _cleanupConnection();
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_status == BluetoothStatus.connecting ||
        _status == BluetoothStatus.connected) {
      return; // Already handling a connection
    }
    await FlutterBluePlus.stopScan(); // Stop scanning
    _updateStatus(BluetoothStatus.connecting);
    _connectedDevice = device;

    // Listen to connection state changes
    _connectionSubscription =
        device.connectionState.listen((BluetoothConnectionState state) {
      log("Device ${device.remoteId} State: $state");
      if (state == BluetoothConnectionState.disconnected) {
        _updateStatus(BluetoothStatus.disconnected);
        _cleanupConnection();
        // Optionally attempt to reconnect automatically after a delay
        // Future.delayed(Duration(seconds: 5), () => startScanAndConnect());
      } else if (state == BluetoothConnectionState.connected) {
        _discoverServicesAndListen(device);
      }
    });

    try {
      await device.connect(timeout: const Duration(seconds: 15));
      log("Connection request sent to ${device.platformName}");
      // State changes handled by the listener above
    } on FlutterBluePlusException catch (e) {
      log("Connection Error: $e");
      _updateStatus(BluetoothStatus.error);
      _cleanupConnection();
    }
  }

  Future<void> _discoverServicesAndListen(BluetoothDevice device) async {
    log("Discovering services for ${device.platformName}");
    try {
      List<BluetoothService> services = await device.discoverServices();
      log("Found ${services.length} services.");
      BluetoothCharacteristic? targetCharacteristic;

      // --- Find Target Characteristic (Adjust!) ---
      // Find the characteristic that provides the GPS data (e.g., NMEA stream)
      // This requires inspecting the device's services/characteristics using a
      // BLE scanner app (like nRF Connect) to find the correct UUIDs.
      for (BluetoothService service in services) {
        // log(" Service: ${service.uuid}");
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          // log("  Characteristic: ${characteristic.uuid} Props: ${characteristic.properties}");
          // Example: Check if it matches a known UUID and supports Notify
          // if (characteristic.uuid == characteristicUuid && characteristic.properties.notify) {
          //    targetCharacteristic = characteristic;
          //    log("Found target characteristic: ${characteristic.uuid}");
          //    break;
          // }
          // --- !! Placeholder: Assume first notify characteristic ---
          // !! Replace this with proper UUID matching for your device !!
          if (targetCharacteristic == null &&
              characteristic.properties.notify) {
            targetCharacteristic = characteristic;
            log("!! Using first notify characteristic as placeholder: ${characteristic.uuid} !!");
          }
        }
        if (targetCharacteristic != null) break;
      }
      // --- End Find Target Characteristic ---

      if (targetCharacteristic != null) {
        if (!targetCharacteristic.isNotifying) {
          await targetCharacteristic.setNotifyValue(true);
          log("Subscribed to characteristic ${targetCharacteristic.uuid}");
        }
        // Listen to data stream
        _dataSubscription =
            targetCharacteristic.onValueReceived.listen((value) {
          // --- !!! PARSE GPS DATA HERE !!! ---
          // This is where you convert the raw byte data (value)
          // into LatLng coordinates. This usually involves:
          // 1. Converting bytes to a String (e.g., UTF8 for NMEA)
          // 2. Parsing the String (e.g., splitting NMEA sentences like $GPGGA)
          // 3. Extracting latitude, longitude, altitude, etc.
          // 4. Validating the data (e.g., check GPS fix status in NMEA)

          // Example Placeholder for NMEA (Highly simplified)
          try {
            String dataString = utf8.decode(value);
            log("BT GPS Raw: $dataString"); // Debug raw data
            // This is just a basic example, needs proper parsing and validation.
            if (dataString.startsWith('\$GPGGA') ||
                dataString.startsWith('\$GNGGA')) {
              List<String> parts = dataString.split(',');
              if (parts.length > 6 &&
                  parts[6] != '0' &&
                  parts[2].isNotEmpty &&
                  parts[4].isNotEmpty) {
                // Check fix status and lat/lon exist
                double lat = _nmeaToDecimal(parts[2], parts[3]); // N/S
                double lon = _nmeaToDecimal(parts[4], parts[5]); // E/W
                if (lat != 0.0 && lon != 0.0) {
                  // Basic validation
                  _lastValidCoordinate = LatLng(lat, lon);
                  // log("BT GPS Parsed: $_lastValidCoordinate"); // Debug parsed data
                  notifyListeners(); // Notify LocationService
                }
              }
            }
          } catch (e) {
            log("Error parsing BT GPS data: $e");
            // Handle parsing errors
          }
          // --- !!! END PARSE GPS DATA !!! ---
        }, onError: (e) {
          log("Characteristic Value Error: $e");
          // Handle errors, maybe disconnect?
        });
        _updateStatus(
            BluetoothStatus.connected); // Mark as connected and listening
      } else {
        log("Target characteristic not found!");
        _updateStatus(BluetoothStatus.error);
        disconnect();
      }
    } catch (e) {
      log("Service Discovery Error: $e");
      _updateStatus(BluetoothStatus.error);
      disconnect();
    }
  }

  // Helper for basic NMEA coordinate conversion (Needs error handling!)
  double _nmeaToDecimal(String nmeaCoord, String direction) {
    if (nmeaCoord.isEmpty || direction.isEmpty) return 0.0;
    try {
      int decimalPoint = nmeaCoord.indexOf('.');
      if (decimalPoint == -1) return 0.0; // Invalid format

      double degrees = double.parse(nmeaCoord.substring(0, decimalPoint - 2));
      double minutes = double.parse(nmeaCoord.substring(decimalPoint - 2));
      double decimalDegrees = degrees + (minutes / 60.0);

      if (direction == 'S' || direction == 'W') {
        decimalDegrees = -decimalDegrees;
      }
      return decimalDegrees;
    } catch (e) {
      log("NMEA parse error: $e for $nmeaCoord $direction");
      return 0.0;
    }
  }

  void disconnect() {
    _cleanupConnection();
    _updateStatus(BluetoothStatus.disconnected);
  }

  void _cleanupConnection() {
    log("Cleaning up Bluetooth connection...");
    _dataSubscription?.cancel();
    _dataSubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _connectedDevice?.disconnect(); // Request disconnect if device exists
    _connectedDevice = null;
    _lastValidCoordinate = null; // Clear last coordinate on disconnect
    // Don't call notifyListeners() here, status update handles it
  }

  @override
  void dispose() {
    log("Disposing BluetoothGpsService");
    FlutterBluePlus.stopScan();
    _cleanupConnection();
    super.dispose();
  }
}

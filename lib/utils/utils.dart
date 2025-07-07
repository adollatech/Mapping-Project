import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<Position> getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  // Check for location permissions
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // Get current location
  return await Geolocator.getCurrentPosition();
}

Position getBestPosition(Position mobilePosition, Position externalPosition,
    {double threshold = 5.0}) {
  double distance = Geolocator.distanceBetween(
    mobilePosition.latitude,
    mobilePosition.longitude,
    externalPosition.latitude,
    externalPosition.longitude,
  );

  Position finalPosition =
      distance > threshold ? externalPosition : mobilePosition;
  return finalPosition;
}

void scanAndConnect() async {
  // Start scanning
  FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

  // Listen to scan results
  var subscription = FlutterBluePlus.scanResults.listen((results) async {
    for (ScanResult r in results) {
      if (r.device.platformName == 'DEVICE') {
        FlutterBluePlus.stopScan();
        try {
          await r.device.connect();
          // Discover services
          // List<BluetoothService> services = await r.device.discoverServices();
          // Handle services
        } catch (e) {
          log('Connection failed: $e');
        }
        break;
      }
    }
  });

  // Stop scanning after timeout
  await Future.delayed(Duration(seconds: 4));
  FlutterBluePlus.stopScan();
  subscription.cancel();
}

void showSnackBar(BuildContext context, String message,
    {bool error = false, bool success = false}) {
  if (!context.mounted) {
    return;
  }
  const padding = EdgeInsets.all(12);
  const style = TextStyle(color: Colors.white);
  ShadToast toast = ShadToast(
    action: const Icon(
      Icons.info_outline_rounded,
      color: Colors.white,
    ),
    padding: padding,
    backgroundColor: Colors.lightBlueAccent,
    title: Text(
      message,
      style: style,
    ),
  );

  if (error) {
    toast = ShadToast.destructive(
      padding: padding,
      action: const Icon(
        Icons.error_outline_rounded,
        color: Colors.white,
      ),
      title: Text(
        message,
        style: style,
      ),
    );
  }

  if (success) {
    toast = ShadToast(
      padding: padding,
      action: const Icon(
        Icons.check_circle_outline_rounded,
        color: Colors.white,
      ),
      title: Text(
        message,
        style: style,
      ),
      backgroundColor: const Color.fromARGB(255, 27, 149, 31),
    );
  }
  ShadToaster.of(context).show(toast);
}

push(BuildContext context, Widget page) {
  Navigator.push(context, MaterialPageRoute(builder: (ctx) => page));
}

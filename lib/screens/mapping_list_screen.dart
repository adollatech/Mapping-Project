import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:surveyapp/models/mapping_session.dart';
import 'package:surveyapp/models/mapping_status_adapter.dart';
import 'package:surveyapp/services/hive_service.dart';

class MappingListScreen extends StatelessWidget {
  const MappingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hiveService = Provider.of<HiveService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Mappings"),
        actions: [
          // Optional: Add button to navigate to Farmer Form
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: "Add Farmer",
            onPressed: () => Navigator.pushNamed(context, '/farmer_form'),
          ),
          // Optional: Add button to trigger sync
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: "Sync Data",
            onPressed: () => Navigator.pushNamed(context, '/data_sync'),
          ),
        ],
      ),
      body: FutureBuilder<Box<MappingSession>>(
        // Open the box when the screen builds
        future: hiveService.getMappingSessionBox(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text("Error opening local storage: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Could not open local storage."));
          }

          final mappingBox = snapshot.data!;

          // Use ValueListenableBuilder to reactively update the list when Hive box changes
          return ValueListenableBuilder(
            valueListenable: mappingBox.listenable(),
            builder: (context, Box<MappingSession> box, _) {
              final sessions = box.values.toList().cast<MappingSession>();
              // Sort sessions, e.g., by start time descending
              sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

              if (sessions.isEmpty) {
                return const Center(
                    child: Text("No mappings saved locally yet."));
              }

              return ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final areaHa = session.calculatedArea != null
                      ? (session.calculatedArea! / 10000)
                      : null;
                  final pointCount = session.mappedPoints?.length ?? 0;

                  return ListTile(
                    leading: Icon(session.status == MappingStatus.synced
                            ? Icons.cloud_done
                            : session.status == MappingStatus.finalized
                                ? Icons.check_circle
                                : session.status == MappingStatus.paused
                                    ? Icons.pause_circle
                                    : Icons.pending // InProgress
                        ),
                    title: Text(
                        "Session: ${session.sessionId.substring(0, 6)}..."),
                    subtitle: Text(
                        "$pointCount points - ${session.status.name}\n"
                        "Started: ${session.startTime.toLocal().toString().substring(0, 16)}"
                        "${areaHa != null ? '\nArea: ${areaHa.toStringAsFixed(4)} ha' : ''}"),
                    isThreeLine: areaHa != null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: "Delete Local",
                      onPressed: () async {
                        await box.delete(session.farmerKey); // Delete from Hive
                      },
                    ),
                    onTap: () {
                      log("Tapped session: ${session.sessionId}");
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

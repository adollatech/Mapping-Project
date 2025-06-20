import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surveyapp/models/geo_point.dart';
import 'package:surveyapp/models/mapping_session.dart';
import 'package:surveyapp/models/mapping_status_adapter.dart';
import 'package:surveyapp/services/hive_service.dart';

class DataSyncScreen extends StatefulWidget {
  const DataSyncScreen({super.key});

  @override
  State<DataSyncScreen> createState() => _DataSyncScreenState();
}

class _DataSyncScreenState extends State<DataSyncScreen> {
  bool _isUploading = false;
  bool _isDownloading = false;
  String _syncStatus = '';

  Future<void> _uploadAllFinalized() async {
    setState(() {
      _isUploading = true;
      _syncStatus = 'Uploading...';
    });
    try {
      final hiveService = Provider.of<HiveService>(context, listen: false);
      final mappingBox = await hiveService.getMappingSessionBox();
      int uploadCount = 0;

      final finalizedSessions = mappingBox.values
          .where((s) =>
                  s.status == MappingStatus.finalized ||
                  (s.status == MappingStatus.synced &&
                      s.pocketBaseId ==
                          null) // Retry if synced but has no ID somehow
              )
          .toList();

      if (finalizedSessions.isEmpty) {
        _syncStatus = 'No finalized mappings to upload.';
      } else {
        for (final session in finalizedSessions) {
          try {
            session.status = MappingStatus.synced; // Mark as synced
            session.pocketBaseId = session
                .pocketBaseId; // Ensure ID is set if returned by upload method
            await session.save();
            uploadCount++;
            _syncStatus = 'Uploaded $uploadCount / ${finalizedSessions.length}';
            setState(() {}); // Update progress
          } catch (e) {
            _syncStatus =
                'Error uploading session ${session.sessionId.substring(0, 6)}: $e';
            setState(() {});
            // Decide whether to stop or continue on error
            break;
          }
        }
        if (uploadCount == finalizedSessions.length) {
          _syncStatus = 'Upload complete ($uploadCount sessions).';
        }
      }
    } catch (e) {
      _syncStatus = 'Upload failed: $e';
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _downloadAll() async {
    setState(() {
      _isDownloading = true;
      _syncStatus = 'Downloading...';
    });
    try {
      final hiveService = Provider.of<HiveService>(context, listen: false);
      final mappingBox = await hiveService.getMappingSessionBox();
      final pointsBox = await hiveService
          .openBox<GeoPoint>('geoPoints'); // Needed for model factory

      int newCount = 0;
      int updateCount = 0;

      for (final record in [MappingSession.fromRecordModel('', pointsBox)]) {
        final pbId = record.pocketBaseId;
        // Check if session with this PocketBase ID already exists locally
        final existingSession = mappingBox.values
            .cast<MappingSession?>()
            .firstWhere((s) => s?.pocketBaseId == pbId, orElse: () => null);

        final downloadedSession =
            MappingSession.fromRecordModel(record, pointsBox);

        if (existingSession != null) {
          // Update existing local record if downloaded is newer
          if (downloadedSession.updatedAt!
              .isAfter(existingSession.updatedAt!)) {
            await mappingBox.put(existingSession.farmerKey, downloadedSession);
            updateCount++;
          }
        } else {
          // Add as new local record
          // Use PocketBase ID as key? Or session ID? Decide on key strategy.
          // Using session ID might be better if it's guaranteed unique.
          await mappingBox.put(downloadedSession.sessionId, downloadedSession);
          newCount++;
        }
      }
      _syncStatus = 'Download complete. New: $newCount, Updated: $updateCount.';
    } catch (e) {
      _syncStatus = 'Download failed: $e';
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Data Synchronization")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload),
              label: const Text("Upload Finalized Mappings"),
              onPressed:
                  _isUploading || _isDownloading ? null : _uploadAllFinalized,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_download),
              label: const Text("Download Mappings from Server"),
              onPressed: _isUploading || _isDownloading ? null : _downloadAll,
            ),
            const SizedBox(height: 24),
            const Text("Status:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_syncStatus.isEmpty ? "Ready to sync." : _syncStatus),
            const Divider(height: 30),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:surveyapp/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authBox = Hive.box('auth');

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (authBox.isNotEmpty) ...[
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("User Email"),
              subtitle: Text(pb.authStore.record?.data['email'] ?? ""),
            ),
            ListTile(
              leading: const Icon(Icons.key),
              title: const Text("User ID"),
              subtitle: Text(pb.authStore.record?.id ?? ''),
              dense: true,
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text("Data Synchronization"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, '/data_sync'),
          ),
          const Divider(),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              onPressed: () {
                AuthService().signOut();
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/models/agent.dart';
import 'package:surveyapp/services/auth_service.dart';
import 'package:surveyapp/widgets/item_selectable_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authBox = Hive.box('settings');
    final user = pb.authStore.isValid
        ? Agent.fromJson(pb.authStore.record!.data)
        : Agent(id: 'id', name: 'Guest', email: '');

    return ValueListenableBuilder(
        valueListenable: authBox.listenable(),
        builder: (context, box, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Settings"),
            ),
            body: ValueListenableBuilder(
                valueListenable: authBox.listenable(),
                builder: (context, box, child) {
                  return ListView(
                    children: [
                      if (authBox.isNotEmpty)
                        ListTile(
                          leading: const Icon(
                            LucideIcons.userCheck,
                            size: 18,
                          ),
                          title: Text(user.name),
                          subtitle: Text(user.email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 4,
                            children: [
                              const Icon(LucideIcons.pencil),
                              Text('Edit'),
                            ],
                          ),
                          onTap: () => context.push(
                            '/profile',
                          ),
                        ),
                      const Divider(),
                      ListTile(
                        title: Text('Measurement System'),
                        leading: Icon(LucideIcons.rulerDimensionLine),
                        dense: true,
                      ),
                      ItemSelectableDialog(
                          label: box.get('measurement_system',
                              defaultValue: 'Metric'),
                          description:
                              'Choose the systems of measurement to use in the app',
                          dialogTitle: 'Measurement System',
                          items: ['Imperial', 'Metric'],
                          itemBuilder: (unit) => Text(unit),
                          leading: Container(
                              margin: EdgeInsets.only(left: 16),
                              child: Icon(
                                  box.get('measurement_system') == 'Imperial'
                                      ? LucideIcons.divide
                                      : LucideIcons.decimalsArrowLeft)),
                          onItemSelected: (unit) {
                            box.put('measurement_system', unit);
                          }),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.gps_fixed_rounded),
                        title: const Text("GPS Selector"),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.color_lens),
                        title: const Text("Theme Mode"),
                        dense: true,
                      ),
                      RadioListTile(
                        groupValue: box.get('theme', defaultValue: 'system'),
                        value: 'system',
                        title: const Text("System Default"),
                        onChanged: (value) => box.put('theme', 'system'),
                      ),
                      RadioListTile(
                        groupValue: box.get('theme', defaultValue: 'system'),
                        value: 'light',
                        title: const Text("Light Mode"),
                        onChanged: (value) => box.put('theme', 'light'),
                      ),
                      RadioListTile(
                        groupValue: box.get('theme', defaultValue: 'system'),
                        value: 'dark',
                        title: const Text("Dark Mode"),
                        onChanged: (value) => box.put('theme', 'dark'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(LucideIcons.hammer),
                        title: const Text("Terms & Conditions"),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => context.push('/sync'),
                      ),
                      ListTile(
                        leading: const Icon(LucideIcons.shield),
                        title: const Text("Privacy Policy"),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => context.push('/sync'),
                      ),
                    ],
                  );
                }),
          );
        });
  }
}

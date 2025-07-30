import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/services/auth_service.dart';
import 'package:surveyapp/utils/utils.dart';
import 'package:surveyapp/widgets/tappable_card.dart';

class Action {
  final IconData icon;
  final String title;
  final String? subtitle;
  final void Function(BuildContext context)? onTap;

  Action({required this.icon, required this.title, this.subtitle, this.onTap});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final actions = [
    Action(
        icon: LucideIcons.plus100,
        title: "New Survey",
        subtitle: "Start a survey to collect responses",
        onTap: (ctx) => Navigator.pushNamed(ctx, '/surveys')),
    Action(
      icon: LucideIcons.recycle,
      title: "Continue Survey",
      subtitle: "Continue an existing survey that was previously saved",
      onTap: (context) => Navigator.pushNamed(context, '/map'),
    ),
    Action(
      icon: LucideIcons.listCheck,
      title: "All Surveys",
      subtitle: "View and manage all captured surveys",
    ),
    Action(
        icon: LucideIcons.chartArea,
        title: "Download Areas",
        subtitle: "Get maps, parcels, vector data"),
    Action(
      icon: LucideIcons.download,
      title: "Download Forms",
      subtitle: "Get the survey forms for your project",
    ),
    Action(
      icon: LucideIcons.bluetoothConnected,
      title: "Devices Connected",
      subtitle: "List all connected Bluetooth devices",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actionsPadding: EdgeInsets.only(right: 16),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              icon: Icon(LucideIcons.settings)),
          ShadButton.ghost(
            onPressed: () {
              AuthService().signOut();
            },
            leading: Icon(LucideIcons.logOut),
            child: Text('Logout'),
          ),
        ],
      ),
      body: GridView.builder(
          itemCount: actions.length,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            mainAxisExtent: 110,
            maxCrossAxisExtent: 400,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          shrinkWrap: true,
          itemBuilder: (context, index) => TappableCard(
                onTap: () {
                  if (actions[index].onTap != null) {
                    actions[index].onTap!(context);
                  } else {
                    showSnackBar(context, 'Action not implemented yet');
                  }
                },
                title: actions[index].title,
                icon: actions[index].icon,
                subtitle: actions[index].subtitle,
              )),
    );
  }
}

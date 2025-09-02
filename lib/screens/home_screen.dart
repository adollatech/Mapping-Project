import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/services/auth_service.dart';
import 'package:surveyapp/widgets/stat_card.dart';
import 'package:surveyapp/widgets/tappable_card.dart';

class Action {
  final IconData icon;
  final String title;
  final String? subtitle;
  final void Function(BuildContext context) onTap;

  Action(
      {required this.icon,
      required this.title,
      this.subtitle,
      required this.onTap});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final actions = [
    Action(
        icon: LucideIcons.circlePlus,
        title: "New Survey",
        subtitle: "Select a survey form to collect responses",
        onTap: (context) => context.push('/forms')),
    Action(
      icon: LucideIcons.recycle,
      title: "Continue Survey",
      subtitle: "Continue an existing survey you previously saved",
      onTap: (context) => context.push('/saved-surveys'),
    ),
    Action(
      icon: LucideIcons.copy,
      title: "Reuse Existing",
      subtitle: "Collect new survey based on existing entry",
      onTap: (context) => context.push('/select-response'),
    ),
    Action(
      icon: LucideIcons.listCheck,
      title: "All Surveys",
      subtitle: "View and manage all captured surveys",
      onTap: (context) => context.push('/surveys'),
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
              onPressed: () => context.push('/settings'),
              icon: Icon(LucideIcons.settings)),
          ShadButton.ghost(
            onPressed: () => AuthService().signOut(),
            leading: Icon(LucideIcons.logOut),
            child: Text('Logout'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              height: 125,
              child: ListView(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                children: [
                  StatCard(
                    collection: 'forms',
                    filter: 'assigned_to.id ?= "${AuthService().userId}"',
                    title: "Assigned Forms",
                    color: Colors.blue,
                    darkColor: Colors.blue.shade900,
                  ),
                  StatCard(
                    collection: 'responses',
                    title: "My Survey Responses",
                    filter: 'collected_by = "${AuthService().userId}"',
                    color: Colors.green,
                    darkColor: Colors.green.shade900,
                  ),
                  StatCard(
                    collection: 'surveys',
                    title: "Unfinished Surveys",
                    isLocal: true,
                    color: Colors.orange,
                    darkColor: Colors.deepOrangeAccent,
                  ),
                ].map((e) => e).toList(),
              ),
            ),
            GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
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
                        actions[index].onTap(context);
                      },
                      title: actions[index].title,
                      icon: actions[index].icon,
                      subtitle: actions[index].subtitle,
                    )),
          ],
        ),
      ),
    );
  }
}

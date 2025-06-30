import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/models/agent.dart';
import 'package:surveyapp/services/auth_service.dart';
import 'package:surveyapp/widgets/loading_widget.dart';
import 'package:surveyapp/widgets/record_stream_builder.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileForm = GlobalKey<ShadFormState>();
  final _passwordChangeForm = GlobalKey<ShadFormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: RecordStreamBuilder(
          collection: 'users',
          recordId: AuthService().userId,
          fromMap: (p0) => Agent.fromJson(p0),
          loader: LoadingWidget(),
          onEmpty: () => Center(
                child: Text('No data'),
              ),
          builder: (context, agent) {
            return Column(
              children: [
                ShadForm(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: Column(
                      spacing: 24,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ShadInputFormField(
                          id: 'name',
                          label: const Text('Name'),
                          enabled: false,
                          initialValue: agent.name,
                        ),
                        ShadInputFormField(
                          id: 'email',
                          initialValue: agent.email,
                          enabled: false,
                          label: Text('Email address'),
                        ),
                        ShadInputFormField(
                          id: 'phone',
                          initialValue: agent.phone,
                          label: Text('Phone number'),
                        ),
                        ShadButton(
                          width: double.infinity,
                          onPressed: () {
                            if (_profileForm.currentState?.validate() == true) {
                              final values = {'': 1};
                              AuthService().updateProfile(agent.id, values);
                            }
                          },
                          child: const Text('Update Profile'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
    );
  }
}

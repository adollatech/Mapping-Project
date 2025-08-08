import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/models/agent.dart';
import 'package:surveyapp/widgets/trailing_loader.dart';
import 'package:surveyapp/services/auth_service.dart';
import 'package:surveyapp/utils/utils.dart';
import 'package:surveyapp/widgets/loading_widget.dart';
import 'package:surveyapp/widgets/password_change.dart';
import 'package:surveyapp/widgets/record_stream_builder.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileForm = GlobalKey<ShadFormState>();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
      ),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.only(top: 16.0, bottom: 24.0),
          width: double.infinity,
          child: RecordStreamBuilder(
              collection: 'users',
              recordId: AuthService().userId,
              fromMap: (p0) => Agent.fromJson(p0),
              loader: LoadingWidget(),
              onEmpty: () => Center(
                    child: Text('No data'),
                  ),
              builder: (context, agent) {
                return Column(
                  spacing: 24,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShadCard(
                      child: ShadForm(
                        key: _profileForm,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 360),
                          child: Column(
                            spacing: 20,
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
                                  if (_profileForm.currentState?.validate() ==
                                      true) {
                                    setState(() {
                                      _loading = true;
                                    });
                                    var details = _profileForm
                                        .currentState!.value
                                        .map((key, value) => MapEntry(
                                            key.toString(), value.trim()));
                                    AuthService()
                                        .updateProfile(details)
                                        .then((value) {
                                      if (context.mounted) {
                                        showSnackBar(context,
                                            'Profile updated successfully',
                                            success: true);
                                      }
                                    }).catchError((error) {
                                      if (context.mounted) {
                                        showSnackBar(context,
                                            'Failed to update profile: ${error.toString()}',
                                            error: true);
                                      }
                                    }).whenComplete(() {
                                      if (context.mounted) {
                                        setState(() {
                                          _loading = false;
                                        });
                                      }
                                    });
                                  }
                                },
                                trailing: _loading ? TrailingLoader() : null,
                                child: _loading
                                    ? const Text("Updating...")
                                    : const Text('Update Profile'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const PasswordChange(),
                  ],
                );
              }),
        ),
      ),
    );
  }
}

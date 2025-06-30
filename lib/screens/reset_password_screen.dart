import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/models/field.dart';
import 'package:surveyapp/services/auth_service.dart';
import 'package:surveyapp/utils/field_validation.dart';
import 'package:surveyapp/utils/service_response_exception.dart';
import 'package:surveyapp/utils/utils.dart';
import 'package:surveyapp/widgets/app_name.dart';
import 'package:surveyapp/widgets/mobile_card.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final formKey = GlobalKey<ShadFormState>();
  bool _loading = false;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MobileCard(
      child: IndexedStack(
        index: _index,
        alignment: Alignment.center,
        children: [
          ShadForm(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 24,
              children: [
                const AppName(),
                const Text(
                  'Reset your password',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                ShadInputFormField(
                  id: 'email',
                  placeholder: const Text('Email address'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                  leading: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(LucideIcons.mail),
                  ),
                  validator: (v) {
                    final validation = FieldValidation(
                        validation: Validation(
                      type: 'email',
                      required: true,
                    ));
                    final result = validation.validate(v);
                    if (result.isNotEmpty) {
                      for (var element in result) {
                        if (element.condition) {
                          return element.message;
                        }
                      }
                    }
                    return null;
                  },
                ),
                ShadButton(
                  onPressed: _loading ? null : _requestPasswordReset,
                  trailing: _loading
                      ? const CircularProgressIndicator.adaptive()
                      : null,
                  child: const Text('Send Reset Token'),
                ),
                Column(
                  children: [
                    ShadButton.link(
                        child: Text('Remembered Password? Login'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        }),
                    ShadButton.link(
                        child: Text('No Account? Register'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        }),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 24,
            children: [
              AppName(),
              const Text(
                'A password reset token has been sent to your email address. Open the email and follow the instructions to reset your password.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              ShadButton(
                onPressed: () async {
                  Navigator.pop(context);
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _requestPasswordReset() async {
    if (formKey.currentState!.saveAndValidate()) {
      setState(() => _loading = true);
      final email = formKey.currentState?.value['email'];
      try {
        await AuthService().requestPasswordReset(email);
        if (mounted) {
          showSnackBar(context, 'A reset token has been sent to your email',
              success: true);
        }
        setState(() => _index = 1);
      } on ServiceResponseException catch (e) {
        if (mounted) {
          showSnackBar(context, e.error, error: true);
        }
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    } else {
      showSnackBar(context, 'Please email address required', error: true);
    }
  }
}

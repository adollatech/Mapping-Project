import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/models/field.dart';
import 'package:surveyapp/services/auth_service.dart';
import 'package:surveyapp/utils/field_validation.dart';
import 'package:surveyapp/utils/service_response_exception.dart';
import 'package:surveyapp/utils/utils.dart';
import 'package:surveyapp/widgets/app_name.dart';
import 'package:surveyapp/widgets/mobile_card.dart';

class EmailConfirmationScreen extends StatefulWidget {
  const EmailConfirmationScreen({super.key});

  @override
  State<EmailConfirmationScreen> createState() => _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
    final formKey = GlobalKey<ShadFormState>();
    bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return MobileCard(
      child: ShadForm(
        key: formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 24,
          children: [
            const AppName(),
            const SizedBox(height: 24),
            const Text(
              'Confirm your email address',
              style: TextStyle(
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            ShadInputFormField(
              id: 'email',
              label: const Text('Email address'),
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
              onPressed: _loading ? null : _verifyEmail,
              trailing:
                  _loading ? const CircularProgressIndicator.adaptive() : null,
              child: const Text('Verify Email'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyEmail() async {
    if (formKey.currentState!.saveAndValidate()) {
      setState(() => _loading = true);
      final email = formKey.currentState?.value['email'];
      try {
        await AuthService().verifyEmail(email);
        if (mounted) {
          showSnackBar(context, 'Email has been verified', success: true);
        }
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
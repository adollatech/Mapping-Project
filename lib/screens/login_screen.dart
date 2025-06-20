import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/models/field.dart';
import 'package:surveyapp/services/auth_service.dart';
import 'package:surveyapp/utils/field_validation.dart';
import 'package:surveyapp/utils/service_response_exception.dart';
import 'package:surveyapp/utils/utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<ShadFormState>();
  bool _obscure = true;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 480,
      child: ShadCard(
        child: ShadForm(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'SurveyLand',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'Login to your account',
                style: TextStyle(
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ShadInputFormField(
                id: 'email',
                // label: const Text('Email address'),
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
              SizedBox(
                height: 24,
              ),
              ShadInputFormField(
                id: "password",
                placeholder: const Text('Password'),
                obscureText: _obscure,
                leading: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(LucideIcons.lock),
                ),
                trailing: ShadIconButton(
                  width: 24,
                  height: 24,
                  padding: EdgeInsets.zero,
                  decoration: const ShadDecoration(
                    secondaryBorder: ShadBorder.none,
                    secondaryFocusedBorder: ShadBorder.none,
                  ),
                  icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye),
                  onPressed: () {
                    setState(() => _obscure = !_obscure);
                  },
                ),
              ),
              SizedBox(
                height: 24,
              ),
              ShadButton(
                onPressed: _loading ? null : _handleLogin,
                trailing: _loading
                    ? const CircularProgressIndicator.adaptive()
                    : null,
                child: const Text('Login'),
              ),
              SizedBox(
                height: 24,
              ),
              Column(
                children: [
                  ShadButton.link(
                      child: Text('Forgot Password?'), onPressed: () {}),
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
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (formKey.currentState!.saveAndValidate()) {
      log("Form: ${formKey.currentState!.value['password']}");
      setState(() => _loading = true);
      final email = formKey.currentState?.value['email'];
      final password = formKey.currentState?.value['password'];
      try {
        await AuthService().signInWithEmailAndPassword(email, password);
        if (mounted) {
          showSnackBar(context, 'Login successful', success: true);
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
      showSnackBar(context, 'All fields are required', error: true);
    }
  }
}

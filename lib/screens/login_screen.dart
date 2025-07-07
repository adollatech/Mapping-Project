import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/models/field.dart';
import 'package:surveyapp/screens/trailing_loader.dart';
import 'package:surveyapp/services/auth_service.dart';
import 'package:surveyapp/utils/field_validation.dart';
import 'package:surveyapp/utils/service_response_exception.dart';
import 'package:surveyapp/utils/utils.dart';
import 'package:surveyapp/widgets/app_name.dart';
import 'package:surveyapp/widgets/mobile_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<ShadFormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
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
            Row(
              children: [
                Expanded(
                  child: const Text(
                    'Login to your account',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (kDebugMode)
                  IconButton(
                      onPressed: _fillFormInDevMode,
                      icon: const Icon(Icons.auto_fix_normal_rounded)),
              ],
            ),
            ShadInputFormField(
              id: 'email',
              // label: const Text('Email address'),
              controller: _emailController,
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
            ShadInputFormField(
              id: "password",
              controller: _passwordController,
              validator: (v) {
                final validation = FieldValidation(
                    validation: Validation(
                  type: 'password',
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
            ShadButton(
              onPressed: _loading ? null : _handleLogin,
              trailing: _loading ? const TrailingLoader() : null,
              child: const Text('Login'),
            ),
            Column(
              children: [
                ShadButton.link(
                    child: Text('Forgot Password?'), onPressed: () {
                      Navigator.pushNamed(context, '/reset-password');
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
    );
  }

  void _fillFormInDevMode() {
    if (formKey.currentState != null) {
      _emailController.text = 'alhassankamil10@gmail.com';
      _passwordController.text = 'Nayi52645@';
    }
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

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/screens/trailing_loader.dart';
import 'package:surveyapp/services/auth_service.dart';
import 'package:surveyapp/utils/utils.dart';

class PasswordChange extends StatefulWidget {
  const PasswordChange({super.key});

  @override
  State<PasswordChange> createState() => _PasswordChangeState();
}

class _PasswordChangeState extends State<PasswordChange> {
  bool obscure = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<ShadFormState>();

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: ShadForm(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 20,
            children: [
              ShadInputFormField(
                id: "oldPassword",
                placeholder: const Text('Current Password'),
                obscureText: obscure,
                leading: Icon(size: 16, LucideIcons.lock),
                trailing: _togglePasswordVisible(),
                validator: (value) {
                  return _validatePassword(value);
                },
              ),
              ShadInputFormField(
                id: "password",
                placeholder: const Text('New Password'),
                obscureText: obscure,
                leading: Icon(size: 16, Icons.lock),
                trailing: _togglePasswordVisible(),
                validator: (value) {
                  return _validatePassword(value);
                },
              ),
              ShadInputFormField(
                id: "passwordConfirm",
                placeholder: const Text('Confirm New Password'),
                obscureText: obscure,
                leading: Icon(size: 16, Icons.lock),
                trailing: _togglePasswordVisible(),
                validator: (value) {
                  return _validatePassword(value, isConfirm: true);
                },
              ),
              ShadButton(
                width: double.infinity,
                onPressed: _isLoading ? null : _handlePasswordChange,
                trailing: _isLoading ? const TrailingLoader() : null,
                child: _isLoading
                    ? const Text('Updating password...')
                    : const Text('Update Password'),
              )
            ],
          ),
        ),
      ),
    );
  }

  ShadIconButton _togglePasswordVisible() {
    return ShadIconButton(
      width: 24,
      height: 24,
      padding: EdgeInsets.zero,
      decoration: const ShadDecoration(
        secondaryBorder: ShadBorder.none,
        secondaryFocusedBorder: ShadBorder.none,
      ),
      icon: Icon(
        size: 16,
        obscure ? LucideIcons.eyeOff : LucideIcons.eye,
      ),
      onPressed: () {
        setState(() => obscure = !obscure);
      },
    );
  }

  String? _validatePassword(String value, {bool isConfirm = false}) {
    final field = isConfirm ? "Confirm password" : "Password";
    if (value.isEmpty) {
      return "$field is required";
    }
    if (value.length < 8) {
      return "$field must be at least 8 characters long";
    }
    if (!RegExp(r"(?=.*[A-Z])").hasMatch(value)) {
      return "$field must contain at least one uppercase letter";
    }
    if (!RegExp(r"(?=.*[a-z])").hasMatch(value)) {
      return "$field must contain at least one lowercase letter";
    }
    if (!RegExp(r"(?=.*\d)").hasMatch(value)) {
      return "$field must contain at least one digit";
    }
    if (isConfirm) {
      if (value != _formKey.currentState?.value['password']) {
        return "Password and confirm password must match";
      }
    }
    return null;
  }

  void _handlePasswordChange() async {
    if (_formKey.currentState!.saveAndValidate()) {
      setState(() => _isLoading = true);
      // final oldPassword = _formKey.currentState?.value['oldPassword'];
      // final newPassword = _formKey.currentState?.value['password'];
      // final confirmPassword = _formKey.currentState?.value['passwordConfirm'];
      try {
        final body = _formKey.currentState!.value.map((key, value) {
          return MapEntry(key.toString(), value);
        });
        await AuthService().updateProfile(body);
        if (mounted) {
          showSnackBar(
            context,
            'Password updated successfully',
            success: true,
          );
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Error updating password: $e', error: true);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}

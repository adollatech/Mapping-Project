import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:surveyapp/utils/service_response_exception.dart';
import 'package:surveyapp/utils/utils.dart';
import 'package:surveyapp/services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<ShadFormState>();
  bool _isLoading = false;
  bool obscure = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ShadCard(
              width: size < 375 ? size : 380,
              // height: 360,
              child: ShadForm(
                key: _formKey,
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
                    ShadInputFormField(
                      id: "name",
                      placeholder: const Text('Full name'),
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Your name is required";
                        }
                        if (value.length < 2) {
                          return "Enter at least two characters for your name";
                        }
                        if (!RegExp(r"^[a-zA-Z]+$").hasMatch(value)) {
                          return "Name can only contain letters";
                        }
                        return null;
                      },
                      leading: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(size: 16, LucideIcons.user),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      id: "phone",
                      placeholder: const Text('Phone number'),
                      keyboardType: TextInputType.phone,
                      maxLength: 15,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      leading: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(size: 16, LucideIcons.phone),
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Phone number is required";
                        }
                        if (!RegExp(r"^\d{10,15}$").hasMatch(value)) {
                          return "Enter a valid phone number";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      id: "email",
                      placeholder: const Text('Email address'),
                      keyboardType: TextInputType.emailAddress,
                      leading: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(size: 16, LucideIcons.mail),
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Email address is required";
                        }
                        if (!RegExp(
                                r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                            .hasMatch(value)) {
                          return "Enter a valid email address";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      id: "password",
                      placeholder: const Text('Password'),
                      obscureText: obscure,
                      leading: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(size: 16, LucideIcons.lock),
                      ),
                      trailing: _togglePasswordVisible(),
                      validator: (value) {
                        return _validatePassword(value);
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    ShadInputFormField(
                      id: "passwordConfirm",
                      placeholder: const Text('Confirm password'),
                      obscureText: obscure,
                      leading: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(size: 16, LucideIcons.lock),
                      ),
                      trailing: _togglePasswordVisible(),
                      validator: (value) {
                        return _validatePassword(value, isConfirm: true);
                      },
                    ),
                    const SizedBox(height: 24),
                    ShadButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      trailing: _isLoading
                          ? const CircularProgressIndicator.adaptive()
                          : null,
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ),
            ),
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
    if (!RegExp(r"(?=.*[@$!%*?&])").hasMatch(value)) {
      return "$field must contain at least one special character";
    }
    if (isConfirm) {
      if (value != _formKey.currentState?.value['password']) {
        return "Password and confirm password must match";
      }
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.saveAndValidate()) {
      setState(() => _isLoading = true);
      final data = _formKey.currentState?.value
          .map((key, val) => MapEntry(key as String, val));
      try {
        await AuthService().register(data!);
        if (mounted) {
          showSnackBar(context, 'Registration successful');
          // Navigator.of(context).pushReplacement(
          //     MaterialPageRoute(builder: (ctx) => const HomeScreen()));
        }
      } on ServiceResponseException catch (e) {
        if (mounted) {
          showSnackBar(context, e.error, error: true);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      showSnackBar(context, 'All fields are required');
    }
  }
}

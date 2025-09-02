import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:device_preview/device_preview.dart';
import 'package:go_router/go_router.dart';
import 'package:surveyapp/models/base_form_response.dart';
import 'package:surveyapp/models/dynamic_form.dart';
import 'package:surveyapp/models/survey_response.dart';

import 'package:surveyapp/screens/about.dart';
import 'package:surveyapp/screens/email_confirmation_screen.dart';
import 'package:surveyapp/screens/forms_screen.dart';
import 'package:surveyapp/screens/mapping_form_screen.dart';
import 'package:surveyapp/screens/profile_screen.dart';
import 'package:surveyapp/screens/reset_password_screen.dart';
import 'package:surveyapp/screens/responses_screen.dart';
import 'package:surveyapp/screens/saved_forms_screen.dart';
import 'package:surveyapp/screens/select_response_screen.dart';
import 'package:surveyapp/screens/view_mapping_screen.dart';
import 'package:surveyapp/services/auth_service.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox<String>('surveys');
  runApp(DevicePreview(
    enabled: !kReleaseMode && defaultTargetPlatform != TargetPlatform.android,
    builder: (context) => MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  bool get isLoggedIn => AuthService().isSignedIn();

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      refreshListenable: Hive.box('settings').listenable(),
      redirect: (context, state) {
        final loggingIn = ['/login', '/reset-password', '/verify-email']
            .contains(state.path ?? state.fullPath);
        if (!isLoggedIn && !loggingIn) {
          return '/login';
        }
        if (isLoggedIn && loggingIn) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          redirect: (_, __) {
            final loggedIn =
                pb.authStore.isValid && pb.authStore.record != null;
            return loggedIn ? '/home' : '/login';
          },
        ),
        GoRoute(
            path: '/form',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              final form = DynamicForm.fromJson(extra['form']);
              BaseFormResponse? response;
              if (extra['response'] != null) {
                response = BaseFormResponse.fromJson(extra['response']);
              }
              return MappingFormScreen(
                form: form,
                response: response,
              );
            }),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const ResetPasswordScreen(),
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) => const EmailConfirmationScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/about',
          builder: (context, state) => const About(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/surveys',
          builder: (context, state) => const ResponsesScreen(),
        ),
        GoRoute(
          path: '/forms',
          builder: (context, state) => const FormsScreen(),
        ),
        GoRoute(
          path: '/saved-surveys',
          builder: (context, state) => const SavedFormsScreen(),
        ),
        GoRoute(
          path: '/select-response',
          builder: (context, state) => const SelectResponsesScreen(),
        ),
        GoRoute(
          path: '/view-mapping',
          builder: (context, state) {
            final survey =
                SurveyResponse.fromJson(state.extra as Map<String, dynamic>);
            return ViewMappingScreen(survey: survey);
          },
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const SignUpScreen(),
        ),
      ],
    );

    return ValueListenableBuilder(
        valueListenable: Hive.box('settings').listenable(),
        builder: (context, settings, child) {
          final savedTheme = settings.get('theme', defaultValue: 'system');
          final themeMode = savedTheme == 'light'
              ? ThemeMode.light
              : savedTheme == 'dark'
                  ? ThemeMode.dark
                  : ThemeMode.system;
          return ShadApp.router(
            title: 'LapTrace',
            darkTheme: ShadThemeData(
              brightness: Brightness.dark,
              colorScheme: ShadGrayColorScheme.dark(),
            ),
            themeMode: themeMode,
            theme: ShadThemeData(
                colorScheme: ShadSlateColorScheme.light(),
                brightness: Brightness.light),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        });
  }
}

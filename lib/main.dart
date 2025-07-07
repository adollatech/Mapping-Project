import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:device_preview/device_preview.dart';

import 'package:surveyapp/screens/about.dart';
import 'package:surveyapp/screens/boundary_mapping.dart';
import 'package:surveyapp/screens/email_confirmation_screen.dart';
import 'package:surveyapp/screens/mapping_form_screen.dart';
import 'package:surveyapp/screens/profile_screen.dart';
import 'package:surveyapp/screens/reset_password_screen.dart';

import 'screens/data_sync_screen.dart';
import 'screens/home_screen.dart';
// import 'package:workmanager/workmanager.dart';

import 'screens/login_screen.dart';
import 'screens/mapping_list_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signup_screen.dart';

// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     switch (task) {
//       case 'simpleTask':
//         // Perform your background task here
//         log("Executing background task: $task");
//         break;
//       default:
//         log("Unknown task: $task");
//     }
//     return Future.value(true);
//   });
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('settings');
  runApp(DevicePreview(
    enabled: !kReleaseMode,
    builder: (context) => MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: Hive.box('settings').listenable(),
        builder: (context, settings, child) {
          final isLoggedIn = settings.containsKey('pb_auth') &&
              settings.get('pb_auth') != null;
          final savedTheme = settings.get('theme', defaultValue: 'system');
          final themeMode = savedTheme == 'light'
              ? ThemeMode.light
              : savedTheme == 'dark'
                  ? ThemeMode.dark
                  : ThemeMode.system;
          return ShadApp(
            title: 'LapTrace',
            darkTheme: ShadThemeData(
              brightness: Brightness.dark,
              colorScheme: ShadGrayColorScheme.dark(),
            ),
            themeMode: themeMode,
            theme: ShadThemeData(
                colorScheme: ShadSlateColorScheme.light(),
                brightness: Brightness.light),
            home: ValueListenableBuilder(
                valueListenable: settings.listenable(),
                builder: (context, box, w) {
                  if (box.containsKey('pb_auth') &&
                      box.get('pb_auth') != null) {
                    return const HomeScreen();
                  }
                  return const LoginScreen();
                }),
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (ctx) {
                  switch (settings.name) {
                    case '/':
                      return isLoggedIn ? const HomeScreen() : LoginScreen();
                    case '/login':
                      return const LoginScreen();
                    case '/signup':
                      return const SignUpScreen();
                    case '/reset-password':
                      return const ResetPasswordScreen();
                    case '/verify-email':
                      return const EmailConfirmationScreen();
                    case '/new-survey':
                      return const MappingFormScreen();
                    case '/map':
                      return const BoundaryMapping();
                    case '/register':
                      return const SignUpScreen();
                    case '/home':
                      return const HomeScreen();
                    case '/mapping_list':
                      return const MappingListScreen();
                    case '/settings':
                      return const SettingsScreen();
                    case '/data_sync':
                      return const DataSyncScreen();
                    case '/about':
                      return const About();
                    case '/profile':
                      return const ProfileScreen();
                    default:
                      return isLoggedIn ? const HomeScreen() : LoginScreen();
                  }
                },
              );
            },
            routes: {
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/reset-password': (context) => const ResetPasswordScreen(),
              '/verify-email': (context) => const EmailConfirmationScreen(),
              '/new-survey': (context) => const MappingFormScreen(),
              '/map': (context) => const BoundaryMapping(),
              '/register': (context) => const SignUpScreen(),
              '/home': (context) => const HomeScreen(),
              '/mapping_list': (context) => const MappingListScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/data_sync': (context) => const DataSyncScreen(),
              '/about': (context) => const About(),
              '/profile': (context) => const ProfileScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        });
  }
}

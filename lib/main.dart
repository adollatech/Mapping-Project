import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:device_preview/device_preview.dart';

import 'package:surveyapp/screens/about.dart';
import 'package:surveyapp/screens/email_confirmation_screen.dart';
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
  // Workmanager().initialize(
  //   callbackDispatcher,
  //   isInDebugMode: true, // Set to false in production
  // );
  // Workmanager().registerPeriodicTask(
  //   "uniquePeriodicTaskName",
  //   "simpleTask",
  //   frequency: Duration(hours: 1), // Minimum 15 minutes
  // );

  await Hive.initFlutter();
  await Hive.openBox('auth');
  runApp(DevicePreview(
    enabled: !kReleaseMode,
    builder: (context) => MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'LapTrace',
      darkTheme: ShadThemeData(
      brightness: Brightness.dark,
      colorScheme:  ShadGrayColorScheme.dark(),
      ),
      
      theme: ShadThemeData(
          colorScheme: ShadSlateColorScheme.light(),
          brightness: Brightness.light),
      home: ValueListenableBuilder(
        valueListenable: Hive.box("auth").listenable(),
        builder: (context, auth, w) {
          if (auth.containsKey('pb_auth') && auth.get('pb_auth') != null) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/verify-email': (context) => const EmailConfirmationScreen(),
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
  }
}

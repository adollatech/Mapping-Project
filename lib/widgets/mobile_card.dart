import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class MobileCard extends StatelessWidget {
  const MobileCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width;
    final isLargeScreenDevice =
        kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    return Scaffold(
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                    child: IntrinsicHeight(
                  child: SingleChildScrollView(
                    child: ShadCard(
                        width: isLargeScreenDevice ? 374 : size,
                        child: child),
                  ),
                )))));
  }
}

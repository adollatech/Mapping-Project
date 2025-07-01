import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class TappableCard extends StatelessWidget {
  const TappableCard(
      {super.key,
      required this.onTap,
      required this.title,
      this.subtitle,
      required this.icon});
  final VoidCallback onTap;
  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ShadCard(
        title: Row(
          spacing: 8,
          children: [
            Icon(
              icon,
              size: 24,
            ),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        child: subtitle != null
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  subtitle!,
                  overflow: TextOverflow.visible,
                  textScaler: TextScaler.linear(
                    0.9,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            : null,
      ),
    );
  }
}
